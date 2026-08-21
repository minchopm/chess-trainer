import Foundation

public enum TrainingMode: String, Codable, CaseIterable, Sendable {
    case tactics, positional, endgame
}

/// One thing a rating can mean.
///
/// A rating is only ever a statement about what it was earned against, and
/// these do not compare. Beating a club bot says nothing about how you hold up
/// at three minutes against a person; solving puzzles with a clock running is a
/// different skill from solving the same puzzles with all afternoon. Kept as
/// one number they average into something that describes nobody — a player
/// strong at rapid and hopeless at bullet gets a middle figure that is wrong
/// about both.
///
/// The identifier is what goes on disk, so the cases can be reordered and
/// renamed without anyone losing a rating.
public enum RatedPool: Hashable, Sendable {
    /// The training libraries, untimed.
    case training(TrainingMode)
    /// Puzzle rush, by how long the run lasts.
    case rush(minutes: Int)
    /// A person, at one clock. Matchmaking already keeps these apart.
    case online(minutes: Int)
    /// The engine, at whatever strength was chosen. Untimed.
    case engine

    public var id: String {
        switch self {
        case .training(let mode): "training.\(mode.rawValue)"
        case .rush(let minutes): "rush.\(minutes)"
        case .online(let minutes): "online.\(minutes)"
        case .engine: "engine"
        }
    }

    public init?(id: String) {
        let parts = id.split(separator: ".", maxSplits: 1).map(String.init)
        switch (parts.first, parts.count > 1 ? parts[1] : nil) {
        case ("engine", _): self = .engine
        case ("training", let rest?):
            guard let mode = TrainingMode(rawValue: rest) else { return nil }
            self = .training(mode)
        case ("rush", let rest?):
            guard let minutes = Int(rest) else { return nil }
            self = .rush(minutes: minutes)
        case ("online", let rest?):
            guard let minutes = Int(rest) else { return nil }
            self = .online(minutes: minutes)
        default: return nil
        }
    }
}

/// A rating and what it was earned on.
///
/// The count is not decoration: it sets how hard the next result moves the
/// number, so a settled rating in one pool must not steady a fresh one in
/// another. That is the whole reason these are kept apart rather than shared.
public struct PoolRating: Codable, Sendable, Equatable {
    public var rating: Int
    public var games: Int

    public init(rating: Int = 1200, games: Int = 0) {
        self.rating = rating
        self.games = games
    }
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

/// How far into a recording somebody got, and when.
///
/// Kept per game rather than as a single "last watched", because the library is
/// nine hundred games and a person dips in and out of several. The date is what
/// makes a history: the list can be ordered by when a game was last opened
/// without keeping a separate log of openings.
public struct WatchMark: Codable, Sendable, Equatable {
    /// Half-moves played, counted from the start of the game.
    public var ply: Int
    /// Half-moves in the whole game, so a fraction can be shown without
    /// looking the game up again.
    public var of: Int
    public var at: Date

    public init(ply: Int, of: Int, at: Date) {
        self.ply = ply
        self.of = of
        self.at = at
    }

    /// Nought to one. A game watched to the last move is finished, and one
    /// stopped in the opening is barely started.
    public var fraction: Double {
        guard of > 0 else { return 0 }
        return min(1, Double(ply) / Double(of))
    }

    public var isFinished: Bool { of > 0 && ply >= of }
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
    /// Every rating the player holds, by the pool it was earned in.
    ///
    /// Keyed by `RatedPool.id` rather than by the enum, so the file on disk
    /// stays readable and a case can be renamed without wiping anybody's
    /// record.
    public var pools: [String: PoolRating] = [:]
    public var cards: [String: ReviewCard] = [:]
    public var themes: [String: ThemeRecord] = [:]
    public var history: [AttemptRecord] = []
    public var games: [GameRecord] = []
    public var rushRecords: [RushRecord] = []
    public var eloGuesses: [EloGuessRecord] = []
    /// Online play keeps its own rating. It is the only one measured against
    /// other people rather than against a library, so mixing it into the
    /// training ratings would make both harder to read.
    /// What the free tier has spent today. Absent for anyone who has paid,
    /// because nothing counts it.
    public var dailyUsage = DailyUsage()
    public var appearance = Appearance()
    /// Career totals across every clock. The ratings are per clock; these are
    /// the tally of games played against people, which is one number a player
    /// does think of as one number.
    public var onlineWins = 0
    public var onlineLosses = 0
    public var onlineDraws = 0
    /// How far each recording has been watched, keyed by the game's id.
    public var watched: [String: WatchMark] = [:]
    /// Recordings kept aside, keyed by the game's id.
    public var favourites: Set<String> = []
    public var currentStreak = 0
    public var bestStreak = 0
    public var lastActiveDay: Date?

