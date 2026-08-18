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
    private(set) var values: MoveValues?
    private(set) var isComputing = false
    private(set) var isEnabled = false

    /// The position the current values belong to. Values from an earlier move
    /// would be worse than none at all.
    private var computedFEN: String?

    var isStale: Bool { values != nil && computedFEN != nil }

    func reset() {
        values = nil
        computedFEN = nil
        isEnabled = false
    }

    /// Drop values that no longer match the position on the board.
    func invalidate(unless fen: String) {
        if computedFEN != fen {
            values = nil
            computedFEN = nil
        }
    }

    func toggle(fen: String, engine: StockfishEngine) async {
        if isEnabled {
            isEnabled = false
            return
        }
        isEnabled = true
        await refresh(fen: fen, engine: engine)
    }

    func refresh(fen: String, engine: StockfishEngine) async {
        guard isEnabled, !isComputing, computedFEN != fen else { return }
        isComputing = true
        defer { isComputing = false }

        if let computed = try? await engine.valueEveryMove(fen: fen) {
            values = computed
            computedFEN = fen
        }
    }
}
