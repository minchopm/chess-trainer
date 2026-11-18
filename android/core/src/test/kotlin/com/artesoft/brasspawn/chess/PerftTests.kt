package com.artesoft.brasspawn.chess

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

/**
 * The six standard perft positions. Between them they cover castling both
 * sides, castling rights lost to rook captures, en passant including the
 * discovered-check case, promotion and under-promotion, and stalemate.
 *
 * The same depths as the Swift suite: the deepest of them walks a few million
 * positions, which the JVM does in about a second.
 */
class PerftTests {
    private fun perftMatches(name: String, fen: String, vararg expected: Long) {
        val position = assertNotNull(Position.fromFen(fen), "FEN should parse: $name")
        for ((index, count) in expected.withIndex()) {
            val depth = index + 1
            val actual = position.perft(depth)
            assertEquals(count, actual, "$name depth $depth: got $actual, expected $count")
        }
    }

    @Test
    fun `starting position`() = perftMatches(
        "starting position",
        Position.startFen,
        20, 400, 8902, 197_281, 4_865_609,
    )

    @Test
    fun kiwipete() = perftMatches(
        "kiwipete",
        "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
        48, 2039, 97_862, 4_085_603,
    )

    @Test
    fun `endgame with en passant`() = perftMatches(
        "endgame with en passant",
        "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
        14, 191, 2812, 43_238, 674_624,
    )

    @Test
    fun `promotion and pins`() = perftMatches(
        "promotion and pins",
        "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
        6, 264, 9467,
    )

    @Test
    fun `under-promotion`() = perftMatches(
        "under-promotion",
        "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
        44, 1486, 62_379,
    )

    @Test
    fun `dense middlegame`() = perftMatches(
        "dense middlegame",
        "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
        46, 2079, 89_890,
    )

    @Test
    fun `The per-move breakdown adds up to the whole`() {
        val divided = Position.start.perftDivide(3)
        assertEquals(20, divided.size)
        assertEquals(8902, divided.sumOf { it.nodes })
        assertEquals(divided.map { it.move }.sorted(), divided.map { it.move })
        assertEquals(PerftCount("a2a3", 380), divided.first())
    }
}
