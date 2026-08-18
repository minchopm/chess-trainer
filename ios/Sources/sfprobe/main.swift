import ChessEngine
import Foundation

// A tiny driver for the engine, used to diagnose failures that a test harness
// swallows: when Stockfish calls exit(), the test process simply vanishes.
let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let networks = root.appendingPathComponent("Resources/Networks")

print("engine: \(StockfishEngine.engineDescription)")
print("networks directory: \(networks.path)")

let files = (try? FileManager.default.contentsOfDirectory(atPath: networks.path))?
    .filter { $0.hasSuffix(".nnue") } ?? []
print("networks found: \(files)")
guard files.count == 2 else {
    print("expected two networks; run scripts/fetch-networks.sh")
    exit(1)
}

func size(_ name: String) -> Int {
    let path = networks.appendingPathComponent(name).path
    return ((try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? Int) ?? 0
}
let sorted = files.sorted { size($0) > size($1) }
let big = networks.appendingPathComponent(sorted[0])
let small = networks.appendingPathComponent(sorted[1])
print("big:   \(sorted[0]) (\(size(sorted[0]) / 1_048_576) MB)")
print("small: \(sorted[1]) (\(size(sorted[1]) / 1_048_576) MB)")

let engine = StockfishEngine()
print("engine created")

do {
    try await engine.loadNetworks(big: big, small: small)
    print("networks loaded")
} catch {
    print("load failed: \(error)")
    exit(1)
}

await engine.setOption("Threads", "1")
await engine.setOption("Hash", "64")
print("options set")

let fen = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1"
print("searching \(fen)")
let analysis = try await engine.analyse(fen: fen, depth: 12, multiPV: 1)
print("lines: \(analysis.lines.count)")
for line in analysis.lines {
    print("  rank \(line.rank) depth \(line.depth) score \(line.score.text) pv \(line.moves.prefix(4).joined(separator: " "))")
}
print("bestmove: \(analysis.bestMove ?? "(none)")")
