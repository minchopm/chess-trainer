package com.artesoft.brasspawn.chess

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

/**
 * The conventions the rest of the Android app codes against. Not in the Swift
 * suite, where the compiler and the struct semantics say the same things.
 */
class TypesTests {
    @Test
    fun `Squares run from a1 at nought to h8 at sixty-three`() {
        assertEquals(0, Square.parse("a1")?.index)
        assertEquals(7, Square.parse("h1")?.index)
        assertEquals(28, Square.parse("e4")?.index)
        assertEquals(63, Square.parse("h8")?.index)
        assertEquals(Square.of(file = 4, rank = 3), Square.parse("e4"))
        assertEquals(4, Square(28).file)
        assertEquals(3, Square(28).rank)
        assertEquals("e4", Square(28).name)
        assertEquals("e4", Square(28).toString())
        assertEquals(4, Square(28).relativeRank(PieceColor.WHITE))
        assertEquals(5, Square(28).relativeRank(PieceColor.BLACK))
        for (index in 0 until 64) {
            assertEquals(index, Square.parse(Square(index).name)?.index)
        }
    }

    @Test
    fun `A square that is not one does not parse`() {
        for (text in listOf("", "e", "e44", "i1", "a9", "a0", "E4", "4e")) {
            assertNull(Square.parse(text), text)
        }
    }

    @Test
    fun `Pieces read and print as FEN letters`() {
        assertEquals(Piece(PieceColor.WHITE, PieceKind.KNIGHT), Piece.fromCharacter('N'))
        assertEquals(Piece(PieceColor.BLACK, PieceKind.QUEEN), Piece.fromCharacter('q'))
        assertNull(Piece.fromCharacter('x'))
        assertEquals('N', Piece(PieceColor.WHITE, PieceKind.KNIGHT).character)
        assertEquals('q', Piece(PieceColor.BLACK, PieceKind.QUEEN).character)
        assertEquals(PieceColor.BLACK, PieceColor.WHITE.opponent)
        assertEquals(PieceKind.ROOK, PieceKind.fromLetter('R'))
    }

    @Test
    fun `A move reads from UCI and prints back`() {
        val push = assertNotNull(Move.fromUci("e2e4"))
        assertEquals(Square.parse("e2"), push.from)
        assertEquals(Square.parse("e4"), push.to)
        assertNull(push.promotion)
        assertEquals("e2e4", push.uci)

        val promotion = assertNotNull(Move.fromUci("e7e8q"))
        assertEquals(PieceKind.QUEEN, promotion.promotion)
        assertEquals("e7e8q", promotion.uci)
        assertEquals("e7e8q", promotion.toString())

        for (text in listOf("", "e2", "e2e", "e2e9", "e2e4qq", "e7e8x")) {
            assertNull(Move.fromUci(text), text)
        }
    }

    @Test
    fun `Notation matches a legal move whatever its kind`() {
        val notation = assertNotNull(Move.fromUci("e2e4"))
        val legal = assertNotNull(Position.start.legalMove(notation))
        assertEquals(Move.Kind.DOUBLE_PAWN_PUSH, legal.kind)
        assertTrue(legal.matchesNotation(of = notation))
        assertNotEquals(notation, legal, "the kind is part of a move, and notation does not carry it")
        assertFalse(legal.matchesNotation(of = Move.fromUci("e2e3")!!))
    }

    @Test
    fun `Making a move leaves the position it was made in alone`() {
        val start = Position.start
        val next = start.make(Move.fromUci("e2e4")!!)

        assertEquals(Position.startFen, start.fen)
        assertEquals(PieceColor.WHITE, start.sideToMove)
        assertEquals(Piece(PieceColor.WHITE, PieceKind.PAWN), start.pieceAt(Square.parse("e2")!!))

        assertEquals("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1", next.fen)
        assertEquals(PieceColor.BLACK, next.sideToMove)
        assertNull(next.pieceAt(Square.parse("e2")!!))
        assertEquals(Piece(PieceColor.WHITE, PieceKind.PAWN), next[Square.parse("e4")!!])
        assertEquals(Square.parse("e3"), next.enPassant)
        assertEquals(64, next.squares.size)
    }

