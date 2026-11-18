package com.artesoft.brasspawn.chess

/**
 * The material story of a position: what has been taken, and who is ahead.
 *
 * Counted against the standard starting set rather than against the position
 * the exercise began in. A puzzle FEN is a snapshot of a real game, and what
 * the two rows beside the board are for is reading that game — "Black is a
 * rook up but White has three pawns for it" — not the handful of plies since
 * the puzzle loaded.
 */
class MaterialBalance(position: Position) {
    /** How many of each kind each colour has on the board, by colour times six plus kind. */
    private val counts = IntArray(12)

    init {
        for (index in 0 until 64) {
            val piece = position.pieceAt(Square(index)) ?: continue
            counts[piece.color.ordinal * 6 + piece.kind.ordinal] += 1
        }
    }

    /**
     * The pieces `color` has captured from the opponent, heaviest first.
     *
     * Under-promotion and a second queen make a colour hold more of a kind
     * than it started with; the surplus is clamped away rather than reported
     * as a negative capture.
     */
    fun capturedBy(color: PieceColor): List<PieceKind> {
        val captured = ArrayList<PieceKind>()
        for ((kind, full) in fullSet) {
            repeat(maxOf(0, full - held(color.opponent, kind))) { captured.add(kind) }
        }
        return captured
    }

    /**
     * How many points `color` is ahead by, counting what is on the board.
     * Zero when level or behind, so a row can show a lead without showing a
     * deficit the other row already states.
     */
    fun lead(of: PieceColor): Int = maxOf(0, total(of) - total(of.opponent))

    private fun held(color: PieceColor, kind: PieceKind): Int = counts[color.ordinal * 6 + kind.ordinal]

    private fun total(color: PieceColor): Int = PieceKind.entries.sumOf { held(color, it) * points(it) }

    override fun equals(other: Any?): Boolean = other is MaterialBalance && counts.contentEquals(other.counts)

    override fun hashCode(): Int = counts.contentHashCode()

    companion object {
        /**
         * Classic teaching values. `PieceKind.value` separates bishop from knight,
         * which is right for an engine explanation and wrong for a scoreboard:
         * nobody reads a material lead as "+0.25".
         */
        private fun points(kind: PieceKind): Int = when (kind) {
            PieceKind.PAWN -> 1
            PieceKind.KNIGHT -> 3
            PieceKind.BISHOP -> 3
            PieceKind.ROOK -> 5
            PieceKind.QUEEN -> 9
            PieceKind.KING -> 0
        }

        /** Heaviest first, so the piece that decides the balance leads the row. */
        private val fullSet: List<Pair<PieceKind, Int>> = listOf(
            PieceKind.QUEEN to 1, PieceKind.ROOK to 2, PieceKind.BISHOP to 2, PieceKind.KNIGHT to 2, PieceKind.PAWN to 8,
        )
    }
}
