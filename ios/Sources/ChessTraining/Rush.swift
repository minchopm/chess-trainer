import Foundation

/// A timed run: solve as many puzzles as you can before the clock runs out.
///
/// The point is different from practice. Practice is about understanding a
/// position; a run is about *recognition* — seeing a pattern before you have
/// time to reason your way to it. That is why the difficulty ramps rather than
/// tracking your rating: the early puzzles should be almost free, so the clock
/// is the opponent rather than the position.
public struct RushSettings: Equatable, Sendable {
    public var duration: TimeInterval
    public var target: Int

    public init(duration: TimeInterval = 300, target: Int = 100) {
        self.duration = duration
        self.target = target
    }

    public static let choices: [TimeInterval] = [180, 300, 600]

    public static func label(for duration: TimeInterval) -> String {
        "\(Int(duration) / 60) min"
    }
}

/// One puzzle in a run, and how hard it was.
public struct RushAttempt: Sendable, Equatable {
    public let rating: Int
    public let solved: Bool

    public init(rating: Int, solved: Bool) {
        self.rating = rating
        self.solved = solved
    }
}

public struct RushRun: Sendable {
    /// Every puzzle the run put up, with its rating. Kept because a run is
    /// rated the way a session of tactics is — one Elo step per puzzle against
    /// that puzzle's own rating — and the rating is only known while the
    /// puzzle is on screen.
    public private(set) var attempts: [RushAttempt] = []
    public private(set) var solved = 0
    public private(set) var missed = 0
    public private(set) var streak = 0
    public private(set) var bestStreak = 0
    public private(set) var attempted = 0

    public let settings: RushSettings
    public let startedAt: Date

    /// Three misses ends a run early. Without a penalty the fastest strategy is
    /// to guess, which trains the opposite of what this is for.
    public static let allowedMisses = 3

    public init(settings: RushSettings, startedAt: Date = Date()) {
        self.settings = settings
        self.startedAt = startedAt
    }

    public var isOver: Bool {
        missed >= Self.allowedMisses || solved >= settings.target
    }

    public var endedByMisses: Bool { missed >= Self.allowedMisses }
    public var completedTarget: Bool { solved >= settings.target }

    public func remaining(at now: Date = Date()) -> TimeInterval {
        max(0, settings.duration - now.timeIntervalSince(startedAt))
    }

    public func hasTimeLeft(at now: Date = Date()) -> Bool { remaining(at: now) > 0 }

    public mutating func record(solved wasSolved: Bool, rating: Int = 1200) {
        attempts.append(RushAttempt(rating: rating, solved: wasSolved))
        attempted += 1
        if wasSolved {
            solved += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            missed += 1
            streak = 0
        }
    }

    /// Difficulty for the next puzzle in the run.
    ///
    /// Starts well below your practice rating and climbs past it, so a run
    /// opens with recognition you already own and ends somewhere you have to
    /// reach for.
    public func targetRating(practiceRating: Int) -> Int {
        let progress = Double(min(attempted, 60)) / 60
        let floor = Double(practiceRating) - 500
        let ceiling = Double(practiceRating) + 350
        return Int(floor + (ceiling - floor) * progress)
    }
}

public struct RushRecord: Codable, Sendable, Equatable {
    public let solved: Int
    public let bestStreak: Int
    public let duration: TimeInterval
    public let achievedAt: Date

    public init(solved: Int, bestStreak: Int, duration: TimeInterval, achievedAt: Date) {
        self.solved = solved
        self.bestStreak = bestStreak
        self.duration = duration
        self.achievedAt = achievedAt
    }
}

extension ItemSelector {
    /// Pick the next puzzle of a run: nearest the target difficulty, not yet
    /// seen in this run, and never repeated within it.
    public static func nextRushPuzzle(
        from puzzles: [Puzzle],
        targetRating: Int,
        excluding used: Set<String>,
        random: (Int) -> Int = { Int.random(in: 0..<$0) }
    ) -> Puzzle? {
        guard !puzzles.isEmpty else { return nil }
        for window in [120, 250, 500, 1500] {
            let pool = puzzles.filter {
                abs($0.rating - targetRating) <= window && !used.contains($0.id)
            }
            if !pool.isEmpty { return pool[random(pool.count)] }
        }
        return puzzles.first { !used.contains($0.id) }
    }
}
