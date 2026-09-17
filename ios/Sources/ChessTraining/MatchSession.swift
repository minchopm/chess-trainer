import ChessCore
import Foundation
import Observation

/// Where a match's packets go. Game Center provides one of these; the tests
/// provide another that hands packets straight to a second session, which is
/// what lets a whole game be played — moves, clock, resignation, rating —
/// without two devices and two Apple IDs.
@MainActor
public protocol MatchTransport: AnyObject {
    func send(_ data: Data)
}

/// One online game.
///
/// Both devices run this, and both run the rules. Nothing arriving over the
/// wire is taken on trust: a move is played only if it is legal in the position
/// this device already has, so a peer that lies produces a dropped packet
/// rather than an illegal board.
@MainActor
@Observable
public final class MatchSession {
    public enum Phase: Equatable, Sendable {
        case waiting            // connected, waiting for the host to deal colours
        case playing
        case finished(MatchResult)
    }

    public private(set) var phase: Phase = .waiting
    public private(set) var position = Position()
    public private(set) var legalDestinations: [Square: [Square]] = [:]
    public private(set) var lastMove: (from: Square, to: Square)?
    public private(set) var myColor: PieceColor = .white
    public private(set) var clock: ChessClock
    public private(set) var moves: [String] = []          // SAN, for the move list
    public private(set) var opponent: MatchPacket.Hello?
    /// True while the opponent's draw offer is on the table.
    public private(set) var drawOffered = false
    public private(set) var drawOfferSent = false

    public let timeControl: TimeControl
    public let isHost: Bool
    public let me: MatchPacket.Hello

    private weak var transport: MatchTransport?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var ply = 0
    /// Set once `begin` has been called, so a hello that arrives before this
    /// device is ready does not start a game it has not been asked for yet.
    private var hasBegun = false
    private var whiteIsHost: Bool?
    private var lastHello: Date?
    /// When the opponent's clock first read zero here. See `tick`.
    private var opponentFlaggedSince: Date?
    /// How long the opponent's flag has to stand before it is claimed.
    private static let flagGrace: TimeInterval = 3

    public var isMyTurn: Bool {
        if case .playing = phase { return position.sideToMove == myColor }
        return false
    }

    public var myClockKey: ChessClock.PieceColorKey { Self.key(myColor) }
    public var opponentClockKey: ChessClock.PieceColorKey { Self.key(myColor.opponent) }

    public init(
        transport: MatchTransport,
        me: MatchPacket.Hello,
        isHost: Bool,
        timeControl: TimeControl
    ) {
        self.transport = transport
        self.me = me
        self.isHost = isHost
        self.timeControl = timeControl
        self.clock = ChessClock(timeControl: timeControl)
    }

    /// Say hello, and — if this device is the host — deal the colours.
    ///
    /// The host decides because two devices choosing at random would disagree
    /// half the time. It decides *randomly* so that being the host, which comes
    /// down to which player ID sorts first, is not worth a colour.
    public func begin(whiteIsHost: Bool? = nil) {
        self.whiteIsHost = whiteIsHost
        hasBegun = true
        send(.hello(me))
        dealColours()
    }

    /// Deal the colours, once there is somebody to deal them to.
    ///
    /// The host used to do this in `begin`, the instant Game Center handed back
    /// a match. That is too early. The two devices do not finish connecting at
    /// the same moment, and a packet sent before the other end has a session to
    /// hand it to is dropped — it is not queued and it is never asked for
    /// again. The guest then sat on "Connecting…" waiting for a start that had
    /// already been spent, which is a game that never begins and never fails
    /// either.
    ///
    /// So the deal waits for the guest's own hello, which is the one piece of
    /// evidence that there is a session at the other end listening. Called from
    /// both ends of that — `begin` and the arrival of a hello — because either
    /// may be the one that happens last.
    private func dealColours() {
        guard isHost, hasBegun, opponent != nil, case .waiting = phase else { return }
        let hostPlaysWhite = whiteIsHost ?? Bool.random()
        myColor = hostPlaysWhite ? .white : .black
        // Ours again with it: if the hello this device sent was the one that
        // was dropped, this is the copy the guest shows in the player row.
        send(.hello(me))
        send(.start(MatchPacket.Start(
            youPlay: hostPlaysWhite ? .black : .white,
            timeControl: timeControl
        )))
        startPlaying()
    }

