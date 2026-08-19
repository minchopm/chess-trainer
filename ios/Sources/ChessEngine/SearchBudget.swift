import Foundation

/// How long the engine may think, per kind of question.
///
/// Every search in this app used to be asked for by depth alone, with the time
/// limit left at zero — which means no limit. Depth 14 in a quiet position
/// takes a moment; the same depth in a sharp middlegame can take minutes, and
/// at full strength the app would sit there for ten. A depth is a promise about
/// quality that nobody can keep in bounded time; a time budget is a promise
/// about the wait, which is the one the player actually cares about.
///
/// Both are passed: the search stops at whichever comes first, so easy
/// positions still finish early rather than burning the whole budget.
public struct SearchBudget: Sendable, Equatable {
    public let depth: Int
    public let movetimeMs: Int

    public init(depth: Int, movetimeMs: Int) {
        self.depth = depth
        self.movetimeMs = movetimeMs
    }

    /// Grading a move that was just played. Runs twice per move — before and
    /// after — so the budget is what the player will wait, doubled.
    public static let coaching = SearchBudget(depth: 14, movetimeMs: 700)

    /// A hint. The player is waiting and watching, so this is the tightest.
    public static let hint = SearchBudget(depth: 14, movetimeMs: 600)

    /// The engine's own move at full strength. Long enough to play well, short
    /// enough that nobody wonders whether the app has died.
    public static let fullStrength = SearchBudget(depth: 20, movetimeMs: 2500)

    /// The engine's move when it is pretending to be a given Elo. Strength
    /// comes from UCI_Elo, not from thinking longer.
    public static let limited = SearchBudget(depth: 12, movetimeMs: 300)

    /// Judging whether an endgame is still winning or drawn after a move.
    public static let verdict = SearchBudget(depth: 14, movetimeMs: 900)

    /// Scoring a whole position for the judgement exercises.
    public static let assessment = SearchBudget(depth: 14, movetimeMs: 900)
}
