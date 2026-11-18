package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.PieceColor
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.pow
import kotlin.math.sqrt
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject

/**
 * What the two devices say to each other.
 *
 * JSON rather than a packed binary frame. A chess match sends a few dozen
 * small messages over several minutes, so the bytes do not matter, and a
 * format that can be read in a log is worth more than one that saves forty
 * bytes on a move nobody is waiting for.
 *
 * The JSON is the shape Swift's synthesised `Codable` gives the enum this is
 * ported from — one key naming the case, its payload under `_0` or under its
 * own labels — because the server relays these between an iPhone and an
 * Android phone, and each has to read what the other wrote. It is written out
 * by hand here, in [toJson] and [fromJson], so that the shape is in plain
 * sight and cannot move when a library does.
 */
sealed interface MatchPacket {
    /** Sent by both sides on connect, so each knows who it is playing. */
    data class Hello(
        val playerID: String,
        val name: String,
        val rating: Int,
        val games: Int,
        /**
         * How sure the rating is (Glicko's RD). Absent from builds before
         * Glicko, whose players are given one from their game count.
         */
        val deviation: Double? = null,
        val version: Int = MatchProtocolVersion.current,
    ) : MatchPacket {
        /** The deviation to score this side against. */
        val ratingDeviation: Double get() = deviation ?: Glicko.deviation(games)
    }

    /** Sent by the host only: it settles colours and the clock. */
    data class Start(
        /**
         * The colour the *receiver* plays. Decided by the host so that the
         * two devices cannot disagree, and randomly so that being host is not
         * worth anything.
         */
        val youPlay: String,
        val minutes: Int,
        val version: Int = MatchProtocolVersion.current,
    ) : MatchPacket {
        constructor(youPlay: PieceColor, timeControl: TimeControl) :
            this(if (youPlay == PieceColor.WHITE) "white" else "black", timeControl.minutes)

        val receiverColor: PieceColor get() = if (youPlay == "white") PieceColor.WHITE else PieceColor.BLACK
        val timeControl: TimeControl get() = TimeControl.fromMinutes(minutes) ?: TimeControl.FIVE
    }

    data class MovePacket(
        val uci: String,
        /**
         * Which ply this is, counted from the start of the game. A move that
         * arrives twice, or out of order after a reconnect, is then something
         * the receiver can recognise rather than something it plays.
         */
        val ply: Int,
        /** The sender's own clock after making the move. */
        val remaining: Double,
        /**
         * And the sender's reading of the *receiver's* clock.
         *
         * Without it the two devices disagree, and always in the same
         * direction: each starts the opponent's clock when the move arrives
         * and its own when the move is sent, so each is a network hop kinder
         * to itself than the other is. A hundred milliseconds a move is four
         * seconds over a blitz game — enough for one player to be out of time
         * on the other's screen while still thinking on their own.
         *
         * Both readings are adopted downwards, so the pair converges on the
         * lower of the two and both screens show the same number.
         *
         * Optional because a packet from a build that predates it still has
         * to decode; there is nothing to adopt and the old drift is what you
         * get.
         */
        val yours: Double? = null,
    ) : MatchPacket

    data object Resign : MatchPacket

    data object DrawOffer : MatchPacket

    data class DrawResponse(val accepted: Boolean) : MatchPacket

    /** Claimed by whichever device notices first; the other accepts it. */
    data class GameOver(
        val winner: String?,      // "white", "black", or null for a draw
        val reason: String,
    ) : MatchPacket {
        constructor(winner: PieceColor?, reason: MatchResult.Reason) : this(
            winner?.let { if (it == PieceColor.WHITE) "white" else "black" },
            reason.rawValue,
        )

        val winnerColor: PieceColor?
            get() = when (winner) {
                "white" -> PieceColor.WHITE
                "black" -> PieceColor.BLACK
                else -> null
            }

        val resultReason: MatchResult.Reason
            get() = MatchResult.Reason.fromRawValue(reason) ?: MatchResult.Reason.AGREEMENT
    }

    /**
     * After a game: another one, in the same match, colours swapped and the
     * clock the same — so two people who want to carry on do not have to find
     * each other again. A build that predates these drops them unread, and
     * the offer simply goes unanswered.
     */
    data object RematchOffer : MatchPacket

    data class RematchResponse(val accepted: Boolean) : MatchPacket

    /**
     * Leaving the match: said, so the other side knows at once rather than
     * after the wait a dropped connection is given to come back.
     */
    data object Goodbye : MatchPacket

