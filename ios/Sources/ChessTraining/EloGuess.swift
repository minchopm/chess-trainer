import Foundation

/// Scoring for one rating estimate in Guess the Elo.
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
            case .spot: L.t("guess.spotOn", "Spot on")
            case .close: L.t("guess.close", "Close")
            case .fair: L.t("guess.rightArea", "In the right area")
            case .off: L.t("guess.notThisTime", "Not this time")
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
        if error < 15 { return L.t("guess.deadOn", "Dead on.") }
        return isHigh
            ? L.t("guess.tooHigh", "%lld points too high.", error)
            : L.t("guess.tooLow", "%lld points too low.", error)
    }
}

/// A separate rating guess for each player in the watched game.
///
/// Each side is judged against that player's real rating. The overall result
/// uses the mean of the two errors, so one accurate slider cannot hide a very
/// inaccurate guess for the other player.
public struct EloPairGuess: Equatable, Sendable {
    public let white: EloGuess
    public let black: EloGuess

    public init(whiteGuess: Int, blackGuess: Int, whiteActual: Int, blackActual: Int) {
        white = EloGuess(guess: whiteGuess, actual: whiteActual)
        black = EloGuess(guess: blackGuess, actual: blackActual)
    }

    public var averageError: Int { (white.error + black.error) / 2 }

    public var verdict: EloGuess.Verdict {
        switch averageError {
        case ..<75: .spot
        case ..<150: .close
        case ..<300: .fair
        default: .off
        }
    }

    public var points: Int { max(0, 100 - averageError / 5) }

    public var summary: String {
        averageError < 15
            ? L.t("guess.bothSpotOn", "Both ratings were spot on.")
            : L.t("guess.averageMiss", "Average miss: %lld points.", averageError)
    }
}

/// One judged game, kept so the mode can report whether you are getting better
/// at reading a game rather than just how the last one went.
public struct EloGuessRecord: Codable, Sendable {
    public let at: Date
    public let gameID: String
    public let guess: Int
    public let actual: Int
    public let whiteGuess: Int?
    public let whiteActual: Int?
    public let blackGuess: Int?
    public let blackActual: Int?

    public init(at: Date = Date(), gameID: String, guess: Int, actual: Int) {
        self.at = at
        self.gameID = gameID
        self.guess = guess
        self.actual = actual
        whiteGuess = nil
        whiteActual = nil
        blackGuess = nil
        blackActual = nil
    }

    public init(
        at: Date = Date(),
        gameID: String,
        whiteGuess: Int,
        whiteActual: Int,
        blackGuess: Int,
        blackActual: Int
    ) {
        self.at = at
        self.gameID = gameID
        guess = (whiteGuess + blackGuess) / 2
        actual = (whiteActual + blackActual) / 2
        self.whiteGuess = whiteGuess
        self.whiteActual = whiteActual
        self.blackGuess = blackGuess
        self.blackActual = blackActual
    }

    public var error: Int {
        guard let whiteGuess, let whiteActual, let blackGuess, let blackActual else {
            return abs(guess - actual)
        }
        return (abs(whiteGuess - whiteActual) + abs(blackGuess - blackActual)) / 2
    }

    public var bias: Int {
        guard let whiteGuess, let whiteActual, let blackGuess, let blackActual else {
            return guess - actual
        }
        return ((whiteGuess - whiteActual) + (blackGuess - blackActual)) / 2
    }
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
        bias = records.reduce(0) { $0 + $1.bias } / records.count
    }
}
