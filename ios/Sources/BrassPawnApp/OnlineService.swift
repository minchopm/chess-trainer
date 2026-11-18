import ChessTraining
import Foundation
import Observation
#if canImport(GameKit)
@preconcurrency import GameKit
#endif

typealias PresenceStatus = OnlinePresence
typealias FriendInvite = OnlineFriendInvite

/// High-level online service wrapper around `OnlineAPI` (`/brasspawn/v1/`):
/// manages Game Center identity login, session refresh, and the `/events`
/// long-poll loop.
@MainActor
@Observable
public final class OnlineService {
    public let api: OnlineAPI

    public private(set) var account: String?
    public private(set) var alias: String = ""
    public private(set) var records: [Int: OnlineRecord] = [:]
    public private(set) var isConnecting = false
    public private(set) var offlineReason: String?

    /// Invoked on the main actor for every event delivered by `/events`.
    public var onEvent: ((OnlineEvent) -> Void)?

    private var eventTask: Task<Void, Never>?
    private var cursor: Int64 = 0
    private var hasSyncedCursor = false

    public init(api: OnlineAPI = OnlineAPI()) {
        self.api = api
        self.api.reauthenticator = { [weak self] in
            guard let self else { throw OnlineError(status: 401, code: "session") }
            return try await self.performLogin()
        }
    }

    public var isSignedIn: Bool {
        account != nil && api.session != nil
    }

    /// Deterministic 32-hex account key for a Game Center `teamPlayerID`.
    nonisolated public static func key(teamPlayerID: String) -> String {
        OnlineConfiguration.gameCenterAccountID(teamPlayerID: teamPlayerID)
    }

    /// This player's 32-hex account ID on the service.
    public var myKey: String? {
        if let account, !account.isEmpty { return account }
        #if canImport(GameKit)
        if GKLocalPlayer.local.isAuthenticated {
            return Self.key(teamPlayerID: GKLocalPlayer.local.teamPlayerID)
        }
        #endif
        return nil
    }

    public func record(for control: TimeControl) -> OnlineRecord {
        records[control.minutes] ?? .new
    }

    public func updateRecords(_ updated: [Int: OnlineRecord]) {
        records = updated
    }

    public func updateRecord(_ record: OnlineRecord, minutes: Int) {
        records[minutes] = record
    }

    // MARK: - Sign-in & Events

    @discardableResult
    public func signIn() async throws -> OnlineLogin {
        isConnecting = true
        offlineReason = nil
        defer { isConnecting = false }
        do {
            let login = try await api.reauthenticate()
            if !hasSyncedCursor {
                if let prime = try? await api.events(after: Int64.max / 2, waitSeconds: 0) {
                    cursor = prime.next
                }
                hasSyncedCursor = true
            }
            applyLogin(login)
            return login
        } catch let error as OnlineError {
            offlineReason = error.code
            throw error
        } catch {
            offlineReason = "network"
            throw error
        }
    }

    private func performLogin() async throws -> OnlineLogin {
        let (loginAlias, proof) = try await buildIdentityProof()
        let login = try await api.login(alias: loginAlias, gameCenter: proof)
        if hasSyncedCursor {
            applyLogin(login)
        }
        return login
    }

    private func applyLogin(_ login: OnlineLogin) {
        account = login.account
        if !login.alias.isEmpty {
            alias = login.alias
        }
        records = login.records
        offlineReason = nil
    }

    private func buildIdentityProof() async throws -> (alias: String, proof: GameCenterProof) {
        #if DEBUG
        if let testPlayer = OnlineDebugOptions.current.testPlayer {
            let bundleID = Bundle.main.bundleIdentifier ?? "com.arte-soft.brasspawn"
            let validBundle = (bundleID == "com.arte-soft.brasspawn" || bundleID == "com.arte-soft.brasspawn.Clip")
                ? bundleID
                : "com.arte-soft.brasspawn"
            return (testPlayer, OnlineDebugOptions.testProof(for: testPlayer, bundleID: validBundle))
        }
        #endif
        #if canImport(GameKit)
        let local = GKLocalPlayer.local
        guard local.isAuthenticated else {
            throw OnlineError(status: 401, code: "gamecenter-unauthenticated")
        }
        let (url, signature, salt, timestamp) = try await local.fetchItemsForIdentityVerificationSignature()
        let rawBundle = Bundle.main.bundleIdentifier ?? "com.arte-soft.brasspawn"
        let bundleID = (rawBundle == "com.arte-soft.brasspawn" || rawBundle == "com.arte-soft.brasspawn.Clip")
            ? rawBundle
            : "com.arte-soft.brasspawn"
        let proof = GameCenterProof(
            playerID: local.teamPlayerID,
            bundleID: bundleID,
            publicKeyURL: url.absoluteString,
            signature: signature.base64EncodedString(),
            salt: salt.base64EncodedString(),
            timestamp: timestamp
        )
        return (local.alias, proof)
        #else
        throw OnlineError(status: 403, code: "gamecenter-unavailable")
        #endif
    }

