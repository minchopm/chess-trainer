package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.Piece
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.PieceKind
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Premoves. */
class PremoveTests {
    private fun square(name: String): Square = Square.parse(name)!!

    /** White has played e4, so Black is to move: White may plan but not play. */
    private fun afterE4(): Position {
        val position = Position.start
        val move = assertNotNull(position.legalMoves().firstOrNull { position.san(it) == "e4" })
        return position.make(move)
    }

    @Test
    fun `A move can be queued while it is the opponent's turn`() {
        val position = afterE4()
        val queue = PremoveQueue().queue(square("g1"), square("f3"), null, position, PieceColor.WHITE)

        assertNotNull(queue)
        assertEquals(1, queue.count)
        assertEquals(listOf(square("g1"), square("f3")), queue.squares)
    }

    @Test
    fun `Nothing is queued on your own turn — that is a move, not a plan`() {
        val queue = PremoveQueue()
        val accepted = queue.queue(square("e2"), square("e4"), null, Position.start, PieceColor.WHITE)

        assertNull(accepted)
        assertTrue(queue.isEmpty)
    }

    @Test
    fun `A plan several moves deep builds on itself`() {
        val position = afterE4()
        val knight = PremoveQueue().queue(square("g1"), square("f3"), null, position, PieceColor.WHITE)
        // f1–c4 needs the e-pawn gone, which it is, and is judged against the
        // board the plan has built rather than the one on screen.
        val bishop = assertNotNull(knight).queue(square("f1"), square("c4"), null, position, PieceColor.WHITE)

        assertNotNull(bishop)
        assertEquals(2, bishop.count)

        val planned = bishop.planned(position, PieceColor.WHITE)
        assertEquals(Piece(PieceColor.WHITE, PieceKind.KNIGHT), planned[square("f3")])
        assertEquals(Piece(PieceColor.WHITE, PieceKind.BISHOP), planned[square("c4")])
    }

    @Test
    fun `The queue plays out when the move is still legal`() {
        var position = afterE4()
        val queue = assertNotNull(PremoveQueue().queue(square("g1"), square("f3"), null, position, PieceColor.WHITE))

        val reply = assertNotNull(position.legalMoves().firstOrNull { position.san(it) == "e5" })
        position = position.make(reply)
        val (played, rest) = queue.next(position)
        val next = assertNotNull(played)

        assertEquals(square("g1"), next.from)
        assertEquals(square("f3"), next.to)
        assertTrue(rest.isEmpty)
        assertFalse(rest.wasDropped)
        assertEquals(1, queue.count, "the queue that was asked is as it was")
    }

    @Test
    fun `A plan whose first step became impossible is dropped whole`() {
        // Black to move, queen and rook facing each other down the d-file.
        // White plans Rxd8; Black takes the rook first.
        var position = assertNotNull(Position.fromFen("3q3k/8/8/8/8/8/6PP/3R2K1 b - - 0 1"))
        val planned = PremoveQueue().queue(square("d1"), square("d8"), null, position, PieceColor.WHITE)
        val queue = assertNotNull(planned)

        val takesTheRook = assertNotNull(position.legalMoves().firstOrNull {
            it.from == square("d8") && it.to == square("d1")
        })
        position = position.make(takesTheRook)
        val (played, rest) = queue.next(position)

        assertNull(played)
        assertTrue(rest.isEmpty)
        assertTrue(rest.wasDropped)
    }

    @Test
    fun `No destinations are offered when it is your move`() {
        val queue = PremoveQueue()
        assertTrue(queue.destinations(Position.start, PieceColor.WHITE).isEmpty())
        assertFalse(queue.destinations(Position.start, PieceColor.BLACK).isEmpty())
    }

    @Test
    fun `Nothing queued is nothing to play, and nothing dropped`() {
        val (played, rest) = PremoveQueue().next(Position.start)
        assertNull(played)
        assertFalse(rest.wasDropped)

        val position = afterE4()
        val queue = assertNotNull(PremoveQueue().queue(square("g1"), square("f3"), null, position, PieceColor.WHITE))
        assertEquals(PremoveQueue(), queue.clear())
    }
}
