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
    /// False until the data files have been read. Screens need it to tell "no
    /// puzzles in this build" from "the puzzles have not arrived yet", which
    /// look identical from an empty array.
    public private(set) var isLibraryLoaded = false
    public private(set) var progress = TrainingProgress()
    public private(set) var engineState: EngineState = .starting

    public enum EngineState: Equatable {
        case starting
        case ready
        case failed(String)
    }

    public let engine = StockfishEngine()
    /// What has been bought. Held here so every screen asks the same object
    /// rather than each keeping its own idea of whether the training is paid
    /// for.
    public let store = SubscriptionStore()
    /// Game Center identity and matchmaking for online play.
    public let matchmaker = GameCenterMatchmaker()
    private let storage: ProgressStorage

    public init(storage: ProgressStorage = .documents()) {
        self.storage = storage
        progress = storage.load() ?? TrainingProgress()
    }

    /// Claim one allowance unit. Most modes call this on the first answer or
    /// explicit run start; Tactics calls it on completion because its free unit
    /// is a completed puzzle rather than an attempt. Loading and browsing never
    /// count. Paid accounts are always admitted and accumulate no free usage.
    @discardableResult
    public func beginAttempt(_ activity: TrainingActivity, at now: Date = Date()) -> Bool {
        guard hasAllowance(for: activity, at: now) else { return false }
        consume(activity, at: now)
        return true
    }

    /// Whether this activity may be attempted right now: paid accounts always,
    /// free accounts until the day's allowance is gone.
    public func hasAllowance(for activity: TrainingActivity, at now: Date = Date()) -> Bool {
        store.isPro || progress.freeRemaining(activity, at: now) > 0
    }

    /// Practice skips have their own daily allowance. They neither spend the
    /// completed-puzzle allowance nor the separate Rush attempt.
    @discardableResult
    public func useTacticsSkip(at now: Date = Date()) -> Bool {
        guard store.isPro || progress.freeTacticsSkipsRemaining(at: now) > 0 else { return false }
        guard !store.isPro else { return true }
        update { $0.recordFreeTacticsSkip(at: now) }
        return true
    }

    /// Count one use against the free allowance. A paid account spends nothing,
    /// so nothing is counted for it and the numbers stay meaningful if a
    /// subscription later lapses.
    private func consume(_ activity: TrainingActivity, at now: Date) {
        guard !store.isPro else { return }
        update { $0.recordFreeUse(of: activity, at: now) }
    }

    public func start() async {
        // Off the main actor: the library is a few megabytes of JSON, and
        // decoding it where the UI runs is the difference between the first
        // screen appearing at once and appearing after a blank pause.
        let resources = Bundle.main.resourceURL ?? URL(fileURLWithPath: ".")
        library = await Task.detached(priority: .userInitiated) {
            (try? ContentLibrary.load(from: resources)) ?? ContentLibrary()
        }.value
        isLibraryLoaded = true

        // The big network is the one over 50 MB; the small one is a few MB.
        // Sizes rather than names, because the names are pinned to the engine
        // version and change with every Stockfish release.
        guard let big = networkURL(matching: { $0 > 50_000_000 }),
              let small = networkURL(matching: { $0 < 50_000_000 })
        else {
            engineState = .failed("The engine networks are missing from the app bundle.")
            return
        }

        await store.prepare()

        do {
            try await engine.loadNetworks(big: big, small: small)

            // Search on several cores, but not on all of them. Two are left for
            // the app itself — a search that starves the UI thread makes the
            // board feel broken, which costs more than the extra depth buys —
            // and the cap keeps a long analysis from cooking the phone.
            let cores = ProcessInfo.processInfo.activeProcessorCount
            await engine.setOption("Threads", String(max(1, min(4, cores - 2))))
            await engine.setOption("Hash", "128")
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
