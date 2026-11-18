package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.match.nowSeconds
import kotlinx.serialization.Serializable

/**
 * A timed run: solve as many puzzles as you can before the clock runs out.
 *
 * The point is different from practice. Practice is about understanding a
 * position; a run is about *recognition* — seeing a pattern before you have
 * time to reason your way to it. That is why the difficulty ramps rather than
 * tracking your rating: the early puzzles should be almost free, so the clock
 * is the opponent rather than the position.
 */
data class RushSettings(
    /** How long the run lasts, in seconds. */
    val duration: Double = 300.0,
    val target: Int = 100,
) {
    companion object {
        val choices: List<Double> = listOf(180.0, 300.0, 600.0)

        fun label(duration: Double): String = "${duration.toInt() / 60} min"
    }
}

/** One puzzle in a run, and how hard it was. */
data class RushAttempt(
    val rating: Int,
    val solved: Boolean,
)

/**
 * A run in progress.
 *
 * Immutable, like `Position` and the clock: [record] hands back the run as it
 * is afterwards, where the Swift struct changes in place.
 */
class RushRun private constructor(
    val settings: RushSettings,
    /** When the run began, in seconds since the epoch. */
    val startedAt: Double,
    /**
     * Every puzzle the run put up, with its rating. Kept because a run is
     * rated the way a session of tactics is — one Elo step per puzzle against
     * that puzzle's own rating — and the rating is only known while the
     * puzzle is on screen.
     */
    val attempts: List<RushAttempt>,
    val solved: Int,
    val missed: Int,
    val streak: Int,
    val bestStreak: Int,
    val attempted: Int,
) {
    constructor(settings: RushSettings, startedAt: Double = nowSeconds()) :
        this(settings, startedAt, attempts = emptyList(), solved = 0, missed = 0, streak = 0, bestStreak = 0, attempted = 0)

    val isOver: Boolean
        get() = missed >= allowedMisses || solved >= settings.target

    val endedByMisses: Boolean get() = missed >= allowedMisses
    val completedTarget: Boolean get() = solved >= settings.target

    fun remaining(at: Double = nowSeconds()): Double =
        maxOf(0.0, settings.duration - (at - startedAt))

    fun hasTimeLeft(at: Double = nowSeconds()): Boolean = remaining(at) > 0

    fun record(solved: Boolean, rating: Int = 1200): RushRun {
        val wasSolved = solved
        val nextStreak = if (wasSolved) streak + 1 else 0
        return RushRun(
            settings = settings,
            startedAt = startedAt,
            attempts = attempts + RushAttempt(rating = rating, solved = wasSolved),
            solved = if (wasSolved) this.solved + 1 else this.solved,
            missed = if (wasSolved) missed else missed + 1,
            streak = nextStreak,
            bestStreak = if (wasSolved) maxOf(bestStreak, nextStreak) else bestStreak,
            attempted = attempted + 1,
        )
    }

    /**
     * Difficulty for the next puzzle in the run.
     *
     * Starts well below your practice rating and climbs past it, so a run
     * opens with recognition you already own and ends somewhere you have to
     * reach for.
     */
    fun targetRating(practiceRating: Int): Int {
        val progress = minOf(attempted, 60).toDouble() / 60
        val floor = practiceRating.toDouble() - 500
        val ceiling = practiceRating.toDouble() + 350
        return (floor + (ceiling - floor) * progress).toInt()
    }

    companion object {
        /**
         * Three misses ends a run early. Without a penalty the fastest strategy is
         * to guess, which trains the opposite of what this is for.
         */
        const val allowedMisses = 3
    }
}

@Serializable
data class RushRecord(
    val solved: Int,
    val bestStreak: Int,
    /** How long the run was set to last, in seconds. */
    @Serializable(with = SwiftDoubleSerializer::class) val duration: Double,
    @Serializable(with = SwiftDateSerializer::class) val achievedAt: Double,
)

// `ItemSelector.nextRushPuzzle`, which Rush.swift adds in an extension, is in
// Selection.kt with the selector's other three.
