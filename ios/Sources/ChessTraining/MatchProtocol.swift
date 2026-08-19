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

    public struct Hello: Codable, Equatable, Sendable {
        public var version: Int = MatchProtocolVersion.current
        public var playerID: String
        public var name: String
        public var rating: Int
        public var games: Int

        public init(playerID: String, name: String, rating: Int, games: Int) {
            self.playerID = playerID
            self.name = name
            self.rating = rating
            self.games = games
        }
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

        public init(uci: String, ply: Int, remaining: TimeInterval) {
            self.uci = uci
            self.ply = ply
            self.remaining = remaining
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

/// Standard Elo, with K falling as a player's record settles.
///
/// The same numbers on both devices, computed from the ratings the two sides
/// exchanged in `hello`. There is no server to be the judge here, so this is
/// honest rather than tamper-proof: it measures you against the people you
/// actually play, and a modified build could lie to it.
public enum OnlineElo {
    public static let starting = 1200
    public static let range = 100...3000

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
        return min(max(Int(next.rounded()), range.lowerBound), range.upperBound)
    }
}
