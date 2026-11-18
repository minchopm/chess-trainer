package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.match.nowSeconds
import kotlin.math.abs
import kotlin.random.Random

/**
 * Why a particular item was chosen. Shown to the user, because a trainer that
 * silently decides what you practise is indistinguishable from a shuffle —
 * and one you can see reasoning is one you can argue with.
 */
sealed interface SelectionReason {
    /** Due for spaced repetition. */
    data object Review : SelectionReason

    data class Weakness(val motif: String, val accuracy: Double, val seen: Int) : SelectionReason

    /** Simply near your rating. */
    data object Level : SelectionReason

    val explanation: String?
        get() = when (this) {
            Review ->
                L.t("selection.review", "Review — you have seen this one before.")
            is Weakness -> {
                val percent = swiftRounded(accuracy * 100)
                L.t(
                    "selection.chosenForYou", "Chosen for you: %@ — %lld%% of %lld so far.",
                    Themes.readable(motif).lowercase(), percent, seen,
                )
            }
            Level ->
                null
        }
}

data class Selection<Item>(
    val item: Item,
    val reason: SelectionReason,
)

object ItemSelector {
    /** How often a puzzle is chosen to attack a weakness rather than by rating. */
    internal const val targetShare = 0.6

    /**
     * Choose the next tactics puzzle.
     *
     * Three mechanisms, in order of precedence:
     *   1. Spaced repetition — anything due comes back first.
     *   2. Weakness targeting — most of the rest come from motifs you are
     *      measurably worse at than your own average.
     *   3. Difficulty tracking — everything stays near your rating, aimed a
     *      little above it.
     *
     * Targeting deliberately does not apply every time. Drilling only weak
     * motifs stops measuring the rest, and the rating would then drift on
     * stale evidence.
     *
     * `random` is handed a count and returns an index below it; `chance`
     * returns a number from 0 up to but not including 1.
     */
    fun nextPuzzle(
        from: List<Puzzle>,
        progress: TrainingProgress,
        now: Double = nowSeconds(),
        random: (Int) -> Int = { Random.nextInt(it) },
        chance: () -> Double = { Random.nextDouble() },
    ): Selection<Puzzle>? {
        val puzzles = from
        if (puzzles.isEmpty()) return null

        val due = progress.dueItemIDs(now).toSet()
        val dueOnes = puzzles.filter { due.contains(it.id) }
        if (dueOnes.isNotEmpty()) {
            return Selection(item = dueOnes[random(dueOnes.size)], reason = SelectionReason.Review)
        }

        val target = progress.rating(TrainingMode.TACTICS) + 60
        fun inRange(window: Int): List<Puzzle> =
            puzzles.filter { abs(it.rating - target) <= window && !progress.hasSeen(it.id) }

        val targets = progress.trainingTargets()
        if (targets.isNotEmpty() && chance() < targetShare) {
            val wanted = targets.map { it.name }.toSet()
            for (window in listOf(250, 450, 800)) {
                val pool = inRange(window).filter { puzzle -> puzzle.themes.any { it in wanted } }
                if (pool.isNotEmpty()) {
                    val chosen = pool[random(pool.size)]
                    val motif = targets.firstOrNull { chosen.themes.contains(it.name) }
                    if (motif != null) {
                        return Selection(
                            item = chosen,
                            reason = SelectionReason.Weakness(
                                motif = motif.name,
                                accuracy = motif.record.accuracy,
                                seen = motif.record.seen,
                            ),
                        )
                    }
                }
            }
        }

        for (window in listOf(150, 300, 500, 1200)) {
            val pool = inRange(window)
            if (pool.isNotEmpty()) return Selection(item = pool[random(pool.size)], reason = SelectionReason.Level)
        }
        return Selection(item = puzzles[random(puzzles.size)], reason = SelectionReason.Level)
    }

    fun nextExercise(
        from: List<PositionalExercise>,
        progress: TrainingProgress,
        random: (Int) -> Int = { Random.nextInt(it) },
    ): PositionalExercise? {
        val exercises = from
        if (exercises.isEmpty()) return null
        val rating = progress.rating(TrainingMode.POSITIONAL)
        for (window in listOf(200, 400, 700, 2000)) {
            val pool = exercises.filter { abs(it.rating - rating) <= window && !progress.hasSeen(it.id) }
            if (pool.isNotEmpty()) return pool[random(pool.size)]
        }
        return exercises[random(exercises.size)]
    }

    /**
     * Endgame drills are few, so rather than filtering by a window we take the
     * closest handful by rating and pick among them — otherwise the same drill
     * would come up over and over.
     */
    fun nextDrill(
        from: List<EndgameDrill>,
        progress: TrainingProgress,
        random: (Int) -> Int = { Random.nextInt(it) },
    ): EndgameDrill? {
        val drills = from
        if (drills.isEmpty()) return null
        val rating = progress.rating(TrainingMode.ENDGAME)
        val closest = drills.sortedBy { abs(it.rating - rating) }
        val pool = closest.take(5)
        return pool[random(pool.size)]
    }

    // MARK: - Rush

    /**
     * Pick the next puzzle of a run: nearest the target difficulty, not yet
     * seen in this run, and never repeated within it.
     *
     * (An extension in Rush.swift; a member here, so that it is found where
     * the other three are.)
     */
    fun nextRushPuzzle(
        from: List<Puzzle>,
        targetRating: Int,
        excluding: Set<String>,
        random: (Int) -> Int = { Random.nextInt(it) },
    ): Puzzle? {
        val puzzles = from
        val used = excluding
        if (puzzles.isEmpty()) return null
        for (window in listOf(120, 250, 500, 1500)) {
            val pool = puzzles.filter {
                abs(it.rating - targetRating) <= window && !used.contains(it.id)
            }
            if (pool.isNotEmpty()) return pool[random(pool.size)]
        }
        return puzzles.firstOrNull { !used.contains(it.id) }
    }
}