    /**
     * The packet as the JSON text that goes on the wire.
     *
     * Fields are written in the order they are declared in the Swift types,
     * an optional one that is null is left out, and a number with nothing
     * after the point is written without one — `300`, not `300.0` — as
     * Swift's encoder writes it. A clock reading that is not a finite number
     * cannot be written as JSON at all, and throws.
     */
    fun toJson(): String = buildJsonObject {
        when (val packet = this@MatchPacket) {
            is Hello -> payload("hello") {
                put("version", packet.version)
                put("playerID", packet.playerID)
                put("name", packet.name)
                put("rating", packet.rating)
                put("games", packet.games)
                packet.deviation?.let { put("deviation", number(it)) }
            }
            is Start -> payload("start") {
                put("version", packet.version)
                put("youPlay", packet.youPlay)
                put("minutes", packet.minutes)
            }
            is MovePacket -> payload("move") {
                put("uci", packet.uci)
                put("ply", packet.ply)
                put("remaining", number(packet.remaining))
                packet.yours?.let { put("yours", number(it)) }
            }
            Resign -> putJsonObject("resign") {}
            DrawOffer -> putJsonObject("drawOffer") {}
            is DrawResponse -> putJsonObject("drawResponse") { put("accepted", packet.accepted) }
            is GameOver -> payload("gameOver") {
                packet.winner?.let { put("winner", it) }
                put("reason", packet.reason)
            }
            RematchOffer -> putJsonObject("rematchOffer") {}
            is RematchResponse -> putJsonObject("rematchResponse") { put("accepted", packet.accepted) }
            Goodbye -> putJsonObject("goodbye") {}
        }
    }.toString()

    companion object {
        /**
         * Reads a packet off the wire, or returns null: for text that is not
         * JSON, for a case this build does not know, for a field that is
         * missing or of the wrong type. Never throws — a packet that cannot be
         * read is a packet that is dropped. Fields this build does not know
         * are passed over, which is what lets a newer build add one.
         */
        fun fromJson(text: String): MatchPacket? {
            val root = try {
                Json.parseToJsonElement(text) as? JsonObject ?: return null
            } catch (notJson: SerializationException) {
                return null
            }
            // Exactly one of the keys has to name a case. Keys that name
            // nothing are not counted, as Swift's decoder does not count them.
            val cases = root.keys.filter { it in caseNames }
            if (cases.size != 1) return null
            val body = root[cases[0]]
            return try {
                when (cases[0]) {
                    "hello" -> body.payload().let {
                        Hello(
                            version = it.int("version"),
                            playerID = it.string("playerID"),
                            name = it.string("name"),
                            rating = it.int("rating"),
                            games = it.int("games"),
                            deviation = it.optionalDouble("deviation"),
                        )
                    }
                    "start" -> body.payload().let {
                        Start(
                            version = it.int("version"),
                            youPlay = it.string("youPlay"),
                            minutes = it.int("minutes"),
                        )
                    }
                    "move" -> body.payload().let {
                        MovePacket(
                            uci = it.string("uci"),
                            ply = it.int("ply"),
                            remaining = it.double("remaining"),
                            yours = it.optionalDouble("yours"),
                        )
                    }
                    "resign" -> body.fields().let { Resign }
                    "drawOffer" -> body.fields().let { DrawOffer }
                    "drawResponse" -> DrawResponse(accepted = body.fields().boolean("accepted"))
                    "gameOver" -> body.payload().let {
                        GameOver(
                            winner = it.optionalString("winner"),
                            reason = it.string("reason"),
                        )
                    }
                    "rematchOffer" -> body.fields().let { RematchOffer }
                    "rematchResponse" -> RematchResponse(accepted = body.fields().boolean("accepted"))
                    "goodbye" -> body.fields().let { Goodbye }
                    else -> null
                }
            } catch (malformed: Malformed) {
                null
            }
        }

        private val caseNames = setOf(
            "hello", "start", "move", "resign", "drawOffer", "drawResponse",
            "gameOver", "rematchOffer", "rematchResponse", "goodbye",
        )
    }
}

object MatchProtocolVersion {
    const val current = 1
}

// MARK: - The wire format

/** A packet that names a known case and then does not hold what that case needs. */
private class Malformed : Exception()

/** A case whose payload is one unlabelled value, which Swift writes under `_0`. */
private fun JsonObjectBuilder.payload(case: String, fields: JsonObjectBuilder.() -> Unit) {
    putJsonObject(case) { putJsonObject("_0", fields) }
}

/** A number as Swift's encoder writes a `Double`: whole values without a fraction. */
private fun number(value: Double): JsonPrimitive {
    require(value.isFinite()) { "$value cannot be written as JSON" }
    return if (value == floor(value) && abs(value) < 1e15) JsonPrimitive(value.toLong()) else JsonPrimitive(value)
}

