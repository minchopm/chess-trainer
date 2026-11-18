package com.artesoft.brasspawn.match

import java.math.BigDecimal
import java.math.RoundingMode
import kotlin.math.ceil

/**
 * The time now, in seconds since the Unix epoch: the unit every instant and
 * every duration in this module is kept in. The default wherever a function
 * takes the current time, so a test can hand in its own.
 */
fun nowSeconds(): Double = System.currentTimeMillis() / 1000.0

/**
 * The clocks an online game can be played at.
 *
 * Minutes only, no increment. An increment changes how a game is played more
 * than the base time does, and offering both would double the matchmaking
 * pools — at which point the wait for an opponent becomes the feature people
 * notice.
 */
enum class TimeControl(val minutes: Int) {
    THREE(3), FIVE(5), TEN(10), FIFTEEN(15), THIRTY(30);

    /** What the Swift enum is written to disk and to the wire as: the minutes. */
    val rawValue: Int get() = minutes
    val id: Int get() = minutes
    val seconds: Double get() = minutes * 60.0
    val label: String get() = L.t("clock.minutes", "%lld min", minutes)

    /**
     * What the clock is called at the board. Worth showing: a player who knows
     * they are bad at blitz should be able to see it before they queue.
     *
     * `name` in the Swift code; a Kotlin enum already has a `name`, and it is
     * the constant's.
     */
    val displayName: String
        get() = when (this) {
            THREE, FIVE -> L.t("clock.blitz", "Blitz")
            TEN, FIFTEEN -> L.t("clock.rapid", "Rapid")
            THIRTY -> L.t("clock.classical", "Classical")
        }

    /**
     * Matchmaking pool. Players only ever meet others who chose the same
     * clock — being handed three minutes when you asked for thirty is not a
     * game of chess, it is a different sport.
     */
    val playerGroup: Int get() = 4000 + minutes

    companion object {
        /** The clock of that many minutes, if there is one. The Swift `init?(rawValue:)`. */
        fun fromMinutes(minutes: Int): TimeControl? = entries.firstOrNull { it.minutes == minutes }

        fun fromPlayerGroup(group: Int): TimeControl? = fromMinutes(group - 4000)
    }
}

/**
 * Two clocks and a side to move.
 *
 * Time is kept as a remaining amount plus the instant the side to move started
 * thinking, rather than as a value counted down by a timer. A timer that fires
 * sixty times a second is sixty chances to drift; this way the display can
 * tick as often or as rarely as it likes and still be right, and a view that
 * was not drawn for a second does not owe the player that second back.
 *
 * Immutable, like `Position`: [start], [press], [stop] and [adopt] hand back
 * the clock as it is afterwards, where the Swift struct changes in place.
 */
class ChessClock private constructor(
    val timeControl: TimeControl,
    private val white: Double,
    private val black: Double,
    val turn: PieceColorKey,
    /** When the side to move started thinking, in seconds since the epoch; null while stopped. */
    val startedAt: Double?,
) {
    /**
     * Colours as a dictionary key. The rules' PieceColor would do, but the
     * clock is deliberately free of the rules: it counts time for two sides
     * and has no opinion about what they are doing.
     */
    enum class PieceColorKey(val rawValue: String) {
        WHITE("white"), BLACK("black");

        val other: PieceColorKey get() = if (this == WHITE) BLACK else WHITE
    }

    constructor(timeControl: TimeControl, turn: PieceColorKey = PieceColorKey.WHITE) :
        this(timeControl, timeControl.seconds, timeControl.seconds, turn, null)

    /** What each side had left when its clock was last banked. See [remaining] for now. */
    val remaining: Map<PieceColorKey, Double>
        get() = mapOf(PieceColorKey.WHITE to white, PieceColorKey.BLACK to black)

    val isRunning: Boolean get() = startedAt != null

    fun remaining(side: PieceColorKey, at: Double = nowSeconds()): Double {
        val stored = stored(side)
        if (side != turn || startedAt == null) return maxOf(0.0, stored)
        return maxOf(0.0, stored - (at - startedAt))
    }

    fun hasFlagged(side: PieceColorKey, at: Double = nowSeconds()): Boolean = remaining(side, at) <= 0

    fun start(at: Double = nowSeconds()): ChessClock {
        if (startedAt != null) return this
        return ChessClock(timeControl, white, black, turn, at)
    }

    /** End the side to move's turn: bank what is left and hand the clock over. */
    fun press(at: Double = nowSeconds()): ChessClock =
        banking(turn, remaining(turn, at), turn = turn.other, startedAt = at)

    fun stop(at: Double = nowSeconds()): ChessClock =
        banking(turn, remaining(turn, at), turn = turn, startedAt = null)

    /**
     * Take the opponent's own reading of their clock, as sent with their move.
     *
     * Trusted only downwards. Their device knows how long they really thought,
     * including the part of it spent on the network, and no peer-to-peer game
     * can do better than ask them — but accepting an increase would let a
     * modified build hand itself unlimited time.
     */
    fun adopt(value: Double, side: PieceColorKey): ChessClock =
        banking(side, maxOf(0.0, minOf(stored(side), value)), turn = turn, startedAt = startedAt)

    private fun stored(side: PieceColorKey): Double = if (side == PieceColorKey.WHITE) white else black

    /** The clock with `value` written down as what `side` has left. */
    private fun banking(side: PieceColorKey, value: Double, turn: PieceColorKey, startedAt: Double?): ChessClock =
        ChessClock(
            timeControl,
            white = if (side == PieceColorKey.WHITE) value else white,
            black = if (side == PieceColorKey.BLACK) value else black,
            turn = turn,
            startedAt = startedAt,
        )

    override fun equals(other: Any?): Boolean =
        other is ChessClock &&
            timeControl == other.timeControl && white == other.white && black == other.black &&
            turn == other.turn && startedAt == other.startedAt

    override fun hashCode(): Int {
        var result = timeControl.hashCode()
        result = 31 * result + white.hashCode()
        result = 31 * result + black.hashCode()
        result = 31 * result + turn.hashCode()
        result = 31 * result + (startedAt?.hashCode() ?: 0)
        return result
    }

    override fun toString(): String =
        "ChessClock(${timeControl.minutes} min, white=$white, black=$black, turn=${turn.rawValue}, startedAt=$startedAt)"

    companion object {
        fun text(seconds: Double): String {
            val whole = ceil(seconds).toInt()
            if (whole >= 60) return "${whole / 60}:${(whole % 60).toString().padStart(2, '0')}"
            // Under a minute the tenths are the whole story.
            //
            // Rounded half to even on the exact value, which is what the C
            // formatter behind `String(format: "%.1f")` does; Java's own rounds
            // a tie the other way, and the two apps would show 0.2 and 0.3 for
            // the same quarter of a second.
            return BigDecimal(maxOf(0.0, seconds)).setScale(1, RoundingMode.HALF_EVEN).toPlainString()
        }
    }
}
