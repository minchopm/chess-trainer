package com.artesoft.brasspawn.match

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Rating pools.
 *
 * The Swift suite of this name is about `TrainingProgress` — the file the
 * iPhone keeps a player's ratings in, with its `RatedPool` and `PoolRating` —
 * which is not part of this module: here the server holds the ratings. What
 * is here is the part of that suite's subject that was ported: the Elo a pool
 * is moved by, and the clock that says which pool a game against a person
 * belongs to.
 */
class RatingPoolTests {
    /** What `TrainingProgress.settle` does to a pool, five times over. */
    @Test
    fun `Beating stronger opponents moves a fresh rating a long way`() {
        var rating = 1200
        for (game in 0 until 5) {
            rating = Elo.updated(rating = rating, games = game, against = 1600, score = 1.0)
        }
        assertTrue(rating > 1200, "beating 1600s should move blitz")
        assertEquals(1374, rating)
    }

    @Test
    fun `K falls as the record settles`() {
        assertEquals(40.0, Elo.kFactor(games = 0))
        assertEquals(40.0, Elo.kFactor(games = 14))
        assertEquals(24.0, Elo.kFactor(games = 15))
        assertEquals(24.0, Elo.kFactor(games = 99))
        assertEquals(16.0, Elo.kFactor(games = 100))
    }

    @Test
    fun `An even game is worth half of K, and nothing takes a rating under the floor`() {
        assertEquals(0.5, Elo.expected(1500, against = 1500))
        assertEquals(1520, Elo.updated(rating = 1500, games = 0, against = 1500, score = 1.0))
        assertEquals(1480, Elo.updated(rating = 1500, games = 0, against = 1500, score = 0.0))
        assertEquals(1500, Elo.updated(rating = 1500, games = 0, against = 1500, score = 0.5))
        assertEquals(Elo.floor, Elo.updated(rating = 105, games = 0, against = 110, score = 0.0))
    }

    /** Matchmaking keeps the clocks apart: each is a pool of its own. */
    @Test
    fun `Every clock is a pool of its own, and reads back as itself`() {
        assertEquals(listOf(3, 5, 10, 15, 30), TimeControl.entries.map { it.minutes })
        assertEquals(TimeControl.entries.size, TimeControl.entries.map { it.playerGroup }.toSet().size)
        for (control in TimeControl.entries) {
            assertEquals(control, TimeControl.fromPlayerGroup(control.playerGroup))
            assertEquals(control, TimeControl.fromMinutes(control.minutes))
        }
        assertEquals(4005, TimeControl.FIVE.playerGroup)
        assertNull(TimeControl.fromPlayerGroup(4007))
        assertNull(TimeControl.fromMinutes(7))
    }
}
