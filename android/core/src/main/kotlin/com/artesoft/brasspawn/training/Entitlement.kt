package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.match.nowSeconds
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * The parts of the app a subscription unlocks.
 *
 * Playing — against the engine or against a person — is not on this list and
 * never will be. A trainer that will not let you play chess is a demo, and the
 * online games cost nothing to run. What is sold is the training: the puzzle
 * library, the judgement exercises, the drills and the run.
 */
@Serializable
enum class TrainingActivity(val rawValue: String) {
    @SerialName("tactics") TACTICS("tactics"),
    @SerialName("rush") RUSH("rush"),
    @SerialName("positional") POSITIONAL("positional"),
    @SerialName("endgame") ENDGAME("endgame"),
    @SerialName("guessTheElo") GUESS_THE_ELO("guessTheElo");

    /**
     * How many of these a free account gets each day.
     *
     * Five of each, and the same five everywhere. Enough to feel the loop and
     * watch the rating move, which is the only thing that makes the paid tier
     * worth buying — one of something shows a person the door and nothing
     * behind it, and a rating that never moves is not a reason to pay.
     *
     * Counted on the attempt, never on opening the screen: browsing the
     * library, reading a position and changing your mind cost nothing.
     */
    val dailyFreeLimit: Int get() = 5

    companion object {
        fun fromRawValue(rawValue: String): TrainingActivity? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

/**
 * What a free account has used today.
 *
 * Counted against a local training day that starts at 09:00. This is a
 * calendar boundary rather than a rolling 24 hours, so it remains 09:00 when
 * the device changes time zone or daylight-saving time begins or ends.
 *
 * Immutable: [record] and [recordTacticsSkip] hand back the usage as it is
 * afterwards. Where the Swift code takes a `Calendar`, this takes the time
 * zone the day is counted in — the device's own unless a test says otherwise.
 */
@Serializable
data class DailyUsage(
    /** When the count was last started afresh, in seconds since the epoch. */
    @Serializable(with = SwiftDateSerializer::class) val day: Double = nowSeconds(),
    @Serializable(with = ActivityCountsSerializer::class) val counts: Map<TrainingActivity, Int> = emptyMap(),
    val tacticsSkips: Int = 0,
) {
    fun used(activity: TrainingActivity, at: Double, zone: ZoneId = ZoneId.systemDefault()): Int =
        if (periodStart(day, zone) == periodStart(at, zone)) counts[activity] ?: 0 else 0

    fun remaining(activity: TrainingActivity, at: Double, zone: ZoneId = ZoneId.systemDefault()): Int =
        maxOf(0, activity.dailyFreeLimit - used(activity, at, zone))

    fun remainingTacticsSkips(at: Double, zone: ZoneId = ZoneId.systemDefault()): Int {
        val used = if (periodStart(day, zone) == periodStart(at, zone)) tacticsSkips else 0
        return maxOf(0, freeTacticsSkips - used)
    }

    fun record(activity: TrainingActivity, at: Double, zone: ZoneId = ZoneId.systemDefault()): DailyUsage {
        val current = resetIfNeeded(at, zone)
        return current.copy(counts = current.counts + (activity to (current.counts[activity] ?: 0) + 1))
    }

    fun recordTacticsSkip(at: Double, zone: ZoneId = ZoneId.systemDefault()): DailyUsage {
        val current = resetIfNeeded(at, zone)
        return current.copy(tacticsSkips = current.tacticsSkips + 1)
    }

    private fun resetIfNeeded(at: Double, zone: ZoneId): DailyUsage {
        if (periodStart(day, zone) == periodStart(at, zone)) return this
        return DailyUsage(day = at, counts = emptyMap(), tacticsSkips = 0)
    }

    companion object {
        const val resetHour = 9
        const val freeTacticsSkips = 2

        /** The next 09:00 boundary where `zone` is, in seconds since the epoch. */
        fun nextReset(after: Double, zone: ZoneId = ZoneId.systemDefault()): Double =
            periodStartTime(after, zone).plusDays(1).toSeconds()

        private fun periodStart(containing: Double, zone: ZoneId): Double =
            periodStartTime(containing, zone).toSeconds()

        /** The 09:00 that began the training day an instant falls in. */
        private fun periodStartTime(containing: Double, zone: ZoneId): ZonedDateTime {
            val todayReset = localDate(containing, zone).atTime(resetHour, 0).atZone(zone)
            if (containing >= todayReset.toSeconds()) return todayReset
            return todayReset.minusDays(1)
        }
    }
}

/** `[TrainingActivity: Int]` as Swift writes it: `["tactics", 3, "rush", 1]`. */
internal object ActivityCountsSerializer : SwiftDictionarySerializer<TrainingActivity>(
    TrainingActivity.serializer(), "com.artesoft.brasspawn.training.ActivityCounts",
)
