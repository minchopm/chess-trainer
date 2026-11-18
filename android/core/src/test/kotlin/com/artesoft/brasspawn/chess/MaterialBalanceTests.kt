package com.artesoft.brasspawn.chess

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/** Material balance. */
class MaterialBalanceTests {
    @Test
    fun `Nothing is captured in the starting position`() {
        val material = MaterialBalance(Position.start)
        assertTrue(material.capturedBy(PieceColor.WHITE).isEmpty())
        assertTrue(material.capturedBy(PieceColor.BLACK).isEmpty())
        assertEquals(0, material.lead(of = PieceColor.WHITE))
        assertEquals(0, material.lead(of = PieceColor.BLACK))
    }

    @Test
    fun `A missing piece is credited to the side that took it`() {
        // White is a knight and a pawn down, Black a rook down.
        val fen = "1nbqkbnr/pppppppp/8/8/8/8/PPPPPPP1/R1BQKBNR w KQk - 0 1"
        val position = assertNotNull(Position.fromFen(fen))
        val material = MaterialBalance(position)

        assertEquals(listOf(PieceKind.KNIGHT, PieceKind.PAWN), material.capturedBy(PieceColor.BLACK))
        assertEquals(listOf(PieceKind.ROOK), material.capturedBy(PieceColor.WHITE))
        // Rook 5 against knight 3 plus pawn 1.
        assertEquals(1, material.lead(of = PieceColor.WHITE))
        assertEquals(0, material.lead(of = PieceColor.BLACK))
    }

    @Test
    fun `A promoted pawn does not read as a captured queen`() {
        // Two white queens, seven white pawns: one pawn promoted, nothing taken.
        val fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPP1/RNBQKBNQ w kq - 0 1"
        val position = assertNotNull(Position.fromFen(fen))
        val material = MaterialBalance(position)

        assertEquals(listOf(PieceKind.ROOK, PieceKind.PAWN), material.capturedBy(PieceColor.BLACK))
        assertTrue(material.capturedBy(PieceColor.WHITE).isEmpty())
    }

    @Test
    fun `Two balances are equal when the same pieces are on the board`() {
        val afterE4 = Position.start.makeUci("e2e4")!!
        assertEquals(MaterialBalance(Position.start), MaterialBalance(afterE4))
        assertEquals(MaterialBalance(Position.start).hashCode(), MaterialBalance(afterE4).hashCode())
        val rookDown = Position.fromFen("1nbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQk - 0 1")!!
        assertNotEquals(MaterialBalance(Position.start), MaterialBalance(rookDown))
    }
}
