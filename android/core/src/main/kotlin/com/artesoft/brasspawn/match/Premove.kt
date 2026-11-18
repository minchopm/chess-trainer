package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.PieceKind
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square

/**
 * Moves given before it is your turn.
 *
 * A queue rather than a single move, because what a player has in mind while
 * the opponent thinks is usually a short plan — take, recapture, castle — not
 * one isolated reply. Each move is checked against the board that actually
 * arrives, and the first one that cannot be played takes the rest with it: the
 * moves behind it were planned on a position that never happened, so carrying
 * them out would be following a plan whose first step already failed.
 *
 * Immutable, like `Position`: [queue], [clear] and [next] hand back the queue
 * as it is afterwards, where the Swift struct changes in place.
 */
data class PremoveQueue(
    val moves: List<Move> = emptyList(),
    /**
     * True when the queue was thrown away because reality diverged, so the
     * screen can say why the plan vanished instead of leaving it a mystery.
     */
    val wasDropped: Boolean = false,
) {
    val isEmpty: Boolean get() = moves.isEmpty()
    val count: Int get() = moves.size

    /** Every square taking part in the plan, for marking on the board. */
    val squares: List<Square> get() = moves.flatMap { listOf(it.from, it.to) }

    /**
     * The position the next premove is planned against: yours to move, with
     * everything already queued played out and the opponent's pieces left
     * exactly where they stand.
     */
    fun planned(from: Position, side: PieceColor): Position {
        var probe = from.speculating(with = side)
        for (move in moves) {
            val next = probe.makeOrNull(move) ?: break
            probe = next.speculating(with = side)
        }
        return probe
    }

    fun destinations(position: Position, side: PieceColor): Map<Square, List<Square>> {
        if (position.sideToMove == side || position.isGameOver) return emptyMap()
        val map = LinkedHashMap<Square, MutableList<Square>>()
        for (move in planned(position, side).legalMoves()) {
            map.getOrPut(move.from) { ArrayList() }.add(move.to)
        }
        return map
    }

    /**
     * Add a move to the plan. Returns the queue with the move on the end, or
     * null — where the Swift method returns false — when the piece could not
     * make that move even on the board the plan assumes.
     */
    fun queue(from: Square, to: Square, promotion: PieceKind?, position: Position, side: PieceColor): PremoveQueue? {
        if (position.sideToMove == side || position.isGameOver) return null
        val notation = Move(from, to, promotion)
        val move = planned(position, side).legalMove(notation) ?: return null
        return PremoveQueue(moves + move, wasDropped = false)
    }

    fun clear(): PremoveQueue = PremoveQueue()

    /** What [next] hands back: the move to play, if there is one, and the queue without it. */
    data class Next(val move: Move?, val queue: PremoveQueue)

    /**
     * The next move to play, or null — either because nothing is queued, or
     * because what was queued is no longer possible, in which case the whole
     * plan is dropped.
     */
    fun next(position: Position): Next {
        val first = moves.firstOrNull() ?: return Next(null, this)
        val legal = position.legalMove(first)
            ?: return Next(null, PremoveQueue(emptyList(), wasDropped = true))
        return Next(legal, PremoveQueue(moves.drop(1), wasDropped = false))
    }
}