    public func receive(_ data: Data) {
        guard let packet = try? decoder.decode(MatchPacket.self, from: data) else { return }
        switch packet {
        case .hello(let hello):
            opponent = hello
            dealColours()

        case .start(let start):
            // Only the guest is told what to play, and only once.
            guard !isHost, case .waiting = phase else { return }
            myColor = start.receiverColor
            startPlaying()

        case .move(let move):
            applyRemote(move)

        case .resign:
            finish(MatchResult(outcome: .win, reason: .resignation))

        case .drawOffer:
            guard case .playing = phase else { return }
            drawOffered = true

        case .drawResponse(let accepted):
            drawOfferSent = false
            if accepted { finish(MatchResult(outcome: .draw, reason: .agreement)) }

        case .gameOver(let over):
            // The other device saw the end first. Believe it only about things
            // it is entitled to declare: its own flag, or a result this device
            // can confirm from its own board.
            accept(over)
        }
    }

    // MARK: - Playing

    @discardableResult
    public func play(from: Square, to: Square, promotion: PieceKind?) -> Bool {
        guard isMyTurn else { return false }
        let notation = Move(from: from, to: to, promotion: promotion)
        guard let move = position.legalMoves().first(where: { $0.matchesNotation(of: notation) })
        else { return false }

        apply(move)
        send(.move(MatchPacket.MovePacket(
            uci: move.uci, ply: ply,
            remaining: clock.remaining(myClockKey),
            yours: clock.remaining(opponentClockKey)
        )))
        checkGameOverAfterMove(justMovedBy: myColor)
        return true
    }

    public func resign() {
        guard case .playing = phase else { return }
        send(.resign)
        finish(MatchResult(outcome: .loss, reason: .resignation))
    }

    public func offerDraw() {
        guard case .playing = phase, !drawOfferSent else { return }
        drawOfferSent = true
        send(.drawOffer)
    }

    public func respondToDraw(accept: Bool) {
        guard drawOffered else { return }
        drawOffered = false
        send(.drawResponse(accepted: accept))
        if accept { finish(MatchResult(outcome: .draw, reason: .agreement)) }
    }

    /// Called on a display timer: the clocks are read here, and a game that
    /// has run out of time is ended here.
    ///
    /// Both flags, not just this device's own. Claiming only your own reads
    /// well — the device whose clock ran out is the one that knows it — but it
    /// assumes that device is awake to say so, and a phone whose screen has
    /// locked or an app in the background is not. The game then carried on
    /// past zero with the clock showing nothing left, and was decided by
    /// whatever happened next instead.
    ///
    /// The opponent's flag waits out `flagGrace` first. This device's reading
    /// of their clock is the lower of the two by design, and their move may be
    /// on the wire as it runs out; a few seconds of doubt costs nothing and
    /// turns a slow network into a lost second rather than a lost game.
    public func tick(now: Date = Date()) {
        // Still waiting: say hello again. The first one can be spent before
        // the other device has a session to receive it, and one lost packet
        // would otherwise cost the whole game — both ends sitting on
        // "Connecting…", each waiting for the other to speak first. A few
        // bytes a second until somebody answers is the cheap way out.
        if case .waiting = phase {
            guard lastHello.map({ now.timeIntervalSince($0) >= 1 }) ?? true else { return }
            lastHello = now
            send(.hello(me))
            return
        }
        guard case .playing = phase, clock.isRunning else { return }

        if clock.hasFlagged(myClockKey, at: now) {
            send(.gameOver(MatchPacket.GameOver(winner: myColor.opponent, reason: .timeout)))
            finish(MatchResult(outcome: .loss, reason: .timeout))
            return
        }

        guard clock.hasFlagged(opponentClockKey, at: now) else {
            opponentFlaggedSince = nil
            return
        }
        let since = opponentFlaggedSince ?? now
        opponentFlaggedSince = since
        guard now.timeIntervalSince(since) >= Self.flagGrace else { return }
        send(.gameOver(MatchPacket.GameOver(winner: myColor, reason: .timeout)))
        finish(MatchResult(outcome: .win, reason: .timeout))
    }