private fun JsonElement?.fields(): JsonObject = this as? JsonObject ?: throw Malformed()

private fun JsonElement?.payload(): JsonObject = fields()["_0"].fields()

/** A field that has to be there, and has to be a JSON value of this kind rather than a string that looks like one. */
private fun JsonObject.primitive(key: String, string: Boolean): JsonPrimitive {
    val value = this[key] as? JsonPrimitive ?: throw Malformed()
    if (value is JsonNull || value.isString != string) throw Malformed()
    return value
}

private fun JsonObject.isAbsent(key: String): Boolean = this[key].let { it == null || it is JsonNull }

private fun JsonObject.string(key: String): String = primitive(key, string = true).content

private fun JsonObject.optionalString(key: String): String? = if (isAbsent(key)) null else string(key)

/** What JSON calls a number. The parser hands over any bare word, and Kotlin would read "1f" or "NaN" as one. */
private val jsonNumber = Regex("""-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?""")

private fun JsonObject.double(key: String): Double {
    val content = primitive(key, string = false).content
    if (!jsonNumber.matches(content)) throw Malformed()
    val value = content.toDoubleOrNull() ?: throw Malformed()
    if (!value.isFinite()) throw Malformed()
    return value
}

private fun JsonObject.optionalDouble(key: String): Double? = if (isAbsent(key)) null else double(key)

/** A whole number. `5.0` is one, as it is to Swift's decoder; `5.5` is not. */
private fun JsonObject.int(key: String): Int {
    val value = double(key)
    if (value != floor(value) || abs(value) > Int.MAX_VALUE) throw Malformed()
    return value.toInt()
}

private fun JsonObject.boolean(key: String): Boolean = when (primitive(key, string = false).content) {
    "true" -> true
    "false" -> false
    else -> throw Malformed()
}

