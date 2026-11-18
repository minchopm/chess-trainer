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

/// Carries a non-Sendable Game Center object from its callback to the main actor.
private final class UncheckedBox<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}

/// Game Center identity + matchmaking coordinator.
///
/// Open matchmaking, invite codes, and friend offers run over the cross-platform
/// Brass Pawn online service (`OnlineService` / `OnlineMatchDriver`). Native
/// Game Center `GKInvite` notifications and App Clip `Invitation.playerGroup`
/// links continue to use `GKMatch` directly as friendly (unrated) games.
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
    public private(set) var localName = L.t("common.you", "You")
    public private(set) var localPlayerID = "local"
    public private(set) var status = L.t("online.signInPrompt", "Sign in to Game Center to play online.")
    /// The session for the match in progress, once one is connected.
    public private(set) var session: MatchSession?
    /// Active service match driver when playing through `/brasspawn/v1/`.
    public private(set) var serviceMatch: OnlineMatchDriver?
    /// Active 6-character invitation code waiting in the lobby.
    public private(set) var activeInviteCode: OnlineInviteCode?
    /// One-shot error code (`"unknown"`, `"own-code"`, `"busy"`, `"offline"`) for the lobby alert.
    public var notice: String?
    /// Set when Game Center wants to show its sign-in screen.
    public var pendingAuthController: AuthControllerItem?

    public struct AuthControllerItem: Identifiable {
        public let id = UUID()
        #if canImport(UIKit)
        public let controller: UIViewController
        #endif
    }

    /// Reference to the online service, wired by `AppModel`.
    public weak var service: OnlineService?

    public var onMatchFinished: ((MatchResult) -> Void)?
    public var onServerResult: ((OnlineGameResult, MatchSession?) -> Void)?
    public var ratingLookup: ((TimeControl) -> (rating: Int, games: Int, deviation: Double))?
    public var onAuthenticated: (() -> Void)?
    public var onInviteAccepted: (() -> Void)?

    public private(set) var invitee: String?
    private var offeredFriendKey: String?
    private var offerWaitTask: Task<Void, Never>?
    private var openPool = true
    private var timeControl: TimeControl = .five

    public var isAuthenticated: Bool {
        if case .signedOut = state { return false }
        if case .authenticating = state { return false }
        return true
    }

    public var canInvite: Bool {
        if service?.isSignedIn == true { return true }
        return isAuthenticated && localPlayerID != "local"
    }

    public var isServiceMatch: Bool {
        serviceMatch != nil && session === serviceMatch?.session
    }

    public var serviceResult: OnlineGameResult? {
        serviceMatch?.latestResult
    }

    public var isOpponentConnected: Bool {
        serviceMatch?.opponentConnected ?? true
    }

    public var isMatchClosed: Bool {
        serviceMatch?.isClosed ?? false
    }

    #if canImport(GameKit)
    private var match: GKMatch?
    public var opponentPlayer: GKPlayer? { match?.players.first }
    private var localRating = Glicko.starting
    private var localGames = 0
    private var localDeviation = Glicko.newDeviation
    private var disconnectWork: Task<Void, Never>?
    private var connectWork: Task<Void, Never>?
    private static let connectGrace: TimeInterval = 20
    private static let reconnectGrace: TimeInterval = 45
    #endif

    private static let offerTimeoutSeconds: Double = 125

    public override init() { super.init() }

#if DEBUG
    private var _loopback: LoopbackMatch?