    @Test
    fun `A move that is not legal is refused`() {
        val illegal = Move.fromUci("e2e5")!!
        assertNull(Position.start.makeOrNull(illegal))
        assertNull(Position.start.makeUci("e2e5"))
        assertNull(Position.start.makeUci("nonsense"))
        assertFailsWith<IllegalArgumentException> { Position.start.make(illegal) }
        assertEquals(PieceColor.BLACK, Position.start.makeUci("g1f3")?.sideToMove)
    }

    @Test
    fun `The legal moves are worked out once, and by square`() {
        val position = Position.start
        assertSame(position.legalMoves(), position.legalMoves())
        assertEquals(20, position.legalMoves().size)
        assertEquals(listOf("g1f3", "g1h3"), position.legalMoves(Square.parse("g1")!!).map { it.uci }.sorted())
    }

    @Test
    fun `Special moves are played whole`() {
        // Castling moves the rook, and spends both rights.
        val castled = Position.fromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")!!.makeUci("e1g1")!!
        assertEquals("r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1", castled.fen)

        // En passant takes the pawn it passed.
        val taken = Position.fromFen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 2")!!.makeUci("e5d6")!!
        assertEquals("4k3/8/3P4/8/8/8/8/4K3 b - - 0 2", taken.fen)

        // Promotion puts the chosen piece down, and taking a rook on its corner spends its right.
        val promoted = Position.fromFen("r3k3/1P6/8/8/8/8/8/4K3 w q - 0 1")!!.makeUci("b7a8n")!!
        assertEquals("N3k3/8/8/8/8/8/8/4K3 b - - 0 1", promoted.fen)
    }

    @Test
    fun `The hash follows the position, not the road to it`() {
        val oneWay = listOf("g1f3", "g8f6", "b1c3", "b8c6").fold(Position.start) { position, uci -> position.makeUci(uci)!! }
        val another = listOf("b1c3", "b8c6", "g1f3", "g8f6").fold(Position.start) { position, uci -> position.makeUci(uci)!! }
        assertEquals(oneWay.hash, another.hash)
        assertNotEquals(Position.start.hash, oneWay.hash)
        // And it is the hash a position read from its FEN would have.
        assertEquals(Position.fromFen(oneWay.fen)!!.hash, oneWay.hash)
    }

    @Test
    fun `Speculating hands the move to the other side`() {
        val afterE4 = Position.start.makeUci("e2e4")!!
        val sketch = afterE4.speculating(with = PieceColor.WHITE)
        assertEquals(PieceColor.WHITE, sketch.sideToMove)
        assertNull(sketch.enPassant)
        assertEquals(PieceColor.BLACK, afterE4.sideToMove, "and the game itself is untouched")
        assertTrue(sketch.legalMoves().any { it.uci == "f1c4" })
    }

    @Test
    fun `Stalemate and the fifty-move rule are draws`() {
        val stalemate = Position.fromFen("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")!!
        assertTrue(stalemate.isStalemate)
        assertFalse(stalemate.isCheckmate)
        assertTrue(stalemate.isDraw)
        assertTrue(stalemate.isGameOver)

        val fifty = Position.fromFen("4k3/8/8/8/8/8/8/R3K3 w - - 100 80")!!
        assertTrue(fifty.isFiftyMoveRule)
        assertTrue(fifty.isDraw)
    }

    @Test
    fun `Move values measure a move against the best`() {
        val values = MoveValues(byMove = mapOf("e2e4" to 30, "a2a3" to -15), best = 30)
        assertEquals(0, values.loss("e2e4"))
        assertEquals(45, values.loss("a2a3"))
        assertNull(values.loss("h2h4"))
        assertEquals(-15, values.score("a2a3"))
    }
}
