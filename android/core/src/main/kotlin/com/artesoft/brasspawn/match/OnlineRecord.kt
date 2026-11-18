package com.artesoft.brasspawn.match

/**
 * A player's online rating on one clock, as Game Center keeps it.
 *
 * Game Center is where the iPhone's online ratings live: each clock's
 * leaderboard holds every player's most recent one, written only by that app,
 * signed as that app. A leaderboard entry is a score and a 64-bit context, and
 * Glicko needs more than a number — so the score is the rating, which is what
 * the list sorts by and shows, and the context carries the rest: how sure the
 * rating is, how many rated games it has, and the day of the last one, which
 * is how far its deviation has widened since.
 *
 * Read from Game Center, never from this device's own copy: that is a file
 * in the app's container, and on a Mac anybody can open it in a text editor.
 *
 * On Android the server holds the record and referees the game; the type and
 * its arithmetic are the same, and the packing into a context is kept so a
 * record written by one platform can be read by the other.
 */
data class OnlineRecord(
    val rating: Int,
    /** As of `lastPlayed`; see `deviation(at)` for now. */
    val deviation: Double,
    val games: Int,
    /** When the last rated game was played, in seconds since the epoch. */
    val lastPlayed: Double?,
) {
    /**
     * An entry read back. One with no context — written before the context
     * carried anything — is a rating whose certainty is not known, which is
     * what a new player's deviation says.
     */
    constructor(score: Int, context: Long) : this(
        rating = maxOf(score, Glicko.floor),
        deviation = (context and ((1L shl deviationBits) - 1)).let { d ->
            if (d == 0L) Glicko.newDeviation else d.toDouble()
        },
        games = ((context shr deviationBits) and ((1L shl gamesBits) - 1)).toInt(),
        lastPlayed = (context shr (deviationBits + gamesBits)).let { day ->
            if (day == 0L) null else day.toDouble() * secondsInDay
        },
    )

    /** How sure the rating is today: widened by the time since the last game. */
    fun deviation(at: Double = nowSeconds()): Double {
        if (lastPlayed == null) return deviation
        return Glicko.deviation(deviation, idle = at - lastPlayed)
    }

    // MARK: - The context

    /**
     * The deviation, the games and the day of the last game, in one integer:
     * ten bits, twenty-two and thirty-two, from the bottom.
     */
    val context: Long
        get() {
            val d = minOf(maxOf(roundedToInt(deviation), 0), (1 shl deviationBits) - 1).toLong()
            val g = minOf(maxOf(games, 0), (1 shl gamesBits) - 1).toLong()
            val day = if (lastPlayed == null) 0L else maxOf((lastPlayed / secondsInDay).toLong(), 0L)
            return (day shl (deviationBits + gamesBits)) or (g shl deviationBits) or d
        }

    /** The record after one game against `against`, scored by Glicko. */
    fun after(score: Double, against: OnlineRecord, at: Double = nowSeconds()): OnlineRecord {
        val next = Glicko.updated(
            rating = rating, deviation = deviation(at),
            against = against.rating, opponentDeviation = against.deviation(at),
            score = score,
        )
        return OnlineRecord(rating = next.rating, deviation = next.deviation, games = games + 1, lastPlayed = at)
    }

    companion object {
        /** Somebody there is no rating for on this clock. */
        val new = OnlineRecord(rating = Glicko.starting, deviation = Glicko.newDeviation, games = 0, lastPlayed = null)

        private const val deviationBits = 10
        private const val gamesBits = 22
        private const val secondsInDay = 86_400.0
    }
}
