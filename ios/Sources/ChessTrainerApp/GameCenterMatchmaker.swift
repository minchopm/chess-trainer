import ChessTraining
import Foundation
import Observation
#if canImport(GameKit)
@preconcurrency import GameKit
#endif
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

/// Carries a non-Sendable Game Center object from its callback to the main
/// actor. Nothing else touches it in between.
private final class UncheckedBox<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}

/// Game Center: who you are, and finding somebody to play.
///
/// Matchmaking is programmatic rather than through GKMatchmakerViewController.
/// The only choice this game offers is the clock, and that is already made
/// before you press the button, so Apple's sheet would add a screen that asks
/// nothing.
@MainActor
@Observable
public final class GameCenterMatchmaker: NSObject {
    public enum State: Equatable {
        case signedOut
        case authenticating
        case ready
        case searching(TimeControl)
        case connected
        case failed(String)
    }

    public private(set) var state: State = .signedOut
    public private(set) var localName = "You"
    public private(set) var localPlayerID = "local"
    public private(set) var status = "Sign in to Game Center to play online."
    /// The session for the match in progress, once one is connected.
    public private(set) var session: MatchSession?
    /// Set when Game Center wants to show its sign-in screen.
    public var pendingAuthController: AuthControllerItem?

    public struct AuthControllerItem: Identifiable {
        public let id = UUID()
        #if canImport(UIKit)
        public let controller: UIViewController
        #endif
    }

    /// Called with the result once a match has finished, so the app can record
    /// it. The session itself has no idea where progress is kept.
    public var onMatchFinished: ((MatchResult) -> Void)?

    public var isAuthenticated: Bool {
        if case .signedOut = state { return false }
        if case .authenticating = state { return false }
        return true
    }

    #if canImport(GameKit)
    private var match: GKMatch?
    private var timeControl: TimeControl = .five
    private var localRating = OnlineElo.starting
    private var localGames = 0
    private var disconnectWork: Task<Void, Never>?
    /// How long an opponent may be gone before the game is given to you. Long
    /// enough for a lift or a tunnel, short enough that nobody sits waiting on
    /// somebody who has closed the app.
    private static let reconnectGrace: TimeInterval = 45
    #endif

    public override init() { super.init() }

#if DEBUG
    private var _loopback: LoopbackMatch?
#endif

    public func authenticate() {
        #if canImport(GameKit)
        state = .authenticating
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor in
                guard let self else { return }
                #if canImport(UIKit)
                if let controller {
                    self.pendingAuthController = AuthControllerItem(controller: controller)
                    self.status = "Sign in to Game Center to play online."
                    return
                }
                #endif
                if let error {
                    self.state = .failed(error.localizedDescription)
                    self.status = error.localizedDescription
                    return
                }
                guard GKLocalPlayer.local.isAuthenticated else {
                    self.state = .signedOut
                    self.status = "Game Center sign-in was cancelled."
                    return
                }
                self.localPlayerID = GKLocalPlayer.local.gamePlayerID
                self.localName = GKLocalPlayer.local.alias
                self.pendingAuthController = nil
                self.state = .ready
                self.status = "Signed in as \(self.localName)."
            }
        }
        #else
        state = .failed("Online play needs Game Center.")
        status = "Online play needs Game Center."
        #endif
    }

    public func findOpponent(timeControl: TimeControl, rating: Int, games: Int) {
        #if canImport(GameKit)
        guard isAuthenticated else {
            authenticate()
            return
        }
        self.timeControl = timeControl
        localRating = rating
        localGames = games

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        // The pool is the clock. Nobody who asked for thirty minutes should be
        // handed a three-minute game.
        request.playerGroup = timeControl.playerGroup

        state = .searching(timeControl)
        status = "Looking for a \(timeControl.label) opponent…"

        GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
            // GKMatch is not Sendable, and the callback lands off the main
            // actor. The box carries it across without the compiler having to
            // take Game Center's word for its thread safety.
            let carried = match.map { UncheckedBox($0) }
            let message = error?.localizedDescription
            Task { @MainActor in
                guard let self else { return }
                guard case .searching = self.state else {
                    carried?.value.disconnect()
                    return
                }
                if let message {
                    self.state = .ready
                    self.status = message
                    return
                }
                guard let carried else {
                    self.state = .ready
                    self.status = "No opponent was found."
                    return
                }
                self.begin(carried.value)
            }
        }
        #endif
    }

    /// Drive the clocks. Both sides of a debug loopback match need ticking;
    /// over a real network the opponent's device does its own.
    public func tick(now: Date) {
        session?.tick(now: now)
#if DEBUG
        loopback?.theirs.tick(now: now)
#endif
    }

    public func cancelSearch() {
        #if canImport(GameKit)
        GKMatchmaker.shared().cancel()
        #endif
        guard isAuthenticated else { return }
        state = .ready
        status = "Search cancelled."
    }

    public func leaveMatch() {
        #if canImport(GameKit)
        disconnectWork?.cancel()
        disconnectWork = nil
        match?.disconnect()
        match = nil
        #endif
        session = nil
#if DEBUG
        loopback = nil
#endif
        if isAuthenticated {
            state = .ready
            status = "Signed in as \(localName)."
        }
    }

