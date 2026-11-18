package com.artesoft.brasspawn.training

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RushTests {
    private fun puzzle(id: String, rating: Int): Puzzle =
        Puzzle(
            id = id,
            fen = "8/8/8/4k3/8/8/8/R3K3 w - - 0 1",
            solution = listOf("a1a8"),
            themes = listOf("mate"),
            rating = rating,
            mate = true,
            source = null,
        )

    @Test
    fun `A fresh run has its full time`() {
        val started = 1_700_000_000.0
        val run = RushRun(settings = RushSettings(duration = 300.0, target = 100), startedAt = started)
        assertEquals(300.0, run.remaining(at = started))
        assertTrue(run.hasTimeLeft(at = started))
        assertFalse(run.isOver)
        assertFalse(run.endedByMisses)
        assertFalse(run.completedTarget)
    }

    @Test
    fun `The clock runs down from the start time`() {
        val started = 1_700_000_000.0
        val run = RushRun(settings = RushSettings(duration = 300.0), startedAt = started)
        assertEquals(180.0, run.remaining(at = started + 120.0))
        assertTrue(run.hasTimeLeft(at = started + 120.0))
        assertEquals(0.0, run.remaining(at = started + 305.0))
        assertFalse(run.hasTimeLeft(at = started + 305.0))
    }

    @Test
    fun `Three misses ends the run, two do not`() {
        var run = RushRun(settings = RushSettings())
        run = run.record(solved = false)
        run = run.record(solved = false)
        assertFalse(run.isOver)
        assertFalse(run.endedByMisses)

        run = run.record(solved = false)
        assertTrue(run.isOver)
        assertTrue(run.endedByMisses)
        assertFalse(run.completedTarget)
    }

    @Test
    fun `Reaching the target ends the run`() {
        var run = RushRun(settings = RushSettings(duration = 300.0, target = 3))
        repeat(2) { run = run.record(solved = true) }
        assertFalse(run.isOver)

        run = run.record(solved = true)
        assertTrue(run.isOver)
        assertTrue(run.completedTarget)
        assertFalse(run.endedByMisses)
    }

    @Test
    fun `Streaks reset on a miss and remember their best`() {
        val initial = RushRun(settings = RushSettings())
        var run = initial
        repeat(4) { run = run.record(solved = true, rating = 1350) }
        assertEquals(4, run.streak)
        assertEquals(0, initial.attempted, "recording leaves the earlier run untouched")

        run = run.record(solved = false, rating = 1400)
        assertEquals(0, run.streak)
        assertEquals(4, run.bestStreak)
        assertEquals(4, run.solved)
        assertEquals(1, run.missed)
        assertEquals(5, run.attempted)
        assertEquals(5, run.attempts.size)
        assertEquals(RushAttempt(rating = 1400, solved = false), run.attempts.last())
    }

    @Test
    fun `Difficulty climbs across a run`() {
        var run = RushRun(settings = RushSettings())
        val opening = run.targetRating(practiceRating = 1500)
        repeat(40) { run = run.record(solved = true) }
        val later = run.targetRating(practiceRating = 1500)
        assertTrue(opening < 1100, "a run should open well below your level, got $opening")
        assertTrue(later > opening)

        repeat(30) { run = run.record(solved = true) }
        assertEquals(1850, run.targetRating(practiceRating = 1500))
        assertEquals(listOf("3 min", "5 min", "10 min"), RushSettings.choices.map(RushSettings::label))
    }

    @Test
    fun `A puzzle is always found for a real library`() {
        // Ratings spread the way the bundled set is.
        val library = (0 until 200).map { puzzle("p$it", rating = 760 + it * 10) }
        val used = HashSet<String>()
        var run = RushRun(settings = RushSettings())

        repeat(50) {
            val target = run.targetRating(practiceRating = 1200)
            val next = assertNotNull(
                ItemSelector.nextRushPuzzle(from = library, targetRating = target, excluding = used),
                "no puzzle for target rating $target",
            )
            assertFalse(used.contains(next.id), "a run must not repeat a puzzle")
            used.add(next.id)
            run = run.record(solved = true)
        }
    }

    @Test
    fun `Best rush records are kept per duration`() {
        var progress = TrainingProgress()
        progress = progress.record(RushRecord(solved = 18, bestStreak = 12, duration = 180.0, achievedAt = 1_000.0))
        progress = progress.record(RushRecord(solved = 24, bestStreak = 15, duration = 180.0, achievedAt = 2_000.0))
        progress = progress.record(RushRecord(solved = 21, bestStreak = 19, duration = 180.0, achievedAt = 3_000.0))
        progress = progress.record(RushRecord(solved = 31, bestStreak = 20, duration = 300.0, achievedAt = 4_000.0))

        val best = progress.rushRecordsByDuration
        assertEquals(24, best[180]?.solved)
        assertEquals(31, best[300]?.solved)
    }
}
