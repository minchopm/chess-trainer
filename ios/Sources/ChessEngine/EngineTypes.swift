import Foundation

/// An evaluation, always from the point of view of the side to move.
public enum EngineScore: Equatable, Sendable {
    case centipawns(Int)
    case mate(Int)

    /// Flip to the given colour's point of view. UCI always reports from the
    /// side to move, which is the wrong frame for anything the user reads.
    public func pointOfView(sideToMove: Bool) -> EngineScore {
        guard !sideToMove else { return self }
        switch self {
        case .centipawns(let cp): return .centipawns(-cp)
        case .mate(let moves): return .mate(-moves)
        }
    }

    /// Centipawns with mate flattened to a large value, for comparing moves.
    public var comparable: Int {
        switch self {
        case .centipawns(let cp): cp
        case .mate(let moves): moves > 0 ? 10_000 - moves : -10_000 - moves
        }
    }

    /// Probability that the side this score favours goes on to win.
    /// The logistic fit Lichess uses, which is a far better basis for judging a
    /// move than raw centipawns: throwing away 100cp when already a queen up
    /// barely matters, and in a level position it decides the game.
    public var winProbability: Double {
        let clamped = Double(max(-1000, min(1000, comparable)))
        return 1 / (1 + exp(-0.00368208 * clamped))
    }

    public var text: String {
        switch self {
        case .mate(let moves):
            return "#\(moves)"
        case .centipawns(let cp):
            let pawns = Double(cp) / 100
            return (pawns >= 0 ? "+" : "−") + String(format: "%.2f", abs(pawns))
        }
    }
}

/// One principal variation from a search.
public struct EngineLine: Equatable, Sendable {
    public let rank: Int          // 1-based; MultiPV order
    public let depth: Int
    public let score: EngineScore
    public let moves: [String]    // UCI

    public var bestMove: String? { moves.first }
}

public struct Analysis: Equatable, Sendable {
    public let lines: [EngineLine]
    public let bestMove: String?

    /// True when the position has no legal moves, so nothing was searched.
    public var isTerminal: Bool { lines.isEmpty }

    public var score: EngineScore? { lines.first?.score }
}

public enum EngineError: Error, LocalizedError {
    case networksMissing(String)
    case invalidPosition(String)

    public var errorDescription: String? {
        switch self {
        case .networksMissing(let path):
            "The Stockfish neural network could not be read at \(path)."
        case .invalidPosition(let fen):
            "The engine rejected this position: \(fen)"
        }
    }
}