#if DEBUG
    /// A match against a second session in this process, wired to the first.
    ///
    /// Game Center cannot be signed into on a simulator, so without this the
    /// clocks, the player rows and the result overlay could only be looked at
    /// on two real devices with two Apple IDs. It plays a random legal move for
    /// the opponent — it is a way to see the screen work, not an opponent.
    public func startLoopbackMatch(timeControl: TimeControl, rating: Int, games: Int) {
        let harness = LoopbackMatch(timeControl: timeControl, rating: rating, games: games)
        loopback = harness
        session = harness.mine
        state = .connected
        status = "Local test game (debug build only)."
        harness.begin()
    }

    private var loopback: LoopbackMatch? {
        get { _loopback }
        set { _loopback = newValue }
    }
#endif

    #if canImport(GameKit)
    private func begin(_ match: GKMatch) {
        self.match = match
        match.delegate = self

        // The host is settled by sorting the two player IDs, so both devices
        // reach the same answer without asking each other. It decides colours;
        // it has no other authority, because both sides run the rules.
        let remoteID = match.players.first?.gamePlayerID ?? ""
        let isHost = localPlayerID < remoteID

        let session = MatchSession(
            transport: self,
            me: .init(playerID: localPlayerID, name: localName, rating: localRating, games: localGames),
            isHost: isHost,
            timeControl: timeControl
        )
        self.session = session
        state = .connected
        status = "Connected."
        session.begin()
    }
    #endif
}

#if canImport(GameKit)
extension GameCenterMatchmaker: MatchTransport {
    nonisolated public func send(_ data: Data) {
        Task { @MainActor in
            // Reliable: a chess move is not a position update that a later one
            // replaces. Losing one stops the game dead.
            try? self.match?.send(data, to: self.match?.players ?? [], dataMode: .reliable)
        }
    }
}

extension GameCenterMatchmaker: @preconcurrency GKMatchDelegate {
    public func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        Task { @MainActor in
            guard self.match === match else { return }
            self.session?.receive(data)
        }
    }

    public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        Task { @MainActor in
            guard self.match === match else { return }
            switch state {
            case .disconnected:
                self.status = "\(player.alias) disconnected — waiting for them to come back…"
                self.disconnectWork?.cancel()
                self.disconnectWork = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(Self.reconnectGrace))
                    guard !Task.isCancelled, let self else { return }
                    self.status = "\(player.alias) did not come back."
                    self.session?.opponentDisconnected()
                }
            case .connected:
                self.disconnectWork?.cancel()
                self.disconnectWork = nil
                self.status = "Connected."
            default:
                break
            }
        }
    }

    public func match(_ match: GKMatch, didFailWithError error: Error?) {
        Task { @MainActor in
            guard self.match === match, let error else { return }
            self.status = error.localizedDescription
        }
    }
}
#else
extension GameCenterMatchmaker: MatchTransport {
    nonisolated public func send(_ data: Data) {}
}
#endif

#if canImport(UIKit)
/// Puts Game Center's own sign-in screen on screen. It hands back a UIKit
/// controller and there is no SwiftUI equivalent to present instead.
struct HostedController: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController { controller }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif


#if DEBUG
/// Two sessions in one process, each one's packets handed to the other.
@MainActor
final class LoopbackMatch {
    let mine: MatchSession
    let theirs: MatchSession

    private final class Link: MatchTransport {
        weak var peer: MatchSession?
        func send(_ data: Data) {
            let peer = self.peer
            // Through a hop, so a packet never lands inside the send that
            // produced it — over a network it never would.
            Task { @MainActor in peer?.receive(data) }
        }
    }

    private let myLink = Link()
    private let theirLink = Link()
    private var play: Task<Void, Never>?

    init(timeControl: TimeControl, rating: Int, games: Int) {
        mine = MatchSession(
            transport: myLink,
            me: .init(playerID: "local", name: "You", rating: rating, games: games),
            isHost: true, timeControl: timeControl
        )
        theirs = MatchSession(
            transport: theirLink,
            me: .init(playerID: "sparring", name: "Sparring bot", rating: 1200, games: 40),
            isHost: false, timeControl: timeControl
        )
        myLink.peer = theirs
        theirLink.peer = mine
    }

    func begin() {
        theirs.begin()
        mine.begin(whiteIsHost: true)
        play = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(900))
                guard let self, case .playing = self.theirs.phase, self.theirs.isMyTurn else { continue }
                guard let move = self.theirs.position.legalMoves().randomElement() else { continue }
                self.theirs.play(from: move.from, to: move.to, promotion: move.promotion)
            }
        }
    }

    deinit { play?.cancel() }
}
#endif
