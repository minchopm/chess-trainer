import ChessTraining
import CryptoKit
import Foundation
#if canImport(GameKit)
@preconcurrency import GameKit
#endif

/// Who is online right now: the one thing Game Center cannot say.
///
/// While the app is on screen, signed in, and the player shows it (Settings →
/// Show when I'm online), it tells a small function of ours — see
/// `scripts/presence` — that they are here, looking for a game, or in one;
/// the players list asks it who is. Each word is signed by Game Center, which
/// is how the function knows it is this player, and lasts five minutes. It
/// keeps nothing else: the ratings are Game Center's (`OnlineRecord`).
@MainActor
final class Presence {
    nonisolated static let endpoint = URL(string: "https://6slkhltuygwkjupda7inipuoae0pxybf.lambda-url.eu-central-1.on.aws")!

    /// A player's key there: never the Game Center ID itself.
    nonisolated static func key(teamPlayerID: String) -> String {
        let digest = SHA256.hash(data: Data("brasspawn:\(teamPlayerID)".utf8))
        return String(digest.map { String(format: "%02x", $0) }.joined().prefix(32))
    }

    // MARK: - Who is online

    /// This player is on screen, and doing this: here, looking for a game on a
    /// clock, or in one. It lasts five minutes unless said again.
    func here(_ status: PresenceStatus) async {
        var body: [String: Any] = ["status": status.word]
        if let minutes = status.minutes { body["minutes"] = minutes }
        _ = try? await postRaw("here", body)
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
