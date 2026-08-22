import CReckless
import Foundation

/// Reckless, driven in-process.
///
/// Deliberately `StockfishEngine.swift` with the symbols changed. The C surface
/// in `Vendor/Reckless/bridge/include/reckless.h` was shaped to make that
/// possible, so that the two engines share one concurrency design rather than
/// each inventing its own. The two comments below are the ones that matter, and
/// they are the originals: both hazards belong to driving a UCI engine
/// in-process, not to Stockfish.
public actor RecklessEngine: Engine {
    /// The C handle, wrapped so it can be released from a nonisolated deinit.
    /// OpaquePointer is not Sendable, and an actor's deinit is not isolated.
    private final class Handle: @unchecked Sendable {
        let pointer: OpaquePointer

        init(_ pointer: OpaquePointer) { self.pointer = pointer }

        deinit { rk_destroy(pointer) }
    }

    private let handleBox: Handle
    private var handle: OpaquePointer { handleBox.pointer }

    /// One search at a time — enforced, not assumed.
    ///
    /// Being an actor serialises *calls*, which is not the same as serialising
    /// searches. `analyse` suspends at the continuation it waits for its results
    /// on, and an actor lets the next call in while it is suspended. So a second
    /// search would start while the first was still running: it overwrote the
    /// callback context the C side holds, so the first search's results were
    /// delivered to the second search's session, and the first call's
    /// continuation was left parked with nothing that would ever resume it.
    private var searching = false
    private var queue: [CheckedContinuation<Void, Never>] = []

    private func beginSearch() async {
        while searching {
            await withCheckedContinuation { queue.append($0) }
        }
        searching = true
    }

    private func endSearch() {
        searching = false
        if !queue.isEmpty { queue.removeFirst().resume() }
    }

    /// Collects one search's output. Lives across the C callback boundary, so it
    /// is a reference type reached through an opaque pointer.
    private final class Session: @unchecked Sendable {
        private let lock = NSLock()
        private var lines: [Int: EngineLine] = [:]
        private var bestMove: String?
        private var continuation: CheckedContinuation<Void, Never>?
        private var finished = false

        private func withLock<T>(_ body: () -> T) -> T {
            lock.lock()
            defer { lock.unlock() }
            return body()
        }

        func record(_ line: EngineLine) {
            withLock { lines[line.rank] = line }
        }

        func setBestMove(_ move: String?) {
            withLock { bestMove = move }
        }

        var results: (lines: [EngineLine], bestMove: String?) {
            withLock { (lines.values.sorted { $0.rank < $1.rank }, bestMove) }
        }

        /// Returns false if the search already finished, so the caller resumes
        /// immediately instead of waiting for a callback that has been and gone.
        func park(_ continuation: CheckedContinuation<Void, Never>) -> Bool {
            withLock {
                guard !finished else { return false }
                self.continuation = continuation
                return true
            }
        }

        func finish() {
            let waiting: CheckedContinuation<Void, Never>? = withLock {
                finished = true
                defer { continuation = nil }
                return continuation
            }
            waiting?.resume()
        }
    }

    private var session: Session?

    public init() {
        rk_global_init()
        guard let created = rk_create() else {
            fatalError("Reckless could not be created")
        }
        handleBox = Handle(created)
    }

    /// No loadNetworks: Reckless's network is compiled into the binary, so
    /// there is no file to find and no failure to report. `init` is
    /// correspondingly infallible where `StockfishEngine` needs a second step.
    public static var engineDescription: String {
        String(cString: rk_engine_info())
    }

    /// Reckless has no strength limiter. See `EngineCapabilities` for what the
    /// app does about that and why it does not do the other thing.
    public nonisolated let capabilities = EngineCapabilities(
        name: RecklessEngine.engineDescription, limitsStrength: false
    )

    public func setOption(_ name: String, _ value: String) {
        name.withCString { namePointer in
            value.withCString { valuePointer in
                rk_set_option(handle, namePointer, valuePointer)
            }
        }
    }

    public func newGame() {
        rk_new_game(handle)
    }

    public func analyse(
        fen: String,
        depth: Int = 14,
        movetimeMs: Int = 0,
        multiPV: Int = 1
    ) async throws -> Analysis {
        await beginSearch()
        defer { endSearch() }

        setOption("MultiPV", String(multiPV))

        guard fen.withCString({ rk_set_position(handle, $0) }) else {
            throw EngineError.invalidPosition(fen)
        }

        let session = Session()
        self.session = session

        // A search that overruns its budget is stopped. The engine honours its
        // own limits and this should never fire — but a player staring at a
        // board has no way to tell a long think from a hang.
        let watchdog = Task { [ceiling = Self.ceilingMs(for: movetimeMs)] in
            try await Task.sleep(for: .milliseconds(ceiling))
            self.stop()
        }
        defer { watchdog.cancel() }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            guard session.park(continuation) else {
                continuation.resume()
                return
            }

            let context = Unmanaged.passUnretained(session).toOpaque()
            rk_go(handle, Int32(depth), Int32(movetimeMs), context,
                  { context, info in
                      guard let context, let info = info?.pointee else { return }
                      let session = Unmanaged<Session>.fromOpaque(context).takeUnretainedValue()
                      let score: EngineScore = info.isMate
                          ? .mate(Int(info.scoreMate))
                          : .centipawns(Int(info.scoreCp))
                      let pv = info.pv.map { String(cString: $0) } ?? ""

                      // A position with no legal moves is still reported, as
                      // `info depth 0 score mate 0` with no variation after it.
                      // That is not a line — there is no move in it — and
                      // recording it would leave `Analysis.isTerminal` false for
                      // a finished game, which is the flag every screen uses to
                      // tell checkmate from a search that simply has not
                      // answered yet. Stockfish reaches the same place by
                      // reporting these through a separate callback the bridge
                      // ignores.
                      guard !pv.isEmpty else { return }

                      let line = EngineLine(
                          rank: Int(info.multiPV),
                          depth: Int(info.depth),
                          score: score,
                          moves: pv.split(separator: " ").map(String.init)
                      )
                      session.record(line)
                  },
                  { context, best, _ in
                      guard let context else { return }
                      let session = Unmanaged<Session>.fromOpaque(context).takeUnretainedValue()
                      if let best {
                          let move = String(cString: best)
                          session.setBestMove((move == "(none)" || move.isEmpty) ? nil : move)
                      }
                      session.finish()
                  })
        }

        self.session = nil
        let results = session.results
        return Analysis(lines: results.lines, bestMove: results.bestMove)
    }

    /// Play a move.
    ///
    /// `elo` is accepted and ignored, which is the whole of what this engine can
    /// honestly say about strength — and is why `capabilities.limitsStrength` is
    /// false, so the settings never offer a rating this method would have to
    /// pretend to hit. Ignoring it beats the alternatives: a shallower search
    /// would produce a strong positional player with sudden tactical blindness,
    /// which is not what "1400" means to anybody.
    public func chooseMove(
        fen: String,
        elo: Int? = nil,
        depth: Int = 12,
        movetimeMs: Int = 0
    ) async throws -> String? {
        try await analyse(fen: fen, depth: depth, movetimeMs: movetimeMs, multiPV: 1).bestMove
    }

    public nonisolated func stop() {
        rk_stop(handleBox.pointer)
    }

    static let hardCeilingMs = 10_000

    private static func ceilingMs(for movetimeMs: Int) -> Int {
        guard movetimeMs > 0 else { return hardCeilingMs }
        return min(movetimeMs + 1_500, hardCeilingMs)
    }
}
