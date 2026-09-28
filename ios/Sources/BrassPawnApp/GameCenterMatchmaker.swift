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

    /// Whether there is a real Game Center player to put in an invitation.
    ///
    /// Stricter than `isAuthenticated`, which is only about the state machine:
    /// on a simulator with nobody signed in the state settles at `.ready` while
    /// the player ID is still the placeholder. A link built from the
    /// placeholder names nobody, so the offer to send one is withheld until
    /// there is somebody to name.
    public var canInvite: Bool {
        isAuthenticated && localPlayerID != "local"
    }

    #if canImport(GameKit)
    private var match: GKMatch?
    /// The opponent in the match under way, as Game Center knows them — whose
    /// rating is read from Game Center rather than taken from what they say.
    public var opponentPlayer: GKPlayer? { match?.players.first }
    private var timeControl: TimeControl = .five
    private var localRating = Glicko.starting
    private var localGames = 0
    private var localDeviation = Glicko.newDeviation
    private var disconnectWork: Task<Void, Never>?
    private var connectWork: Task<Void, Never>?
    /// How long two paired devices are given to actually reach each other.
    /// Being matched and never connecting is a real outcome — a message beats
    /// a screen that says Connecting for ever.
    private static let connectGrace: TimeInterval = 20
    /// How long an opponent may be gone before the game is given to you. Long
    /// enough for a lift or a tunnel, short enough that nobody sits waiting on
    /// somebody who has closed the app.
    private static let reconnectGrace: TimeInterval = 45
    #endif

    /// This player's rating and games on a clock — for a match that starts
    /// from an invitation, which can arrive anywhere in the app rather than
    /// from the lobby that knows them.
    public var ratingLookup: ((TimeControl) -> (rating: Int, games: Int, deviation: Double))?
    /// Signed in: time to tell the rank lists this player is still about.
    public var onAuthenticated: (() -> Void)?
    /// An invitation was accepted, from Game Center's own notification: the
    /// app should be on the online screen for the game that follows.
    public var onInviteAccepted: (() -> Void)?
    /// Who is being invited, while an invitation is out.
    public private(set) var invitee: String?
    /// Whether the search under way is the open one, among everybody on the
    /// clock, rather than an invitation — which decides whether its games
    /// can be rated (`MatchSession.openPool`).
    private var openPool = true

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
                // Only while nothing is under way: signing in again mid-game
                // must not put the lobby back.
                if case .authenticating = self.state {
                    self.state = .ready
                    self.status = "Signed in as \(self.localName)."
                }
                // Invitations sent to this player arrive through the listener,
                // including the one whose notification opened the app.
                GKLocalPlayer.local.unregisterAllListeners()
                GKLocalPlayer.local.register(self)
                self.onAuthenticated?()
            }
        }
        #else
        state = .failed("Online play needs Game Center.")
        status = "Online play needs Game Center."
        #endif
    }

    /// Look for a game.
    ///
    /// With an `invitation`, the search happens in that invitation's own pool
    /// rather than the clock's, so the only person who can be found is the one
    /// who sent the link. It is the nearest Game Center comes to a named
    /// opponent: it pairs by pool, never by player.
    public func findOpponent(
        timeControl: TimeControl,
        rating: Int,
        games: Int,
        deviation: Double,
        invitation: Invitation? = nil
    ) {
        #if canImport(GameKit)
        guard isAuthenticated else {
            authenticate()
            return
        }
        self.timeControl = timeControl
        localRating = rating
        localGames = games
        localDeviation = deviation
        openPool = invitation == nil

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        // The pool is the clock. Nobody who asked for thirty minutes should be
        // handed a three-minute game.
        request.playerGroup = invitation?.playerGroup ?? timeControl.playerGroup

        state = .searching(timeControl)
        status = invitation.map { "Waiting for \($0.name)…" }
            ?? "Looking for a \(timeControl.label) opponent…"

        GKMatchmaker.shared().findMatch(for: request, withCompletionHandler: found)
        #endif
    }

    #if canImport(GameKit)
    /// What Game Center hands back from a search, an invitation sent or one
    /// accepted: a match to begin, or the reason there is none.
    private var found: (GKMatch?, Error?) -> Void {
        { [weak self] match, error in
            // GKMatch is not Sendable, and the callback lands off the main
            // actor. The box carries it across without the compiler having to
            // take Game Center's word for its thread safety.
            let carried = match.map { UncheckedBox($0) }
            let message = error?.localizedDescription
            Task { @MainActor in
                guard let self else { return }
                self.invitee = nil
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
    }

    /// Invite one player, by their Game Center identity — somebody off the
    /// rank list, or a recent opponent. Game Center delivers it as a
    /// notification on their devices; accepting it puts both straight into a
    /// match on this clock, with no search and no link.
    public func invite(_ player: GKPlayer, timeControl: TimeControl) {
        guard isAuthenticated, session == nil else { return }
        if case .searching = state { cancelSearch() }
        self.timeControl = timeControl
        if let lookup = ratingLookup { (localRating, localGames, localDeviation) = lookup(timeControl) }
        openPool = false
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.recipients = [player]
        // The clock travels with the invitation, as its pool.
        request.playerGroup = timeControl.playerGroup
        request.inviteMessage = L.t("online.inviteNote", "A game of chess, %@ each.", timeControl.label)
        request.recipientResponseHandler = { [weak self] player, response in
            let alias = player.alias
            let declined = response != .accepted
            Task { @MainActor in
                guard let self, declined, case .searching = self.state, self.invitee != nil else { return }
                self.cancelSearch()
                self.status = L.t("online.inviteDeclined", "%@ cannot play right now.", alias)
            }
        }
        invitee = player.alias
        state = .searching(timeControl)
        status = L.t("online.inviting", "Inviting %@…", player.alias)
        GKMatchmaker.shared().findMatch(for: request, withCompletionHandler: found)
    }

    /// Invite somebody off one of the lists.
    func invite(_ player: BoardPlayer, on control: TimeControl, from boards: OnlineBoards) {
        guard let gkPlayer = boards.player(player.id) else {
            status = L.t("online.inviteUnavailable", "%@ cannot be invited from here right now.", player.alias)
            return
        }
        invite(gkPlayer, timeControl: control)
    }

    /// An invitation this player accepted — from Game Center's notification,
    /// wherever in the app they were, or with the app not running at all.
    fileprivate func accept(_ invite: GKInvite) {
        guard session == nil else { return }
        if case .searching = state { cancelSearch() }
        let control = TimeControl.fromPlayerGroup(invite.playerGroup) ?? .five
        timeControl = control
        if let lookup = ratingLookup { (localRating, localGames, localDeviation) = lookup(control) }
        openPool = false
        state = .searching(control)
        status = L.t("online.joining", "Joining %@…", invite.sender.alias)
        onInviteAccepted?()
        GKMatchmaker.shared().match(for: invite, completionHandler: found)
    }
    #endif

    /// The instant the clocks are read at.
    ///
    /// Kept here rather than in the screen that shows the board, because the
    /// clock is now drawn in the chrome at the top of the window as well, and
    /// two tickers reading two slightly different instants would show two
    /// slightly different times.
    public private(set) var now = Date()

    /// Drive the clocks. Both sides of a debug loopback match need ticking;
    /// over a real network the opponent's device does its own.
    public func tick(now: Date) {
        self.now = now
        session?.tick(now: now)
#if DEBUG
        loopback?.theirs.tick(now: now)
#endif
    }

    /// The clock of the game being searched for, invited to, or played.
    public var currentTimeControl: TimeControl {
        #if canImport(GameKit)
        return session?.timeControl ?? timeControl
        #else
        return session?.timeControl ?? .five
        #endif
    }

    public func cancelSearch() {
        #if canImport(GameKit)
        // Takes back an invitation that is out as well as a search.
        GKMatchmaker.shared().cancel()
        #endif
        invitee = nil
        guard isAuthenticated else { return }
        state = .ready
        status = "Search cancelled."
    }

    public func leaveMatch() {
        // Said before going, so the other side can stop waiting on an answer
        // to a rematch at once, rather than after the reconnect grace.
        session?.leave()
        #if canImport(GameKit)
        disconnectWork?.cancel()
        disconnectWork = nil
        connectWork?.cancel()
        connectWork = nil
        // A moment for the goodbye to leave before the link does.
        let leaving = match.map { UncheckedBox($0) }
        match = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            leaving?.value.disconnect()
        }
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
    /// Whether the match is the debug loopback one, which has nobody in Game
    /// Center at the other end.
    public var isLoopback: Bool { loopback != nil && session === loopback?.mine }

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

    /// The other side of a loopback match offers a draw.
    ///
    /// For the screenshot scene only. There is no other way to see the offer:
    /// Game Center does not sign in on a simulator, so the only real one takes
    /// two devices, two Apple IDs and a draw offered at the right moment.
    public func offerDrawFromLoopback() {
        loopback?.theirs.offerDraw()
    }

    /// The other side of a loopback match resigns and asks for another game.
    public func resignAndAskForRematchFromLoopback() {
        loopback?.theirs.resign()
        loopback?.theirs.offerRematch()
    }
#endif

    #if canImport(GameKit)
    private func begin(_ match: GKMatch) {
        self.match = match
        match.delegate = self
        state = .connected
        status = "Connecting…"

        connectWork?.cancel()
        connectWork = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.connectGrace))
            guard !Task.isCancelled, let self, self.session == nil else { return }
            self.leaveMatch()
            self.status = "Paired, but the connection could not be made."
        }
        startSessionIfConnected()
    }

    /// Being handed a match is not the same as being connected to it.
    ///
    /// `findMatch` returns as soon as Game Center has paired two players, and
    /// `GKMatch.players` is filled in there and then — but the direct
    /// connection between the devices is still being made, and
    /// `expectedPlayerCount` is what says whether it has been. The session used
    /// to be built and begun on the spot, so the host's opening packets went
    /// out over a link that did not exist yet and were simply lost. Both sides
    /// then sat on "Connecting…".
    ///
    /// Called from both places the answer can change: when the match arrives
    /// already connected, and when the delegate says a player has connected.
    private func startSessionIfConnected() {
        guard let match, session == nil, match.expectedPlayerCount == 0 else { return }
        connectWork?.cancel()
        connectWork = nil

        // The host is settled by sorting the two player IDs, so both devices
        // reach the same answer without asking each other. It decides colours;
        // it has no other authority, because both sides run the rules.
        let remoteID = match.players.first?.gamePlayerID ?? ""
        let isHost = localPlayerID < remoteID

        let session = MatchSession(
            transport: self,
            me: .init(playerID: localPlayerID, name: localName, rating: localRating, games: localGames,
                      deviation: localDeviation),
            isHost: isHost,
            timeControl: timeControl,
            openPool: openPool
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

extension GameCenterMatchmaker: @preconcurrency GKLocalPlayerListener {
    /// Accepted in Game Center's notification — the app may have been opened
    /// by it, in which case this arrives as soon as the player is signed in.
    public func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        let carried = UncheckedBox(invite)
        Task { @MainActor in self.accept(carried.value) }
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
                // After a game there is nothing to come back to: they left.
                if let session = self.session, case .finished = session.phase {
                    session.opponentDisconnected()
                    return
                }
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
                // The link is up. If this is the first player to arrive, it is
                // also the moment the session can be started.
                self.startSessionIfConnected()
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

    private final class LoopbackLink: MatchTransport {
        weak var peer: MatchSession?
        func send(_ data: Data) {
            let peer = self.peer
            // Through a hop, so a packet never lands inside the send that
            // produced it — over a network it never would.
            Task { @MainActor in peer?.receive(data) }
        }
    }

    private let myLink = LoopbackLink()
    private let theirLink = LoopbackLink()
    private var play: Task<Void, Never>?

    init(timeControl: TimeControl, rating: Int, games: Int) {
        mine = MatchSession(
            transport: myLink,
            me: .init(playerID: "local", name: L.t("common.you", "You"), rating: rating, games: games),
            isHost: true, timeControl: timeControl
        )
        theirs = MatchSession(
            transport: theirLink,
            me: .init(playerID: "sparring", name: L.t("common.sparringBot", "Sparring bot"), rating: 1200, games: 40),
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
