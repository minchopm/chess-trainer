import ChessCore
import Foundation

/// The daily feed: the finished games from the day's top events, each with the
/// move where the engine says it turned.
///
/// Collected every two hours by `scripts/feed/collect.mjs` in Lambda and
/// served as static files from brasspawn.com: the newest days in one file, and
/// every earlier day in a file of its own. The moves and results are the
/// official broadcast's and the scores are Stockfish's. The words either say
/// only what those two say — the collector's own — or were rewritten and
/// approved by a person. The app adds the parts that can be said in every
/// language — who beat whom, which round, which move — and shows the English
/// commentary as it came.
public struct FeedFile: Codable, Sendable, Equatable {
    /// One day of the history, and how many stories it has.
    public struct Day: Codable, Sendable, Hashable {
        public let date: String
        public let count: Int
    }

    public let version: Int
    public let generatedAt: Date
    /// The newest few days, in full.
    public let stories: [FeedStory]
    /// Every day there is, newest first — the ones not in `stories` are
    /// fetched one file each as the reader goes back through them.
    public let days: [Day]?

    /// The only version this build understands. A later one is a feed this
    /// build cannot read, and saying so is better than reading half of it.
    public static let supportedVersion = 1

    public static func decode(_ data: Data) throws -> FeedFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: text) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: text) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "not an ISO 8601 date: \(text)"))
        }
        let file = try decoder.decode(FeedFile.self, from: data)
        guard file.version == supportedVersion else { throw FeedError.unsupportedVersion(file.version) }
        // A story whose moves do not play is dropped rather than shown: its
        // replay would stop halfway and nobody could tell whose fault it was.
        return FeedFile(version: file.version, generatedAt: file.generatedAt,
                        stories: file.stories.filter { $0.line != nil }, days: file.days)
    }

    public init(version: Int, generatedAt: Date, stories: [FeedStory], days: [Day]? = nil) {
        self.version = version
        self.generatedAt = generatedAt
        self.stories = stories
        self.days = days
    }
}

/// One day's stories: `days/<date>.json`, for going back through the history.
public struct FeedDay: Codable, Sendable, Equatable {
    public let date: String
    public let stories: [FeedStory]

    public static func decode(_ data: Data) throws -> FeedDay {
        let day = try JSONDecoder().decode(FeedDay.self, from: data)
        return FeedDay(date: day.date, stories: day.stories.filter { $0.line != nil })
    }

    public init(date: String, stories: [FeedStory]) {
        self.date = date
        self.stories = stories
    }
}

public enum FeedError: Error, Equatable {
    case unsupportedVersion(Int)
}

public struct FeedStory: Codable, Sendable, Hashable, Identifiable {
    public struct Player: Codable, Sendable, Hashable {
        public let name: String
        public let short: String
        public let title: String?
        public let elo: Int?
        public let team: String?
    }

    public struct Event: Codable, Sendable, Hashable {
        public let name: String
        public let short: String
        public let section: String?
        public let round: Int?
        public let location: String?
    }

    public struct Score: Codable, Sendable, Hashable {
        public let cp: Int?
        public let mate: Int?
    }

    public struct Key: Codable, Sendable, Hashable {
        /// `mistake`: the loser's move that decided it. `breakthrough`: the
        /// winner's. `swing`: in a draw, the chance that came and went.
        public let kind: String
        /// Half-moves played up to and including the key move.
        public let ply: Int
        public let played: String
        public let better: String?
        public let reply: String?
        public let replyPlayed: Bool?
        public let before: Score
        public let after: Score
    }

    public struct Opening: Codable, Sendable, Hashable {
        public let eco: String?
        public let name: String?
    }

    public struct Source: Codable, Sendable, Hashable {
        public let name: String
        public let url: URL?
    }

    public let id: String
    /// The day the round was played, as `yyyy-MM-dd`.
    public let date: String
    public let event: Event
    public let white: Player
    public let black: Player
    /// `1-0`, `0-1` or `1/2-1/2`.
    public let result: String
    public let opening: Opening
    /// SAN, space separated, from the initial position.
    public let moves: String
    public let key: Key?
    public let headline: String
    public let body: String
    public let url: URL
    public let source: Source
    /// The board the story is about and the move that made it, worked out by
    /// the collector. Optional: a story written before it did is replayed.
    public let fen: String?
    public let last: LastMove?

    public struct LastMove: Codable, Sendable, Hashable {
        public let from: String
        public let to: String
    }

    public var sans: [String] { moves.split(separator: " ").map(String.init) }

