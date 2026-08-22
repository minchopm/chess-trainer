import Foundation

/// What an engine can be asked to do.
///
/// Not every engine can do the same things, and the honest way to handle that is
/// to let the engine say so rather than to have the app guess from its name. The
/// one difference that reaches the player is strength: Stockfish can be told to
/// play like a 1400, and Reckless cannot — its whole option list is Hash,
/// Threads, MoveOverhead, Minimal, Clear Hash, UCI_Chess960, MultiPV and
/// SyzygyPath, with no `UCI_LimitStrength` and no `UCI_Elo` anywhere in it.
///
/// So `limitsStrength` is false for Reckless and the settings offer it one
/// level. The alternative — capping depth or nodes and calling the result
/// "Casual (1400)" — would be a lie about what the player is facing. A
/// depth-capped engine is not a weaker human. It is a strong engine that plays
/// a positionally excellent game and then hangs a rook, which is both easier to
/// beat and far less instructive than the rating on the label suggests.
public struct EngineCapabilities: Sendable, Equatable {
    /// Shown to the player, so it carries the version the app is actually running.
    public let name: String

    /// Whether `chooseMove(fen:elo:…)` can honour a rating. When false, the
    /// engine plays at full strength whatever `elo` is passed, and callers
    /// should not offer a ladder.
    public let limitsStrength: Bool

    public init(name: String, limitsStrength: Bool) {
        self.name = name
        self.limitsStrength = limitsStrength
    }
}

/// A chess engine driven in-process.
///
/// An actor because a UCI engine holds exactly one position and one search:
/// serialising access is a correctness requirement, not an optimisation. Both
/// conforming engines have the same two hazards behind this interface, both
/// documented at `StockfishEngine.analyse` — searches gated to one at a time,
/// and a watchdog on every search — and both solve them the same way, because
/// the second engine's C bridge was shaped to let it.
public protocol Engine: Actor {
    nonisolated var capabilities: EngineCapabilities { get }

    func setOption(_ name: String, _ value: String)

    /// Forget everything learned from the previous game.
    func newGame()

    /// Search a position.
    ///
    /// Giving both a depth and a time cap means "this deep, but never longer
    /// than this" — some positions take minutes to reach even a modest depth,
    /// and on a phone that is the difference between a coach and a hot battery.
    func analyse(fen: String, depth: Int, movetimeMs: Int, multiPV: Int) async throws -> Analysis

    /// Pick a move, optionally at a limited strength.
    ///
    /// An engine whose `capabilities.limitsStrength` is false ignores `elo` and
    /// plays its best. Callers must not read a returned move as evidence that
    /// the rating was honoured.
    func chooseMove(fen: String, elo: Int?, depth: Int, movetimeMs: Int) async throws -> String?

    /// Cut the current search short. Safe to call when nothing is running.
    func stop()
}

extension Engine {
    /// Search under a named budget, which is how the app asks for all of them.
    public func analyse(
        fen: String, budget: SearchBudget, multiPV: Int = 1
    ) async throws -> Analysis {
        try await analyse(
            fen: fen, depth: budget.depth, movetimeMs: budget.movetimeMs, multiPV: multiPV
        )
    }

    /// Play at full strength.
    ///
    /// Spelled out rather than left to a default argument on the requirement:
    /// a call through `any Engine` dispatches to the protocol witness, and the
    /// concrete engines' defaults are not visible there.
    public func chooseMove(
        fen: String, depth: Int, movetimeMs: Int
    ) async throws -> String? {
        try await chooseMove(fen: fen, elo: nil, depth: depth, movetimeMs: movetimeMs)
    }

    public func chooseMove(
        fen: String, elo: Int? = nil, budget: SearchBudget
    ) async throws -> String? {
        try await chooseMove(
            fen: fen, elo: elo, depth: budget.depth, movetimeMs: budget.movetimeMs
        )
    }
}
