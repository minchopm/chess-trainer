import ChessCore
import CryptoKit
import Foundation
import Observation

/// Error returned by the Brass Pawn online service (`/brasspawn/v1/`).
public struct OnlineError: Error, Equatable, Sendable {
    public let status: Int
    public let code: String

    public init(status: Int, code: String) {
        self.status = status
        self.code = code
    }

    /// True when the error may clear on retry (rate limit, store hiccup, or gateway timeout).
    public var isTransient: Bool {
        status == 408 || status == 429 || status >= 500
    }
}

/// Raw HTTP reply from `OnlineHTTPTransport`.
public struct OnlineHTTPResponse: Equatable, Sendable {
    public let status: Int
    public let body: Data

    public init(status: Int, body: Data) {
        self.status = status
        self.body = body
    }
}

/// Transport abstraction so unit tests can drive `OnlineAPI` without network sockets.
public protocol OnlineHTTPTransport: Sendable {
    func send(
        method: String,
        url: URL,
        headers: [String: String],
        body: Data?,
        timeout: TimeInterval
    ) async throws -> OnlineHTTPResponse
}

/// Production `URLSession` transport with HTTP/3 enabled on HTTPS origins.
public final class URLSessionOnlineTransport: OnlineHTTPTransport {
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 65
        self.session = URLSession(configuration: configuration)
    }

    public func send(
        method: String,
        url: URL,
        headers: [String: String],
        body: Data?,
        timeout: TimeInterval
    ) async throws -> OnlineHTTPResponse {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.httpMethod = method
        if url.scheme?.lowercased() == "https" {
            request.assumesHTTP3Capable = true
        }
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        return OnlineHTTPResponse(status: status, body: data)
    }
}

/// Endpoint and per-install device configuration for the Brass Pawn online service.
public enum OnlineConfiguration {
    public static let releaseBaseURL = URL(string: "https://chat-api.wonek.com:5433")!
    private static let deviceDefaultsKey = "brasspawn.online.deviceID"

    /// Service origin: fixed to `https://chat-api.wonek.com:5433` in Release;
    /// overrideable via `-onlineBaseURL <url>` or UserDefaults in Debug builds.
    public static var resolvedBaseURL: URL {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-onlineBaseURL"), index + 1 < arguments.count,
           let override = URL(string: arguments[index + 1]), override.scheme != nil, override.host != nil {
            return override
        }
        if let stored = UserDefaults.standard.string(forKey: "onlineBaseURL"),
           let override = URL(string: stored), override.scheme != nil, override.host != nil {
            return override
        }
        #endif
        return releaseBaseURL
    }

    /// Persistent per-install 16..128 character device identifier bound to the session.
    public static func deviceID(defaults: UserDefaults = .standard) -> String {
        let base: String
        if let existing = defaults.string(forKey: deviceDefaultsKey),
           existing.count >= 16, existing.count <= 128 {
            base = existing
        } else {
            let created = UUID().uuidString.lowercased()
            defaults.set(created, forKey: deviceDefaultsKey)
            base = created
        }
        #if DEBUG
        if let testPlayer = OnlineDebugOptions.current.testPlayer {
            let safe = testPlayer.unicodeScalars
                .filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" }
                .map(String.init)
                .joined()
            let candidate = "test-\(safe.prefix(24))-\(base)"
            return String(candidate.prefix(96))
        }
        #endif
        return base
    }

    /// Deterministic 32-hex account ID for a Game Center `teamPlayerID`.
    public static func gameCenterAccountID(teamPlayerID: String) -> String {
        let digest = SHA256.hash(data: Data("brasspawn:\(teamPlayerID)".utf8))
        return String(digest.map { String(format: "%02x", $0) }.joined().prefix(32))
    }
}

#if DEBUG
/// Debug-only launch flags for automated simulator verification. Compiled out of Release builds.
public struct OnlineDebugOptions: Sendable, Equatable {
    public let testPlayer: String?
    public let autoSeekMinutes: Int?
    public let autoJoinCode: String?
    public let autoCreateInviteMinutes: Int?
    public let autoMoves: [String]
    public let autoPlayAny: Bool
    public let autoShowRanksMinutes: Int?

