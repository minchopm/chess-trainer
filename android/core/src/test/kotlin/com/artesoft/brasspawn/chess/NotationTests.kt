package com.artesoft.brasspawn.chess

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class NotationTests {
    private fun parse(fen: String): Position = assertNotNull(Position.fromFen(fen), "FEN should parse: $fen")

    @Test
    fun `FEN round-trips through parsing and printing`() {
        val samples = listOf(
            Position.startFen,
            "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
            "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
            "4k3/8/8/8/8/8/4P3/4K3 b - - 5 39",
        )
        for (fen in samples) {
            assertEquals(fen, parse(fen).fen)
        }
    }

    @Test
    fun `Illegal positions are rejected`() {
        // Side not to move is in check — unreachable in a real game. The web
        // version shipped three hand-written drills with exactly this fault.
        assertNull(Position.fromFen("8/8/8/4k3/8/8/4Q3/4K3 w - - 0 1"))
        assertNull(Position.fromFen("8/8/8/8/8/5k2/5p2/5K1Q w - - 0 1"))
        // Missing a king.
        assertNull(Position.fromFen("8/8/8/4k3/8/8/8/8 w - - 0 1"))
    }

    @Test
    fun `SAN is produced and parsed consistently`() {
        var position = Position.start
        val game = listOf("e4", "e5", "Nf3", "Nc6", "Bb5", "a6", "Ba4", "Nf6", "O-O", "Be7", "Re1", "b5", "Bb3", "d6", "c3", "O-O")
        for (text in game) {
            val move = assertNotNull(position.moveFromSan(text), "should parse $text")
            assertEquals(text, position.san(move))
            position = position.make(move)
        }
        assertEquals(9, position.fullmoveNumber)
    }

    @Test
    fun `Disambiguation names the right piece`() {
        // Two knights on d2 and f2 can both reach e4; the file separates them.
        var position = parse("4k3/8/8/8/8/8/3N1N2/4K3 w - - 0 1")
        val move = assertNotNull(position.moveFromSan("Nde4"))
        assertEquals("Nde4", position.san(move))

        // Rooks on the same file need the rank instead.
        position = parse("4k3/8/8/R7/8/8/R7/4K3 w - - 0 1")
        val rookMove = assertNotNull(position.moveFromSan("R5a4"))
        assertEquals("R5a4", position.san(rookMove))
    }

    @Test
    fun `Checkmate is marked with #, plain check with +`() {
        // Fool's mate: after 1.f3 e5 2.g4, Qh4 is mate.
        var position = parse("rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2")
        val mate = assertNotNull(position.moveFromSan("Qh4"))
        assertEquals("Qh4#", position.san(mate))
        position = position.make(mate)
        assertTrue(position.isCheckmate)
        assertTrue(position.legalMoves().isEmpty())

        // A check that is not mate gets "+".
        var check = parse("4k3/8/8/8/8/8/8/R6K w - - 0 1")
        val rookCheck = assertNotNull(check.moveFromSan("Re1+"))
        assertEquals("Re1+", check.san(rookCheck))
        check = check.make(rookCheck)
        assertTrue(check.isCheck)
        assertFalse(check.isCheckmate)
    }

    @Test
    fun `Threefold repetition is detected`() {
        var position = parse("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")
        // The first cycle changes castling rights, so it is not a repetition of
        // the start. Occurrences two and three come from the cycles after it.
        for (cycle in 0 until 3) {
            assertFalse(position.isThreefoldRepetition, "not before the third cycle is done")
            for (text in listOf("Rh2", "Ke7", "Rh1", "Ke8")) {
                val move = assertNotNull(position.moveFromSan(text), "should parse $text")
                position = position.make(move)
            }
        }
        assertTrue(position.isThreefoldRepetition)
        assertTrue(position.isDraw)
    }

    @Test
    fun `Insufficient material covers the usual cases`() {
        assertTrue(parse("4k3/8/8/8/8/8/8/4K3 w - - 0 1").isInsufficientMaterial)
        assertTrue(parse("4k3/8/8/8/8/8/8/4KN2 w - - 0 1").isInsufficientMaterial)
        assertTrue(parse("4k3/8/8/8/8/8/8/4KB2 w - - 0 1").isInsufficientMaterial)
        assertFalse(parse("4k3/8/8/8/8/8/4P3/4K3 w - - 0 1").isInsufficientMaterial)
        assertFalse(parse("4k3/8/8/8/8/8/8/2B1KB2 w - - 0 1").isInsufficientMaterial)
    }
}
