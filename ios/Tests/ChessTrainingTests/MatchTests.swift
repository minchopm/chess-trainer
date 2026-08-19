import ChessCore
import Foundation
import Testing
@testable import ChessTraining

/// Hands every packet straight to the other session, so a whole game can be
/// played in a test without Game Center, two devices or two Apple IDs.
@MainActor
final class LoopbackTransport: MatchTransport {
    weak var peer: MatchSession?
    var dropped = false

    func send(_ data: Data) {
        guard !dropped else { return }
        peer?.receive(data)
    }
}

/// Holds the transports as well as the sessions. A session keeps only a weak
/// reference to its transport — in the app the Game Center service owns it, and
/// a strong link back would be a cycle — so a test that let them go out of
/// scope would be testing two sessions shouting into a void.
@MainActor
private final class Pair {
    let host: MatchSession
    let guest: MatchSession
    let hostTransport = LoopbackTransport()
    let guestTransport = LoopbackTransport()

    init(timeControl: TimeControl = .five) {
        host = MatchSession(
            transport: hostTransport,
            me: .init(playerID: "A", name: "Ann", rating: 1200, games: 0),
            isHost: true, timeControl: timeControl
        )
        guest = MatchSession(
            transport: guestTransport,
            me: .init(playerID: "B", name: "Bo", rating: 1200, games: 0),
            isHost: false, timeControl: timeControl
        )
        hostTransport.peer = guest
        guestTransport.peer = host
    }

    /// Both devices announce themselves; only the host deals the colours.
    func begin(hostPlaysWhite: Bool = true) {
        guest.begin()
        host.begin(whiteIsHost: hostPlaysWhite)
    }
}

@MainActor
private func makePair(timeControl: TimeControl = .five) -> Pair {
    Pair(timeControl: timeControl)
}

@Suite("Online match")
@MainActor
struct MatchTests {
    @Test("The host deals the colours and both sides agree")
    func colours() {
        let pair = makePair()
        pair.begin()

        #expect(pair.host.myColor == .white)
        #expect(pair.guest.myColor == .black)
        #expect(pair.host.isMyTurn)
        #expect(!pair.guest.isMyTurn)
        #expect(pair.guest.opponent?.name == "Ann")
        #expect(pair.host.opponent?.name == "Bo")
    }

    @Test("A move made on one board appears on the other")
    func movesCross() {
        let pair = makePair()
        pair.begin()

        #expect(pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil))
        #expect(pair.guest.position.fen == pair.host.position.fen)
        #expect(pair.guest.moves == ["e4"])
        #expect(pair.guest.isMyTurn)
        #expect(!pair.host.isMyTurn)
    }

    @Test("A move out of turn is refused rather than sent")
    func refusesOutOfTurn() {
        let pair = makePair()
        pair.begin()

        #expect(!pair.guest.play(from: Square("e7")!, to: Square("e5")!, promotion: nil))
        #expect(pair.guest.moves.isEmpty)
        #expect(pair.host.moves.isEmpty)
    }

    @Test("Checkmate ends both sides, one as a win and one as a loss")
    func checkmate() {
        let pair = makePair()
        pair.begin()

        // Fool's mate: 1.f3 e5 2.g4 Qh4#
        pair.host.play(from: Square("f2")!, to: Square("f3")!, promotion: nil)
        pair.guest.play(from: Square("e7")!, to: Square("e5")!, promotion: nil)
        pair.host.play(from: Square("g2")!, to: Square("g4")!, promotion: nil)
        pair.guest.play(from: Square("d8")!, to: Square("h4")!, promotion: nil)

        #expect(pair.guest.phase == .finished(MatchResult(outcome: .win, reason: .checkmate)))
        #expect(pair.host.phase == .finished(MatchResult(outcome: .loss, reason: .checkmate)))
    }

    @Test("Resigning loses for the sender and wins for the receiver")
    func resignation() {
        let pair = makePair()
        pair.begin()
        pair.host.resign()

        #expect(pair.host.phase == .finished(MatchResult(outcome: .loss, reason: .resignation)))
        #expect(pair.guest.phase == .finished(MatchResult(outcome: .win, reason: .resignation)))
    }

    @Test("A draw is agreed only when the offer is accepted")
    func drawOffer() {
        let pair = makePair()
        pair.begin()

        pair.host.offerDraw()
        #expect(pair.guest.drawOffered)

        pair.guest.respondToDraw(accept: false)
        #expect(!pair.guest.drawOffered)
        #expect(pair.host.phase == .playing)

        pair.host.offerDraw()
        pair.guest.respondToDraw(accept: true)
        #expect(pair.host.phase == .finished(MatchResult(outcome: .draw, reason: .agreement)))
        #expect(pair.guest.phase == .finished(MatchResult(outcome: .draw, reason: .agreement)))
    }

    @Test("Your own flag ends the game; the opponent's does not")
    func flagFall() {
        let pair = makePair(timeControl: .three)
        pair.begin()
        let later = Date().addingTimeInterval(TimeControl.three.seconds + 1)

        // The side not to move has burned no time, so its own tick is silent.
        pair.guest.tick(now: later)
        #expect(pair.guest.phase == .playing)

        pair.host.tick(now: later)
        #expect(pair.host.phase == .finished(MatchResult(outcome: .loss, reason: .timeout)))
        #expect(pair.guest.phase == .finished(MatchResult(outcome: .win, reason: .timeout)))
    }

    @Test("A packet from a peer that lies is dropped, not played")
    func rejectsIllegalRemoteMoves() throws {
        let pair = makePair()
        pair.begin()
        pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil)

        // A rook teleporting off its starting square, with the right ply.
        let lie = MatchPacket.move(.init(uci: "a8a5", ply: 2, remaining: 100))
        pair.host.receive(try JSONEncoder().encode(lie))

        #expect(pair.host.moves == ["e4"])
        #expect(pair.host.position[Square("a8")!] == Piece(.black, .rook))
    }

    @Test("A move replayed after a retry is not played twice")
    func ignoresDuplicates() throws {
        let pair = makePair()
        pair.begin()
        pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil)
        pair.guest.play(from: Square("e7")!, to: Square("e5")!, promotion: nil)

        let repeated = MatchPacket.move(.init(uci: "e7e5", ply: 2, remaining: 100))
        pair.host.receive(try JSONEncoder().encode(repeated))

        #expect(pair.host.moves == ["e4", "e5"])
    }

    @Test("The opponent's clock is trusted downwards only")
    func clockCannotBeInflated() throws {
        let pair = makePair(timeControl: .three)
        pair.begin()
        pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil)

        let generous = MatchPacket.move(.init(uci: "e7e5", ply: 2, remaining: 9_999))
        pair.host.receive(try JSONEncoder().encode(generous))

        #expect(pair.host.clock.remaining(.black) <= TimeControl.three.seconds)
    }

    @Test("The rating moves by the usual Elo, once")
    func rating() {
        let pair = makePair()
        pair.begin()
        pair.host.resign()

        let settled = pair.guest.settle(rating: 1200, games: 0)
        #expect(settled?.ratingDelta == 20)          // K=40, even ratings, a win
        #expect(pair.guest.settle(rating: 1220, games: 1) == nil)
    }
}