    public init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            let next = arguments[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
            return next.isEmpty ? nil : next
        }
        self.testPlayer = value(after: "-onlineTestPlayer")
        self.autoSeekMinutes = value(after: "-onlineAutoSeek").flatMap(Int.init)
        self.autoJoinCode = value(after: "-onlineAutoJoin").flatMap(Invitation.normalizedInviteCode)
        self.autoCreateInviteMinutes = value(after: "-onlineAutoCreateInvite").flatMap(Int.init)
        if let rawMoves = value(after: "-onlineAutoMoves") {
            self.autoMoves = rawMoves
                .split(whereSeparator: { $0.isWhitespace || $0 == "," })
                .map { String($0).lowercased() }
        } else {
            self.autoMoves = []
        }
        self.autoPlayAny = arguments.contains("-onlineAutoPlayAny")
        self.autoShowRanksMinutes = value(after: "-onlineAutoShowRanks").flatMap(Int.init)
    }

    public static let current = OnlineDebugOptions()

    public var opensOnlineAtLaunch: Bool {
        autoSeekMinutes != nil || autoJoinCode != nil || autoCreateInviteMinutes != nil || autoShowRanksMinutes != nil
    }

    private nonisolated(unsafe) static var lastTimestampMs: UInt64 = 0
    private static let timestampLock = NSLock()

    /// Synthetic Game Center proof accepted by `brasspawn-dev -trust-gamecenter`.
    public static func testProof(for playerName: String, bundleID: String = "com.arte-soft.brasspawn") -> GameCenterProof {
        timestampLock.lock()
        let wallMs = UInt64(Date().timeIntervalSince1970 * 1000)
        let stamp = max(wallMs, lastTimestampMs + 1)
        lastTimestampMs = stamp
        timestampLock.unlock()
        return GameCenterProof(
            playerID: "T:test-\(playerName)",
            bundleID: bundleID,
            publicKeyURL: "https://static.gc.apple.com/public-key/gc-prod-10.cer",
            signature: "AA==",
            salt: "AA==",
            timestamp: stamp
        )
    }
}
#endif

// MARK: - Wire Models

/// Game Center identity verification proof sent to `POST /login`.
public struct GameCenterProof: Codable, Equatable, Sendable {
    public let playerID: String
    public let bundleID: String
    public let publicKeyURL: String
    public let signature: String
    public let salt: String
    public let timestamp: UInt64

    public init(
        playerID: String,
        bundleID: String,
        publicKeyURL: String,
        signature: String,
        salt: String,
        timestamp: UInt64
    ) {
        self.playerID = playerID
        self.bundleID = bundleID
        self.publicKeyURL = publicKeyURL
        self.signature = signature
        self.salt = salt
        self.timestamp = timestamp
    }
}

public struct OnlinePlayer: Equatable, Sendable, Identifiable {
    public let id: String
    public let alias: String
    public let record: OnlineRecord
    public let rank: Int?

    public init(id: String, alias: String, record: OnlineRecord = .new, rank: Int? = nil) {
        self.id = id
        self.alias = alias
        self.record = record
        self.rank = rank
    }
}

public struct OnlineLogin: Equatable, Sendable {
    public let session: String
    public let expires: Int64
    public let account: String
    public let alias: String
    public let aliasNeeded: Bool
    public let records: [Int: OnlineRecord]

    public init(
        session: String,
        expires: Int64,
        account: String,
        alias: String,
        aliasNeeded: Bool,
        records: [Int: OnlineRecord]
    ) {
        self.session = session
        self.expires = expires
        self.account = account
        self.alias = alias
        self.aliasNeeded = aliasNeeded
        self.records = records
    }
}

public struct OnlineMatchInfo: Equatable, Sendable {
    public let id: String
    public let host: Bool
    public let minutes: Int
    public let open: Bool
    public let opponent: OnlinePlayer
    public let me: OnlineRecord

