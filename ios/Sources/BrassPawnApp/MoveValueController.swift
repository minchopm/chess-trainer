import ChessCore
import ChessEngine
import Foundation
import Observation

/// Computes and holds per-move values for the position on screen.
///
/// Deliberately opt-in rather than always on. In a tactics puzzle the values
/// *are* the answer, so switching them on has to be as conscious an act as
/// asking for a hint — and it is treated as one when the attempt is scored.
@MainActor
@Observable
final class MoveValueController {
    private(set) var isComputing = false
    private(set) var isEnabled = false

    /// What was computed, and the position it was computed for. Values from an
    /// earlier move would be worse than none at all.
    private var computed: MoveValues?
    private var computedFEN: String?

    /// The values to draw, which is nothing at all unless they are switched on.
    ///
    /// One property rather than two, because two let the board show values the
    /// switch says are off — and it did. Switching off left the last set behind
    /// for the board to go on drawing, and they survived a move as well: they
    /// were only dropped where a screen remembered to say so, and the move the
    /// *opponent* plays goes through none of those places.
    var values: MoveValues? { isEnabled ? computed : nil }

    func reset() {
        computed = nil
        computedFEN = nil
        isEnabled = false
    }

    /// Drop values that no longer match the position on the board.
    func invalidate(unless fen: String) {
        if computedFEN != fen {
            computed = nil
            computedFEN = nil
        }
    }

    func toggle(fen: String, engine: StockfishEngine) async {
        if isEnabled {
            isEnabled = false
            computed = nil
            computedFEN = nil
            return
        }
        isEnabled = true
        await refresh(fen: fen, engine: engine)
    }

    func refresh(fen: String, engine: StockfishEngine) async {
        guard isEnabled, !isComputing, computedFEN != fen else { return }
        isComputing = true
        defer { isComputing = false }

        if let result = try? await engine.valueEveryMove(fen: fen) {
            computed = result
            computedFEN = fen
        }
    }
}
