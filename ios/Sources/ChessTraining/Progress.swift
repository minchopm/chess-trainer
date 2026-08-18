import Foundation

public enum TrainingMode: String, Codable, CaseIterable, Sendable {
    case tactics, positional, endgame
}

/// One scheduled item in the spaced-repetition queue.
public struct ReviewCard: Codable, Sendable {
    public var ease: Double
    public var intervalDays: Int
    public var due: Date
    public var repetitions: Int
    public var lapses: Int
    public var lastSolved: Bool

    init(now: Date) {
        ease = 2.5
        intervalDays = 0
        due = now
        repetitions = 0
        lapses = 0
        lastSolved = false
    }
}

public struct ThemeRecord: Codable, Sendable {
    public var seen: Int = 0
    public var solved: Int = 0

    public init(seen: Int = 0, solved: Int = 0) {
        self.seen = seen
        self.solved = solved
    }

    public var accuracy: Double { seen == 0 ? 0 : Double(solved) / Double(seen) }

    /// Upper end of a Wilson interval for the accuracy.
    ///
    /// Ranking motifs by raw accuracy makes small samples shout: one missed
    /// puzzle reads as "0% — your worst weakness". The upper bound asks the
    /// more useful question — how good could you plausibly be at this? — so a
    /// motif only rises to the top once there is evidence you are truly worse.
    public var ceiling: Double {
        guard seen > 0 else { return 1 }
        let z = 1.0
        let p = accuracy
        let n = Double(seen)
        let denominator = 1 + z * z / n
        let centre = p + z * z / (2 * n)
        let margin = z * ((p * (1 - p) + z * z / (4 * n)) / n).squareRoot()
        return min(1, (centre + margin) / denominator)
    }
}

public struct GameRecord: Codable, Sendable {
    public let playedAt: Date
    public let result: String       // "win", "draw", "loss"
    public let accuracy: Int
    public let blunders: Int
    public let opponentElo: Int

    public init(playedAt: Date, result: String, accuracy: Int, blunders: Int, opponentElo: Int) {
        self.playedAt = playedAt
        self.result = result
        self.accuracy = accuracy
        self.blunders = blunders
        self.opponentElo = opponentElo
    }
}

public struct AttemptRecord: Codable, Sendable {
    public let at: Date
    public let mode: TrainingMode
    public let itemID: String
    public let correct: Bool
    public let ratingAfter: Int
}

/// Everything the trainer remembers about you. Codable so it is one file on
/// disk, and a value type so a view can hold a snapshot without racing.
public struct TrainingProgress: Codable, Sendable {
    public var ratings: [TrainingMode: Int] = [.tactics: 1200, .positional: 1200, .endgame: 1200]
    public var cards: [String: ReviewCard] = [:]
    public var themes: [String: ThemeRecord] = [:]
    public var history: [AttemptRecord] = []
    public var games: [GameRecord] = []
    public var currentStreak = 0
    public var bestStreak = 0
    public var lastActiveDay: Date?

    public init() {}

    public func rating(_ mode: TrainingMode) -> Int { ratings[mode] ?? 1200 }

    /// Tactics dominates practical strength at club level, so it weighs heaviest.
    public var overallRating: Int {
        Int((Double(rating(.tactics)) * 0.5
            + Double(rating(.positional)) * 0.25
            + Double(rating(.endgame)) * 0.25).rounded())
    }

    // MARK: - Recording

    /// Standard Elo. K shrinks as the rating settles, so early sessions find
    /// your level quickly and later ones stop jumping around.
    mutating func updateRating(_ mode: TrainingMode, against itemRating: Int, correct: Bool) -> Int {
        let current = rating(mode)
        let played = history.filter { $0.mode == mode }.count
        let k: Double = played < 20 ? 60 : (played < 60 ? 32 : 20)
        let expected = 1 / (1 + pow(10, Double(itemRating - current) / 400))
        let next = Double(current) + k * ((correct ? 1 : 0) - expected)
        ratings[mode] = max(400, Int(next.rounded()))
        return ratings[mode]!
    }

