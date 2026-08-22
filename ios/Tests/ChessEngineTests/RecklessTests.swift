import ChessCore
import Foundation
import Testing
@testable import ChessEngine

/// Reckless needs no network files — its network is compiled into the library —
/// so unlike the Stockfish suite these never skip.
///
/// Serialised for the same reason: each engine holds a transposition table and a
/// thread pool, and six at once is not a useful thing to measure.
@Suite(.serialized)
struct RecklessTests {
    static func makeEngine() async -> RecklessEngine {
        let engine = RecklessEngine()
        await engine.setOption("Threads", "1")
        await engine.setOption("Hash", "64")
        return engine
    }

    @Test("The engine reports itself")
    func engineInfo() {
        #expect(RecklessEngine.engineDescription.contains("Reckless"))
    }

    @Test("It finds mate in one")
    func findsMate() async throws {
        let engine = await Self.makeEngine()
        let analysis = try await engine.analyse(
            fen: "6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1", depth: 12
        )
        #expect(analysis.bestMove == "a1a8")
        if case .mate(let moves) = analysis.score {
            #expect(moves == 1)
        } else {
            Issue.record("expected a mate score, got \(String(describing: analysis.score))")
        }
    }

    @Test("It wins the hanging queen")
    func winsMaterial() async throws {
        let engine = await Self.makeEngine()
        let analysis = try await engine.analyse(
            fen: "4k3/8/8/8/3q4/8/8/3RK3 w - - 0 1", depth: 14
        )
        #expect(analysis.bestMove == "d1d4")
    }

    @Test("MultiPV returns several ranked lines")
    func multiPV() async throws {
        let engine = await Self.makeEngine()
        let analysis = try await engine.analyse(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            depth: 12, multiPV: 3
        )
        #expect(analysis.lines.count == 3)
        #expect(analysis.lines.map(\.rank) == [1, 2, 3])
        let scores = analysis.lines.map(\.score.comparable)
        #expect(scores == scores.sorted(by: >))
    }

    @Test("A terminal position yields no lines rather than crashing")
    func terminalPosition() async throws {
        let engine = await Self.makeEngine()
        let analysis = try await engine.analyse(fen: "7k/5KQ1/8/8/8/8/8/8 b - - 0 1", depth: 8)
        #expect(analysis.isTerminal)
        #expect(analysis.bestMove == nil)
    }

    @Test("Repeated searches on one engine stay stable")
    func repeatedSearches() async throws {
        let engine = await Self.makeEngine()
        for _ in 0..<8 {
            let analysis = try await engine.analyse(
                fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
                depth: 10, multiPV: 2
            )
            #expect(analysis.bestMove != nil)
        }
    }

    /// An invalid FEN is refused rather than silently searched.
    ///
    /// The engine's own wasm binding answers an unparseable FEN with the
    /// starting position; the C bridge deliberately does not, because a wrong
    /// answer to a question nobody asked is the harder bug to find.
    @Test("A nonsense position is rejected")
    func rejectsBadFEN() async throws {
        let engine = await Self.makeEngine()
        await #expect(throws: EngineError.self) {
            _ = try await engine.analyse(fen: "not a fen", depth: 4)
        }
    }
}
