package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.match.Elo
import com.artesoft.brasspawn.match.Glicko
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.match.MatchResult
import com.artesoft.brasspawn.match.OnlineRecord
import com.artesoft.brasspawn.match.TimeControl
import com.artesoft.brasspawn.match.nowSeconds
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import kotlin.math.pow
import kotlin.math.sqrt
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

@Serializable
enum class TrainingMode(val rawValue: String) {
    @SerialName("tactics") TACTICS("tactics"),
    @SerialName("positional") POSITIONAL("positional"),
    @SerialName("endgame") ENDGAME("endgame");

    companion object {
        fun fromRawValue(rawValue: String): TrainingMode? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

/**
 * One thing a rating can mean.
 *
 * A rating is only ever a statement about what it was earned against, and
 * these do not compare. Beating a club bot says nothing about how you hold up
 * at three minutes against a person; solving puzzles with a clock running is a
 * different skill from solving the same puzzles with all afternoon. Kept as
 * one number they average into something that describes nobody — a player
 * strong at rapid and hopeless at bullet gets a middle figure that is wrong
 * about both.
 *
 * The identifier is what goes on disk, so the cases can be reordered and
 * renamed without anyone losing a rating.
 */
sealed interface RatedPool {
    /** The training libraries, untimed. */
    data class Training(val mode: TrainingMode) : RatedPool

    /** Puzzle rush, by how long the run lasts. */
    data class Rush(val minutes: Int) : RatedPool

    /** A person, at one clock. Matchmaking already keeps these apart. */
    data class Online(val minutes: Int) : RatedPool

    /** The engine, at whatever strength was chosen. Untimed. */
    data object Engine : RatedPool

    val id: String
        get() = when (this) {
            is Training -> "training.${mode.rawValue}"
            is Rush -> "rush.$minutes"
            is Online -> "online.$minutes"
            Engine -> "engine"
        }

    companion object {
        /** The pool an identifier names, or null for one that names none. The Swift `init?(id:)`. */
        fun fromId(id: String): RatedPool? {
            // Split once at the first full stop, as Swift's `split(separator:
            // maxSplits: 1)` does: leading stops are skipped, and what follows
            // the split is kept whole — or is absent when nothing follows.
            val start = id.indexOfFirst { it != '.' }
            if (start < 0) return null
            val stop = id.indexOf('.', start)
            val first = if (stop < 0) id.substring(start) else id.substring(start, stop)
            val rest = if (stop < 0 || stop + 1 >= id.length) null else id.substring(stop + 1)

            return when {
                first == "engine" -> Engine
                first == "training" && rest != null -> TrainingMode.fromRawValue(rest)?.let { Training(it) }
                first == "rush" && rest != null -> swiftInt(rest)?.let { Rush(it) }
                first == "online" && rest != null -> swiftInt(rest)?.let { Online(it) }
                else -> null
            }
        }
    }
}

/**
 * A rating and what it was earned on.
 *
 * The count is not decoration: it sets how hard the next result moves the
 * number, so a settled rating in one pool must not steady a fresh one in
 * another. That is the whole reason these are kept apart rather than shared.
 */
@Serializable
data class PoolRating(
    val rating: Int = 1200,
    val games: Int = 0,
    /**
     * Online only: how sure the rating is (Glicko's RD) as of `lastPlayed`.
     * Absent from files before Glicko, and then taken from the game count.
     */
    @Serializable(with = SwiftDoubleSerializer::class) val deviation: Double? = null,
    @Serializable(with = SwiftDateSerializer::class) val lastPlayed: Double? = null,
)

/** One scheduled item in the spaced-repetition queue. */
@Serializable
data class ReviewCard(
    @Serializable(with = SwiftDoubleSerializer::class) val ease: Double,
    val intervalDays: Int,
    @Serializable(with = SwiftDateSerializer::class) val due: Double,
    val repetitions: Int,
    val lapses: Int,
    val lastSolved: Boolean,
) {
    internal constructor(now: Double) : this(
        ease = 2.5,
        intervalDays = 0,
        due = now,
        repetitions = 0,
        lapses = 0,
        lastSolved = false,
    )
}

@Serializable
data class ThemeRecord(
    val seen: Int = 0,
    val solved: Int = 0,
) {
    val accuracy: Double get() = if (seen == 0) 0.0 else solved.toDouble() / seen.toDouble()

    /**
     * Upper end of a Wilson interval for the accuracy.
     *
     * Ranking motifs by raw accuracy makes small samples shout: one missed
     * puzzle reads as "0% — your worst weakness". The upper bound asks the
     * more useful question — how good could you plausibly be at this? — so a
     * motif only rises to the top once there is evidence you are truly worse.
     */
    val ceiling: Double
        get() {
            if (seen <= 0) return 1.0
            val z = 1.0
            val p = accuracy
            val n = seen.toDouble()
            val denominator = 1 + z * z / n
            val centre = p + z * z / (2 * n)
            val margin = z * sqrt((p * (1 - p) + z * z / (4 * n)) / n)
            return minOf(1.0, (centre + margin) / denominator)
        }
}

@Serializable
data class GameRecord(
    @Serializable(with = SwiftDateSerializer::class) val playedAt: Double,
    val result: String,       // "win", "draw", "loss"
    val accuracy: Int,
    val blunders: Int,
    val opponentElo: Int,
)

/**
 * How far into a recording somebody got, and when.
 *
 * Kept per game rather than as a single "last watched", because the library is
 * nine hundred games and a person dips in and out of several. The date is what
 * makes a history: the list can be ordered by when a game was last opened
 * without keeping a separate log of openings.
 */
@Serializable
data class WatchMark(
    /** Half-moves played, counted from the start of the game. */
    val ply: Int,
    /**
     * Half-moves in the whole game, so a fraction can be shown without
     * looking the game up again.
     */
    val of: Int,
    @Serializable(with = SwiftDateSerializer::class) val at: Double,
) {
    /**
     * Nought to one. A game watched to the last move is finished, and one
     * stopped in the opening is barely started.
     */
    val fraction: Double
        get() {
            if (of <= 0) return 0.0
            return minOf(1.0, ply.toDouble() / of.toDouble())
        }

    val isFinished: Boolean get() = of > 0 && ply >= of
}

@Serializable
data class AttemptRecord(
    @Serializable(with = SwiftDateSerializer::class) val at: Double,
    val mode: TrainingMode,
    val itemID: String,
    val correct: Boolean,
    val ratingAfter: Int,
)

/** A motif and how it has gone: what `weakestThemes` and `trainingTargets` list. */
data class ThemeStanding(val name: String, val record: ThemeRecord)

/** A day's work: what `sessionStats` reports. */
data class SessionStats(val attempted: Int, val solved: Int, val accuracy: Double)

/**
 * Everything the trainer remembers about you. Serializable so it is one file
 * on disk, and a value so a view can hold a snapshot without racing.
 *
 * Immutable, where the Swift type is a struct that is changed in place: every
 * function that records something hands back the progress as it is afterwards
 * and leaves this one as it was — `progress = progress.record(...)`. Where the
 * Swift function also returned something, a note on it says where to find it.
 */
@Serializable(with = TrainingProgressSerializer::class)
data class TrainingProgress(
    /**
     * Every rating the player holds, by the pool it was earned in.
     *
     * Keyed by `RatedPool.id` rather than by the pool itself, so the file on
     * disk stays readable and a case can be renamed without wiping anybody's
     * record.
     */
    val pools: Map<String, PoolRating> = emptyMap(),
    val cards: Map<String, ReviewCard> = emptyMap(),
    val themes: Map<String, ThemeRecord> = emptyMap(),
    val history: List<AttemptRecord> = emptyList(),
    val games: List<GameRecord> = emptyList(),
    val rushRecords: List<RushRecord> = emptyList(),
    val eloGuesses: List<EloGuessRecord> = emptyList(),
    // Online play keeps its own rating. It is the only one measured against
    // other people rather than against a library, so mixing it into the
    // training ratings would make both harder to read.
    /**
     * What the free tier has spent today. Absent for anyone who has paid,
     * because nothing counts it.
     */
    val dailyUsage: DailyUsage = DailyUsage(),
    val appearance: Appearance = Appearance(),
    /**
     * Career totals across every clock. The ratings are per clock; these are
     * the tally of games played against people, which is one number a player
     * does think of as one number.
     */
    val onlineWins: Int = 0,
    val onlineLosses: Int = 0,
    val onlineDraws: Int = 0,
    /**
     * When a rated game was last played against each opponent, by player ID.
     * Only one game a day against the same person counts: otherwise two
     * accounts of one's own, playing each other, would climb the rank list.
     */
    val ratedOpponents: Map<String, Double> = emptyMap(),
    /** How far each recording has been watched, keyed by the game's id. */
    val watched: Map<String, WatchMark> = emptyMap(),
    /** Recordings kept aside, keyed by the game's id. */
    val favourites: Set<String> = emptySet(),
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    /** The first moment of the last day anything was recorded, in seconds since the epoch. */
    val lastActiveDay: Double? = null,
) {
    // MARK: - On disk

    /**
     * The progress as the JSON text the file holds: the same keys, shapes and
     * dates as the iPhone app's `JSONEncoder().encode(progress)`.
     */
    fun encode(): String = swiftJson.encodeToString(TrainingProgressSerializer, this)

    // MARK: - Guess the Elo

    /**
     * Records a judged game.
     *
     * The Swift function also returns the verdict; here that is
     * `EloGuess(guess, actual)`, which costs nothing to make.
     */
    fun record(guess: Int, on: String, actual: Int, at: Double = nowSeconds()): TrainingProgress =
        copy(eloGuesses = eloGuesses + EloGuessRecord(at = at, gameID = on, guess = guess, actual = actual))

    val eloGuessStats: EloGuessStats get() = EloGuessStats(eloGuesses)

    // MARK: - The free tier

    /** How many more of this a free account may have today. */
    fun freeRemaining(
        activity: TrainingActivity, at: Double = nowSeconds(), zone: ZoneId = ZoneId.systemDefault(),
    ): Int = dailyUsage.remaining(activity, at = at, zone = zone)

    fun recordFreeUse(
        of: TrainingActivity, at: Double = nowSeconds(), zone: ZoneId = ZoneId.systemDefault(),
    ): TrainingProgress = copy(dailyUsage = dailyUsage.record(of, at = at, zone = zone))

    fun freeTacticsSkipsRemaining(
        at: Double = nowSeconds(), zone: ZoneId = ZoneId.systemDefault(),
    ): Int = dailyUsage.remainingTacticsSkips(at = at, zone = zone)

    fun recordFreeTacticsSkip(
        at: Double = nowSeconds(), zone: ZoneId = ZoneId.systemDefault(),
    ): TrainingProgress = copy(dailyUsage = dailyUsage.recordTacticsSkip(at = at, zone = zone))

    // MARK: - Online play

    // Record a finished online game. The rating change is computed by the
    // session, which is the only place that knows what the opponent was rated.
    // A finished game against a person, at the clock it was played on.
    //
    // The clock is the pool. Somebody who is 1700 at fifteen minutes and 1300
    // at three is not 1500 at either, and the two only ever meet opponents
    // from their own pool — matchmaking has always kept them apart.

    /**
     * Whether a game against this opponent can be rated now: not if a rated
     * one was played against them in the last day.
     */
    fun canRate(against: String, at: Double = nowSeconds()): Boolean {
        if (against.isEmpty()) return true
        val last = ratedOpponents[against] ?: return true
        return at - last >= ratedOpponentWindow
    }

    /**
     * A rated game against this opponent, remembered for a day. Anything
     * older is dropped, so the record never grows past a day's opponents.
     */
    fun noteRated(against: String, at: Double = nowSeconds()): TrainingProgress {
        if (against.isEmpty()) return this
        val kept = LinkedHashMap(ratedOpponents.filter { at - it.value < ratedOpponentWindow })
        kept[against] = at
        return copy(ratedOpponents = kept)
    }

    /**
     * A clock's record as the authority holds it — the rating that counts —
     * kept here too, to show without asking.
     */
    fun adopt(online: OnlineRecord, at: TimeControl): TrainingProgress {
        val held = PoolRating(
            rating = online.rating, games = online.games,
            deviation = online.deviation, lastPlayed = online.lastPlayed,
        )
        return copy(pools = pools + (RatedPool.Online(at.minutes).id to held))
    }

    /**
     * This device's copy of a clock's record: for showing, and for scoring a
     * game only when the authority cannot be asked.
     */
    fun onlineRecord(control: TimeControl): OnlineRecord {
        val pool = RatedPool.Online(control.minutes)
        val held = pools[pool.id] ?: return OnlineRecord.new
        return OnlineRecord(
            rating = held.rating, deviation = held.deviation ?: Glicko.deviation(games = held.games),
            games = held.games, lastPlayed = held.lastPlayed,
        )
    }

    /** A game against a person, counted in the career totals. */
    fun tally(online: MatchResult.Outcome): TrainingProgress = when (online) {
        MatchResult.Outcome.WIN -> copy(onlineWins = onlineWins + 1)
        MatchResult.Outcome.LOSS -> copy(onlineLosses = onlineLosses + 1)
        MatchResult.Outcome.DRAW -> copy(onlineDraws = onlineDraws + 1)
    }

    fun record(online: MatchResult, at: TimeControl, now: Double = nowSeconds()): TrainingProgress {
        val pool = RatedPool.Online(at.minutes)
        val held = pools[pool.id] ?: PoolRating(rating = starting(pool))
        val next = held.copy(
            deviation = online.deviation ?: deviation(pool, at = now),
            lastPlayed = now,
            rating = maxOf(held.rating + online.ratingDelta, Glicko.floor),
            games = held.games + 1,
        )
        return copy(pools = pools + (pool.id to next)).tally(online.outcome)
    }

    // MARK: - Ratings

    fun rating(mode: TrainingMode): Int = rating(RatedPool.Training(mode))

    fun rating(pool: RatedPool): Int = pools[pool.id]?.rating ?: starting(pool)

    /**
     * Where a pool begins, before anything has been played in it.
     *
     * Not 1200 for everything. Somebody who has solved tactics for a month
     * has already told us roughly how hard their first timed run should be,
     * and opening it at 1200 wastes the run on puzzles they can do in their
     * sleep. It is a guess and it is meant to be moved — the count starts at
     * nought, so the first few results shift it hard.
     */
    private fun starting(pool: RatedPool): Int = when (pool) {
        is RatedPool.Rush -> pools[RatedPool.Training(TrainingMode.TACTICS).id]?.rating ?: 1200
        else -> 1200
    }

    fun gamesPlayed(pool: RatedPool): Int = pools[pool.id]?.games ?: 0

    /**
     * How sure an online rating is now: as the last game left it, widened by
     * the time since.
     */
    fun deviation(pool: RatedPool, at: Double = nowSeconds()): Double {
        val held = pools[pool.id] ?: return Glicko.newDeviation
        val base = held.deviation ?: Glicko.deviation(games = held.games)
        val last = held.lastPlayed ?: return base
        return Glicko.deviation(base, idle = at - last)
    }

    /**
     * Moves a pool's rating by one result against a known opponent.
     *
     * The same Elo everywhere, so a rating means the same thing whichever
     * pool it came from — what differs is only who it was earned against.
     *
     * The Swift function also returns the new rating; here that is
     * `rating(pool)` on what this hands back.
     */
    fun settle(pool: RatedPool, against: Int, score: Double): TrainingProgress {
        val held = pools[pool.id] ?: PoolRating(rating = starting(pool))
        val next = held.copy(
            rating = Elo.updated(rating = held.rating, games = held.games, against = against, score = score),
            games = held.games + 1,
        )
        return copy(pools = pools + (pool.id to next))
    }

    /** Tactics dominates practical strength at club level, so it weighs heaviest. */
    val overallRating: Int
        get() = swiftRounded(
            rating(TrainingMode.TACTICS).toDouble() * 0.5 +
                rating(TrainingMode.POSITIONAL).toDouble() * 0.25 +
                rating(TrainingMode.ENDGAME).toDouble() * 0.25
        )

    // MARK: - Recording

    /**
     * Standard Elo. K shrinks as the rating settles, so early sessions find
     * your level quickly and later ones stop jumping around.
     *
     * The rating afterwards is `rating(mode)` on what this hands back.
     */
    internal fun updateRating(mode: TrainingMode, against: Int, correct: Boolean): TrainingProgress {
        val current = rating(mode)
        val played = history.count { it.mode == mode }
        val k = if (played < 20) 60.0 else if (played < 60) 32.0 else 20.0
        val expected = 1 / (1 + 10.0.pow((against - current).toDouble() / 400))
        val next = current.toDouble() + k * ((if (correct) 1.0 else 0.0) - expected)
        val id = RatedPool.Training(mode).id
        val held = pools[id] ?: PoolRating()
        return copy(pools = pools + (id to held.copy(rating = maxOf(400, swiftRounded(next)), games = held.games + 1)))
    }

    /**
     * SM-2, trimmed to the two outcomes a puzzle actually has. A missed puzzle
     * returns tomorrow; a solved one is pushed out by its ease factor. Solving
     * something just as you were about to forget it is what makes it stick.
     */
    internal fun schedule(itemID: String, solved: Boolean, usedHint: Boolean, now: Double): TrainingProgress {
        val card = cards[itemID] ?: ReviewCard(now)
        val ease: Double
        val intervalDays: Int
        var repetitions = card.repetitions
        var lapses = card.lapses

        if (solved) {
            val quality = if (usedHint) 3.0 else 5.0
            ease = maxOf(1.3, card.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
            // The interval is stretched by the ease as it has just become, not as it was.
            intervalDays = if (card.repetitions == 0) {
                1
            } else if (card.repetitions == 1) {
                4
            } else {
                swiftRounded(card.intervalDays.toDouble() * ease)
            }
            repetitions += 1
        } else {
            ease = maxOf(1.3, card.ease - 0.2)
            intervalDays = 1
            lapses += 1
        }

        val next = ReviewCard(
            ease = ease,
            intervalDays = intervalDays,
            due = now + intervalDays.toDouble() * 86_400,
            repetitions = repetitions,
            lapses = lapses,
            lastSolved = solved,
        )
        return copy(cards = cards + (itemID to next))
    }

    fun record(
        mode: TrainingMode,
        itemID: String,
        itemRating: Int,
        correct: Boolean,
        themes: List<String> = emptyList(),
        usedHint: Boolean = false,
        now: Double = nowSeconds(),
        zone: ZoneId = ZoneId.systemDefault(),
    ): TrainingProgress {
        val rated = updateRating(mode, against = itemRating, correct = correct && !usedHint)
        val ratingAfter = rated.rating(mode)
        val scheduled = rated.schedule(itemID, solved = correct, usedHint = usedHint, now = now)

        val records = LinkedHashMap(scheduled.themes)
        for (theme in themes) {
            if (!Themes.isMotif(theme)) continue
            val record = records[theme] ?: ThemeRecord()
            records[theme] = ThemeRecord(seen = record.seen + 1, solved = record.solved + (if (correct) 1 else 0))
        }

        var attempts = scheduled.history +
            AttemptRecord(at = now, mode = mode, itemID = itemID, correct = correct, ratingAfter = ratingAfter)
        if (attempts.size > 2000) attempts = attempts.drop(attempts.size - 2000)
        return scheduled.copy(themes = records, history = attempts).bumpStreak(now, zone)
    }

    /**
     * A finished game against the engine.
     *
     * Rated, and in a pool of its own. The engine's strength is chosen rather
     * than met, which makes this a different measurement from a rating earned
     * against people — but it is a measurement: the opponent's rating is known
     * exactly, which is more than can be said for most games.
     */
    fun record(game: GameRecord, zone: ZoneId = ZoneId.systemDefault()): TrainingProgress {
        var kept = games + game
        if (kept.size > 200) kept = kept.drop(kept.size - 200)
        val score = when (game.result) {
            "win" -> 1.0
            "draw" -> 0.5
            else -> 0.0
        }
        return copy(games = kept)
            .settle(RatedPool.Engine, against = game.opponentElo, score = score)
            .bumpStreak(game.playedAt, zone)
    }

    /**
     * Counts the day `now` falls on towards the streak. A day is a calendar
     * day where `zone` is — the device's own, unless a test says otherwise —
     * which is what `Calendar.current` is to the Swift code.
     */
    internal fun bumpStreak(now: Double, zone: ZoneId = ZoneId.systemDefault()): TrainingProgress {
        val today = startOfDay(now, zone)
        val last = lastActiveDay?.let { startOfDay(it, zone) }
            ?: return copy(currentStreak = 1, bestStreak = maxOf(bestStreak, 1), lastActiveDay = today)
        if (today == last) return this

        val dayGap = ChronoUnit.DAYS.between(localDate(last, zone), localDate(today, zone))
        val streak = if (dayGap == 1L) currentStreak + 1 else 1
        return copy(currentStreak = streak, bestStreak = maxOf(bestStreak, streak), lastActiveDay = today)
    }

    // MARK: - Reporting

    fun hasSeen(itemID: String): Boolean = cards[itemID] != null

    /**
     * Everything whose interval has elapsed — missed items that come back the
     * next day, and solved ones resurfacing later. Solved cards have to return
     * too, or the schedule is only a penalty box rather than a memory system.
     */
    fun dueItemIDs(now: Double = nowSeconds()): List<String> =
        cards.filter { it.value.due <= now }.map { it.key }

    fun weakestThemes(limit: Int = 6, minimumSeen: Int = 3): List<ThemeStanding> =
        themes.filter { it.value.seen >= minimumSeen }
            .entries.sortedBy { it.value.ceiling }
            .take(maxOf(limit, 0))
            .map { ThemeStanding(name = it.key, record = it.value) }

    /**
     * The motifs worth aiming puzzles at: those measurably below your own
     * average. Compared against your own baseline rather than a fixed number,
     * because a 60% solver and an 85% solver need different thresholds.
     */
    fun trainingTargets(minimumSeen: Int = 4, margin: Double = 0.05, limit: Int = 6): List<ThemeStanding> {
        val candidates = themes.filter { it.value.seen >= minimumSeen }
        if (candidates.size < 3) return emptyList()  // too early to know anything

        val solved = candidates.values.sumOf { it.solved }
        val seen = candidates.values.sumOf { it.seen }
        if (seen <= 0) return emptyList()
        val baseline = solved.toDouble() / seen.toDouble()

        return candidates.filter { it.value.ceiling < baseline - margin }
            .entries.sortedBy { it.value.ceiling }
            .take(maxOf(limit, 0))
            .map { ThemeStanding(name = it.key, record = it.value) }
    }

    /** What was attempted since the first moment of the day `on` falls on, where `zone` is. */
    fun sessionStats(on: Double = nowSeconds(), zone: ZoneId = ZoneId.systemDefault()): SessionStats {
        val start = startOfDay(on, zone)
        val todays = history.filter { it.at >= start }
        val solved = todays.count { it.correct }
        return SessionStats(
            attempted = todays.size,
            solved = solved,
            accuracy = if (todays.isEmpty()) 0.0 else solved.toDouble() / todays.size.toDouble(),
        )
    }

    // MARK: - Runs, recordings

    /**
     * Best timed run per duration, so a three-minute record is not compared
     * against a ten-minute one.
     */
    val rushRecordsByDuration: Map<Int, RushRecord>
        get() {
            val result = LinkedHashMap<Int, RushRecord>()
            for (record in rushRecords) {
                val key = record.duration.toInt()
                val existing = result[key]
                if (existing != null && existing.solved >= record.solved) continue
                result[key] = record
            }
            return result
        }

    /**
     * Remembers where a recording was left.
     *
     * Only ever forward: scrubbing back to look at a move again is not
     * un-watching the game, and a list that forgot half a game because
     * somebody rewound would be worse than one that never remembered.
     */
    fun mark(watched: String, ply: Int, of: Int, at: Double = nowSeconds()): TrainingProgress {
        val marks = LinkedHashMap(this.watched)
        val reached = maxOf(ply, marks[watched]?.ply ?: 0)
        marks[watched] = WatchMark(ply = reached, of = of, at = at)
        if (marks.size > 400) {
            // Oldest first, so what goes is what has not been looked at.
            val stale = marks.entries.sortedBy { it.value.at }
                .take(marks.size - 400).map { it.key }
            for (key in stale) marks.remove(key)
        }
        return copy(watched = marks)
    }

    fun watchMark(game: String): WatchMark? = watched[game]

    fun isFavourite(game: String): Boolean = favourites.contains(game)

    fun toggleFavourite(game: String): TrainingProgress =
        copy(favourites = if (favourites.contains(game)) favourites - game else favourites + game)

    fun record(rush: RushRecord, attempts: List<RushAttempt> = emptyList()): TrainingProgress {
        var records = rushRecords + rush
        if (records.size > 100) records = records.drop(records.size - 100)

        // Rated per puzzle rather than per run: a run is not one contest with
        // one opponent, it is forty of them, and each puzzle knows its own
        // rating. Its own pool, and one per length — a three-minute run and a
        // ten-minute run are different tests of the same eyes.
        val pool = RatedPool.Rush(minutes = rush.duration.toInt() / 60)
        var next = copy(rushRecords = records)
        for (attempt in attempts) {
            next = next.settle(pool, against = attempt.rating, score = if (attempt.solved) 1.0 else 0.0)
        }
        return next
    }

    companion object {
        /** How long a rated game against someone keeps the next one unrated. */
        const val ratedOpponentWindow: Double = 24 * 3600.0

        /**
         * Reads a progress file: one this app wrote, one the iPhone app wrote,
         * or one from a build of either that knew less than this one.
         *
         * Throws `SerializationException` for text that is not a progress file
         * at all. See [decodeOrNull] for the caller that would rather start
         * afresh than be told.
         */
        fun decode(text: String): TrainingProgress = swiftJson.decodeFromString(TrainingProgressSerializer, text)

        /** [decode], or null when the text cannot be read. */
        fun decodeOrNull(text: String): TrainingProgress? =
            try {
                decode(text)
            } catch (_: SerializationException) {
                null
            } catch (_: IllegalArgumentException) {
                null
            }
    }
}

/**
 * The file as it lies on disk.
 *
 * Written out by these names, and read by them plus the two the ratings used
 * to live under. `ratings` and `onlineRating` are no longer stored — they are
 * listed so a file from before the split can still be read.
 *
 * Every field is optional, so a file written by an older build still loads.
 * Requiring them would mean that adding one field throws away everything the
 * file held: ratings, streak, review schedule. Silently, because the caller
 * only sees a failure and starts fresh. A missing key here means the feature
 * did not exist yet, which is exactly what a default value is for.
 */
@Serializable
private class ProgressFile(
    val pools: Map<String, PoolRating>? = null,
    val cards: Map<String, ReviewCard>? = null,
    val themes: Map<String, ThemeRecord>? = null,
    val history: List<AttemptRecord>? = null,
    val games: List<GameRecord>? = null,
    val rushRecords: List<RushRecord>? = null,
    val eloGuesses: List<EloGuessRecord>? = null,
    val dailyUsage: DailyUsage? = null,
    val appearance: Appearance? = null,
    val watched: Map<String, WatchMark>? = null,
    val favourites: Set<String>? = null,
    val onlineWins: Int? = null,
    val onlineLosses: Int? = null,
    val onlineDraws: Int? = null,
    val ratedOpponents: Map<String, @Serializable(with = SwiftDateSerializer::class) Double>? = null,
    val currentStreak: Int? = null,
    val bestStreak: Int? = null,
    @Serializable(with = SwiftDateSerializer::class) val lastActiveDay: Double? = null,
    @Serializable(with = ModeRatingsSerializer::class) val ratings: Map<TrainingMode, Int>? = null,
    val onlineRating: Int? = null,
)

/** `[TrainingMode: Int]` as Swift wrote it: `["tactics", 1683, "positional", 1420, "endgame", 1310]`. */
private object ModeRatingsSerializer : SwiftDictionarySerializer<TrainingMode>(
    TrainingMode.serializer(), "com.artesoft.brasspawn.training.ModeRatings",
)

internal object TrainingProgressSerializer : KSerializer<TrainingProgress> {
    override val descriptor: SerialDescriptor =
        SerialDescriptor("com.artesoft.brasspawn.training.TrainingProgress", ProgressFile.serializer().descriptor)

    override fun serialize(encoder: Encoder, value: TrainingProgress) {
        encoder.encodeSerializableValue(
            ProgressFile.serializer(),
            ProgressFile(
                pools = value.pools,
                cards = value.cards,
                themes = value.themes,
                history = value.history,
                games = value.games,
                rushRecords = value.rushRecords,
                eloGuesses = value.eloGuesses,
                dailyUsage = value.dailyUsage,
                appearance = value.appearance,
                watched = value.watched,
                favourites = value.favourites,
                onlineWins = value.onlineWins,
                onlineLosses = value.onlineLosses,
                onlineDraws = value.onlineDraws,
                ratedOpponents = value.ratedOpponents,
                currentStreak = value.currentStreak,
                bestStreak = value.bestStreak,
                lastActiveDay = value.lastActiveDay,
            ),
        )
    }

    override fun deserialize(decoder: Decoder): TrainingProgress {
        val file = decoder.decodeSerializableValue(ProgressFile.serializer())
        var pools = file.pools ?: emptyMap()

        if (pools.isEmpty()) {
            // A file from before the ratings were split. The three training
            // ratings carry over as they are; the one online rating is copied
            // to every clock, because a rating earned at five minutes is a
            // better guess at somebody's three-minute strength than 1200 is.
            //
            // The game counts do *not* carry over. They set how hard the next
            // result moves the number, and the point of splitting is that each
            // clock now has to find its own level — starting each at nought
            // lets it, which is what a fresh pool is for.
            val migrated = LinkedHashMap<String, PoolRating>()
            val old = file.ratings ?: mapOf(
                TrainingMode.TACTICS to 1200, TrainingMode.POSITIONAL to 1200, TrainingMode.ENDGAME to 1200,
            )
            for ((mode, rating) in old) {
                migrated[RatedPool.Training(mode).id] = PoolRating(rating = rating, games = 0)
            }
            val online = file.onlineRating ?: Glicko.starting
            for (control in TimeControl.entries) {
                migrated[RatedPool.Online(control.minutes).id] = PoolRating(rating = online, games = 0)
            }
            pools = migrated
        }

        return TrainingProgress(
            pools = pools,
            cards = file.cards ?: emptyMap(),
            themes = file.themes ?: emptyMap(),
            history = file.history ?: emptyList(),
            games = file.games ?: emptyList(),
            rushRecords = file.rushRecords ?: emptyList(),
            eloGuesses = file.eloGuesses ?: emptyList(),
            dailyUsage = file.dailyUsage ?: DailyUsage(),
            appearance = file.appearance ?: Appearance(),
            onlineWins = file.onlineWins ?: 0,
            onlineLosses = file.onlineLosses ?: 0,
            onlineDraws = file.onlineDraws ?: 0,
            ratedOpponents = file.ratedOpponents ?: emptyMap(),
            watched = file.watched ?: emptyMap(),
            favourites = file.favourites ?: emptySet(),
            currentStreak = file.currentStreak ?: 0,
            bestStreak = file.bestStreak ?: 0,
            lastActiveDay = file.lastActiveDay,
        )
    }
}

/**
 * The ladder. Honest labels for what a puzzle rating means in practice — a
 * puzzle rating is not an over-the-board rating and runs several hundred
 * points above one.
 */
data class LadderRung(
    val id: Int,
    val minimum: Int,
    val name: String,
    val focus: String,
) {
    companion object {
        /**
         * Looked up each time it is asked for, where the Swift list is made
         * once: the app hands this module its strings after it has started,
         * and a list made before then would stay in English.
         */
        val all: List<LadderRung>
            get() = listOf(
                LadderRung(id = 0, minimum = 0, name = L.t("ladder.name0", "Beginner"), focus = L.t("ladder.focus0", "Piece safety, one-move threats, basic mates")),
                LadderRung(id = 1, minimum = 1000, name = L.t("ladder.name1", "Club player"), focus = L.t("ladder.focus1", "Forks, pins, back rank, king-and-pawn endings")),
                LadderRung(id = 2, minimum = 1400, name = L.t("ladder.name2", "Strong club"), focus = L.t("ladder.focus2", "Two-move combinations, rook activity, opposition")),
                LadderRung(id = 3, minimum = 1750, name = L.t("ladder.name3", "Expert"), focus = L.t("ladder.focus3", "Deflection, interference, prophylaxis, Lucena and Philidor")),
                LadderRung(id = 4, minimum = 2050, name = L.t("ladder.name4", "Candidate master"), focus = L.t("ladder.focus4", "Quiet moves, long forcing lines, minor-piece endings")),
                LadderRung(id = 5, minimum = 2300, name = L.t("ladder.name5", "Master"), focus = L.t("ladder.focus5", "Positional sacrifices, defensive resources, technique")),
                LadderRung(id = 6, minimum = 2500, name = L.t("ladder.name6", "Grandmaster range"), focus = L.t("ladder.focus6", "Deep calculation, imbalance evaluation, endgame precision")),
            )

        fun current(rating: Int): LadderRung {
            val rungs = all
            return rungs.lastOrNull { rating >= it.minimum } ?: rungs[0]
        }
    }
}
