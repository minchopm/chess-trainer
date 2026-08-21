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

    /// Only this value is handed to a board. A completed engine request may be
    /// retained as a cache while hidden, but it must never make the overlay
    /// visible again by itself.
    var displayedValues: MoveValues? { isEnabled ? values : nil }

    /// The position the current values belong to. Values from an earlier move
    /// would be worse than none at all.
    private var computedFEN: String?
    private var currentFEN: String?
    /// Invalidates engine responses that finish after reset or a board change.
    private var positionRevision = 0

    func reset() {
        positionRevision &+= 1
        values = nil
        computedFEN = nil
        currentFEN = nil
        isComputing = false
        isEnabled = false
    }

    /// Drop values that no longer match the position on the board.
    func invalidate(unless fen: String) {
        adopt(fen: fen)
    }

    /// Toggle visibility synchronously. Starting an engine request is detached
    /// from the button action so a second tap can hide the overlay immediately.
    func toggle(fen: String, engine: StockfishEngine) {
        adopt(fen: fen)

        if isEnabled {
            isEnabled = false
            return
        }

        isEnabled = true
        Task { [weak self] in
            await self?.refresh(fen: fen, engine: engine)
        }
    }

    func refresh(fen: String, engine: StockfishEngine) async {
        adopt(fen: fen)
        guard isEnabled, !isComputing, computedFEN != fen else { return }

        let revision = positionRevision
        isComputing = true
        defer {
            if positionRevision == revision { isComputing = false }
        }

        if let computed = try? await engine.valueEveryMove(fen: fen) {
            guard positionRevision == revision, currentFEN == fen else { return }
            values = computed
            computedFEN = fen
        }
    }

    private func adopt(fen: String) {
        guard currentFEN != fen else { return }
        positionRevision &+= 1
        currentFEN = fen
        values = nil
        computedFEN = nil
        isComputing = false
    }
}
