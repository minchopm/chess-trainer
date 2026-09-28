import ChessCore
import Foundation

/// What the two devices say to each other.
///
/// JSON rather than a packed binary frame. A chess match sends a few dozen
/// small messages over several minutes, so the bytes do not matter, and a
/// format that can be read in a log is worth more than one that saves forty
/// bytes on a move nobody is waiting for.
public enum MatchPacket: Codable, Equatable, Sendable {
    /// Sent by both sides on connect, so each knows who it is playing.
    case hello(Hello)
    /// Sent by the host only: it settles colours and the clock.
    case start(Start)
    case move(MovePacket)
    case resign
    case drawOffer
    case drawResponse(accepted: Bool)
    /// Claimed by whichever device notices first; the other accepts it.
    case gameOver(GameOver)
    /// After a game: another one, in the same match, colours swapped and the
    /// clock the same — so two people who want to carry on do not have to find
    /// each other again. A build that predates these drops them unread, and
    /// the offer simply goes unanswered.
    case rematchOffer
    case rematchResponse(accepted: Bool)
    /// Leaving the match: said, so the other side knows at once rather than
    /// after the wait a dropped connection is given to come back.
    case goodbye

    public struct Hello: Codable, Equatable, Sendable {
        public var version: Int = MatchProtocolVersion.current
        public var playerID: String
        public var name: String
        public var rating: Int
        public var games: Int
        /// How sure the rating is (Glicko's RD). Absent from builds before
        /// Glicko, whose players are given one from their game count.
        public var deviation: Double?

        public init(playerID: String, name: String, rating: Int, games: Int, deviation: Double? = nil) {
            self.playerID = playerID
            self.name = name
            self.rating = rating
            self.games = games
            self.deviation = deviation
        }

        /// The deviation to score this side against.
        public var ratingDeviation: Double { deviation ?? Glicko.deviation(games: games) }
    }

    public struct Start: Codable, Equatable, Sendable {
        public var version: Int = MatchProtocolVersion.current
        /// The colour the *receiver* plays. Decided by the host so that the
        /// two devices cannot disagree, and randomly so that being host is not
        /// worth anything.
        public var youPlay: String
        public var minutes: Int

        public init(youPlay: PieceColor, timeControl: TimeControl) {
            self.youPlay = youPlay == .white ? "white" : "black"
            self.minutes = timeControl.minutes
        }

        public var receiverColor: PieceColor { youPlay == "white" ? .white : .black }
        public var timeControl: TimeControl { TimeControl(rawValue: minutes) ?? .five }
    }

    public struct MovePacket: Codable, Equatable, Sendable {
        public var uci: String
        /// Which ply this is, counted from the start of the game. A move that
        /// arrives twice, or out of order after a reconnect, is then something
        /// the receiver can recognise rather than something it plays.
        public var ply: Int
        /// The sender's own clock after making the move.
        public var remaining: TimeInterval
        /// And the sender's reading of the *receiver's* clock.
        ///
        /// Without it the two devices disagree, and always in the same
        /// direction: each starts the opponent's clock when the move arrives
        /// and its own when the move is sent, so each is a network hop kinder
        /// to itself than the other is. A hundred milliseconds a move is four
        /// seconds over a blitz game — enough for one player to be out of time
        /// on the other's screen while still thinking on their own.
        ///
        /// Both readings are adopted downwards, so the pair converges on the
        /// lower of the two and both screens show the same number.
        ///
        /// Optional because a packet from a build that predates it still has
        /// to decode; there is nothing to adopt and the old drift is what you
        /// get.
        public var yours: TimeInterval?

        public init(uci: String, ply: Int, remaining: TimeInterval, yours: TimeInterval? = nil) {
            self.uci = uci
            self.ply = ply
            self.remaining = remaining
            self.yours = yours
        }
    }

    public struct GameOver: Codable, Equatable, Sendable {
        public var winner: String?      // "white", "black", or nil for a draw
        public var reason: String

        public init(winner: PieceColor?, reason: MatchResult.Reason) {
            self.winner = winner.map { $0 == .white ? "white" : "black" }
            self.reason = reason.rawValue
        }

        public var winnerColor: PieceColor? {
            switch winner {
            case "white": .white
            case "black": .black
            default: nil
            }
        }

        public var resultReason: MatchResult.Reason {
            MatchResult.Reason(rawValue: reason) ?? .agreement
        }
    }
}

public enum MatchProtocolVersion {
    public static let current = 1
}

/// How a match ended, from the local player's point of view.
public struct MatchResult: Equatable, Sendable {
    public enum Outcome: String, Sendable { case win, loss, draw }
    public enum Reason: String, Codable, Sendable {
        case checkmate, resignation, timeout, stalemate, insufficientMaterial
        case repetition, fiftyMoveRule, agreement, disconnected

        public var text: String {
            switch self {
            case .checkmate: L.t("result.checkmate", "checkmate")
            case .resignation: L.t("result.resignation", "resignation")
            case .timeout: L.t("result.time", "time")
            case .stalemate: L.t("result.stalemate", "stalemate")
            case .insufficientMaterial: L.t("result.insufficientMaterial", "insufficient material")
            case .repetition: L.t("result.repetition", "repetition")
            case .fiftyMoveRule: L.t("result.fiftyMoveRule", "the fifty-move rule")
            case .agreement: L.t("result.agreement", "agreement")
            case .disconnected: L.t("result.disconnected", "the opponent leaving")
            }
        }
    }

