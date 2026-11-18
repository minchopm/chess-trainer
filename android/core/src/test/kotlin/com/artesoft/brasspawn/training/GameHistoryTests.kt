package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.chess.GameImport
import com.artesoft.brasspawn.chess.PieceColor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The store for games that were actually played. */
class GameHistoryTests {
    private fun game(
        id: String? = null,
        playedAt: Double = 1_700_000_000.0,
        notation: String = "e4 e5 Nf3 Nc6",
        result: String = "win",
        white: String = "",
        black: String = "Club (1800)",
        yourColor: String? = "white",
    ): SavedGame = SavedGame(
        id = id ?: java.util.UUID.randomUUID().toString().uppercase(),
        playedAt = playedAt,
        notation = notation,
        result = result,
        white = white,
        black = black,
        yourColor = yourColor,
        source = "play",
    )

    @Test
    fun `A game goes in and comes back out`() {
        val history = GameHistory()
        val saved = game()
        history.insert(saved)

        assertEquals(1, history.count)
        assertEquals(1, history.games.size)
        assertEquals(listOf("e4", "e5", "Nf3", "Nc6"), history.games[0].moves)
        assertEquals(4, history.games[0].moveCount)
        assertEquals(saved, SavedGame.decode(saved.encode()))

        val decoded = GameHistory.decode(history.encode())
        assertEquals(history.games, decoded.games)
        assertNull(GameHistory.decodeOrNull("{broken"))
    }

    /**
     * Storing the moves as notation is what lets a saved game go back through
     * the same reader as a pasted one.
     */
    @Test
    fun `The stored notation reads back through the game importer`() {
        val saved = game()
        val imported = assertNotNull(GameImport.read(saved.notation))
        assertEquals(4, imported.moves.size)
    }

    @Test
    fun `A game that began from a set-up position keeps that position`() {
        val fen = "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"
        val saved = SavedGame(
            startFEN = fen,
            notation = "e4",
            result = "*",
            white = "Stockfish",
            black = "Reckless",
            source = "board",
        )
        assertEquals(fen, saved.startPosition.fen)
        assertFalse(saved.isYours)
    }

    /**
     * Your own side is stored empty rather than as the word "You", so a
     * history written while the app was in one language does not read wrong in
     * another.
     */
    @Test
    fun `Your side is named in the language being read, not the one it was played in`() {
        val saved = game()
        assertTrue(saved.white.isEmpty())
        assertTrue(saved.isYours)
        assertEquals("You", saved.name(PieceColor.WHITE))
        assertEquals("Club (1800)", saved.name(PieceColor.BLACK))
        assertEquals("You — Club (1800)", saved.players)
    }

    @Test
    fun `An empty game is still a game`() {
        val saved = game(notation = "")
        assertTrue(saved.moves.isEmpty())
        assertEquals(0, saved.moveCount)
    }

    @Test
    fun `Games come back newest first`() {
        val history = GameHistory()
        val old = game(notation = "e4", playedAt = 1_000.0)
        val recent = game(notation = "d4", playedAt = 2_000.0)
        history.insert(old)
        history.insert(recent)

        assertEquals(listOf("d4", "e4"), history.games.map { it.notation })
    }

    @Test
    fun `Inserting a duplicate id replaces the game, and changes notify listeners`() {
        val history = GameHistory()
        var changes = 0
        history.onChange = { changes += 1 }

        val original = game(id = "G1", notation = "e4", playedAt = 1_000.0)
        val updated = game(id = "G1", notation = "e4 e5", playedAt = 1_000.0)
        history.insert(original)
        history.insert(updated)

        assertEquals(1, history.count)
        assertEquals("e4 e5", history.game("G1")?.notation)
        assertEquals(2, changes)

        assertFalse(history.delete("MISSING"))
        assertEquals(2, changes)
        assertTrue(history.delete("G1"))
        assertEquals(0, history.count)
        assertEquals(3, changes)

        history.insert(original)
        history.deleteAll()
        assertEquals(0, history.count)
        assertEquals(5, changes)
    }
}