    public init(
        id: String,
        host: Bool,
        minutes: Int,
        open: Bool,
        opponent: OnlinePlayer,
        me: OnlineRecord
    ) {
        self.id = id
        self.host = host
        self.minutes = minutes
        self.open = open
        self.opponent = opponent
        self.me = me
    }
}

public struct OnlineGameResult: Equatable, Sendable {
    public let match: String
    public let game: Int
    public let winner: String?
    public let reason: String
    public let rated: Bool
    public let unrated: String?
    public let minutes: Int
    public let delta: Int
    public let record: OnlineRecord

    public init(
        match: String,
        game: Int,
        winner: String?,
        reason: String,
        rated: Bool,
        unrated: String?,
        minutes: Int,
        delta: Int,
        record: OnlineRecord
    ) {
        self.match = match
        self.game = game
        self.winner = winner
        self.reason = reason
        self.rated = rated
        self.unrated = unrated
        self.minutes = minutes
        self.delta = delta
        self.record = record
    }

    public var unratedReason: UnratedReason {
        guard let unrated, let parsed = UnratedReason(rawValue: unrated) else { return .void }
        return parsed
    }
}

public struct OnlineFriendInvite: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let alias: String
    public let minutes: Int

    public init(id: String, alias: String, minutes: Int) {
        self.id = id
        self.alias = alias
        self.minutes = minutes
    }

    public var clock: TimeControl { TimeControl(rawValue: minutes) ?? .five }
}

public struct OnlineFriends: Equatable, Sendable {
    public let friends: [OnlinePlayer]
    public let incoming: [OnlinePlayer]
    public let outgoing: [OnlinePlayer]
    public let invites: [OnlineFriendInvite]

    public init(
        friends: [OnlinePlayer] = [],
        incoming: [OnlinePlayer] = [],
        outgoing: [OnlinePlayer] = [],
        invites: [OnlineFriendInvite] = []
    ) {
        self.friends = friends
        self.incoming = incoming
        self.outgoing = outgoing
        self.invites = invites
    }
}

public struct OnlineLeaderboard: Equatable, Sendable {
    public let entries: [OnlinePlayer]
    public let me: OnlinePlayer?
    public let total: Int

    public init(entries: [OnlinePlayer], me: OnlinePlayer?, total: Int) {
        self.entries = entries
        self.me = me
        self.total = total
    }
}

public struct OnlineInviteCode: Codable, Equatable, Sendable {
    public let code: String
    public let minutes: Int
    public let link: String
    public let expires: Int64

    public init(code: String, minutes: Int, link: String, expires: Int64) {
        self.code = code
        self.minutes = minutes
        self.link = link
        self.expires = expires
    }
}

public enum OnlinePresence: Equatable, Sendable {
    case online
    case looking(TimeControl)
    case playing(TimeControl)

    public var word: String {
        switch self {
        case .online: "online"
        case .looking: "looking"
        case .playing: "playing"
        }
    }

    public var minutes: Int? {
        switch self {
        case .online: nil
        case .looking(let clock), .playing(let clock): clock.minutes
        }
    }

    public init?(status: String, minutes: Int?) {
        let clock = minutes.flatMap(TimeControl.init(rawValue:))
        switch (status, clock) {
        case ("online", _): self = .online
        case ("looking", let clock?): self = .looking(clock)
        case ("playing", let clock?): self = .playing(clock)
        default: return nil
        }
    }

    public var label: String {
        switch self {
        case .online: L.t("online.presence.online", "Online now")
        case .looking(let clock): L.t("online.presence.looking", "Looking for a %@ game", clock.label)
        case .playing: L.t("online.presence.playing", "In a game")
        }
    }
}

public enum OnlineEvent: Equatable, Sendable {
    case matched(OnlineMatchInfo)
    case packet(match: String, packet: Data)
    case result(OnlineGameResult)
    case peer(match: String, connected: Bool)
    case matchEnded(match: String)
    case seekEnded(reason: String)
    case friendsChanged
    case invited(OnlineFriendInvite)
    case inviteDeclined(from: String)
}

public struct OnlineEventBatch: Equatable, Sendable {
    public let events: [OnlineEvent]
    public let next: Int64
    public let reset: Bool
    public let serverTime: Int64

