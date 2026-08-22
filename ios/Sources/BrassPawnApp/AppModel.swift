import ChessCore
import ChessEngine
import ChessTraining
import Foundation
import Observation

/// Shared state: the engine, the content library and your progress.
///
/// One engine for the whole app, and only one at a time. Stockfish holds a
/// 104 MB network and a thread pool; a second instance would double both for no
/// benefit, since only one search can usefully run on a phone at a time. That
/// applies across engines too — switching builds the new one and lets the old
/// one go, rather than keeping both resident so the change is instant.
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

    /// Whichever engine the player chose. Replaced by `useEngine`, so screens
    /// must read it at the moment they search rather than capturing it once.
    ///
    /// Stands as a Stockfish until `start` reads the saved preference and builds
    /// the real one. A placeholder rather than an optional because every screen
    /// would otherwise have to unwrap it, and it is no less usable than the
    /// engine used to be at this point: networks are not loaded yet either way,
    /// so a search throws until `engineState` becomes `.ready`, which is what
    /// the screens already wait for.
    public private(set) var engine: any Engine = StockfishEngine()
    /// What `engine` currently is, so the settings can show the choice without
    /// asking the actor.
    public private(set) var engineChoice: EngineChoice = .stockfish
    /// The running engine's own account of itself, version and all.
    public var engineDescription: String { engine.capabilities.name }
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

        networks = (big: big, small: small)
        await useEngine(progress.appearance.engine)
    }

    /// Where the Stockfish networks were found, kept so the engine can be built
    /// again if the player switches back to it.
    private var networks: (big: URL, small: URL)?

    /// Build the chosen engine and make it the one the app searches with.
    ///
    /// The old engine is stopped before it is released. Releasing it alone would
    /// eventually do the same — both actors destroy their C handle in `deinit`,
    /// and both bridges stop and join the search first — but "eventually" here
    /// means whenever the last in-flight search lets go of the actor, and there
    /// is no reason to leave a search running for a position nobody will be
    /// shown.
    public func useEngine(_ choice: EngineChoice) async {
        let previous = engine
        engineState = .starting

        switch choice {
        case .stockfish:
            guard let networks else {
                engineState = .failed("The engine networks are missing from the app bundle.")
                return
            }
            let stockfish = StockfishEngine()
            do {
                try await stockfish.loadNetworks(big: networks.big, small: networks.small)
            } catch {
                engineState = .failed(error.localizedDescription)
                return
            }
            engine = stockfish
        case .reckless:
            // No networks to load: Reckless's is compiled into the binary.
            engine = RecklessEngine()
        }

        // Unconditionally: `engine` has just been replaced by a new object, so
        // `previous` is always the one being let go, whatever it was. Stopping
        // an engine that is not searching does nothing.
        await previous.stop()
        engineChoice = choice

        // Search on several cores, but not on all of them. Two are left for
        // the app itself — a search that starves the UI thread makes the
        // board feel broken, which costs more than the extra depth buys —
        // and the cap keeps a long analysis from cooking the phone.
        let cores = ProcessInfo.processInfo.activeProcessorCount
        await engine.setOption("Threads", String(max(1, min(4, cores - 2))))
        await engine.setOption("Hash", "128")
        engineState = .ready
    }

    /// Record the choice and act on it. The settings call this rather than
    /// writing to `appearance` directly, so the two cannot disagree.
    public func chooseEngine(_ choice: EngineChoice) async {
        guard choice != engineChoice else { return }
        await useEngine(choice)
        // Saved only once it is true. Building an engine can fail — Stockfish
        // needs its networks off the bundle — and in that case the app is still
        // playing the previous one. Persisting the choice anyway would leave the
        // setting describing an engine that is not running, and would make the
        // next launch fail the same way with nothing said about it.
        guard engineChoice == choice else { return }
        update { $0.appearance.engine = choice }
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
