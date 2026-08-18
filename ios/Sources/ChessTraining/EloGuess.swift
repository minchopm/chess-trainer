import Foundation

/// Scoring for Guess the Elo.
///
/// The guess is judged against the average of the two players' ratings. Not
/// against either player individually: the game you watched was played by both
/// of them, and a 1500 who is being outplayed by a 1900 produces moves that
/// belong to neither level.
public struct EloGuess: Equatable, Sendable {
    public let guess: Int
    public let actual: Int

    public init(guess: Int, actual: Int) {
        self.guess = guess
        self.actual = actual
    }

    public var error: Int { abs(guess - actual) }
    public var isHigh: Bool { guess > actual }

    /// The range a guess may move in. Wider than the games in the library, so
    /// the ends of the slider are not answers in themselves.
    public static let range = 600...2800
    public static let step = 25

    public enum Verdict: Sendable {
        case spot, close, fair, off

        public var title: String {
            switch self {
            case .spot: "Spot on"
            case .close: "Close"
            case .fair: "In the right area"
            case .off: "Not this time"
            }
        }
    }

    /// Bands rather than a continuous score, because that is how the skill
    /// actually works: reading a game to within a class is the achievement, and
    /// the last fifty points are noise in the rating itself.
    public var verdict: Verdict {
        switch error {
        case ..<75: .spot
        case ..<150: .close
        case ..<300: .fair
        default: .off
        }
    }

    /// 100 for a perfect read, nothing once you are 500 out.
    public var points: Int { max(0, 100 - error / 5) }

    public var summary: String {
        if error < 15 { return "Dead on." }
        return "\(error) points too \(isHigh ? "high" : "low")."
    }
}

/// One judged game, kept so the mode can report whether you are getting better
/// at reading a game rather than just how the last one went.
public struct EloGuessRecord: Codable, Sendable {
    public let at: Date
    public let gameID: String
    public let guess: Int
    public let actual: Int

    public init(at: Date = Date(), gameID: String, guess: Int, actual: Int) {
        self.at = at
        self.gameID = gameID
        self.guess = guess
        self.actual = actual
    }

    public var error: Int { abs(guess - actual) }
}

public struct EloGuessStats: Sendable {
    public let judged: Int
    public let averageError: Int
    public let bestError: Int
    /// Positive when you tend to read games as stronger than they were, which
    /// is the common way to be wrong and worth naming.
    public let bias: Int

    public init(_ records: [EloGuessRecord]) {
        judged = records.count
        guard !records.isEmpty else {
            averageError = 0
            bestError = 0
            bias = 0
            return
        }
        averageError = records.reduce(0) { $0 + $1.error } / records.count
        bestError = records.map(\.error).min() ?? 0
        bias = records.reduce(0) { $0 + ($1.guess - $1.actual) } / records.count
    }
}
