import ChessCore
import Foundation

/// What every legal move in a position is worth.
public struct MoveValues: Sendable {
    /// Score after each move, in centipawns from the *mover's* point of view.
    public let byMove: [String: Int]
    /// The best score available, for measuring everything else against.
    public let best: Int

    public init(byMove: [String: Int], best: Int) {
        self.byMove = byMove
        self.best = best
    }

    /// Centipawns given up by playing this move instead of the best one.
    public func loss(for uci: String) -> Int? {
        byMove[uci].map { max(0, best - $0) }
    }

    public func score(for uci: String) -> Int? { byMove[uci] }
}

extension StockfishEngine {
    /// Evaluate every legal move at once.
    ///
    /// One search with MultiPV set to the number of legal moves, rather than a
    /// separate search per move. A queen in an open position has around thirty
    /// moves; thirty searches would take seconds and drain the battery, while a
    /// single wide search shares its whole tree between them.
    ///
    /// Wide MultiPV does weaken pruning, so this deliberately runs shallower
    /// than an analysis search: the aim is to rank moves, not to find the truth
    /// about the position.
    public func valueEveryMove(
        fen: String,
        depth: Int = 10,
        movetimeMs: Int = 900
    ) async throws -> MoveValues {
        guard let position = Position(fen: fen) else {
            throw EngineError.invalidPosition(fen)
        }
        let legal = position.legalMoves()
        guard !legal.isEmpty else { return MoveValues(byMove: [:], best: 0) }

        let analysis = try await analyse(
            fen: fen, depth: depth, movetimeMs: movetimeMs, multiPV: legal.count
        )

        var byMove: [String: Int] = [:]
        for line in analysis.lines {
            guard let move = line.bestMove else { continue }
            byMove[move] = line.score.comparable
        }

        // Stockfish reports scores for the side to move, which is the mover —
        // no conversion needed here, unlike scores taken *after* a move.
        let best = byMove.values.max() ?? 0
        return MoveValues(byMove: byMove, best: best)
    }
}
