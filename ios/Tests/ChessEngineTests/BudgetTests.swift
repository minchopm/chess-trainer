import ChessEngine
import Foundation
import Testing

@Suite("Search budgets")
struct BudgetTests {
    /// The position that made this bug obvious: a sharp middlegame where depth
    /// alone takes minutes. Asked for by depth with no time limit, the engine
    /// would think for as long as it liked, and the app looked hung.
    private let sharp = "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQK2R w KQkq - 0 1"

    @Test("Full strength answers inside its budget")
    func fullStrengthIsBounded() async throws {
        guard let engine = try await StockfishTests.makeEngine() else { return }

        let started = Date()
        let move = try await engine.chooseMove(
            fen: sharp,
            depth: SearchBudget.fullStrength.depth,
            movetimeMs: SearchBudget.fullStrength.movetimeMs
        )
        let elapsed = Date().timeIntervalSince(started)

        #expect(move != nil)
        // Generous against the budget itself: the engine finishes the iteration
        // it is in, and a loaded machine adds its own delay. What is being
        // checked is that there is a ceiling at all.
        #expect(elapsed < 8, "full-strength search took \(String(format: "%.1f", elapsed))s")
    }

    @Test("Coaching stays quick enough to run after every move")
    func coachingIsBounded() async throws {
        guard let engine = try await StockfishTests.makeEngine() else { return }

        let started = Date()
        _ = try await engine.analyse(
            fen: sharp,
            depth: SearchBudget.coaching.depth,
            movetimeMs: SearchBudget.coaching.movetimeMs,
            multiPV: 2
        )
        let elapsed = Date().timeIntervalSince(started)

        #expect(elapsed < 4, "coaching search took \(String(format: "%.1f", elapsed))s")
    }
}
