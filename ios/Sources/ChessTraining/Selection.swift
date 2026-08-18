import Foundation

/// Why a particular item was chosen. Shown to the user, because a trainer that
/// silently decides what you practise is indistinguishable from a shuffle —
/// and one you can see reasoning is one you can argue with.
public enum SelectionReason: Equatable, Sendable {
    case review                       // due for spaced repetition
    case weakness(motif: String, accuracy: Double, seen: Int)
    case level                        // simply near your rating

    public var explanation: String? {
        switch self {
        case .review:
            return "Review — you have seen this one before."
        case .weakness(let motif, let accuracy, let seen):
            let percent = Int((accuracy * 100).rounded())
            return "Chosen for you: \(Themes.readable(motif).lowercased()) — \(percent)% of \(seen) so far."
        case .level:
            return nil
        }
    }
}

public struct Selection<Item>: Sendable where Item: Sendable {
    public let item: Item
    public let reason: SelectionReason
}

public enum ItemSelector {
    /// How often a puzzle is chosen to attack a weakness rather than by rating.
    static let targetShare = 0.6

    /// Choose the next tactics puzzle.
    ///
    /// Three mechanisms, in order of precedence:
    ///   1. Spaced repetition — anything due comes back first.
    ///   2. Weakness targeting — most of the rest come from motifs you are
    ///      measurably worse at than your own average.
    ///   3. Difficulty tracking — everything stays near your rating, aimed a
    ///      little above it.
    ///
    /// Targeting deliberately does not apply every time. Drilling only weak
    /// motifs stops measuring the rest, and the rating would then drift on
    /// stale evidence.
    public static func nextPuzzle(
        from puzzles: [Puzzle],
        progress: TrainingProgress,
        now: Date = Date(),
        random: (Int) -> Int = { Int.random(in: 0..<$0) },
        chance: () -> Double = { Double.random(in: 0..<1) }
    ) -> Selection<Puzzle>? {
        guard !puzzles.isEmpty else { return nil }

        let due = Set(progress.dueItemIDs(now: now))
        let dueOnes = puzzles.filter { due.contains($0.id) }
        if !dueOnes.isEmpty {
            return Selection(item: dueOnes[random(dueOnes.count)], reason: .review)
        }

        let target = progress.rating(.tactics) + 60
        func inRange(_ window: Int) -> [Puzzle] {
            puzzles.filter { abs($0.rating - target) <= window && !progress.hasSeen($0.id) }
        }

        let targets = progress.trainingTargets()
        if !targets.isEmpty, chance() < targetShare {
            let wanted = Set(targets.map(\.name))
            for window in [250, 450, 800] {
                let pool = inRange(window).filter { !wanted.isDisjoint(with: $0.themes) }
                if !pool.isEmpty {
                    let chosen = pool[random(pool.count)]
                    if let motif = targets.first(where: { chosen.themes.contains($0.name) }) {
                        return Selection(item: chosen, reason: .weakness(
                            motif: motif.name,
                            accuracy: motif.record.accuracy,
                            seen: motif.record.seen
                        ))
                    }
                }
            }
        }

        for window in [150, 300, 500, 1200] {
            let pool = inRange(window)
            if !pool.isEmpty { return Selection(item: pool[random(pool.count)], reason: .level) }
        }
        return Selection(item: puzzles[random(puzzles.count)], reason: .level)
    }

    public static func nextExercise(
        from exercises: [PositionalExercise],
        progress: TrainingProgress,
        random: (Int) -> Int = { Int.random(in: 0..<$0) }
    ) -> PositionalExercise? {
        guard !exercises.isEmpty else { return nil }
        let rating = progress.rating(.positional)
        for window in [200, 400, 700, 2000] {
            let pool = exercises.filter { abs($0.rating - rating) <= window && !progress.hasSeen($0.id) }
            if !pool.isEmpty { return pool[random(pool.count)] }
        }
        return exercises[random(exercises.count)]
    }

    /// Endgame drills are few, so rather than filtering by a window we take the
    /// closest handful by rating and pick among them — otherwise the same drill
    /// would come up over and over.
    public static func nextDrill(
        from drills: [EndgameDrill],
        progress: TrainingProgress,
        random: (Int) -> Int = { Int.random(in: 0..<$0) }
    ) -> EndgameDrill? {
        guard !drills.isEmpty else { return nil }
        let rating = progress.rating(.endgame)
        let closest = drills.sorted { abs($0.rating - rating) < abs($1.rating - rating) }
        let pool = Array(closest.prefix(5))
        return pool[random(pool.count)]
    }
}