    public init(events: [OnlineEvent], next: Int64, reset: Bool = false, serverTime: Int64 = 0) {
        self.events = events
        self.next = next
        self.reset = reset
        self.serverTime = serverTime
    }
}

// MARK: - API Client

/// Client for `/brasspawn/v1/` (see `PROTOCOL.md`).
@MainActor
public final class OnlineAPI {
    private let transport: any OnlineHTTPTransport
    private let rootURL: String
    public let device: String
    public var session: String?

    /// Invoked automatically on HTTP `401` to refresh `session` and retry once.
    public var reauthenticator: (() async throws -> OnlineLogin)?
    private var activeReauth: Task<OnlineLogin, Error>?

    public init(
        transport: any OnlineHTTPTransport = URLSessionOnlineTransport(),
        baseURL: URL = OnlineConfiguration.resolvedBaseURL,
        device: String = OnlineConfiguration.deviceID()
    ) {
        self.transport = transport
        var trimmed = baseURL.absoluteString
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        self.rootURL = trimmed + "/brasspawn/v1"
        self.device = device
    }

    // MARK: Identity & Account

    @discardableResult
    public func login(alias: String?, gameCenter proof: GameCenterProof) async throws -> OnlineLogin {
        var body: [String: Any] = [
            "device": device,
            "gamecenter": [
                "playerID": proof.playerID,
                "bundleID": proof.bundleID,
                "publicKeyURL": proof.publicKeyURL,
                "signature": proof.signature,
                "salt": proof.salt,
                "timestamp": proof.timestamp,
            ],
        ]
        if let alias, !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body["alias"] = alias
        }
        let reply = try await post("/login", body: body, authorized: false)
        guard let token = reply.string("session"), !token.isEmpty else {
            throw OnlineError(status: 200, code: "malformed")
        }
        var records: [Int: OnlineRecord] = [:]
        if let rawRecords = reply.dict("records") {
            for (minutesText, value) in rawRecords {
                if let minutes = Int(minutesText), let obj = value as? [String: Any] {
                    records[minutes] = Self.parseRecord(obj)
                }
            }
        }
        let result = OnlineLogin(
            session: token,
            expires: reply.int64("expires") ?? 0,
            account: reply.string("account") ?? "",
            alias: reply.string("alias") ?? "",
            aliasNeeded: reply.bool("aliasNeeded") ?? false,
            records: records
        )
        self.session = token
        return result
    }

    public func setAlias(_ alias: String) async throws -> String {
        let reply = try await post("/profile", body: ["alias": alias])
        return reply.string("alias") ?? alias
    }

    public func deleteAccount() async throws {
        _ = try await post("/account/delete")
        session = nil
    }

    // MARK: Events

    public func events(after: Int64, waitSeconds: Int = 25) async throws -> OnlineEventBatch {
        let clampedWait = max(0, min(waitSeconds, 25))
        let timeout = TimeInterval(clampedWait + 15)
        let reply = try await call(
            method: "GET",
            path: "/events?after=\(after)&wait=\(clampedWait)",
            body: nil,
            authorized: true,
            timeout: timeout
        )
        let parsed = reply.dictList("events").compactMap(Self.parseEvent)
        return OnlineEventBatch(
            events: parsed,
            next: reply.int64("next") ?? after,
            reset: reply.bool("reset") ?? false,
            serverTime: reply.int64("serverTime") ?? 0
        )
    }

    // MARK: Finding a Game

    public func seek(minutes: Int) async throws {
        _ = try await post("/seek", body: ["minutes": minutes])
    }

    public func cancelSeek() async throws {
        _ = try await post("/seek/cancel")
    }

    public func createInvite(minutes: Int) async throws -> OnlineInviteCode {
        let reply = try await post("/invite/create", body: ["minutes": minutes])
        return OnlineInviteCode(
            code: reply.string("code") ?? "",
            minutes: reply.int("minutes") ?? minutes,
            link: reply.string("link") ?? "",
            expires: reply.int64("expires") ?? 0
        )
    }

    public func joinInvite(code: String) async throws {
        _ = try await post("/invite/join", body: ["code": code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()])
    }

    public func cancelInvite() async throws {
        _ = try await post("/invite/cancel")
    }

    // MARK: Match Relay

    public func send(match: String, packet: Data) async throws {
        guard let packetObject = try? JSONSerialization.jsonObject(with: packet) as? [String: Any] else {
            throw OnlineError(status: 400, code: "invalid-packet")
        }
        _ = try await post("/match/send", body: ["match": match, "packet": packetObject])
    }

    public func leave(match: String) async throws {
        _ = try await post("/match/leave", body: ["match": match])
    }

    // MARK: Ratings, Lists & Search

    public func records(minutes: Int, ids: [String]) async throws -> [String: OnlinePlayer] {
        guard !ids.isEmpty else { return [:] }
        let reply = try await post("/records", body: ["minutes": minutes, "ids": Array(ids.prefix(100))])
        guard let map = reply.dict("records") else { return [:] }
        var out: [String: OnlinePlayer] = [:]
        for (id, raw) in map {
            guard let obj = raw as? [String: Any] else { continue }
            out[id] = OnlinePlayer(
                id: id,
                alias: obj.string("alias") ?? "",
                record: Self.parseRecord(obj),
                rank: nil
            )
        }
        return out
    }

    public func leaderboard(minutes: Int, scope: String = "top", limit: Int = 50) async throws -> OnlineLeaderboard {
        let clampedLimit = max(1, min(limit, 100))
        let reply = try await post("/leaderboard", body: [
            "minutes": minutes,
            "scope": scope,
            "limit": clampedLimit,
        ])
        let entries = reply.dictList("entries").map(Self.parsePlayer)
        let me = reply.dict("me").map(Self.parsePlayer)
        return OnlineLeaderboard(entries: entries, me: me, total: reply.int("total") ?? entries.count)
    }

    @discardableResult
    public func importRating(minutes: Int, record: OnlineRecord) async throws -> OnlineRecord {
        let lastPlayed = Int64(record.lastPlayed?.timeIntervalSince1970 ?? 0)
        let reply = try await post("/rating/import", body: [
            "minutes": minutes,
            "rating": record.rating,
            "deviation": record.deviation,
            "games": record.games,
            "lastPlayed": max(0, lastPlayed),
        ])
        return Self.parseRecord(reply.dict("record"))
    }

    public func searchPlayers(alias: String) async throws -> [OnlinePlayer] {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let reply = try await post("/players/search", body: ["alias": String(trimmed.prefix(40))])
        return reply.dictList("players").map(Self.parsePlayer)
    }

    // MARK: Presence & Friends

    @discardableResult
    public func here(_ status: OnlinePresence) async throws -> [OnlineFriendInvite] {
        var body: [String: Any] = ["status": status.word]
        if let minutes = status.minutes {
            body["minutes"] = minutes
        }
        let reply = try await post("/here", body: body)
        return reply.dictList("invites").map(Self.parseInvite)
    }

    public func gone() async throws {
        _ = try await post("/gone")
    }

    public func online() async throws -> [String: OnlinePresence] {
        let reply = try await post("/online")
        var map: [String: OnlinePresence] = [:]
        for entry in reply.dictList("players") {
            guard let id = entry.string("id"), !id.isEmpty,
                  let statusText = entry.string("status"),
                  let presence = OnlinePresence(status: statusText, minutes: entry.int("minutes"))
            else { continue }
            map[id] = presence
        }
        return map
    }

    public func friends() async throws -> OnlineFriends {
        let reply = try await post("/friends")
        return OnlineFriends(
            friends: reply.dictList("friends").map(Self.parsePlayer),
            incoming: reply.dictList("incoming").map(Self.parsePlayer),
            outgoing: reply.dictList("outgoing").map(Self.parsePlayer),
            invites: reply.dictList("invites").map(Self.parseInvite)
        )
    }

    public func friendInvites() async throws -> [OnlineFriendInvite] {
        let reply = try await post("/friends/invites")
        return reply.dictList("invites").map(Self.parseInvite)
    }

    public func requestFriend(to id: String) async throws {
        _ = try await post("/friends/request", body: ["to": id])
    }

    public func acceptFriend(from id: String) async throws {
        _ = try await post("/friends/accept", body: ["from": id])
    }

    public func removeFriend(_ id: String) async throws {
        _ = try await post("/friends/remove", body: ["other": id])
    }

    public func offerGame(to id: String, minutes: Int) async throws {
        _ = try await post("/friends/invite", body: ["to": id, "minutes": minutes])
    }

    public func answerOffer(from id: String, accept: Bool) async throws {
        _ = try await post("/friends/answer", body: ["from": id, "accept": accept])
    }

    public func cancelOffer(to id: String) async throws {
        _ = try await post("/friends/cancel", body: ["to": id])
    }

    // MARK: One-off Rating Carry-over

    /// Carries over existing Game Center leaderboard ratings into clocks where
    /// the service currently holds 0 games for this account.
    public static func importRatingsIfNeeded(
        serverRecords: [Int: OnlineRecord],
        api: OnlineAPI,
        loadGameCenterRecord: (TimeControl) async -> OnlineRecord?
    ) async -> [Int: OnlineRecord] {
        var updated = serverRecords
        for control in TimeControl.allCases {
            let current = updated[control.minutes] ?? .new
            guard current.games == 0 else { continue }
            guard var gcRecord = await loadGameCenterRecord(control) else { continue }
            if gcRecord.games <= 0 {
                gcRecord.games = 1
            }
            if let imported = try? await api.importRating(minutes: control.minutes, record: gcRecord) {
                updated[control.minutes] = imported
            }
        }
        return updated
    }

    // MARK: Internals

    private func post(_ path: String, body: [String: Any] = [:], authorized: Bool = true) async throws -> [String: Any] {
        let payload = try JSONSerialization.data(withJSONObject: body)
        return try await call(method: "POST", path: path, body: payload, authorized: authorized, timeout: 15)
    }

    private func call(
        method: String,
        path: String,
        body: Data?,
        authorized: Bool,
        timeout: TimeInterval,
        allowReauth: Bool = true
    ) async throws -> [String: Any] {
        guard let url = URL(string: rootURL + path) else {
            throw OnlineError(status: 400, code: "bad-url")
        }
        var headers: [String: String] = [
            "Accept": "application/json",
            "X-Device-ID": device,
        ]
        if authorized {
            if session == nil, allowReauth, reauthenticator != nil {
                _ = try await reauthenticate()
            }
            guard let session else {
                throw OnlineError(status: 401, code: "session")
            }
            headers["Authorization"] = "Bearer \(session)"
        }

        let response = try await transport.send(
            method: method,
            url: url,
            headers: headers,
            body: body,
            timeout: timeout
        )

        if response.status == 401, authorized, allowReauth, reauthenticator != nil {
            _ = try await reauthenticate()
            return try await call(
                method: method,
                path: path,
                body: body,
                authorized: true,
                timeout: timeout,
                allowReauth: false
            )
        }

        let parsed = (try? JSONSerialization.jsonObject(with: response.body)) as? [String: Any]
        guard response.status == 200 else {
            throw OnlineError(status: response.status, code: parsed?.string("error") ?? "http")
        }
        guard let parsed else {
            throw OnlineError(status: 200, code: "malformed")
        }
        return parsed
    }

    @discardableResult
    public func reauthenticate() async throws -> OnlineLogin {
        if let activeReauth {
            return try await activeReauth.value
        }
        guard let reauthenticator else {
            throw OnlineError(status: 401, code: "session")
        }
        let task = Task { @MainActor in
            try await reauthenticator()
        }
        activeReauth = task
        defer { activeReauth = nil }
        let login = try await task.value
        self.session = login.session
        return login
    }

    // MARK: JSON Parsing

    public static func parseRecord(_ json: [String: Any]?) -> OnlineRecord {
        guard let json else { return .new }
        let rating = json.int("rating") ?? Glicko.starting
        let deviation = json.double("deviation") ?? Glicko.newDeviation
        let games = json.int("games") ?? 0
        let lastSeconds = json.int64("lastPlayed") ?? 0
        let lastPlayed = lastSeconds > 0 ? Date(timeIntervalSince1970: TimeInterval(lastSeconds)) : nil
        return OnlineRecord(rating: rating, deviation: deviation, games: games, lastPlayed: lastPlayed)
    }

    private static func parsePlayer(_ json: [String: Any]) -> OnlinePlayer {
        OnlinePlayer(
            id: json.string("id") ?? "",
            alias: json.string("alias") ?? "",
            record: parseRecord(json),
            rank: json.int("rank")
        )
    }

    private static func parseInvite(_ json: [String: Any]) -> OnlineFriendInvite {
        OnlineFriendInvite(
            id: json.string("id") ?? json.string("from") ?? "",
            alias: json.string("alias") ?? "",
            minutes: json.int("minutes") ?? 5
        )
    }

    public static func parseEvent(_ json: [String: Any]) -> OnlineEvent? {
        switch json.string("type") {
        case "match":
            let opponent = json.dict("opponent").map(parsePlayer) ?? OnlinePlayer(id: "", alias: "")
            let info = OnlineMatchInfo(
                id: json.string("match") ?? "",
                host: json.bool("host") ?? false,
                minutes: json.int("minutes") ?? 5,
                open: json.bool("open") ?? true,
                opponent: opponent,
                me: parseRecord(json.dict("me"))
            )
            return .matched(info)

        case "packet":
            guard let packetObj = json["packet"],
                  JSONSerialization.isValidJSONObject(packetObj),
                  let data = try? JSONSerialization.data(withJSONObject: packetObj)
            else { return nil }
            return .packet(match: json.string("match") ?? "", packet: data)

        case "result":
            let result = OnlineGameResult(
                match: json.string("match") ?? "",
                game: json.int("game") ?? 1,
                winner: json.string("winner"),
                reason: json.string("reason") ?? "",
                rated: json.bool("rated") ?? false,
                unrated: json.string("unrated"),
                minutes: json.int("minutes") ?? 5,
                delta: json.int("delta") ?? 0,
                record: parseRecord(json.dict("record"))
            )
            return .result(result)

        case "peer":
            return .peer(match: json.string("match") ?? "", connected: json.bool("connected") ?? true)

        case "matchEnded":
            return .matchEnded(match: json.string("match") ?? "")

        case "seekEnded":
            return .seekEnded(reason: json.string("reason") ?? "")

        case "friends":
            return .friendsChanged

        case "invite":
            return .invited(parseInvite(json))

        case "inviteDeclined":
            return .inviteDeclined(from: json.string("from") ?? "")

        default:
            return nil
        }
    }
}