    public init() {}

    /// Written out by these names, and read by them plus the two the ratings
    /// used to live under. `ratings` and `onlineRating` are no longer stored —
    /// they are listed so a file from before the split can still be read.
    private enum CodingKeys: String, CodingKey {
        case pools, cards, themes, history, games, rushRecords, eloGuesses
        case dailyUsage, appearance, watched, favourites
        case onlineWins, onlineLosses, onlineDraws
        case currentStreak, bestStreak, lastActiveDay
        case ratings, onlineRating
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pools, forKey: .pools)
        try container.encode(cards, forKey: .cards)
        try container.encode(themes, forKey: .themes)
        try container.encode(history, forKey: .history)
        try container.encode(games, forKey: .games)
        try container.encode(rushRecords, forKey: .rushRecords)
        try container.encode(eloGuesses, forKey: .eloGuesses)
        try container.encode(dailyUsage, forKey: .dailyUsage)
        try container.encode(appearance, forKey: .appearance)
        try container.encode(watched, forKey: .watched)
        try container.encode(favourites, forKey: .favourites)
        try container.encode(onlineWins, forKey: .onlineWins)
        try container.encode(onlineLosses, forKey: .onlineLosses)
        try container.encode(onlineDraws, forKey: .onlineDraws)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(bestStreak, forKey: .bestStreak)
        try container.encodeIfPresent(lastActiveDay, forKey: .lastActiveDay)
    }

    /// Decoded key by key, so a file written by an older build still loads.
    ///
    /// The synthesized initialiser treats every non-optional property as
    /// required, which means adding one field throws away everything the file
    /// held: ratings, streak, review schedule. Silently, because the caller
    /// only sees `nil` and starts fresh. A missing key here means the feature
    /// did not exist yet, which is exactly what a default value is for.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pools = try container.decodeIfPresent([String: PoolRating].self, forKey: .pools) ?? [:]
        cards = try container.decodeIfPresent([String: ReviewCard].self, forKey: .cards) ?? [:]
        themes = try container.decodeIfPresent([String: ThemeRecord].self, forKey: .themes) ?? [:]
        history = try container.decodeIfPresent([AttemptRecord].self, forKey: .history) ?? []
        games = try container.decodeIfPresent([GameRecord].self, forKey: .games) ?? []
        rushRecords = try container.decodeIfPresent([RushRecord].self, forKey: .rushRecords) ?? []
        eloGuesses = try container.decodeIfPresent([EloGuessRecord].self, forKey: .eloGuesses) ?? []
        dailyUsage = try container.decodeIfPresent(DailyUsage.self, forKey: .dailyUsage) ?? DailyUsage()
        appearance = try container.decodeIfPresent(Appearance.self, forKey: .appearance) ?? Appearance()
        watched = try container.decodeIfPresent([String: WatchMark].self, forKey: .watched) ?? [:]
        favourites = try container.decodeIfPresent(Set<String>.self, forKey: .favourites) ?? []
        onlineWins = try container.decodeIfPresent(Int.self, forKey: .onlineWins) ?? 0
        onlineLosses = try container.decodeIfPresent(Int.self, forKey: .onlineLosses) ?? 0
        onlineDraws = try container.decodeIfPresent(Int.self, forKey: .onlineDraws) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        bestStreak = try container.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        lastActiveDay = try container.decodeIfPresent(Date.self, forKey: .lastActiveDay)

