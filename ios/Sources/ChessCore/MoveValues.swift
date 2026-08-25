import Foundation

/// What every legal move in a position is worth.
///
/// Here rather than beside the engine that produces it. The board draws these
/// numbers on its squares, and the board has no business linking a chess
/// engine — an App Clip showing a position would have had to carry a hundred
/// megabytes of neural network to draw a label.
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
