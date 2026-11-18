package com.artesoft.brasspawn.chess

/** One line of a perft breakdown: a first move, and the leaves under it. */
data class PerftCount(val move: String, val nodes: Long)

/**
 * Count leaf nodes at a fixed depth.
 *
 * This is the standard way to prove a move generator correct: the counts
 * for well-known positions are published and unforgiving. A generator that
 * mishandles en passant, castling rights or promotion under-promotion will
 * match at depth 1 and diverge by depth 3.
 */
internal fun Position.countLeaves(depth: Int): Long {
    if (depth <= 0) return 1
    val moves = legalMoves()
    if (depth == 1) return moves.size.toLong()

    var total = 0L
    for (move in moves) {
        total += makeUnchecked(move).countLeaves(depth - 1)
    }
    return total
}

/** Per-move breakdown, for locating exactly where a count diverges. */
internal fun Position.divideLeaves(depth: Int): List<PerftCount> =
    legalMoves()
        .map { move -> PerftCount(move.uci, makeUnchecked(move).countLeaves(depth - 1)) }
        .sortedBy { it.move }
