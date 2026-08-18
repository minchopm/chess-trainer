import ChessCore
import ChessEngine
import ChessTraining
import Foundation
import Observation

/// Shared state: the engine, the content library and your progress.
///
/// One engine for the whole app. Stockfish holds a 104 MB network and a thread
/// pool; a second instance would double both for no benefit, since only one
/// search can usefully run on a phone at a time.
@MainActor
@Observable
public final class AppModel {
    public private(set) var library = ContentLibrary()
    public private(set) var progress = TrainingProgress()
    public private(set) var engineState: EngineState = .starting

    public enum EngineState: Equatable {
        case starting
        case ready
        case failed(String)
    }

    public let engine = StockfishEngine()
    private let storage: ProgressStorage

    public init(storage: ProgressStorage = .documents()) {
        self.storage = storage
        progress = storage.load() ?? TrainingProgress()
    }

    public func start() async {
        library = (try? ContentLibrary.load(from: Bundle.main.resourceURL ?? URL(fileURLWithPath: ".")))
            ?? ContentLibrary()

        // The big network is the one over 50 MB; the small one is a few MB.
        // Sizes rather than names, because the names are pinned to the engine
        // version and change with every Stockfish release.
        guard let big = networkURL(matching: { $0 > 50_000_000 }),
              let small = networkURL(matching: { $0 < 50_000_000 })
        else {
            engineState = .failed("The engine networks are missing from the app bundle.")
            return
        }

        do {
            try await engine.loadNetworks(big: big, small: small)
            await engine.setOption("Threads", "1")
            await engine.setOption("Hash", "64")
            engineState = .ready
        } catch {
            engineState = .failed(error.localizedDescription)
        }
    }

    /// Networks are found by size rather than name: the file names are pinned to
    /// the Stockfish version and change whenever it is updated.
    private func networkURL(matching predicate: (Int) -> Bool) -> URL? {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "nnue", subdirectory: nil) else {
            return nil
        }
        return urls.first { url in
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? Int
            return predicate(size ?? 0)
        }
    }

    public func update(_ mutate: (inout TrainingProgress) -> Void) {
        mutate(&progress)
        storage.save(progress)
    }

    public func resetProgress() {
        progress = TrainingProgress()
        storage.save(progress)
    }
}

/// Progress on disk. A single JSON file rather than UserDefaults: the history
/// grows past what defaults are meant for, and a file is trivial to inspect,
/// back up or delete.
public struct ProgressStorage: Sendable {
    let url: URL

    public static func documents() -> ProgressStorage {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return ProgressStorage(url: directory.appendingPathComponent("progress.json"))
    }

    public func load() -> TrainingProgress? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TrainingProgress.self, from: data)
    }

    public func save(_ progress: TrainingProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