#endif

    // MARK: - Authentication

    public func authenticate() {
        #if DEBUG
        if let testPlayer = OnlineDebugOptions.current.testPlayer {
            localPlayerID = "T:test-\(testPlayer)"
            localName = testPlayer
            pendingAuthController = nil
            if session == nil {
                state = .ready
                status = L.t("online.signedInAs", "Signed in as %@.", testPlayer)
            }
            onAuthenticated?()
            return
        }
        #endif

        #if canImport(GameKit)
        state = .authenticating
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor in
                guard let self else { return }
                #if canImport(UIKit)
                if let controller {
                    self.pendingAuthController = AuthControllerItem(controller: controller)
                    self.status = L.t("online.signInPrompt", "Sign in to Game Center to play online.")
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
                    self.status = L.t("online.signInCancelled", "Game Center sign-in was cancelled.")
                    return
                }
                self.localPlayerID = GKLocalPlayer.local.gamePlayerID
                self.localName = GKLocalPlayer.local.alias
                self.pendingAuthController = nil
                if case .authenticating = self.state {
                    self.state = .ready
                    self.status = L.t("online.signedInAs", "Signed in as %@.", self.localName)
                }
                GKLocalPlayer.local.unregisterAllListeners()
                GKLocalPlayer.local.register(self)
                self.onAuthenticated?()
            }
        }
        #else
        state = .failed(L.t("online.offline", "The server cannot be reached. Check the connection and try again."))
        status = L.t("online.offline", "The server cannot be reached. Check the connection and try again.")
        #endif
    }

    private func ensureServiceReady() async throws -> OnlineService {
        guard let service else {
            throw OnlineError(status: 503, code: "unavailable")
        }
        if !service.isSignedIn {
            let login = try await service.signIn()
            if !login.alias.isEmpty {
                localName = login.alias
            }
        }
        service.startEvents()
        return service
    }

    // MARK: - Open Matchmaking & App Clip Invitations

    public func findOpponent(
        timeControl: TimeControl,
        rating: Int,
        games: Int,
        deviation: Double,
        invitation: Invitation? = nil
    ) {
        guard isAuthenticated else {
            authenticate()
            return
        }
        self.timeControl = timeControl
        openPool = invitation == nil

        // App Clip / legacy base64 link invitations use their dedicated GKMatchmaker pool.
        if let invitation {
            #if canImport(GameKit)
            localRating = rating
            localGames = games
            localDeviation = deviation
            let request = GKMatchRequest()
            request.minPlayers = 2
            request.maxPlayers = 2
            request.playerGroup = invitation.playerGroup
            state = .searching(timeControl)
            invitee = invitation.name
            status = L.t("online.inviting", "Inviting %@…", invitation.name)
            GKMatchmaker.shared().findMatch(for: request, withCompletionHandler: found)
            #endif
            return
        }

        // Open matchmaking goes through the Brass Pawn backend service (`POST /seek`).
        guard session == nil else {
            notice = "busy"
            return
        }
        cancelServiceInvite()
        withdrawFriendOffer()
        invitee = nil
        state = .searching(timeControl)
        status = L.t("online.searchingTapToCancel", "Searching — tap to cancel")

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let svc = try await self.ensureServiceReady()
                guard case .searching(let current) = self.state, current == timeControl else { return }
                try await svc.api.seek(minutes: timeControl.minutes)
            } catch {
                if case .searching = self.state {
                    self.state = .ready
                }
                self.recordFailure(error)
            }
        }
    }

    // MARK: - Service Invite Codes (`/invite/*`)

    public func createServiceInvite(timeControl: TimeControl) {
        guard session == nil else {
            notice = "busy"
            return
        }
        if case .searching = state { cancelSearch() }
        self.timeControl = timeControl
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let svc = try await self.ensureServiceReady()
                let created = try await svc.api.createInvite(minutes: timeControl.minutes)
                self.activeInviteCode = created
                #if DEBUG
                try? Data(created.code.utf8).write(
                    to: URL.documentsDirectory.appending(path: "debug-invite-code.txt"),
                    options: .atomic
                )
                #endif
            } catch {
                self.recordFailure(error)
            }
        }
    }

    public func cancelServiceInvite() {
        guard activeInviteCode != nil else { return }
        activeInviteCode = nil
        Task { try? await service?.api.cancelInvite() }
    }

    public func joinServiceInvite(code: String) {
        guard let normalized = Invitation.normalizedInviteCode(code) else {
            notice = "unknown"
            return
        }
        guard session == nil else {
            notice = "busy"
            return
        }
        if case .searching = state { cancelSearch() }
        cancelServiceInvite()
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let svc = try await self.ensureServiceReady()
                try await svc.api.joinInvite(code: normalized)
            } catch {
                self.recordFailure(error)
            }
        }
    }

    // MARK: - Service Friend Offers & Game Center Native Invites

    public func offerServiceFriend(key: String, alias: String, timeControl: TimeControl) {
        guard session == nil else {
            notice = "busy"
            return
        }
        if case .searching = state { cancelSearch() }
        cancelServiceInvite()
        withdrawFriendOffer()

        self.timeControl = timeControl
        openPool = false
        invitee = alias
        offeredFriendKey = key
        state = .searching(timeControl)
        status = L.t("online.inviting", "Inviting %@…", alias)

        offerWaitTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let svc = try await self.ensureServiceReady()
                try await svc.api.offerGame(to: key, minutes: timeControl.minutes)
                try? await Task.sleep(for: .seconds(Self.offerTimeoutSeconds))
                guard !Task.isCancelled else { return }
                if self.session == nil, self.offeredFriendKey == key {
                    self.gaveUp(on: alias)
                }
            } catch {
                guard !Task.isCancelled else { return }
                if case .searching = self.state, self.offeredFriendKey == key {
                    self.offeredFriendKey = nil
                    self.invitee = nil
                    self.state = .ready
                }
                self.recordFailure(error)
            }
        }
    }

    private func withdrawFriendOffer() {
        offerWaitTask?.cancel()
        offerWaitTask = nil
        if let key = offeredFriendKey {
            offeredFriendKey = nil
            Task { await service?.cancelOffer(to: key) }
        }
    }

    private func recordFailure(_ error: Error) {
        if let onlineError = error as? OnlineError {
            switch onlineError.code {
            case "no-invite", "unknown", "invite-unknown":
                notice = "unknown"
            case "own-code":
                notice = "own-code"
            case "in-match", "opponent-busy", "busy":
                notice = "busy"
            default:
                notice = "offline"
            }
            status = L.t("online.offline", "The server cannot be reached. Check the connection and try again.")
        } else {
            notice = "offline"
            status = L.t("online.offline", "The server cannot be reached. Check the connection and try again.")
        }
    }

    // MARK: - Service Event Stream Handling

    public func handleServiceEvent(_ event: OnlineEvent) {
        switch event {
        case .matched(let info):
            guard let svc = service else { return }
            offerWaitTask?.cancel()
            offerWaitTask = nil
            offeredFriendKey = nil
            invitee = nil
            activeInviteCode = nil
            serviceMatch?.shutdown()

            let myAccount = svc.account ?? localPlayerID
            let myAlias = svc.alias.isEmpty ? localName : svc.alias
            if !myAlias.isEmpty {
                localName = myAlias
            }
            let driver = OnlineMatchDriver(info: info, account: myAccount, alias: myAlias, api: svc.api)
            serviceMatch = driver
            session = driver.session
            timeControl = driver.session.timeControl
            openPool = info.open
            state = .connected
            status = L.t("online.connected", "Connected.")
            if !info.open {
                onInviteAccepted?()
            }
            driver.begin()

        case .packet, .peer, .matchEnded:
            serviceMatch?.handle(event)

        case .result(let res):
            serviceMatch?.handle(event)
            onServerResult?(res, serviceMatch?.session)

        case .seekEnded:
            if case .searching = state, offeredFriendKey == nil {
                state = .ready
                status = L.t("online.noOpponentFound", "No opponent was found.")
            }

        case .inviteDeclined(let from):
            if offeredFriendKey == from {
                let alias = invitee ?? L.t("online.opponent", "Opponent")
                offerWaitTask?.cancel()
                offerWaitTask = nil
                offeredFriendKey = nil
                invitee = nil
                state = .ready
                status = L.t("online.inviteDeclined", "%@ cannot play right now.", alias)
            }

        case .friendsChanged, .invited:
            break
        }
    }

    // MARK: - Game Center Native Invitations (`GKInvite` / `GKMatch`)

    #if canImport(GameKit)
    private var found: @Sendable (GKMatch?, Error?) -> Void {
        { [weak self] match, error in
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
                    self.status = L.t("online.noOpponentFound", "No opponent was found.")
                    return
                }
                self.begin(carried.value)
            }
        }
    }

    public func invite(_ player: GKPlayer, timeControl: TimeControl) {
        guard isAuthenticated, session == nil else { return }
        if case .searching = state { cancelSearch() }
        cancelServiceInvite()
        self.timeControl = timeControl
        if let lookup = ratingLookup { (localRating, localGames, localDeviation) = lookup(timeControl) }
        openPool = false
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.recipients = [player]
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

    func invite(_ player: BoardPlayer, on control: TimeControl, from boards: OnlineBoards) {
        if boards.friendState(of: player) == .friend, let key = player.key {
            offerServiceFriend(key: key, alias: player.alias, timeControl: control)
            return
        }
        if let gkPlayer = boards.player(player.id) ?? player.key.flatMap({ boards.player($0) }) {
            invite(gkPlayer, timeControl: control)
            return
        }
        status = L.t("online.inviteUnavailable", "%@ cannot be invited from here right now.", player.alias)
    }

    fileprivate func accept(_ invite: GKInvite) {
        guard session == nil else { return }
        if case .searching = state { cancelSearch() }
        cancelServiceInvite()
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

    // MARK: - Clocks, Cancel & Leave

    public private(set) var now = Date()

    public func tick(now: Date) {
        self.now = now
        session?.tick(now: now)
#if DEBUG
        loopback?.theirs.tick(now: now)
#endif
    }

    public var currentTimeControl: TimeControl {
        session?.timeControl ?? timeControl
    }

    public func gaveUp(on name: String) {
        guard case .searching = state else { return }
        cancelSearch()
        status = L.t("online.inviteDeclined", "%@ cannot play right now.", name)
    }

    public func cancelSearch() {
        #if canImport(GameKit)
        GKMatchmaker.shared().cancel()
        #endif
        let wasOfferedFriend = offeredFriendKey != nil
        withdrawFriendOffer()
        cancelServiceInvite()
        if !wasOfferedFriend {
            Task { try? await service?.api.cancelSeek() }
        }
        invitee = nil
        guard isAuthenticated else { return }
        if session == nil {
            state = .ready
            status = L.t("online.searchCancelled", "Search cancelled.")
        }
    }

    public func leaveMatch() {
        if let current = serviceMatch {
            let matchID = current.info.id
            current.shutdown()
            serviceMatch = nil
            session = nil
            Task { try? await service?.api.leave(match: matchID) }
        } else {
            session?.leave()
            #if canImport(GameKit)
            disconnectWork?.cancel()
            disconnectWork = nil
            connectWork?.cancel()
            connectWork = nil
            let leaving = match.map { UncheckedBox($0) }
            match = nil
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                leaving?.value.disconnect()
            }
            #endif
            session = nil
        }
#if DEBUG
        loopback = nil
#endif
        if isAuthenticated {
            state = .ready
            status = L.t("online.signedInAs", "Signed in as %@.", localName)
        }
    }

    public func resetAfterAccountDeletion() {
        serviceMatch?.shutdown()
        serviceMatch = nil
        activeInviteCode = nil
        withdrawFriendOffer()
        session = nil
        if isAuthenticated {
            state = .ready
        }
    }

#if DEBUG
    public var isLoopback: Bool { loopback != nil && session === loopback?.mine }

    public func startLoopbackMatch(timeControl: TimeControl, rating: Int, games: Int) {
        let harness = LoopbackMatch(timeControl: timeControl, rating: rating, games: games)
        loopback = harness
        session = harness.mine
        state = .connected
        status = L.t("online.localTestGame", "Local test game")
        harness.begin()
    }

    private var loopback: LoopbackMatch? {
        get { _loopback }
        set { _loopback = newValue }
    }

    public func offerDrawFromLoopback() {
        loopback?.theirs.offerDraw()
    }

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
        status = L.t("online.connecting", "Connecting…")

        connectWork?.cancel()
        connectWork = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.connectGrace))
            guard !Task.isCancelled, let self, self.session == nil else { return }
            self.leaveMatch()
            self.status = L.t("online.pairedNoConnection", "Paired, but the connection could not be made.")
        }
        startSessionIfConnected()
    }

    private func startSessionIfConnected() {
        guard let match, session == nil, match.expectedPlayerCount == 0 else { return }
        connectWork?.cancel()
        connectWork = nil

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
        status = L.t("online.connected", "Connected.")
        session.begin()
    }
    #endif
}