// MARK: - Ordered Match Outbox & Match Driver

/// Strictly ordered FIFO packet relay (`POST /match/send`), keeping at most one
/// HTTP request in flight and retrying transient network/server errors.
@MainActor
public final class ServiceMatchOutbox: MatchTransport {
    private var continuation: AsyncStream<Data>.Continuation?
    private var worker: Task<Void, Never>?
    private var isClosed = false

    public init(
        matchID: String,
        api: OnlineAPI,
        maxAttempts: Int = 5,
        retryDelay: @escaping @Sendable (Int) -> Duration = { attempt in .milliseconds(600 * attempt) }
    ) {
        let (stream, continuation) = AsyncStream<Data>.makeStream()
        self.continuation = continuation
        self.worker = Task { @MainActor in
            for await packet in stream {
                var attempt = 0
                while !Task.isCancelled {
                    do {
                        try await api.send(match: matchID, packet: packet)
                        break
                    } catch is CancellationError {
                        return
                    } catch let error as OnlineError {
                        if !error.isTransient {
                            // Refused by referee (illegal/stale move or closed match) — do not repeat.
                            break
                        }
                    } catch {
                        // Network error (URLError, etc.) — retry in place to preserve packet order.
                    }
                    attempt += 1
                    if attempt >= maxAttempts || Task.isCancelled { break }
                    try? await Task.sleep(for: retryDelay(attempt))
                }
            }
        }
    }