    /// The opponent left and did not come back.
    public func opponentDisconnected() {
        guard case .playing = phase else { return }
        finish(MatchResult(outcome: .win, reason: .disconnected))
    }

    /// Apply the rating change and hand back the finished result.
    @discardableResult
    public func settle(rating: Int, games: Int) -> MatchResult? {
        guard case .finished(var result) = phase, result.ratingDelta == 0 else { return nil }
        let opponentRating = opponent?.rating ?? OnlineElo.starting
        let updated = OnlineElo.updated(
            rating: rating, games: games, against: opponentRating, score: result.score
        )
        result.ratingDelta = updated - rating
        phase = .finished(result)
        return result
    }

    // MARK: - Internals

    private static func key(_ color: PieceColor) -> ChessClock.PieceColorKey {
        color == .white ? .white : .black
    }

    private func startPlaying() {
        position = Position()
        ply = 0
        moves = []
        lastMove = nil
        clock = ChessClock(timeControl: timeControl)
        clock.start()
        phase = .playing
        refreshDestinations()
    }

    private func apply(_ move: Move) {
        let san = position.san(for: move)
        position.make(move)
        moves.append(san)
        lastMove = (from: move.from, to: move.to)
        ply += 1
        clock.press()
        drawOffered = false
        refreshDestinations()
    }

    private func applyRemote(_ packet: MatchPacket.MovePacket) {
        guard case .playing = phase, position.sideToMove != myColor else { return }
        // A move for a ply that has already been played is a duplicate from a
        // retry, not a second move.
        guard packet.ply == ply + 1 else { return }
        guard let parsed = Move(uci: packet.uci),
              let move = position.legalMoves().first(where: { $0.matchesNotation(of: parsed) })
        else { return }

        apply(move)
        clock.adopt(packet.remaining, for: opponentClockKey)
        // And their reading of mine. Downwards only, like theirs — see
        // `MovePacket.yours` for why both directions are needed.
        if let mine = packet.yours { clock.adopt(mine, for: myClockKey) }
        checkGameOverAfterMove(justMovedBy: myColor.opponent)
    }

    private func checkGameOverAfterMove(justMovedBy mover: PieceColor) {
        guard case .playing = phase else { return }
        if position.isCheckmate {
            let over = MatchPacket.GameOver(winner: mover, reason: .checkmate)
            if mover == myColor { send(.gameOver(over)) }
            finish(MatchResult(
                outcome: mover == myColor ? .win : .loss, reason: .checkmate
            ))
            return
        }
        guard position.isDraw else { return }
        let reason: MatchResult.Reason = if position.isStalemate {
            .stalemate
        } else if position.isInsufficientMaterial {
            .insufficientMaterial
        } else if position.isThreefoldRepetition {
            .repetition
        } else {
            .fiftyMoveRule
        }
        if mover == myColor { send(.gameOver(MatchPacket.GameOver(winner: nil, reason: reason))) }
        finish(MatchResult(outcome: .draw, reason: reason))
    }

    private func accept(_ over: MatchPacket.GameOver) {
        guard case .playing = phase else { return }
        let outcome: MatchResult.Outcome = if let winner = over.winnerColor {
            winner == myColor ? .win : .loss
        } else {
            .draw
        }
        finish(MatchResult(outcome: outcome, reason: over.resultReason))
    }

    private func finish(_ result: MatchResult) {
        guard case .playing = phase else { return }
        clock.stop()
        legalDestinations = [:]
        drawOffered = false
        drawOfferSent = false
        phase = .finished(result)
    }

    private func refreshDestinations() {
        guard isMyTurn else {
            legalDestinations = [:]
            return
        }
        var map: [Square: [Square]] = [:]
        for move in position.legalMoves() { map[move.from, default: []].append(move.to) }
        legalDestinations = map
    }

    private func send(_ packet: MatchPacket) {
        guard let data = try? encoder.encode(packet) else { return }
        transport?.send(data)
    }
}
