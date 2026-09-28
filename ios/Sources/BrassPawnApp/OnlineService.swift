import ChessTraining
import CryptoKit
import Foundation
#if canImport(GameKit)
@preconcurrency import GameKit
#endif

/// The small service of ours behind online play — see `scripts/presence` —
/// for the two things Game Center cannot do.
///
/// Who is online right now: while the app is on screen, signed in, and the
/// player shows it (Settings → Show when I'm online), it says they are here,
/// looking for a game, or in one, and the players list asks who is. Each word
/// lasts five minutes.
///
/// And friends, asked for by the nickname on a list, which Game Center's
/// friends cannot be: requests, the friends themselves, and games offered to a
/// friend Game Center cannot send an invitation to. Every request is signed by
/// Game Center, which is how the service knows it is this player. The ratings
/// are not here: they are Game Center's (`OnlineRecord`).
@MainActor
final class OnlineService {
    nonisolated static let endpoint = URL(string: "https://6slkhltuygwkjupda7inipuoae0pxybf.lambda-url.eu-central-1.on.aws")!

    /// A player's key there: never the Game Center ID itself.
    nonisolated static func key(teamPlayerID: String) -> String {
        let digest = SHA256.hash(data: Data("brasspawn:\(teamPlayerID)".utf8))
        return String(digest.map { String(format: "%02x", $0) }.joined().prefix(32))
    }

    // MARK: - Who is online

    /// This player is on screen, and doing this: here, looking for a game on a
    /// clock, or in one. It lasts five minutes unless said again.
    /// The answer carries any game a friend has offered, so saying it is
    /// also hearing that.
    @discardableResult
    func here(_ status: PresenceStatus) async -> [FriendInvite]? {
        var body: [String: Any] = ["status": status.word]
        if let minutes = status.minutes { body["minutes"] = minutes }
        guard let data = try? await postRaw("here", body) else { return nil }
        return (try? JSONDecoder().decode(Offers.self, from: data))?.invites
    }

    /// Gone to the background, or no longer showing.
    func gone() async {
        _ = try? await postRaw("gone", [:])
    }

    /// Everybody on screen right now, by their key on the lists.
    func online() async -> [String: PresenceStatus]? {
        guard let data = try? await postRaw("online", [:]),
              let answer = try? JSONDecoder().decode(OnlineNow.self, from: data) else { return nil }
        return Dictionary(answer.players.compactMap { entry in PresenceStatus(entry).map { (entry.id, $0) } },
                          uniquingKeysWith: { a, _ in a })
    }

    // MARK: - Friends

    /// This player's friends, the requests both ways, and games offered.
    func friends() async -> FriendsList? {
        guard let data = try? await postRaw("friends", [:]) else { return nil }
        return try? JSONDecoder().decode(FriendsList.self, from: data)
    }

    /// Just the games offered: cheap enough to ask every few seconds while the
    /// lobby is open.
    func invites() async -> [FriendInvite]? {
        guard let data = try? await postRaw("friends/invites", [:]) else { return nil }
        return (try? JSONDecoder().decode(Offers.self, from: data))?.invites
    }

    /// Ask to be friends; if they had asked already, it is a yes.
    func request(_ key: String, alias: String) async -> Bool {
        await ok("friends/request", ["alias": myAlias, "to": key, "toAlias": alias])
    }

    func accept(_ key: String) async -> Bool {
        await ok("friends/accept", ["alias": myAlias, "from": key])
    }

    /// No longer friends, a request declined, or one taken back.
    func remove(_ key: String) async -> Bool {
        await ok("friends/remove", ["other": key])
    }

    /// Offer a friend a game on a clock. It waits two minutes for an answer.
    func offer(to key: String, minutes: Int) async -> Bool {
        await ok("friends/invite", ["alias": myAlias, "to": key, "minutes": minutes])
    }

    /// An offered game answered, yes or no.
    func answer(_ key: String) async {
        _ = await ok("friends/answer", ["from": key])
    }

    /// An offered game taken back.
    func cancelOffer(to key: String) async {
        _ = await ok("friends/cancel", ["to": key])
    }

    /// This player's nickname, as their friends will see it.
    var myAlias: String {
        #if canImport(GameKit)
        GKLocalPlayer.local.alias
        #else
        ""
        #endif
    }

    /// This player's own key.
    var myKey: String? {
        #if canImport(GameKit)
        GKLocalPlayer.local.isAuthenticated ? Self.key(teamPlayerID: GKLocalPlayer.local.teamPlayerID) : nil
        #else
        nil
        #endif
    }

    private func ok(_ path: String, _ body: [String: Any]) async -> Bool {
        (try? await postRaw(path, body)) != nil
    }

    // MARK: -

    private func postRaw(_ path: String, _ body: [String: Any]) async throws -> Data {
        var body = body
        body["identity"] = try await identity()
        var request = URLRequest(url: Self.endpoint.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }

    /// Game Center's word for who this player is: signed by Apple, fresh for
    /// each request, so it cannot be kept and sent again later.
    private func identity() async throws -> [String: Any] {
        #if canImport(GameKit)
        let local = GKLocalPlayer.local
        guard local.isAuthenticated else { throw URLError(.userAuthenticationRequired) }
        let (url, signature, salt, timestamp) = try await local.fetchItemsForIdentityVerificationSignature()
        return [
            "playerID": local.teamPlayerID,
            "bundleID": Bundle.main.bundleIdentifier ?? "",
            "publicKeyURL": url.absoluteString,
            "signature": signature.base64EncodedString(),
            "salt": salt.base64EncodedString(),
            "timestamp": timestamp,
        ]
        #else
        throw URLError(.unsupportedURL)
        #endif
    }
}

/// What a player online is doing, as far as anybody else is told.
enum PresenceStatus: Equatable, Sendable {
    case online
    case looking(TimeControl)
    case playing(TimeControl)

    var word: String {
        switch self {
        case .online: "online"
        case .looking: "looking"
        case .playing: "playing"
        }
    }

    var minutes: Int? {
        switch self {
        case .online: nil
        case .looking(let clock), .playing(let clock): clock.minutes
        }
    }

    fileprivate init?(_ entry: OnlineNow.Entry) {
        let clock = entry.minutes.flatMap(TimeControl.init(rawValue:))
        switch (entry.status, clock) {
        case ("online", _): self = .online
        case ("looking", let clock?): self = .looking(clock)
        case ("playing", let clock?): self = .playing(clock)
        default: return nil
        }
    }

    /// How a row on the players list says it.
    var label: String {
        switch self {
        case .online: L.t("online.presence.online", "Online now")
        case .looking(let clock): L.t("online.presence.looking", "Looking for a %@ game", clock.label)
        case .playing: L.t("online.presence.playing", "In a game")
        }
    }
}

private struct OnlineNow: Decodable {
    struct Entry: Decodable {
        let id: String
        let status: String
        let minutes: Int?
    }
    let players: [Entry]
}

/// A game a friend offered: who, and on what clock.
struct FriendInvite: Decodable, Equatable, Identifiable {
    /// The friend's key.
    let id: String
    let alias: String
    let minutes: Int

    var clock: TimeControl { TimeControl(rawValue: minutes) ?? .five }
}

/// A player's friends, as the service keeps them.
struct FriendsList: Decodable {
    struct Entry: Decodable {
        let id: String
        let alias: String
    }
    let friends: [Entry]
    let incoming: [Entry]
    let outgoing: [Entry]
    let invites: [FriendInvite]
}

private struct Offers: Decodable {
    let invites: [FriendInvite]
}