    /// The game as positions, or nil when a move does not play.
    public var line: [Position]? {
        var position = Position()
        var positions = [position]
        for san in sans {
            guard let move = position.move(san: san), position.make(move) != nil else { return nil }
            positions.append(position)
        }
        return positions
    }

    /// The half-move the story is about: the key move when there is one, the
    /// last move when there is not.
    public var focusPly: Int { key?.ply ?? sans.count }

    /// The board the story is about, and the move that made it — read off the
    /// stored position when there is one, which is every list row, many
    /// times a second while it scrolls, rather than a replay of the game.
    public var focus: (position: Position, lastMove: Move?) {
        if let fen, let position = Position(fen: fen) {
            let move = last.flatMap { last in
                Square(last.from).flatMap { from in Square(last.to).map { Move(from: from, to: $0) } }
            }
            return (position, move)
        }
        var position = Position()
        var last: Move?
        for san in sans.prefix(focusPly) {
            guard let move = position.move(san: san), position.make(move) != nil else { break }
            last = move
        }
        return (position, last)
    }

    /// Who won, or nil for a draw.
    public var winner: PieceColor? {
        switch result {
        case "1-0": .white
        case "0-1": .black
        default: nil
        }
    }

    /// The story's title in the reader's language: the one sentence the feed
    /// can say in all thirty-two without a translator having read the game.
    public var title: String {
        switch winner {
        case .white: L.t("today.beat", "%1$@ beat %2$@", white.short, black.short)
        case .black: L.t("today.beat", "%1$@ beat %2$@", black.short, white.short)
        case nil: L.t("today.drew", "%1$@ and %2$@ drew", white.short, black.short)
        }
    }

    /// "Olympiad · Open · Round 9", with the round in the reader's language.
    public var occasion: String {
        [event.short, event.section, event.round.map { L.t("today.round", "Round %lld", $0) }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// 41.Rxg7+ or 40...Rxb3 — the move as it is printed, and as the
    /// commentary prints it, so the two can be read side by side.
    public static func label(ply: Int, san: String) -> String {
        let number = (ply + 1) / 2
        return ply % 2 == 1 ? "\(number).\(san)" : "\(number)...\(san)"
    }

    /// The day, as the reader's calendar writes it.
    public var day: Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

extension FeedStory.Score {
    /// Stockfish's number, from White's side: +1.08, −4.40, #3.
    public var text: String {
        if let mate { return mate > 0 ? "#\(mate)" : "#−\(-mate)" }
        let pawns = Double(cp ?? 0) / 100
        let sign = pawns > 0 ? "+" : pawns < 0 ? "−" : ""
        return sign + abs(pawns).formatted(.number.precision(.fractionLength(2)))
    }
}

/// The addresses a story travels by.
///
/// Three reach the app. brasspawn://today/<id> is the site's own button for
/// somebody who has the app. The App Clip link — the same form a game
/// invitation takes — is the one an iPhone can follow whether the app is there
/// or not: with it, iOS hands the link to the app; without, to the clip, which
/// shows the game and leaves it in the shared container for the app installed
/// from it. And brasspawn.com/today/<id>, in case the site's address is ever
/// handed over as it is.
public enum FeedLink {
    public static func storyID(in url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var candidate: String?
        switch (url.scheme, url.host()) {
        case ("brasspawn", "today"):
            candidate = url.pathComponents.dropFirst().first
        case ("https", "appclip.apple.com"):
            candidate = components?.queryItems?.first { $0.name == "s" }?.value
        case ("https", "brasspawn.com"), ("https", "www.brasspawn.com"):
            let parts = url.pathComponents
            if parts.count == 3, parts[1] == "today", parts[2] != "story" {
                candidate = parts[2]
            } else if parts.count == 3, parts[1] == "today", parts[2] == "story" {
                candidate = components?.queryItems?.first { $0.name == "id" }?.value
            }
        default:
            break
        }
        guard let id = candidate, id.range(of: "^[a-z0-9-]{1,120}$", options: .regularExpression) != nil
        else { return nil }
        return id
    }

    /// The App Clip's link for a story.
    public static func clip(for id: String) -> URL {
        var components = URLComponents(string: "https://appclip.apple.com/id")!
        components.queryItems = [
            URLQueryItem(name: "p", value: Invitation.clipBundleID),
            URLQueryItem(name: "s", value: id),
        ]
        return components.url!
    }

    /// Where a story's file is, for the clip, which has no feed of its own.
    public static func file(for id: String) -> URL {
        URL(string: "https://brasspawn.com/media/feed/v1/stories/\(id).json")!
    }
}
