package com.artesoft.brasspawn.chess

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Reading a pasted game. */
class GameImportTests {
    private fun read(text: String): GameImport = assertNotNull(GameImport.read(text), "should read: $text")

    @Test
    fun `Bare moves, the way a book prints them`() {
        val read = read("1. e4 e5 2. Nf3 Nc6 3. Bb5")
        assertEquals(5, read.moves.size)
        assertNull(read.stoppedAt)
        assertEquals(PieceColor.BLACK, read.final.sideToMove)
    }

    @Test
    fun `Moves with no numbering at all`() {
        val read = read("e4 e5 Nf3 Nc6")
        assertEquals(4, read.moves.size)
    }

    @Test
    fun `A number stuck to its move`() {
        val read = read("1.e4 e5 2.Nf3 Nc6")
        assertEquals(4, read.moves.size)
    }

    /** What actually comes off a website. */
    @Test
    fun `A full PGN, headers, comments, variations and result`() {
        val pgn = """
            [Event "Paris"]
            [Site "Paris FRA"]
            [Result "1-0"]

            1. e4 e5 {the old way} 2. Nf3 (2. f4 exf4 is the gambit) 2... Nc6 $1
            3. Bb5 a6 1-0
        """.trimIndent()
        val read = read(pgn)
        assertEquals(6, read.moves.size, "got ${read.moves.size}")
        assertNull(read.stoppedAt)
    }

    /** A variation is somebody else's idea about a move that was not played. */
    @Test
    fun `The variation is not played`() {
        val read = read("1. e4 e5 (1... c5 2. Nf3) 2. Nf3")
        assertEquals(3, read.moves.size)
        assertTrue(read.final.fen.startsWith("rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2"))
    }

    @Test
    fun `A game that starts from a FEN header`() {
        // The h-pawn is on h6, not h7: with all three pawns home this is a
        // back-rank mate and the king has nowhere to go, which is what the
        // first draft of this test asked it to do.
        val pgn = """
            [FEN "6k1/5pp1/7p/8/8/8/5PPP/R5K1 w - - 0 1"]

            1. Ra8+ Kh7
        """.trimIndent()
        val read = read(pgn)
        assertTrue(read.start.fen.startsWith("6k1/5pp1"))
        assertEquals(2, read.moves.size)
    }

    @Test
    fun `A FEN pasted on its own is a position with no moves`() {
        val read = read("6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1")
        assertTrue(read.moves.isEmpty())
        assertTrue(read.isEmpty)
        assertTrue(read.final.fen.startsWith("6k1/5ppp"))
    }

    @Test
    fun `UCI moves, the way a log writes them`() {
        val read = read("e2e4 e7e5 g1f3")
        assertEquals(3, read.moves.size)
        assertEquals(listOf("e2e4", "e7e5", "g1f3"), read.moves.map { it.uci })
    }

    /** Twenty-nine moves and a reason beats nothing and no reason. */
    @Test
    fun `A typo stops the line and says where`() {
        val read = read("1. e4 e5 2. Nf3 Qxq9 3. Bb5")
        assertEquals(3, read.moves.size)
        assertEquals("Qxq9", read.stoppedAt?.token)
        assertEquals(3, read.stoppedAt?.afterMoves)
    }

    @Test
    fun `An illegal but well-formed move stops it too`() {
        val read = read("1. e4 e5 2. Nf6")
        assertEquals(2, read.moves.size)
        assertEquals("Nf6", read.stoppedAt?.token)
    }

    @Test
    fun `Nonsense is nothing at all`() {
        assertNull(GameImport.read("hello there"))
        assertNull(GameImport.read(""))
    }

    @Test
    fun `Two readings of the same paste are equal`() {
        assertEquals(read("1. e4 e5 2. Nf3"), read("e4 e5 Nf3"))
        assertEquals(read("1. e4 e5 2. Nf3").hashCode(), read("e4 e5 Nf3").hashCode())
    }

    /** Windows line endings: the headers are still headers and the moves still moves. */
    @Test
    fun `A PGN with carriage returns reads the same`() {
        val read = read("[Event \"Paris\"]\r\n[Result \"1-0\"]\r\n\r\n1. e4 e5 {the old way}\r\n2. Nf3 Nc6 1-0\r\n")
        assertEquals(4, read.moves.size)
        assertNull(read.stoppedAt)
    }
}
