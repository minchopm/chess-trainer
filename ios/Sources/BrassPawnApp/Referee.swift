import ChessTraining
import CryptoKit
import Foundation
#if canImport(GameKit)
@preconcurrency import GameKit
#endif

/// What the referee said about one game, for this player.
struct RefereeVerdict: Decodable, Equatable {
    /// "rated", "unrated", "void" or "pending".
    let status: String
    let reason: String?
    let minutes: Int?
    /// The rating now, and what the game did to it, when it was rated.
    let rating: Int?
    let delta: Int?
    let deviation: Double?
    let games: Int?

    var isRated: Bool { status == "rated" && rating != nil }
    var isPending: Bool { status == "pending" }
}

/// One clock's list, as the referee publishes it: everybody rated on it,
/// best first, by the hash of their Game Center team player ID.
struct Standings: Decodable {
    struct Entry: Decodable {
        let id: String
        let rating: Int
        let deviation: Double
        let games: Int
        /// The day of their last rated game.
        let last: String
    }
    let minutes: Int
    let players: [Entry]
}

/// The referee: the ratings of games played online are its, not this device's.
///
/// A device that worked out its own rating could be made to claim any number.
/// So both players tell the referee — a small function of ours, see
/// `scripts/ratings` — that a game began and how it ended, each with Game
/// Center's signature saying who they are; it rates the game only on a result
/// both sides stand behind, by its own numbers, and publishes each clock's list.
/// It is told nothing else: no name, no photo, no contacts — Game Center's
/// team player ID, which it keeps only as a hash, the clock, the colour, the
/// moves and the result.
@MainActor
final class Referee {
    nonisolated static let endpoint = URL(string: "https://ebb7rhdzn3yv7pjsrjtsec3ddq0nwifq.lambda-url.eu-central-1.on.aws")!
    nonisolated static let lists = URL(string: "https://brasspawn.com/media/ratings/v1/")!

    /// A player's key on the lists: never the ID itself.
    nonisolated static func key(teamPlayerID: String) -> String {
        let digest = SHA256.hash(data: Data("brasspawn:\(teamPlayerID)".utf8))
        return String(digest.map { String(format: "%02x", $0) }.joined().prefix(32))
    }

    /// This player's key, once signed in to Game Center.
    var localKey: String? {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated else { return nil }
        return Self.key(teamPlayerID: GKLocalPlayer.local.teamPlayerID)
        #else
        return nil
        #endif
    }

    /// A game has begun. Said by both players, so that a report later can be
    /// checked against a game that both of them were in.
    func begin(_ session: MatchSession) async {
        guard let game = ticket(session) else { return }
        _ = try? await post("begin", game)
    }

    /// How a game ended, and what the referee made of it. The other player's
    /// report is usually a second behind this one; if it is not, the answer is
    /// asked for again a few times, then left to the lists.
    func end(_ session: MatchSession, result: MatchResult) async -> RefereeVerdict? {
        guard var game = ticket(session) else { return nil }
        game["moves"] = session.uciMoves
        game["outcome"] = result.outcome.rawValue
        game["reason"] = result.reason.rawValue
        var verdict: RefereeVerdict?
        for wait in [0, 2, 4, 8, 15, 30] {
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            if let answer = try? await post("end", game) {
                verdict = answer
                if !answer.isPending { break }
            }
        }
        return verdict
    }

    /// This player's online ratings, removed from the referee and its lists.
    func forget() async -> Bool {
        (try? await post("forget", [:]))?.status == "forgotten"
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

    /// One clock's list. Served as a file by the site, cached for a minute.
    nonisolated static func standings(_ control: TimeControl) async -> Standings? {
        let url = Self.lists.appendingPathComponent("\(control.minutes).json")
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadRevalidatingCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(Standings.self, from: data)
    }

    // MARK: -

    private func ticket(_ session: MatchSession) -> [String: Any]? {
        guard let gameID = session.gameID else { return nil }
        return [
            "gameID": gameID,
            "minutes": session.timeControl.minutes,
            "openPool": session.openPool,
            "gameNumber": session.gameNumber,
            "color": session.myColor == .white ? "white" : "black",
        ]
    }

    private func post(_ path: String, _ body: [String: Any]) async throws -> RefereeVerdict {
        try JSONDecoder().decode(RefereeVerdict.self, from: await postRaw(path, body))
    }

    private func postRaw(_ path: String, _ body: [String: Any]) async throws -> Data {
        var body = body
        body["identity"] = try await identity()
        var request = URLRequest(url: Self.endpoint.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 20
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
