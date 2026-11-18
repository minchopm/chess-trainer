package com.artesoft.brasspawn.chess

/**
 * What every legal move in a position is worth.
 *
 * Here rather than beside the engine that produces it. The board draws these
 * numbers on its squares, and the board has no business linking a chess
 * engine — an App Clip showing a position would have had to carry a hundred
 * megabytes of neural network to draw a label.
 */
data class MoveValues(
    /** Score after each move, in centipawns from the *mover's* point of view. */
    val byMove: Map<String, Int>,
    /** The best score available, for measuring everything else against. */
    val best: Int,
) {
    /** Centipawns given up by playing this move instead of the best one. */
    fun loss(uci: String): Int? = byMove[uci]?.let { maxOf(0, best - it) }

    fun score(uci: String): Int? = byMove[uci]
}
