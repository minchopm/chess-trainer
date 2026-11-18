package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.match.ChessClock.PieceColorKey
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The clock on its own. The Swift suite only reaches it through a match; here
 * the time is handed in, so what it does can be said to the second.
 */
class ClockTests {
    private val t0 = 1_790_000_000.0

    @Test
    fun `A clock that has not started does not run`() {
        val clock = ChessClock(TimeControl.FIVE)
        assertFalse(clock.isRunning)
        assertNull(clock.startedAt)
        assertEquals(PieceColorKey.WHITE, clock.turn)
        assertEquals(300.0, clock.remaining(PieceColorKey.WHITE, at = t0 + 1_000))
        assertEquals(300.0, clock.remaining(PieceColorKey.BLACK, at = t0 + 1_000))
        assertEquals(mapOf(PieceColorKey.WHITE to 300.0, PieceColorKey.BLACK to 300.0), clock.remaining)
    }

    @Test
    fun `Only the side to move loses time, and a press banks it`() {
        val started = ChessClock(TimeControl.FIVE).start(at = t0)
        assertTrue(started.isRunning)
        assertEquals(290.0, started.remaining(PieceColorKey.WHITE, at = t0 + 10))
        assertEquals(300.0, started.remaining(PieceColorKey.BLACK, at = t0 + 10))
        assertEquals(started, started.start(at = t0 + 5), "starting twice is starting once")

        val pressed = started.press(at = t0 + 10)
        assertEquals(PieceColorKey.BLACK, pressed.turn)
        assertEquals(290.0, pressed.remaining(PieceColorKey.WHITE, at = t0 + 60))
        assertEquals(250.0, pressed.remaining(PieceColorKey.BLACK, at = t0 + 60))

        // And the clock that was pressed is as it was.
        assertEquals(PieceColorKey.WHITE, started.turn)
        assertNotEquals(started, pressed)

        val stopped = pressed.stop(at = t0 + 60)
        assertFalse(stopped.isRunning)
        assertEquals(250.0, stopped.remaining(PieceColorKey.BLACK, at = t0 + 600))
    }

    @Test
    fun `A clock runs out at nought and no lower`() {
        val clock = ChessClock(TimeControl.THREE).start(at = t0)
        assertFalse(clock.hasFlagged(PieceColorKey.WHITE, at = t0 + 179))
        assertTrue(clock.hasFlagged(PieceColorKey.WHITE, at = t0 + 180))
        assertEquals(0.0, clock.remaining(PieceColorKey.WHITE, at = t0 + 500))
        assertFalse(clock.hasFlagged(PieceColorKey.BLACK, at = t0 + 500))
    }

    @Test
    fun `Another reading is taken downwards only`() {
        val clock = ChessClock(TimeControl.FIVE)
        assertEquals(120.0, clock.adopt(120.0, PieceColorKey.BLACK).remaining(PieceColorKey.BLACK, at = t0))
        assertEquals(300.0, clock.adopt(999.0, PieceColorKey.BLACK).remaining(PieceColorKey.BLACK, at = t0))
        assertEquals(0.0, clock.adopt(-5.0, PieceColorKey.BLACK).remaining(PieceColorKey.BLACK, at = t0))
        assertEquals(300.0, clock.adopt(120.0, PieceColorKey.BLACK).remaining(PieceColorKey.WHITE, at = t0))
    }

    @Test
    fun `Time reads as minutes and seconds, then as tenths under a minute`() {
        assertEquals("5:00", ChessClock.text(300.0))
        assertEquals("4:59", ChessClock.text(298.2))
        assertEquals("1:02", ChessClock.text(61.2))
        assertEquals("1:00", ChessClock.text(59.94))
        assertEquals("59.0", ChessClock.text(59.0))
        assertEquals("12.3", ChessClock.text(12.34))
        assertEquals("0.1", ChessClock.text(0.1))
        assertEquals("0.0", ChessClock.text(0.0))
        assertEquals("0.0", ChessClock.text(-3.0))
        // A tie goes to the even tenth, as it does in the Swift app.
        assertEquals("0.2", ChessClock.text(0.25))
        assertEquals("0.8", ChessClock.text(0.75))
    }

    @Test
    fun `A clock has a length, a label and a name`() {
        assertEquals(180.0, TimeControl.THREE.seconds)
        assertEquals("5 min", TimeControl.FIVE.label)
        assertEquals(listOf("Blitz", "Blitz", "Rapid", "Rapid", "Classical"), TimeControl.entries.map { it.displayName })
        assertEquals(15, TimeControl.FIFTEEN.rawValue)
        assertEquals(15, TimeControl.FIFTEEN.id)
        assertEquals(PieceColorKey.BLACK, PieceColorKey.WHITE.other)
        assertEquals("white", PieceColorKey.WHITE.rawValue)
    }
}