    /// Start the `/events` long-poll if not already running.
    public func startEvents() {
        guard eventTask == nil, isSignedIn else { return }
        eventTask = Task { @MainActor [weak self] in
            var failures = 0
            while !Task.isCancelled {
                guard let self else { return }
                do {
                    let batch = try await self.api.events(after: self.cursor, waitSeconds: 25)
                    self.cursor = batch.next
                    failures = 0
                    self.offlineReason = nil
                    for event in batch.events {
                        if case .result(let res) = event {
                            self.records[res.minutes] = res.record
                        }
                        self.onEvent?(event)
                    }
                } catch is CancellationError {
                    return
                } catch let error as OnlineError {
                    if error.status == 401 {
                        do {
                            let login = try await self.api.reauthenticate()
                            self.applyLogin(login)
                            continue
                        } catch {
                            try? await Task.sleep(for: .seconds(4))
                        }
                    } else {
                        try? await Task.sleep(for: .seconds(2))
                    }
                } catch {
                    failures += 1
                    let backoff = min(failures, 8)
                    try? await Task.sleep(for: .seconds(backoff))
                }
            }
        }
    }

    public func stopEvents() {
        eventTask?.cancel()
        eventTask = nil
    }

    // MARK: - Presence, Lists & Friends

    @discardableResult
    func here(_ status: PresenceStatus) async -> [FriendInvite]? {
        guard isSignedIn else { return nil }
        return try? await api.here(status)
    }

    func gone() async {
        guard isSignedIn else { return }
        try? await api.gone()
    }

    func online() async -> [String: PresenceStatus]? {
        guard isSignedIn else { return nil }
        return try? await api.online()
    }

    func friends() async -> OnlineFriends? {
        guard isSignedIn else { return nil }
        return try? await api.friends()
    }

    func invites() async -> [FriendInvite]? {
        guard isSignedIn else { return nil }
        return try? await api.friendInvites()
    }

    func request(_ id: String) async -> Bool {
        guard isSignedIn else { return false }
        return (try? await api.requestFriend(to: id)) != nil
    }

    func accept(_ id: String) async -> Bool {
        guard isSignedIn else { return false }
        return (try? await api.acceptFriend(from: id)) != nil
    }

    func remove(_ id: String) async -> Bool {
        guard isSignedIn else { return false }
        return (try? await api.removeFriend(id)) != nil
    }

    func offer(to id: String, minutes: Int) async -> Bool {
        guard isSignedIn else { return false }
        return (try? await api.offerGame(to: id, minutes: minutes)) != nil
    }

    @discardableResult
    func answer(_ id: String, accept: Bool) async -> Bool {
        guard isSignedIn else { return false }
        return (try? await api.answerOffer(from: id, accept: accept)) != nil
    }

    func cancelOffer(to id: String) async {
        guard isSignedIn else { return }
        try? await api.cancelOffer(to: id)
    }

    func leaderboard(minutes: Int, scope: String = "top", limit: Int = 100) async -> OnlineLeaderboard? {
        guard isSignedIn else { return nil }
        return try? await api.leaderboard(minutes: minutes, scope: scope, limit: limit)
    }

    func records(minutes: Int, ids: [String]) async -> [String: OnlinePlayer]? {
        guard isSignedIn else { return nil }
        return try? await api.records(minutes: minutes, ids: ids)
    }

    func searchPlayers(alias: String) async -> [OnlinePlayer]? {
        guard isSignedIn else { return nil }
        return try? await api.searchPlayers(alias: alias)
    }

    func deleteAccount() async -> Bool {
        guard isSignedIn else { return false }
        stopEvents()
        let deleted = (try? await api.deleteAccount()) != nil
        if deleted {
            account = nil
            alias = ""
            records = [:]
            cursor = 0
            hasSyncedCursor = false
        }
        return deleted
    }
}
