import CStockfish
import Foundation

/// Stockfish, driven in-process.
///
/// An actor because a UCI engine holds exactly one position and one search:
/// serialising access is not an optimisation but a correctness requirement.
/// The web version learned this the hard way — sending a new position while a
/// search was still unwinding killed the engine outright.
public actor StockfishEngine {
    /// The C handle, wrapped so it can be released from a nonisolated deinit.
    /// OpaquePointer is not Sendable, and an actor's deinit is not isolated.
    private final class Handle: @unchecked Sendable {
        let pointer: OpaquePointer

        init(_ pointer: OpaquePointer) { self.pointer = pointer }

        deinit { sf_destroy(pointer) }
    }

    private let handleBox: Handle
    private var handle: OpaquePointer { handleBox.pointer }
    private var isReady = false

    /// Collects one search's output. Lives across the C callback boundary, so
    /// it is a reference type reached through an opaque pointer.
    private final class Session: @unchecked Sendable {
        private let lock = NSLock()
        private var lines: [Int: EngineLine] = [:]
        private var bestMove: String?
        private var continuation: CheckedContinuation<Void, Never>?
        private var finished = false

        /// Scoped locking. Swift 6 forbids bare lock/unlock across an await for
        /// good reason — a lock held over a suspension point is a deadlock
        /// waiting for the right scheduling.
        private func withLock<T>(_ body: () -> T) -> T {
            lock.lock()
            defer { lock.unlock() }
            return body()
        }

        func record(_ line: EngineLine) {
            // A deeper report for the same rank supersedes the earlier one.
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
        sf_global_init()
        guard let created = sf_create() else {
            fatalError("Stockfish could not be created")
        }
        handleBox = Handle(created)
    }

    public static var engineDescription: String {
        String(cString: sf_engine_info())
    }

    /// Point the engine at its two network files. Must succeed before searching.
    public func loadNetworks(big: URL, small: URL) throws {
        let ok = big.path.withCString { bigPath in
            small.path.withCString { smallPath in
                sf_load_networks(handle, bigPath, smallPath)
            }
        }
        guard ok else { throw EngineError.networksMissing(big.path) }
        isReady = true
    }

    public func setOption(_ name: String, _ value: String) {
        name.withCString { namePointer in
            value.withCString { valuePointer in
                sf_set_option(handle, namePointer, valuePointer)
            }
        }
    }

    public func newGame() {
        sf_new_game(handle)
    }

    /// Search a position.
    ///
    /// Giving both a depth and a time cap means "this deep, but never longer
    /// than this" — some positions take minutes to reach even a modest depth,
    /// and on a phone that is the difference between a coach and a hot battery.
    public func analyse(
        fen: String,
        depth: Int = 14,
        movetimeMs: Int = 0,
        multiPV: Int = 1
    ) async throws -> Analysis {
        guard isReady else { throw EngineError.networksMissing("networks not loaded") }

        setOption("MultiPV", String(multiPV))
        setOption("UCI_LimitStrength", "false")

        guard fen.withCString({ sf_set_position(handle, $0) }) else {
            throw EngineError.invalidPosition(fen)
        }

        let session = Session()
        self.session = session

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            guard session.park(continuation) else {
                continuation.resume()
                return
            }

            let context = Unmanaged.passUnretained(session).toOpaque()
            sf_go(handle, Int32(depth), Int32(movetimeMs), context,
                  { context, info in
                      guard let context, let info = info?.pointee else { return }
                      let session = Unmanaged<Session>.fromOpaque(context).takeUnretainedValue()
                      let score: EngineScore = info.isMate
                          ? .mate(Int(info.scoreMate))
                          : .centipawns(Int(info.scoreCp))
                      let pv = info.pv.map { String(cString: $0) } ?? ""
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

    /// Pick a move at a limited strength, using Stockfish's own limiter rather
    /// than a shallow search — it plays far more like a human of that rating.
    public func chooseMove(
        fen: String,
        elo: Int? = nil,
        depth: Int = 12,
        movetimeMs: Int = 0
    ) async throws -> String? {
        if let elo {
            setOption("UCI_LimitStrength", "true")
            setOption("UCI_Elo", String(max(1320, min(3190, elo))))
        } else {
            setOption("UCI_LimitStrength", "false")
        }
        let analysis = try await analyse(
            fen: fen, depth: depth, movetimeMs: movetimeMs, multiPV: 1
        )
        setOption("UCI_LimitStrength", "false")
        return analysis.bestMove
    }

    public func stop() {
        sf_stop(handle)
    }
}
