package com.artesoft.brasspawn.training

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EloGuessTests {
    @Test
    fun `A guess is scored against the average of the two players`() {
        val guess = EloGuess(guess = 1600, actual = 1550)
        assertEquals(50, guess.error)
        assertTrue(guess.isHigh)
        assertEquals(EloGuess.Verdict.SPOT, guess.verdict)
        assertEquals(90, guess.points)
        assertEquals("50 points too high.", guess.summary)
    }

    @Test
    fun `White and black guesses are scored independently`() {
        val guess = EloPairGuess(
            whiteGuess = 1700,
            blackGuess = 1400,
            whiteActual = 1600,
            blackActual = 1600,
        )

        assertEquals(100, guess.white.error)
        assertEquals(200, guess.black.error)
        assertEquals(150, guess.averageError)
        assertEquals(EloGuess.Verdict.FAIR, guess.verdict)
        assertEquals(70, guess.points)
        assertEquals("Average miss: 150 points.", guess.summary)

        val spotOn = EloPairGuess(whiteGuess = 1605, blackGuess = 1595, whiteActual = 1600, blackActual = 1600)
        assertEquals("Both ratings were spot on.", spotOn.summary)

        val record = EloGuessRecord(
            at = 1_700_000_000.0,
            gameID = "pair",
            whiteGuess = 1700,
            whiteActual = 1600,
            blackGuess = 1400,
            blackActual = 1600,
        )
        assertEquals(150, record.error)
        assertEquals(-50, record.bias)
    }

    @Test
    fun `Verdicts widen in bands, not by a hair`() {
        val deadOn = EloGuess(guess = 1500, actual = 1500)
        assertEquals(EloGuess.Verdict.SPOT, deadOn.verdict)
        assertEquals("Dead on.", deadOn.summary)
        assertEquals("Spot on", deadOn.verdict.title)

        val low = EloGuess(guess = 1400, actual = 1500)
        assertFalse(low.isHigh)
        assertEquals(EloGuess.Verdict.CLOSE, low.verdict)
        assertEquals("100 points too low.", low.summary)

        assertEquals(EloGuess.Verdict.CLOSE, EloGuess(guess = 1600, actual = 1500).verdict)
        assertEquals(EloGuess.Verdict.FAIR, EloGuess(guess = 1750, actual = 1500).verdict)
        assertEquals(EloGuess.Verdict.OFF, EloGuess(guess = 2000, actual = 1500).verdict)
        // Five hundred out is worth nothing, and nothing is the floor.
        assertEquals(0, EloGuess(guess = 2200, actual = 1500).points)
        assertEquals(600..2800, EloGuess.range)
        assertEquals(25, EloGuess.step)
    }

    @Test
    fun `Statistics report the miss and the direction of it`() {
        val empty = EloGuessStats(emptyList())
        assertEquals(0, empty.judged)
        assertEquals(0, empty.averageError)
        assertEquals(0, empty.bestError)
        assertEquals(0, empty.bias)

        val stats = EloGuessStats(
            listOf(
                EloGuessRecord(at = 1_000.0, gameID = "a", guess = 1700, actual = 1500),
                EloGuessRecord(at = 2_000.0, gameID = "b", guess = 1600, actual = 1500),
                EloGuessRecord(at = 3_000.0, gameID = "c", guess = 1500, actual = 1500),
            )
        )
        assertEquals(3, stats.judged)
        assertEquals(100, stats.averageError)
        assertEquals(0, stats.bestError)
        // Consistently high, which is the useful half of the report.
        assertEquals(100, stats.bias)
    }

    @Test
    fun `A judged game is remembered`() {
        val progress = TrainingProgress().record(guess = 1450, on = "gabc", actual = 1500, at = 1_700_000_000.0)
        val verdict = EloGuess(guess = 1450, actual = 1500)
        assertEquals(50, verdict.error)
        assertEquals(1, progress.eloGuesses.size)
        assertEquals(50, progress.eloGuessStats.averageError)

        val roundTripped = TrainingProgress.decode(progress.encode())
        assertEquals(progress.eloGuesses, roundTripped.eloGuesses)
    }

    @Test
    fun `Progress written by an older build still loads`() {
        // Everything Guess the Elo added is missing here, as it would be in a
        // file written before the mode existed. The ratings must survive.
        val json = """
            {"cards":{},"themes":{},"history":[],"games":[],"rushRecords":[],
             "currentStreak":4,"bestStreak":9,
             "ratings":["tactics",1683,"positional",1420,"endgame",1310]}
        """.trimIndent()
        val progress = TrainingProgress.decode(json)

        assertEquals(1683, progress.rating(TrainingMode.TACTICS))
        assertEquals(1420, progress.rating(TrainingMode.POSITIONAL))
        assertEquals(1310, progress.rating(TrainingMode.ENDGAME))
        assertEquals(4, progress.currentStreak)
        assertEquals(9, progress.bestStreak)
        assertTrue(progress.eloGuesses.isEmpty())
    }
}
