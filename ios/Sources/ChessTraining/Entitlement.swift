import Foundation

/// The parts of the app a subscription unlocks.
///
/// Playing — against the engine or against a person — is not on this list and
/// never will be. A trainer that will not let you play chess is a demo, and the
/// online games cost nothing to run. What is sold is the training: the puzzle
/// library, the judgement exercises, the drills and the run.
public enum TrainingActivity: String, Codable, CaseIterable, Sendable {
    case tactics, rush, positional, endgame, guessTheElo

    /// How many of these a free account gets each day.
    ///
    /// Enough to feel the loop and watch the rating move, which is the only
    /// thing that makes the paid tier worth buying. A locked door teaches
    /// nobody what is behind it.
    public var dailyFreeLimit: Int {
        switch self {
        case .tactics: 5
        case .rush: 1
        case .positional, .endgame, .guessTheElo: 3
        }
    }
}

/// What a free account has used today.
///
/// Counted against the local day rather than a rolling 24 hours: "come back
/// tomorrow" is a promise a person can act on, while "come back in nine hours
/// and twenty minutes" is a puzzle of its own.
public struct DailyUsage: Codable, Equatable, Sendable {
    public private(set) var day: Date
    public private(set) var counts: [TrainingActivity: Int]

    public init(day: Date = Date(), counts: [TrainingActivity: Int] = [:]) {
        self.day = day
        self.counts = counts
    }

    public func used(_ activity: TrainingActivity, at now: Date, calendar: Calendar = .current) -> Int {
        calendar.isDate(day, inSameDayAs: now) ? (counts[activity] ?? 0) : 0
    }

    public func remaining(_ activity: TrainingActivity, at now: Date, calendar: Calendar = .current) -> Int {
        max(0, activity.dailyFreeLimit - used(activity, at: now, calendar: calendar))
    }

    public mutating func record(_ activity: TrainingActivity, at now: Date, calendar: Calendar = .current) {
        if !calendar.isDate(day, inSameDayAs: now) {
            day = now
            counts = [:]
        }
        counts[activity, default: 0] += 1
    }
}
