import Foundation
import Testing
@testable import ChessEngine

/// These run against the real engine and the real networks, so they need
/// `ios/scripts/fetch-networks.sh` to have been run.
///
/// Serialised deliberately: each engine holds a 104 MB network, and letting the
/// test runner start six of them at once exhausts memory and kills the process
/// without reporting a failure.
@Suite(.serialized)
struct StockfishTests {
    static func networkURLs() -> (big: URL, small: URL)? {
        // Tests run from .build, so walk up to the package root.
        var directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // ChessEngineTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // package root
        directory.appendPathComponent("Resources/Networks")

        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
            return nil
        }
        let nets = files.filter { $0.hasSuffix(".nnue") }
        guard nets.count == 2 else { return nil }

        // The big network is the larger file; names change between releases.
        let sorted = nets.sorted { first, second in
            let sizeOf: (String) -> Int = { name in
                let path = directory.appendingPathComponent(name).path
                let attributes = try? FileManager.default.attributesOfItem(atPath: path)
                return (attributes?[.size] as? Int) ?? 0
            }
            return sizeOf(first) > sizeOf(second)
        }
        return (directory.appendingPathComponent(sorted[0]),
                directory.appendingPathComponent(sorted[1]))
    }

    static func makeEngine() async throws -> StockfishEngine? {
        guard let urls = networkURLs() else { return nil }
        let engine = StockfishEngine()
        try await engine.loadNetworks(big: urls.big, small: urls.small)
        await engine.setOption("Threads", "1")
        await engine.setOption("Hash", "64")
        return engine
    }

    @Test("The engine reports itself")
    func engineInfo() {
        #expect(StockfishEngine.engineDescription.contains("Stockfish"))
    }

    @Test("It finds mate in one")
    func findsMate() async throws {
        guard let engine = try await Self.makeEngine() else { return }
        // Back-rank mate: Ra8#.
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
        guard let engine = try await Self.makeEngine() else { return }
        // Black's queen on d4 is simply attacked by the rook on d1.
        let analysis = try await engine.analyse(
            fen: "4k3/8/8/8/3q4/8/8/3RK3 w - - 0 1", depth: 14
        )
        #expect(analysis.bestMove == "d1d4")
    }

    @Test("MultiPV returns several ranked lines")
    func multiPV() async throws {
        guard let engine = try await Self.makeEngine() else { return }
        let analysis = try await engine.analyse(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            depth: 12, multiPV: 3
        )
        #expect(analysis.lines.count == 3)
        #expect(analysis.lines.map(\.rank) == [1, 2, 3])
        // Ranked best first, from the mover's point of view.
        let scores = analysis.lines.map(\.score.comparable)
        #expect(scores == scores.sorted(by: >))
    }

    @Test("A terminal position yields no lines rather than crashing")
    func terminalPosition() async throws {
        guard let engine = try await Self.makeEngine() else { return }
        // Already checkmated: no legal moves.
        let analysis = try await engine.analyse(fen: "7k/5KQ1/8/8/8/8/8/8 b - - 0 1", depth: 8)
        #expect(analysis.isTerminal)
        #expect(analysis.bestMove == nil)
    }

    @Test("Strength limiting changes how it plays")
    func limitedStrength() async throws {
        guard let engine = try await Self.makeEngine() else { return }
        let move = try await engine.chooseMove(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            elo: 1400, movetimeMs: 200
        )
        #expect(move != nil)
        #expect(move?.count == 4)
    }

    @Test("Repeated searches on one engine stay stable")
    func repeatedSearches() async throws {
        guard let engine = try await Self.makeEngine() else { return }
        // The web version died here: a new position sent while the previous
        // search was still unwinding took the engine down.
        for _ in 0..<8 {
            let analysis = try await engine.analyse(
                fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
                depth: 10, multiPV: 2
            )
            #expect(analysis.bestMove != nil)
            _ = try await engine.chooseMove(
                fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
                elo: 1800, movetimeMs: 100
            )
        }
    }
}