    public let outcome: Outcome
    public let reason: Reason
    /// Change in your rating, once it has been applied.
    public var ratingDelta: Int = 0
    /// How sure the rating is after this game, once it has been applied.
    public var deviation: Double?

    public init(outcome: Outcome, reason: Reason, ratingDelta: Int = 0) {
        self.outcome = outcome
        self.reason = reason
        self.ratingDelta = ratingDelta
    }

    public var headline: String {
        switch outcome {
        case .win: L.t("result.youWonBy", "You won by %@", reason.text)
        case .loss: L.t("result.youLostBy", "You lost by %@", reason.text)
        case .draw: L.t("result.drawnBy", "Drawn by %@", reason.text)
        }
    }

    /// The score this outcome is worth for a rating calculation.
    public var score: Double {
        switch outcome {
        case .win: 1
        case .draw: 0.5
        case .loss: 0
        }
    }
}

/// Why a game played online leaves the ratings alone.
///
/// The rank lists are only worth anything if a place on them has to be won
/// against whoever the search turns up. So a game two people arranged, a
/// rematch, and a second game in a day against the same opponent are played
/// just the same, and scored as a friendly.
public enum UnratedReason: String, Sendable {
    case invitation, rematch, sameOpponentToday

    public var text: String {
        switch self {
        case .invitation: L.t("online.unrated.invitation", "Not rated: games from an invitation are friendly.")
        case .rematch: L.t("online.unrated.rematch", "Not rated: a rematch is a friendly game.")
        case .sameOpponentToday: L.t("online.unrated.again", "Not rated: only one game a day against the same opponent counts.")
        }
    }
}

/// Elo, for the training ratings: a rating measured against a library of
/// rated puzzles and positions, with K falling as the record settles.
public enum Elo {
    /// No rating goes below this; there is no ceiling.
    public static let floor = 100

    public static func expected(_ rating: Int, against opponent: Int) -> Double {
        1 / (1 + pow(10, Double(opponent - rating) / 400))
    }

    public static func kFactor(games: Int) -> Double {
        if games < 15 { return 40 }
        if games < 100 { return 24 }
        return 16
    }

    public static func updated(
        rating: Int, games: Int, against opponent: Int, score: Double
    ) -> Int {
        let next = Double(rating) + kFactor(games: games) * (score - expected(rating, against: opponent))
        return max(Int(next.rounded()), floor)
    }
}

/// Glicko, for games against people — the system chess.com rates with.
///
/// A rating comes with a deviation, how sure it is. A new player's is wide,
/// so their first games move it a long way; it narrows with every game, and
/// widens again while they are away. What a result is worth follows from the
/// gap: beating somebody far below earns next to nothing — nothing at all, past
/// a point — and drawing with them costs points, as losing to them costs many.
///
/// The same numbers on both devices, computed from the ratings the two sides
/// exchanged in `hello`.
public enum Glicko {
    public static let starting = 1200
    /// No rating goes below this; there is no ceiling.
    public static let floor = 100
    /// A new player's deviation, and the most an idle one grows back to.
    public static let newDeviation = 350.0
    /// The narrowest a deviation gets, however many games: a rating always
    /// stays able to move.
    public static let settledDeviation = 50.0
    /// How much uncertainty a day without a game adds: a settled rating is
    /// back to a new player's after about a year away.
    public static let growthPerDay = ((newDeviation * newDeviation - settledDeviation * settledDeviation) / 365).squareRoot()

    private static let q = log(10.0) / 400

    /// A deviation for a record that has none — a build before Glicko: wide
    /// for a handful of games, narrow for hundreds.
    public static func deviation(games: Int) -> Double {
        max(settledDeviation, newDeviation / (1 + Double(max(games, 0)) / 2.5).squareRoot())
    }

    /// A deviation after time without a game.
    public static func deviation(_ deviation: Double, idle: TimeInterval) -> Double {
        let days = max(idle, 0) / 86_400
        return min((deviation * deviation + growthPerDay * growthPerDay * days).squareRoot(), newDeviation)
    }

    /// How much an opponent's result says: less, the less sure their rating is.
    private static func g(_ deviation: Double) -> Double {
        1 / (1 + 3 * q * q * deviation * deviation / (Double.pi * Double.pi)).squareRoot()
    }

    /// The score expected against this opponent, from 0 to 1.
    public static func expected(_ rating: Int, against opponent: Int, opponentDeviation: Double) -> Double {
        1 / (1 + pow(10, -g(opponentDeviation) * Double(rating - opponent) / 400))
    }

    /// The rating and deviation after one game.
    public static func updated(
        rating: Int, deviation: Double,
        against opponent: Int, opponentDeviation: Double,
        score: Double
    ) -> (rating: Int, deviation: Double) {
        let impact = g(opponentDeviation)
        let e = expected(rating, against: opponent, opponentDeviation: opponentDeviation)
        let inverseD2 = q * q * impact * impact * e * (1 - e)
        let precision = 1 / (deviation * deviation) + inverseD2
        let next = Double(rating) + q / precision * impact * (score - e)
        let nextDeviation = max((1 / precision).squareRoot(), settledDeviation)
        return (max(Int(next.rounded()), floor), nextDeviation)
    }
}
