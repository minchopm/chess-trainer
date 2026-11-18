package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.match.nowSeconds
import java.util.UUID
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException

/**
 * A game that was actually played, kept whole.
 *
 * `TrainingProgress.games` already records that a game happened — result,
 * accuracy, how strong the opponent was — because those are the numbers a
 * rating is made of. It says nothing about what was played. This is the moves,
 * so a game can be watched back afterwards and picked up again from any point
 * in it.
 *
 * Its own store rather than another field on the progress file: that file is
 * read and rewritten whole on every change, and a couple of hundred games of
 * notation is not something to re-encode because somebody solved a puzzle.
 *
 * A SwiftData model on the iPhone; a plain value here, which [encode] turns
 * into one JSON object — a row for whatever the app keeps its rows in.
 */
@Serializable
data class SavedGame(
    /**
     * A string, so it keys the same watch marks and favourites the classics
     * use. `TrainingProgress` stores both against a `String` id already, and a
     * game you played is a game like any other in that respect.
     */
    val id: String = UUID.randomUUID().toString().uppercase(),
    /** When it was played, in seconds since the epoch. */
    @Serializable(with = SwiftDateSerializer::class) val playedAt: Double = nowSeconds(),

    /**
     * Where the line begins. The opening position for an ordinary game, and
     * something else entirely for one that began from a board you set up.
     */
    val startFEN: String = Position.start.fen,

    /**
     * The moves in SAN, separated by spaces — the form `GameImport` reads.
     *
     * Stored as notation rather than as a move list so that a saved game comes
     * back through the same parser as a pasted one. One reader, one set of
     * bugs, and a database that can be read by eye if anybody ever looks.
     */
    val notation: String,

    /** "win", "draw" or "loss" from your side; "*" when neither side was yours. */
    val result: String,
    val white: String,
    val black: String,

    /**
     * "white", "black", or null when you held neither side — two engines
     * playing each other is still a game worth keeping.
     *
     * Your own side's name is stored empty rather than as "You": the word is
     * translated, and a history written in the language the app happened to be
     * in on the day would read wrong ever after. The empty string means "the
     * player", and `name(color)` puts the right word in at the time of asking.
     */
    val yourColor: String? = null,
    val opponentElo: Int? = null,
    val accuracy: Int? = null,

    /** Which screen it came from: "play", "board", "online". */
    val source: String,
) {
    /** Who held a side, in the language being read now. */
    fun name(color: PieceColor): String {
        val stored = if (color == PieceColor.WHITE) white else black
        return if (stored.isEmpty()) L.t("history.you", "You") else stored
    }

    val players: String get() = "${name(PieceColor.WHITE)} — ${name(PieceColor.BLACK)}"

    val moves: List<String> get() = swiftSplit(notation, ' ')

    val moveCount: Int get() = moves.size

    /**
     * Where the line begins, or the opening position if the stored FEN has
     * somehow stopped being one.
     */
    val startPosition: Position get() = Position.fromFen(startFEN) ?: Position.start

    /**
     * True when the game is one you took part in, rather than one you set two
     * engines going and watched.
     */
    val isYours: Boolean get() = yourColor != null

    /** The game as one JSON object. */
    fun encode(): String = swiftJson.encodeToString(serializer(), this)

    companion object {
        /** Reads what [encode] wrote. Throws `SerializationException` for text that is not a saved game. */
        fun decode(text: String): SavedGame = swiftJson.decodeFromString(serializer(), text)
    }
}

/**
 * The store the saved games live in.
 *
 * On the iPhone this is a SwiftData container, and the screens query it. Here
 * it is the games in memory and nothing else: where they are kept between
 * launches — a file, a database, one row a game — is the app's business, and
 * [encode], [decode] and `SavedGame.encode` are what it needs for any of them.
 *
 * Nothing is trimmed. A game is a few hundred bytes of notation, so ten
 * thousand of them is a couple of megabytes — cheaper than deciding on
 * somebody's behalf which of their own games they are done with.
 *
 * Not safe to change from two threads at once; like the SwiftData context it
 * stands in for, it belongs to the thread that draws the screen.
 */
class GameHistory(games: Collection<SavedGame> = emptyList()) {
    /** Called after a game is added, replaced or removed. */
    var onChange: (() -> Unit)? = null

    private val byId = LinkedHashMap<String, SavedGame>()
    private var newestFirst: List<SavedGame>? = null

    init {
        for (game in games) byId[game.id] = game
    }

    /** Every game, newest first — the order the history screen shows them in. */
    val games: List<SavedGame>
        get() {
            newestFirst?.let { return it }
            val sorted = byId.values.sortedByDescending { it.playedAt }
            newestFirst = sorted
            return sorted
        }

    val count: Int get() = byId.size

    fun game(id: String): SavedGame? = byId[id]

    /**
     * Adds a game. The id is unique: a game with one already in the store
     * takes that one's place, which is also how a game is changed.
     */
    fun insert(game: SavedGame) {
        byId[game.id] = game
        changed()
    }

    /** Removes a game. False when there was none by that id. */
    fun delete(id: String): Boolean {
        if (byId.remove(id) == null) return false
        changed()
        return true
    }

    fun deleteAll() {
        if (byId.isEmpty()) return
        byId.clear()
        changed()
    }

    private fun changed() {
        newestFirst = null
        onChange?.invoke()
    }

    /** Every game as one JSON document: `{"games":[…]}`, newest first. */
    fun encode(): String = swiftJson.encodeToString(HistoryFile.serializer(), HistoryFile(games))

    @Serializable
    private class HistoryFile(val games: List<SavedGame> = emptyList())

    companion object {
        /** Reads what [encode] wrote. Throws `SerializationException` for text that is not a history. */
        fun decode(text: String): GameHistory =
            GameHistory(swiftJson.decodeFromString(HistoryFile.serializer(), text).games)

        /** [decode], or null when the text cannot be read. */
        fun decodeOrNull(text: String): GameHistory? =
            try {
                decode(text)
            } catch (_: SerializationException) {
                null
            } catch (_: IllegalArgumentException) {
                null
            }
    }
}
