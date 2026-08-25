import ChessCore
import Foundation

extension Engine {
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

        // UCI reports scores for the side to move, which is the mover — no
        // conversion needed here, unlike scores taken *after* a move.
        let best = byMove.values.max() ?? 0
        return MoveValues(byMove: byMove, best: best)
    }
}
