package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.match.nowSeconds
import kotlin.math.abs
import kotlinx.serialization.Serializable

/** Scoring for one rating estimate in Guess the Elo. */
data class EloGuess(
    val guess: Int,
    val actual: Int,
) {
    val error: Int get() = abs(guess - actual)
    val isHigh: Boolean get() = guess > actual

    enum class Verdict {
        SPOT, CLOSE, FAIR, OFF;

        val title: String
            get() = when (this) {
                SPOT -> L.t("guess.spotOn", "Spot on")
                CLOSE -> L.t("guess.close", "Close")
                FAIR -> L.t("guess.rightArea", "In the right area")
                OFF -> L.t("guess.notThisTime", "Not this time")
            }

        companion object {
            /** The band a miss of this many points falls in. */
            internal fun forError(error: Int): Verdict = when {
                error < 75 -> SPOT
                error < 150 -> CLOSE
                error < 300 -> FAIR
                else -> OFF
            }
        }
    }

    /**
     * Bands rather than a continuous score, because that is how the skill
     * actually works: reading a game to within a class is the achievement, and
     * the last fifty points are noise in the rating itself.
     */
    val verdict: Verdict get() = Verdict.forError(error)

    /** 100 for a perfect read, nothing once you are 500 out. */
    val points: Int get() = maxOf(0, 100 - error / 5)

    val summary: String
        get() {
            if (error < 15) return L.t("guess.deadOn", "Dead on.")
            return if (isHigh) {
                L.t("guess.tooHigh", "%lld points too high.", error)
            } else {
                L.t("guess.tooLow", "%lld points too low.", error)
            }
        }

    companion object {
        /**
         * The range a guess may move in. Wider than the games in the library, so
         * the ends of the slider are not answers in themselves.
         */
        val range: IntRange = 600..2800
        const val step = 25
    }
}

/**
 * A separate rating guess for each player in the watched game.
 *
 * Each side is judged against that player's real rating. The overall result
 * uses the mean of the two errors, so one accurate slider cannot hide a very
 * inaccurate guess for the other player.
 */
data class EloPairGuess(
    val white: EloGuess,
    val black: EloGuess,
) {
    constructor(whiteGuess: Int, blackGuess: Int, whiteActual: Int, blackActual: Int) : this(
        white = EloGuess(guess = whiteGuess, actual = whiteActual),
        black = EloGuess(guess = blackGuess, actual = blackActual),
    )

    val averageError: Int get() = (white.error + black.error) / 2

    val verdict: EloGuess.Verdict get() = EloGuess.Verdict.forError(averageError)

    val points: Int get() = maxOf(0, 100 - averageError / 5)

    val summary: String
        get() = if (averageError < 15) {
            L.t("guess.bothSpotOn", "Both ratings were spot on.")
        } else {
            L.t("guess.averageMiss", "Average miss: %lld points.", averageError)
        }
}

/**
 * One judged game, kept so the mode can report whether you are getting better
 * at reading a game rather than just how the last one went.
 */
@Serializable
data class EloGuessRecord(
    @Serializable(with = SwiftDateSerializer::class) val at: Double = nowSeconds(),
    val gameID: String,
    val guess: Int,
    val actual: Int,
    val whiteGuess: Int? = null,
    val whiteActual: Int? = null,
    val blackGuess: Int? = null,
    val blackActual: Int? = null,
) {
    /** A guess for each player; `guess` and `actual` are then the two averaged. */
    constructor(
        at: Double = nowSeconds(),
        gameID: String,
        whiteGuess: Int,
        whiteActual: Int,
        blackGuess: Int,
        blackActual: Int,
    ) : this(
        at = at,
        gameID = gameID,
        guess = (whiteGuess + blackGuess) / 2,
        actual = (whiteActual + blackActual) / 2,
        whiteGuess = whiteGuess,
        whiteActual = whiteActual,
        blackGuess = blackGuess,
        blackActual = blackActual,
    )

    val error: Int
        get() {
            if (whiteGuess == null || whiteActual == null || blackGuess == null || blackActual == null) {
                return abs(guess - actual)
            }
            return (abs(whiteGuess - whiteActual) + abs(blackGuess - blackActual)) / 2
        }

    val bias: Int
        get() {
            if (whiteGuess == null || whiteActual == null || blackGuess == null || blackActual == null) {
                return guess - actual
            }
            return ((whiteGuess - whiteActual) + (blackGuess - blackActual)) / 2
        }
}

class EloGuessStats(records: List<EloGuessRecord>) {
    val judged: Int = records.size
    val averageError: Int
    val bestError: Int

    /**
     * Positive when you tend to read games as stronger than they were, which
     * is the common way to be wrong and worth naming.
     */
    val bias: Int

    init {
        if (records.isEmpty()) {
            averageError = 0
            bestError = 0
            bias = 0
        } else {
            averageError = records.sumOf { it.error } / records.size
            bestError = records.minOf { it.error }
            bias = records.sumOf { it.bias } / records.size
        }
    }
}