    public func send(_ data: Data) {
        guard !isClosed else { return }
        continuation?.yield(data)
    }

    public func close() {
        guard !isClosed else { return }
        isClosed = true
        continuation?.finish()
        continuation = nil
        worker?.cancel()
        worker = nil
    }
}

/// Bridges a service `OnlineMatchInfo` and its `/events` stream into `MatchSession`.
@MainActor
@Observable
public final class OnlineMatchDriver {
    public let info: OnlineMatchInfo
    public let session: MatchSession
    public let outbox: ServiceMatchOutbox
    public private(set) var opponentConnected = true
    public private(set) var isClosed = false
    public private(set) var resultsByGame: [Int: OnlineGameResult] = [:]

    public var latestResult: OnlineGameResult? {
        resultsByGame[session.gameNumber]
    }

    public init(
        info: OnlineMatchInfo,
        account: String,
        alias: String,
        api: OnlineAPI,
        retryDelay: @escaping @Sendable (Int) -> Duration = { attempt in .milliseconds(600 * attempt) }
    ) {
        self.info = info
        let outbox = ServiceMatchOutbox(matchID: info.id, api: api, retryDelay: retryDelay)
        self.outbox = outbox
        let clock = TimeControl(rawValue: info.minutes) ?? .five
        self.session = MatchSession(
            transport: outbox,
            me: MatchPacket.Hello(
                playerID: account,
                name: alias,
                rating: info.me.rating,
                games: info.me.games,
                deviation: info.me.deviation
            ),
            isHost: info.host,
            timeControl: clock,
            openPool: info.open
        )
    }

