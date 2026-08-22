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

    /// The app asks the engine three things at once on every move — the reply,
    /// the grade for what was just played, and the verdict on the position —
    /// and all three have to come back.
    ///
    /// Being an actor serialises calls but not searches: `analyse` suspends
    /// while it waits for its results, and an actor admits the next caller
    /// while it is suspended. A second search starting there overwrites the
    /// callback context the C side holds, which would deliver the first
    /// search's results to the second search's session and leave the first
    /// caller parked on a continuation nothing resumes.
    ///
    /// This test does not reproduce that — three searches at once come back
    /// under a gate and, on this machine, without one. It holds the guarantee
    /// that matters rather than the mechanism: whatever the scheduler does with
    /// them, all three answer and none of them approaches the ceiling.
    @Test("Searches asked for at the same moment all come back")
    func overlappingSearchesFinish() async throws {
        guard let engine = try await StockfishTests.makeEngine() else { return }

        let started = Date()
        async let reply = engine.chooseMove(
            fen: sharp, depth: SearchBudget.fullStrength.depth,
            movetimeMs: SearchBudget.fullStrength.movetimeMs
        )
        async let grading = engine.analyse(
            fen: sharp, depth: SearchBudget.coaching.depth,
            movetimeMs: SearchBudget.coaching.movetimeMs, multiPV: 2
        )
        async let verdict = engine.analyse(
            fen: sharp, depth: SearchBudget.verdict.depth,
            movetimeMs: SearchBudget.verdict.movetimeMs, multiPV: 1
        )

        let move = try await reply
        let graded = try await grading
        let judged = try await verdict
        let elapsed = Date().timeIntervalSince(started)

        #expect(move != nil)
        #expect(graded.lines.isEmpty == false)
        #expect(judged.lines.isEmpty == false)
        // A parked continuation never resumes, so the real signal is that this
        // line is reached at all. The bound is a backstop, and a loose one on
        // purpose: this suite runs beside perft and the whole game library, and
        // on a machine with every core busy three searches with budgets summing
        // to four seconds have been seen to take eighteen. Tightening it would
        // measure the load rather than the gate.
        #expect(elapsed < 30, "three overlapping searches took \(String(format: "%.1f", elapsed))s")
    }

    /// The same guarantee, for the second engine.
    ///
    /// It has the same hazard for the same reason: `analyse` suspends at its
    /// continuation, the actor admits the next caller, and the C side holds one
    /// callback context. `RecklessEngine` inherits the gate along with the rest
    /// of `StockfishEngine`'s shape, and this is what says so.
    @Test("Reckless answers three searches asked for at once")
    func recklessOverlappingSearchesFinish() async throws {
        let engine = await RecklessTests.makeEngine()

        let started = Date()
        async let reply = engine.chooseMove(
            fen: sharp, elo: nil, depth: SearchBudget.fullStrength.depth,
            movetimeMs: SearchBudget.fullStrength.movetimeMs
        )
        async let grading = engine.analyse(
            fen: sharp, depth: SearchBudget.coaching.depth,
            movetimeMs: SearchBudget.coaching.movetimeMs, multiPV: 2
        )
        async let verdict = engine.analyse(
            fen: sharp, depth: SearchBudget.verdict.depth,
            movetimeMs: SearchBudget.verdict.movetimeMs, multiPV: 1
        )

        let move = try await reply
        let graded = try await grading
        let judged = try await verdict
        let elapsed = Date().timeIntervalSince(started)

        #expect(move != nil)
        #expect(graded.lines.isEmpty == false)
        #expect(judged.lines.isEmpty == false)
        #expect(elapsed < 30, "three overlapping searches took \(String(format: "%.1f", elapsed))s")
    }

    /// Both engines searching at once.
    ///
    /// The app holds one engine at a time, but switching in Settings builds the
    /// new one while a search on the old one may still be unwinding — so the two
    /// do briefly overlap, and they share nothing that would object. Each
    /// engine's gate is its own; neither knows about the other.
    @Test("Both engines can search at the same moment")
    func bothEnginesAtOnce() async throws {
        guard let stockfish = try await StockfishTests.makeEngine() else { return }
        let reckless = await RecklessTests.makeEngine()

        let started = Date()
        async let first = stockfish.analyse(
            fen: sharp, depth: SearchBudget.coaching.depth,
            movetimeMs: SearchBudget.coaching.movetimeMs, multiPV: 1
        )
        async let second = reckless.analyse(
            fen: sharp, depth: SearchBudget.coaching.depth,
            movetimeMs: SearchBudget.coaching.movetimeMs, multiPV: 1
        )

        let one = try await first
        let two = try await second
        let elapsed = Date().timeIntervalSince(started)

        #expect(one.bestMove != nil)
        #expect(two.bestMove != nil)
        #expect(elapsed < 30, "two engines took \(String(format: "%.1f", elapsed))s")
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
