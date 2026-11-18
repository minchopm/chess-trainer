package com.artesoft.brasspawn.engine

import kotlin.math.abs
import kotlin.math.exp

/** An evaluation, always from the point of view of the side to move. */
sealed interface EngineScore {
    data class Centipawns(val value: Int) : EngineScore
    data class Mate(val moves: Int) : EngineScore

    /**
     * Flip to the given colour's point of view. UCI always reports from the
     * side to move, which is the wrong frame for anything the user reads.
     */
    fun pointOfView(sideToMove: Boolean): EngineScore = when {
        sideToMove -> this
        this is Centipawns -> Centipawns(-value)
        else -> Mate(-(this as Mate).moves)
    }

    /** Centipawns with mate flattened to a large value, for comparing moves. */
    val comparable: Int
        get() = when (this) {
            is Centipawns -> value
            is Mate -> if (moves > 0) 10_000 - moves else -10_000 - moves
        }

    /**
     * Probability that the side this score favours goes on to win. The
     * logistic fit Lichess uses, which is a far better basis for judging a
     * move than raw centipawns: throwing away 100cp when already a queen up
     * barely matters, and in a level position it decides the game.
     */
    val winProbability: Double
        get() = 1 / (1 + exp(-0.00368208 * comparable.coerceIn(-1000, 1000)))

    val text: String
        get() = when (this) {
            is Mate -> "#$moves"
            is Centipawns -> {
                val pawns = value / 100.0
                (if (pawns >= 0) "+" else "−") + String.format(java.util.Locale.US, "%.2f", abs(pawns))
            }
        }
}

/** One principal variation from a search. */
data class EngineLine(
    /** 1-based; MultiPV order. */
    val rank: Int,
    val depth: Int,
    val score: EngineScore,
    /** UCI. */
    val moves: List<String>,
) {
    val bestMove: String? get() = moves.firstOrNull()
}

data class Analysis(val lines: List<EngineLine>, val bestMove: String?) {
    /** True when the position has no legal moves, so nothing was searched. */
    val isTerminal: Boolean get() = lines.isEmpty()
    val score: EngineScore? get() = lines.firstOrNull()?.score
}

class EngineException(message: String) : Exception(message)

/**
 * How long the engine may think, per kind of question. Both a depth and a time
 * are passed: the search stops at whichever comes first, so easy positions
 * finish early and hard ones cannot keep the player waiting.
 */
data class SearchBudget(val depth: Int, val movetimeMs: Int) {
    companion object {
        /** Grading a move that was just played. Runs twice per move. */
        val coaching = SearchBudget(14, 700)
        /** A hint. The player is waiting and watching, so this is the tightest. */
        val hint = SearchBudget(14, 600)
        /** The engine's own move at full strength. */
        val fullStrength = SearchBudget(20, 2500)
        /** The engine's move when it plays at a given Elo: strength comes from UCI_Elo. */
        val limited = SearchBudget(12, 300)
        /** Judging whether an endgame is still winning or drawn after a move. */
        val verdict = SearchBudget(14, 900)
        /** Scoring a whole position for the judgement exercises. */
        val assessment = SearchBudget(14, 900)
    }
}
