package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.match.L
import kotlin.math.exp

/** How good a move was. */
enum class MoveGrade(val rawValue: String) {
    BEST("best"),
    EXCELLENT("excellent"),
    GOOD("good"),
    INACCURACY("inaccuracy"),
    MISTAKE("mistake"),
    BLUNDER("blunder");

    val label: String
        get() = when (this) {
            BEST -> L.t("grade.best", "Best move")
            EXCELLENT -> L.t("grade.excellent", "Excellent")
            GOOD -> L.t("grade.good", "Good")
            INACCURACY -> L.t("grade.inaccuracy", "Inaccuracy")
            MISTAKE -> L.t("grade.mistake", "Mistake")
            BLUNDER -> L.t("grade.blunder", "Blunder")
        }

    val isMistake: Boolean
        get() = this == INACCURACY || this == MISTAKE || this == BLUNDER

    companion object {
        /** Ceilings on win probability given up, best-first. */
        internal val thresholds: List<Pair<MoveGrade, Double>> = listOf(
            BEST to 0.005, EXCELLENT to 0.02, GOOD to 0.05,
            INACCURACY to 0.10, MISTAKE to 0.20, BLUNDER to Double.POSITIVE_INFINITY,
        )

        fun fromRawValue(rawValue: String): MoveGrade? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

data class MoveAssessment(
    val grade: MoveGrade,
    /** Win probability given up, 0...1. */
    val winProbabilityLost: Double,
    /** Centipawns given up, for readers who think in pawns. */
    val centipawnsLost: Int,
)

object Coach {
    /**
     * Grade a move by how much winning chance it threw away, not by raw
     * centipawns.
     *
     * Losing 100 centipawns when already a queen up barely matters; losing the
     * same 100 in a level position decides the game. Centipawns cannot tell
     * those apart, and a coach that shouts "blunder" when nothing happened
     * stops being worth listening to.
     *
     * Both scores must be from the *mover's* point of view.
     */
    fun assess(before: Int, after: Int, wasEngineChoice: Boolean): MoveAssessment {
        val lost = maxOf(0.0, winProbability(before) - winProbability(after))
        val grade = if (wasEngineChoice) {
            MoveGrade.BEST
        } else {
            MoveGrade.thresholds.first { lost <= it.second }.first
        }
        return MoveAssessment(
            grade = grade,
            winProbabilityLost = lost,
            centipawnsLost = maxOf(0, before - after),
        )
    }

    /** Lichess' logistic fit from centipawns to expected score. */
    fun winProbability(centipawns: Int): Double {
        val clamped = maxOf(-1000, minOf(1000, centipawns)).toDouble()
        return 1 / (1 + exp(-0.00368208 * clamped))
    }

    /**
     * Accuracy for a whole game, in the usual sense: how close the moves were
     * to engine play. Capped per move so one catastrophe does not swamp an
     * otherwise sound game.
     */
    fun accuracy(centipawnLosses: List<Int>): Int {
        if (centipawnLosses.isEmpty()) return 100
        val average = centipawnLosses.sumOf { minOf(300, it) } / centipawnLosses.size
        return maxOf(0, 100 - average / 3)
    }
}