#if canImport(GameKit)
extension GameCenterMatchmaker: MatchTransport {
    nonisolated public func send(_ data: Data) {
        Task { @MainActor in
            try? self.match?.send(data, to: self.match?.players ?? [], dataMode: .reliable)
        }
    }
}

extension GameCenterMatchmaker: @preconcurrency GKLocalPlayerListener {
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
                if let session = self.session, case .finished = session.phase {
                    session.opponentDisconnected()
                    return
                }
                self.status = L.t("online.opponentAway", "%@ has lost the connection — waiting for them to come back.", player.alias)
                self.disconnectWork?.cancel()
                self.disconnectWork = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(Self.reconnectGrace))
                    guard !Task.isCancelled, let self else { return }
                    self.status = L.t("online.opponentDidNotReturn", "%@ did not come back.", player.alias)
                    self.session?.opponentDisconnected()
                }
            case .connected:
                self.disconnectWork?.cancel()
                self.disconnectWork = nil
                self.status = L.t("online.connected", "Connected.")
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
struct HostedController: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController { controller }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif

#if DEBUG
@MainActor
final class LoopbackMatch {
    let mine: MatchSession
    let theirs: MatchSession

    private final class LoopbackLink: MatchTransport {
        weak var peer: MatchSession?
        func send(_ data: Data) {
            let peer = self.peer
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
