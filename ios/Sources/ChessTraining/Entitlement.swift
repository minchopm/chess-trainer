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
    /// Five of each, and the same five everywhere. Enough to feel the loop and
    /// watch the rating move, which is the only thing that makes the paid tier
    /// worth buying — one of something shows a person the door and nothing
    /// behind it, and a rating that never moves is not a reason to pay.
    ///
    /// Counted on the attempt, never on opening the screen: browsing the
    /// library, reading a position and changing your mind cost nothing.
    public var dailyFreeLimit: Int { 5 }
}

/// What a free account has used today.
///
/// Counted against a local training day that starts at 09:00. This is a
/// calendar boundary rather than a rolling 24 hours, so it remains 09:00 when
/// the device changes time zone or daylight-saving time begins or ends.
public struct DailyUsage: Codable, Equatable, Sendable {
    public static let resetHour = 9
    public static let freeTacticsSkips = 2

    public private(set) var day: Date
    public private(set) var counts: [TrainingActivity: Int]
    public private(set) var tacticsSkips: Int

    public init(
        day: Date = Date(),
        counts: [TrainingActivity: Int] = [:],
        tacticsSkips: Int = 0
    ) {
        self.day = day
        self.counts = counts
        self.tacticsSkips = tacticsSkips
    }

    private enum CodingKeys: String, CodingKey {
        case day, counts, tacticsSkips
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decodeIfPresent(Date.self, forKey: .day) ?? Date()
        counts = try container.decodeIfPresent([TrainingActivity: Int].self, forKey: .counts) ?? [:]
        tacticsSkips = try container.decodeIfPresent(Int.self, forKey: .tacticsSkips) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode(counts, forKey: .counts)
        try container.encode(tacticsSkips, forKey: .tacticsSkips)
    }

    public func used(_ activity: TrainingActivity, at now: Date, calendar: Calendar = .current) -> Int {
        Self.periodStart(containing: day, calendar: calendar)
            == Self.periodStart(containing: now, calendar: calendar)
            ? (counts[activity] ?? 0)
            : 0
    }

    public func remaining(_ activity: TrainingActivity, at now: Date, calendar: Calendar = .current) -> Int {
        max(0, activity.dailyFreeLimit - used(activity, at: now, calendar: calendar))
    }

    public func remainingTacticsSkips(
        at now: Date,
        calendar: Calendar = .current
    ) -> Int {
        let used = Self.periodStart(containing: day, calendar: calendar)
            == Self.periodStart(containing: now, calendar: calendar)
            ? tacticsSkips
            : 0
        return max(0, Self.freeTacticsSkips - used)
    }

    public mutating func record(_ activity: TrainingActivity, at now: Date, calendar: Calendar = .current) {
        resetIfNeeded(at: now, calendar: calendar)
        counts[activity, default: 0] += 1
    }

    public mutating func recordTacticsSkip(at now: Date, calendar: Calendar = .current) {
        resetIfNeeded(at: now, calendar: calendar)
        tacticsSkips += 1
    }

    /// The next 09:00 boundary in the supplied local calendar.
    public static func nextReset(after date: Date, calendar: Calendar = .current) -> Date {
        let start = periodStart(containing: date, calendar: calendar)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86_400)
    }

    private mutating func resetIfNeeded(at now: Date, calendar: Calendar) {
        guard Self.periodStart(containing: day, calendar: calendar)
            != Self.periodStart(containing: now, calendar: calendar)
        else { return }
        day = now
        counts = [:]
        tacticsSkips = 0
    }

    private static func periodStart(containing date: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let todayReset = calendar.date(bySettingHour: resetHour, minute: 0, second: 0, of: startOfDay)
            ?? calendar.date(byAdding: .hour, value: resetHour, to: startOfDay)
            ?? startOfDay
        if date >= todayReset { return todayReset }
        return calendar.date(byAdding: .day, value: -1, to: todayReset)
            ?? todayReset.addingTimeInterval(-86_400)
    }
}