/** How a match ended, from the local player's point of view. */
data class MatchResult(
    val outcome: Outcome,
    val reason: Reason,
    /** Change in your rating, once it has been applied. */
    val ratingDelta: Int = 0,
    /** How sure the rating is after this game, once it has been applied. */
    val deviation: Double? = null,
) {
    enum class Outcome(val rawValue: String) { WIN("win"), LOSS("loss"), DRAW("draw") }

    enum class Reason(val rawValue: String) {
        CHECKMATE("checkmate"),
        RESIGNATION("resignation"),
        TIMEOUT("timeout"),
        STALEMATE("stalemate"),
        INSUFFICIENT_MATERIAL("insufficientMaterial"),
        REPETITION("repetition"),
        FIFTY_MOVE_RULE("fiftyMoveRule"),
        AGREEMENT("agreement"),
        DISCONNECTED("disconnected");

        val text: String
            get() = when (this) {
                CHECKMATE -> L.t("result.checkmate", "checkmate")
                RESIGNATION -> L.t("result.resignation", "resignation")
                TIMEOUT -> L.t("result.time", "time")
                STALEMATE -> L.t("result.stalemate", "stalemate")
                INSUFFICIENT_MATERIAL -> L.t("result.insufficientMaterial", "insufficient material")
                REPETITION -> L.t("result.repetition", "repetition")
                FIFTY_MOVE_RULE -> L.t("result.fiftyMoveRule", "the fifty-move rule")
                AGREEMENT -> L.t("result.agreement", "agreement")
                DISCONNECTED -> L.t("result.disconnected", "the opponent leaving")
            }

        companion object {
            /** The reason a packet names, or null for a word this build does not know. */
            fun fromRawValue(rawValue: String): Reason? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    val headline: String
        get() = when (outcome) {
            Outcome.WIN -> L.t("result.youWonBy", "You won by %@", reason.text)
            Outcome.LOSS -> L.t("result.youLostBy", "You lost by %@", reason.text)
            Outcome.DRAW -> L.t("result.drawnBy", "Drawn by %@", reason.text)
        }

    /** The score this outcome is worth for a rating calculation. */
    val score: Double
        get() = when (outcome) {
            Outcome.WIN -> 1.0
            Outcome.DRAW -> 0.5
            Outcome.LOSS -> 0.0
        }
}

/**
 * Why a game played online leaves the ratings alone.
 *
 * The rank lists are only worth anything if a place on them has to be won
 * against whoever the search turns up. So a game two people arranged, a
 * rematch, and a second game in a day against the same opponent are played
 * just the same, and scored as a friendly.
 */
enum class UnratedReason(val rawValue: String) {
    INVITATION("invitation"),
    REMATCH("rematch"),
    SAME_OPPONENT_TODAY("sameOpponentToday"),

    /** Fewer than two moves: nobody played a game. */
    ABORTED("aborted");

    val text: String
        get() = when (this) {
            INVITATION -> L.t("online.unrated.invitation", "Not rated: games from an invitation are friendly.")
            REMATCH -> L.t("online.unrated.rematch", "Not rated: a rematch is a friendly game.")
            SAME_OPPONENT_TODAY -> L.t("online.unrated.again", "Not rated: only one game a day against the same opponent counts.")
            ABORTED -> L.t("online.unrated.aborted", "Not rated: the game ended before both sides had moved.")
        }
}

/**
 * Rounds to the nearest whole number, a half going away from zero: what
 * Swift's `rounded()` does, and neither of the things Kotlin's `round` and
 * `roundToInt` do with a half.
 */
internal fun roundedToInt(value: Double): Int =
    (if (value >= 0) floor(value + 0.5) else ceil(value - 0.5)).toInt()

/**
 * Elo, for the training ratings: a rating measured against a library of
 * rated puzzles and positions, with K falling as the record settles.
 */
object Elo {
    /** No rating goes below this; there is no ceiling. */
    const val floor = 100

    fun expected(rating: Int, against: Int): Double =
        1 / (1 + 10.0.pow((against - rating).toDouble() / 400))

    fun kFactor(games: Int): Double {
        if (games < 15) return 40.0
        if (games < 100) return 24.0
        return 16.0
    }

    fun updated(rating: Int, games: Int, against: Int, score: Double): Int {
        val next = rating.toDouble() + kFactor(games) * (score - expected(rating, against))
        return maxOf(roundedToInt(next), floor)
    }
}

/**
 * Glicko, for games against people — the system chess.com rates with.
 *
 * A rating comes with a deviation, how sure it is. A new player's is wide,
 * so their first games move it a long way; it narrows with every game, and
 * widens again while they are away. What a result is worth follows from the
 * gap: beating somebody far below earns next to nothing — nothing at all, past
 * a point — and drawing with them costs points, as losing to them costs many.
 *
 * On the iPhone each device works out its own player's new rating, from both
 * players' records as Game Center held them when the game began
 * (`OnlineRecord`), and writes it there. Here the server referees and reports
 * the change (`MatchSession.applyServerResult`); the arithmetic is kept so the
 * two can be checked against each other.
 */
object Glicko {
    const val starting = 1200

    /** No rating goes below this; there is no ceiling. */
    const val floor = 100

    /** A new player's deviation, and the most an idle one grows back to. */
    const val newDeviation = 350.0

    /**
     * The narrowest a deviation gets, however many games: a rating always
     * stays able to move.
     */
    const val settledDeviation = 50.0

    /**
     * How much uncertainty a day without a game adds: a settled rating is
     * back to a new player's after about a year away.
     */
    val growthPerDay: Double = sqrt((newDeviation * newDeviation - settledDeviation * settledDeviation) / 365)

    private val q = ln(10.0) / 400

    /** The rating and deviation after one game. */
    data class Updated(val rating: Int, val deviation: Double)

    /**
     * A deviation for a record that has none — a build before Glicko: wide
     * for a handful of games, narrow for hundreds.
     */
    fun deviation(games: Int): Double =
        maxOf(settledDeviation, newDeviation / sqrt(1 + maxOf(games, 0).toDouble() / 2.5))

    /** A deviation after time without a game; `idle` in seconds. */
    fun deviation(deviation: Double, idle: Double): Double {
        val days = maxOf(idle, 0.0) / 86_400
        return minOf(sqrt(deviation * deviation + growthPerDay * growthPerDay * days), newDeviation)
    }

    /** How much an opponent's result says: less, the less sure their rating is. */
    private fun g(deviation: Double): Double =
        1 / sqrt(1 + 3 * q * q * deviation * deviation / (PI * PI))

    /** The score expected against this opponent, from 0 to 1. */
    fun expected(rating: Int, against: Int, opponentDeviation: Double): Double =
        1 / (1 + 10.0.pow(-g(opponentDeviation) * (rating - against).toDouble() / 400))

    /** The rating and deviation after one game. */
    fun updated(
        rating: Int, deviation: Double,
        against: Int, opponentDeviation: Double,
        score: Double,
    ): Updated {
        val impact = g(opponentDeviation)
        val e = expected(rating, against, opponentDeviation)
        val inverseD2 = q * q * impact * impact * e * (1 - e)
        val precision = 1 / (deviation * deviation) + inverseD2
        val next = rating.toDouble() + q / precision * impact * (score - e)
        val nextDeviation = maxOf(sqrt(1 / precision), settledDeviation)
        return Updated(maxOf(roundedToInt(next), floor), nextDeviation)
    }
}