        if pools.isEmpty {
            // A file from before the ratings were split. The three training
            // ratings carry over as they are; the one online rating is copied
            // to every clock, because a rating earned at five minutes is a
            // better guess at somebody's three-minute strength than 1200 is.
            //
            // The game counts do *not* carry over. They set how hard the next
            // result moves the number, and the point of splitting is that each
            // clock now has to find its own level — starting each at nought
            // lets it, which is what a fresh pool is for.
            let old = try container.decodeIfPresent([TrainingMode: Int].self, forKey: .ratings)
                ?? [.tactics: 1200, .positional: 1200, .endgame: 1200]
            for (mode, rating) in old {
                pools[RatedPool.training(mode).id] = PoolRating(rating: rating, games: 0)
            }
            let online = try container.decodeIfPresent(Int.self, forKey: .onlineRating)
                ?? OnlineElo.starting
            for control in TimeControl.allCases {
                pools[RatedPool.online(minutes: control.minutes).id] =
                    PoolRating(rating: online, games: 0)
            }
        }
    }

    /// Records a judged game and returns the verdict, so the caller does not
    /// have to score it a second time to show it.
    @discardableResult
    public mutating func record(guess: Int, on game: String, actual: Int, at now: Date = Date()) -> EloGuess {
        eloGuesses.append(EloGuessRecord(at: now, gameID: game, guess: guess, actual: actual))
        return EloGuess(guess: guess, actual: actual)
    }

    public var eloGuessStats: EloGuessStats { EloGuessStats(eloGuesses) }

    /// How many more of this a free account may have today.
    public func freeRemaining(
        _ activity: TrainingActivity, at now: Date = Date(), calendar: Calendar = .current
    ) -> Int {
        dailyUsage.remaining(activity, at: now, calendar: calendar)
    }

    public mutating func recordFreeUse(
        of activity: TrainingActivity, at now: Date = Date(), calendar: Calendar = .current
    ) {
        dailyUsage.record(activity, at: now, calendar: calendar)
    }

    public func freeTacticsSkipsRemaining(
        at now: Date = Date(), calendar: Calendar = .current
    ) -> Int {
        dailyUsage.remainingTacticsSkips(at: now, calendar: calendar)
    }

    public mutating func recordFreeTacticsSkip(
        at now: Date = Date(), calendar: Calendar = .current
    ) {
        dailyUsage.recordTacticsSkip(at: now, calendar: calendar)
    }

    /// Record a finished online game. The rating change is computed by the
    /// session, which is the only place that knows what the opponent was rated.
    /// A finished game against a person, at the clock it was played on.
    ///
    /// The clock is the pool. Somebody who is 1700 at fifteen minutes and 1300
    /// at three is not 1500 at either, and the two only ever meet opponents
    /// from their own pool — matchmaking has always kept them apart.
    public mutating func record(online result: MatchResult, at control: TimeControl) {
        let pool = RatedPool.online(minutes: control.minutes)
        var held = pools[pool.id] ?? PoolRating(rating: starting(pool))
        held.rating = min(max(held.rating + result.ratingDelta, OnlineElo.range.lowerBound),
                          OnlineElo.range.upperBound)
        held.games += 1
        pools[pool.id] = held
        switch result.outcome {
        case .win: onlineWins += 1
        case .loss: onlineLosses += 1
        case .draw: onlineDraws += 1
        }
    }

    public func rating(_ mode: TrainingMode) -> Int { rating(.training(mode)) }

    public func rating(_ pool: RatedPool) -> Int {
        pools[pool.id]?.rating ?? starting(pool)
    }

    /// Where a pool begins, before anything has been played in it.
    ///
    /// Not 1200 for everything. Somebody who has solved tactics for a month
    /// has already told us roughly how hard their first timed run should be,
    /// and opening it at 1200 wastes the run on puzzles they can do in their
    /// sleep. It is a guess and it is meant to be moved — the count starts at
    /// nought, so the first few results shift it hard.
    private func starting(_ pool: RatedPool) -> Int {
        switch pool {
        case .rush: pools[RatedPool.training(.tactics).id]?.rating ?? 1200
        default: 1200
        }
    }

    public func gamesPlayed(_ pool: RatedPool) -> Int { pools[pool.id]?.games ?? 0 }

    /// Moves a pool's rating by one result against a known opponent.
    ///
    /// The same Elo everywhere, so a rating means the same thing whichever
    /// pool it came from — what differs is only who it was earned against.
    @discardableResult
    public mutating func settle(
        _ pool: RatedPool, against opponent: Int, score: Double
    ) -> Int {
        var held = pools[pool.id] ?? PoolRating(rating: starting(pool))
        held.rating = OnlineElo.updated(
            rating: held.rating, games: held.games, against: opponent, score: score
        )
        held.games += 1
        pools[pool.id] = held
        return held.rating
    }

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
        var held = pools[RatedPool.training(mode).id] ?? PoolRating()
        held.rating = max(400, Int(next.rounded()))
        held.games += 1
        pools[RatedPool.training(mode).id] = held
        return held.rating
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

    /// A finished game against the engine.
    ///
    /// Rated, and in a pool of its own. The engine's strength is chosen rather
    /// than met, which makes this a different measurement from a rating earned
    /// against people — but it is a measurement: the opponent's rating is known
    /// exactly, which is more than can be said for most games.
    public mutating func record(game: GameRecord) {
        games.append(game)
        if games.count > 200 { games.removeFirst(games.count - 200) }
        let score: Double = switch game.result {
        case "win": 1
        case "draw": 0.5
        default: 0
        }
        settle(.engine, against: game.opponentElo, score: score)
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
        LadderRung(id: 0, minimum: 0, name: L.t("ladder.name0", "Beginner"), focus: L.t("ladder.focus0", "Piece safety, one-move threats, basic mates")),
        LadderRung(id: 1, minimum: 1000, name: L.t("ladder.name1", "Club player"), focus: L.t("ladder.focus1", "Forks, pins, back rank, king-and-pawn endings")),
        LadderRung(id: 2, minimum: 1400, name: L.t("ladder.name2", "Strong club"), focus: L.t("ladder.focus2", "Two-move combinations, rook activity, opposition")),
        LadderRung(id: 3, minimum: 1750, name: L.t("ladder.name3", "Expert"), focus: L.t("ladder.focus3", "Deflection, interference, prophylaxis, Lucena and Philidor")),
        LadderRung(id: 4, minimum: 2050, name: L.t("ladder.name4", "Candidate master"), focus: L.t("ladder.focus4", "Quiet moves, long forcing lines, minor-piece endings")),
        LadderRung(id: 5, minimum: 2300, name: L.t("ladder.name5", "Master"), focus: L.t("ladder.focus5", "Positional sacrifices, defensive resources, technique")),
        LadderRung(id: 6, minimum: 2500, name: L.t("ladder.name6", "Grandmaster range"), focus: L.t("ladder.focus6", "Deep calculation, imbalance evaluation, endgame precision")),
    ]

    public static func current(for rating: Int) -> LadderRung {
        all.last { rating >= $0.minimum } ?? all[0]
    }
}

