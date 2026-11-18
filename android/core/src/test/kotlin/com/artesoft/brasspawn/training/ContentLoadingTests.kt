package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.Position
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ContentLoadingTests {
    private fun locateDataDirectory(): File {
        var dir: File? = File(System.getProperty("user.dir") ?: ".").canonicalFile
        while (dir != null) {
            val candidate = File(dir, "data")
            if (File(candidate, ContentLibrary.tacticsFile).isFile) return candidate
            dir = dir.parentFile
        }
        error("Could not locate bundled data directory starting from ${System.getProperty("user.dir")}")
    }

    @Test
    fun `All five bundled JSON libraries parse and a 300-puzzle sample plays out legally`() {
        val dataDir = locateDataDirectory()
        for (name in listOf(
            ContentLibrary.tacticsFile,
            ContentLibrary.positionsFile,
            ContentLibrary.endgamesFile,
            ContentLibrary.classicsFile,
            ContentLibrary.gamesFile,
        )) {
            assertTrue(File(dataDir, name).isFile, "Expected bundled file $name in $dataDir")
        }

        val library = ContentLibrary.load(from = dataDir)
        assertTrue(library.puzzles.isNotEmpty(), "tactics.json should yield puzzles")
        assertTrue(library.exercises.isNotEmpty(), "positions.json should yield positional exercises")
        assertTrue(library.drills.isNotEmpty(), "endgames.json should yield endgame drills")
        assertTrue(library.classics.isNotEmpty(), "classics.json should yield classic games")
        assertTrue(library.games.isNotEmpty(), "games.json should yield annotated games")

        val totalPuzzles = library.puzzles.size
        assertTrue(totalPuzzles >= 300, "expected at least 300 puzzles in tactics.json, found $totalPuzzles")

        // Evenly spaced sample of 300 puzzles spanning the full library.
        val sample = (0 until 300).map { index ->
            library.puzzles[(index.toLong() * totalPuzzles / 300).toInt()]
        }
        assertEquals(300, sample.size)

        for (puzzle in sample) {
            var position = assertNotNull(
                Position.fromFen(puzzle.fen),
                "Puzzle ${puzzle.id} FEN did not parse: ${puzzle.fen}",
            )
            assertEquals(puzzle.sideToMove, position.sideToMove, "Puzzle ${puzzle.id} sideToMove mismatch")
            assertTrue(puzzle.solution.isNotEmpty(), "Puzzle ${puzzle.id} has an empty solution")

            for ((ply, uci) in puzzle.solution.withIndex()) {
                val parsed = assertNotNull(
                    Move.fromUci(uci),
                    "Puzzle ${puzzle.id} ply $ply UCI did not parse: $uci",
                )
                position = assertNotNull(
                    position.makeOrNull(parsed),
                    "Puzzle ${puzzle.id} ply $ply move $uci is illegal in ${position.fen}",
                )
            }
        }
    }

    @Test
    fun `Missing or malformed files leave their libraries empty without failing the rest`() {
        val partial = ContentLibrary.load(
            tactics = "not json",
            endgames = """{"drills":[{"id":"e1","name":"Opposition","fen":"4k3/8/4K3/4P3/8/8/8/8 w - - 0 1","goal":"win","rating":1100,"idea":"Take the opposition","themes":["pawnEndgame"]}]}""",
        )
        assertTrue(partial.puzzles.isEmpty())
        assertTrue(partial.exercises.isEmpty())
        assertEquals(1, partial.drills.size)
        assertEquals(EndgameDrill.Goal.WIN, partial.drills[0].goal)
    }

    @Test
    fun `Themes and game metadata format cleanly`() {
        assertEquals("Mate in 2", Themes.readable("mateIn2"))
        assertEquals("Knight fork", Themes.readable("knightFork"))
        assertTrue(Themes.isMotif("knightFork"))
        assertFalse(Themes.isMotif("middlegame"))

        val annotated = AnnotatedGame(
            id = "g1",
            white = 1620,
            black = 1580,
            result = "1-0",
            speed = "Blitz",
            timeControl = "300+3",
            opening = "Sicilian Defense",
            moves = "e2e4 c7c5 g1f3",
        )
        assertEquals(1600, annotated.averageRating)
        assertEquals(listOf("e2e4", "c7c5", "g1f3"), annotated.uciMoves)
        assertEquals("Blitz · 5+3 · Sicilian Defense", annotated.subtitle)
        assertEquals("45s+1", AnnotatedGame.readableClock("45+1"))

        val classic = ClassicGame(
            id = "c1",
            white = "Morphy",
            black = "Duke of Brunswick",
            event = "Paris",
            year = 1858,
            result = "1–0",
            eco = "C41",
            notable = true,
            moves = "e4 e5 Nf3 d6 d4",
        )
        assertEquals("Morphy — Duke of Brunswick", classic.players)
        assertEquals("Paris, 1858 · 1–0", classic.occasion)
        assertEquals(5, classic.plyCount)
        assertEquals(3, classic.moveCount)
        assertTrue(classic.haystack.contains("morphy"))
        assertTrue(classic.haystack.contains("c41"))
    }
}