    public func begin(whiteIsHost: Bool? = nil) {
        session.begin(whiteIsHost: whiteIsHost)
    }

    public func handle(_ event: OnlineEvent) {
        switch event {
        case .packet(let match, let packet) where match == info.id:
            session.receive(packet)

        case .peer(let match, let connected) where match == info.id:
            opponentConnected = connected

        case .result(let result) where result.match == info.id:
            resultsByGame[result.game] = result
            guard result.game == session.gameNumber else { return }
            if case .playing = session.phase {
                let winnerColor: PieceColor? = switch result.winner {
                case "white": .white
                case "black": .black
                default: nil
                }
                let reason = MatchResult.Reason(rawValue: result.reason) ?? .agreement
                if let overData = try? JSONEncoder().encode(MatchPacket.gameOver(.init(winner: winnerColor, reason: reason))) {
                    session.receive(overData)
                }
            }
            session.applyServerResult(
                ratingDelta: result.delta,
                deviation: result.rated ? result.record.deviation : nil
            )

        case .matchEnded(let match) where match == info.id:
            isClosed = true
            session.opponentDisconnected()

        default:
            break
        }
    }

    public func shutdown() {
        outbox.close()
    }
}

// MARK: - Dictionary Helpers

private extension Dictionary where Key == String, Value == Any {
    func string(_ key: String) -> String? {
        guard let value = self[key], !(value is NSNull) else { return nil }
        return value as? String
    }

    func int(_ key: String) -> Int? {
        if let i = self[key] as? Int { return i }
        if let n = self[key] as? NSNumber { return n.intValue }
        return nil
    }

    func int64(_ key: String) -> Int64? {
        if let i = self[key] as? Int64 { return i }
        if let i = self[key] as? Int { return Int64(i) }
        if let n = self[key] as? NSNumber { return n.int64Value }
        return nil
    }

    func double(_ key: String) -> Double? {
        if let d = self[key] as? Double { return d }
        if let n = self[key] as? NSNumber { return n.doubleValue }
        return nil
    }

    func bool(_ key: String) -> Bool? {
        if let b = self[key] as? Bool { return b }
        if let n = self[key] as? NSNumber { return n.boolValue }
        return nil
    }

    func dict(_ key: String) -> [String: Any]? {
        guard let value = self[key], !(value is NSNull) else { return nil }
        return value as? [String: Any]
    }

    func dictList(_ key: String) -> [[String: Any]] {
        guard let array = self[key] as? [Any] else { return [] }
        return array.compactMap { $0 as? [String: Any] }
    }
}