extension TrainingProgress {
    /// Best timed run per duration, so a three-minute record is not compared
    /// against a ten-minute one.
    public var rushRecordsByDuration: [Int: RushRecord] {
        get {
            var result: [Int: RushRecord] = [:]
            for record in rushRecords { 
                let key = Int(record.duration)
                if let existing = result[key], existing.solved >= record.solved { continue }
                result[key] = record
            }
            return result
        }
    }

    /// Remembers where a recording was left.
    ///
    /// Only ever forward: scrubbing back to look at a move again is not
    /// un-watching the game, and a list that forgot half a game because
    /// somebody rewound would be worse than one that never remembered.
    public mutating func mark(watched game: String, ply: Int, of total: Int, at now: Date = Date()) {
        let reached = max(ply, watched[game]?.ply ?? 0)
        watched[game] = WatchMark(ply: reached, of: total, at: now)
        if watched.count > 400 {
            // Oldest first, so what goes is what has not been looked at.
            let stale = watched.sorted { $0.value.at < $1.value.at }
                .prefix(watched.count - 400).map(\.key)
            for key in stale { watched.removeValue(forKey: key) }
        }
    }

    public func watchMark(for game: String) -> WatchMark? { watched[game] }

    public func isFavourite(_ game: String) -> Bool { favourites.contains(game) }

    public mutating func toggleFavourite(_ game: String) {
        if favourites.contains(game) { favourites.remove(game) } else { favourites.insert(game) }
    }

    public mutating func record(rush: RushRecord, attempts: [RushAttempt] = []) {
        rushRecords.append(rush)
        if rushRecords.count > 100 { rushRecords.removeFirst(rushRecords.count - 100) }

        // Rated per puzzle rather than per run: a run is not one contest with
        // one opponent, it is forty of them, and each puzzle knows its own
        // rating. Its own pool, and one per length — a three-minute run and a
        // ten-minute run are different tests of the same eyes.
        let pool = RatedPool.rush(minutes: Int(rush.duration) / 60)
        for attempt in attempts {
            settle(pool, against: attempt.rating, score: attempt.solved ? 1 : 0)
        }
    }
}