    /// SM-2, trimmed to the two outcomes a puzzle actually has. A missed puzzle
    /// returns tomorrow; a solved one is pushed out by its ease factor. Solving
    /// something just as you were about to forget it is what makes it stick.
    mutating func schedule(_ itemID: String, solved: Bool, usedHint: Bool, now: Date) {
        var card = cards[itemID] ?? ReviewCard(now: now)

        if solved {
            let quality = usedHint ? 3.0 : 5.0
            card.ease = max(1.3, card.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
            card.intervalDays = card.repetitions == 0 ? 1
                : (card.repetitions == 1 ? 4 : Int((Double(card.intervalDays) * card.ease).rounded()))
            card.repetitions += 1
        } else {
            card.ease = max(1.3, card.ease - 0.2)
            card.intervalDays = 1
            card.lapses += 1
        }

        card.due = now.addingTimeInterval(Double(card.intervalDays) * 86_400)
        card.lastSolved = solved
        cards[itemID] = card
    }

    public mutating func record(
        mode: TrainingMode,
        itemID: String,
        itemRating: Int,
        correct: Bool,
        themes attemptThemes: [String] = [],
        usedHint: Bool = false,
        now: Date = Date()
    ) {
        let ratingAfter = updateRating(mode, against: itemRating, correct: correct && !usedHint)
        schedule(itemID, solved: correct, usedHint: usedHint, now: now)

        for theme in attemptThemes where Themes.isMotif(theme) {
            var record = themes[theme] ?? ThemeRecord()
            record.seen += 1
            if correct { record.solved += 1 }
            themes[theme] = record
        }

        history.append(AttemptRecord(at: now, mode: mode, itemID: itemID, correct: correct, ratingAfter: ratingAfter))
        if history.count > 2000 { history.removeFirst(history.count - 2000) }
        bumpStreak(now: now)
    }

    public mutating func record(game: GameRecord) {
        games.append(game)
        if games.count > 200 { games.removeFirst(games.count - 200) }
        bumpStreak(now: game.playedAt)
    }

    mutating func bumpStreak(now: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        guard let last = lastActiveDay.map({ calendar.startOfDay(for: $0) }) else {
            currentStreak = 1
            bestStreak = max(bestStreak, 1)
            lastActiveDay = today
            return
        }
        guard today != last else { return }

        let dayGap = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        currentStreak = dayGap == 1 ? currentStreak + 1 : 1
        bestStreak = max(bestStreak, currentStreak)
        lastActiveDay = today
    }

    // MARK: - Reporting

    public func hasSeen(_ itemID: String) -> Bool { cards[itemID] != nil }

    /// Everything whose interval has elapsed — missed items that come back the
    /// next day, and solved ones resurfacing later. Solved cards have to return
    /// too, or the schedule is only a penalty box rather than a memory system.
    public func dueItemIDs(now: Date = Date()) -> [String] {
        cards.filter { $0.value.due <= now }.map(\.key)
    }

    public func weakestThemes(limit: Int = 6, minimumSeen: Int = 3) -> [(name: String, record: ThemeRecord)] {
        themes.filter { $0.value.seen >= minimumSeen }
            .sorted { $0.value.ceiling < $1.value.ceiling }
            .prefix(limit)
            .map { (name: $0.key, record: $0.value) }
    }

    /// The motifs worth aiming puzzles at: those measurably below your own
    /// average. Compared against your own baseline rather than a fixed number,
    /// because a 60% solver and an 85% solver need different thresholds.
    public func trainingTargets(minimumSeen: Int = 4, margin: Double = 0.05, limit: Int = 6)
        -> [(name: String, record: ThemeRecord)] {
        let candidates = themes.filter { $0.value.seen >= minimumSeen }
        guard candidates.count >= 3 else { return [] }  // too early to know anything

        let solved = candidates.values.reduce(0) { $0 + $1.solved }
        let seen = candidates.values.reduce(0) { $0 + $1.seen }
        guard seen > 0 else { return [] }
        let baseline = Double(solved) / Double(seen)

        return candidates.filter { $0.value.ceiling < baseline - margin }
            .sorted { $0.value.ceiling < $1.value.ceiling }
            .prefix(limit)
            .map { (name: $0.key, record: $0.value) }
    }

    public func sessionStats(on day: Date = Date()) -> (attempted: Int, solved: Int, accuracy: Double) {
        let start = Calendar.current.startOfDay(for: day)
        let todays = history.filter { $0.at >= start }
        let solved = todays.filter(\.correct).count
        return (todays.count, solved, todays.isEmpty ? 0 : Double(solved) / Double(todays.count))
    }
}

/// The ladder. Honest labels for what a puzzle rating means in practice — a
/// puzzle rating is not an over-the-board rating and runs several hundred
/// points above one.
public struct LadderRung: Sendable, Identifiable {
    public let id: Int
    public let minimum: Int
    public let name: String
    public let focus: String

    public static let all: [LadderRung] = [
        LadderRung(id: 0, minimum: 0, name: "Beginner", focus: "Piece safety, one-move threats, basic mates"),
        LadderRung(id: 1, minimum: 1000, name: "Club player", focus: "Forks, pins, back rank, king-and-pawn endings"),
        LadderRung(id: 2, minimum: 1400, name: "Strong club", focus: "Two-move combinations, rook activity, opposition"),
        LadderRung(id: 3, minimum: 1750, name: "Expert", focus: "Deflection, interference, prophylaxis, Lucena and Philidor"),
        LadderRung(id: 4, minimum: 2050, name: "Candidate master", focus: "Quiet moves, long forcing lines, minor-piece endings"),
        LadderRung(id: 5, minimum: 2300, name: "Master", focus: "Positional sacrifices, defensive resources, technique"),
        LadderRung(id: 6, minimum: 2500, name: "Grandmaster range", focus: "Deep calculation, imbalance evaluation, endgame precision"),
    ]

    public static func current(for rating: Int) -> LadderRung {
        all.last { rating >= $0.minimum } ?? all[0]
    }
}
