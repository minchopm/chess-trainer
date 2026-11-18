@file:OptIn(ExperimentalSerializationApi::class)

package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.match.L
import java.io.File
import java.io.IOException
import java.io.InputStream
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.decodeFromStream

/**
 * A tactics puzzle: one position, one winning idea.
 *
 * `solution` alternates solver move, opponent reply, solver move… and always
 * ends on a solver move.
 */
@Serializable
data class Puzzle(
    val id: String,
    val fen: String,
    val solution: List<String>,     // UCI
    val themes: List<String>,
    val rating: Int,
    val mate: Boolean,
    val source: String? = null,
) {
    val solverMoveCount: Int get() = (solution.size + 1) / 2

    val sideToMove: PieceColor get() = sideToMove(fen)
}

/** A quiet position where judgement, not calculation, decides. */
@Serializable
data class PositionalExercise(
    val id: String,
    val fen: String,
    /**
     * Evaluation from White's point of view, which is what the assessment
     * question asks about.
     */
    val cp: Int,
    val best: Candidate,
    val alternatives: List<Candidate>,
    val rating: Int,
    val themes: List<String>,
) {
    @Serializable
    data class Candidate(
        val uci: String,
        /** Centipawns from the mover's point of view. */
        val cp: Int,
        val pv: List<String>? = null,
    )

    val sideToMove: PieceColor get() = sideToMove(fen)
}

/** Who a FEN says is to move: White only when the second field is exactly "w". */
private fun sideToMove(fen: String): PieceColor =
    if (swiftSplit(fen, ' ').getOrNull(1) == "w") PieceColor.WHITE else PieceColor.BLACK

/** An endgame played out against the engine to a required result. */
@Serializable
data class EndgameDrill(
    val id: String,
    val name: String,
    val fen: String,
    val goal: Goal,
    val rating: Int,
    val idea: String,
    val themes: List<String>,
) {
    @Serializable
    enum class Goal(val rawValue: String) {
        @SerialName("win") WIN("win"),
        @SerialName("draw") DRAW("draw"),
    }
}

/**
 * A complete rated game between two humans, for Guess the Elo.
 *
 * The two ratings are kept apart rather than averaged in the file: the guess
 * is scored against the average, but the reveal is more interesting when it
 * can show what each player was actually rated.
 */
@Serializable
data class AnnotatedGame(
    val id: String,
    val white: Int,
    val black: Int,
    val result: String,
    val speed: String? = null,
    val timeControl: String? = null,
    val termination: String? = null,
    val eco: String? = null,
    val opening: String? = null,
    val date: String? = null,
    /**
     * UCI moves, space separated — one string rather than an array because a
     * few thousand games of quoted four-character strings is mostly quotes.
     */
    val moves: String,
) {
    val uciMoves: List<String> get() = swiftSplit(moves, ' ')

    val averageRating: Int get() = (white + black) / 2

    /**
     * "Blitz · 5+0 · Sicilian Defense" — everything about the game that is not
     * a clue to the players' strength.
     */
    val subtitle: String
        get() = listOfNotNull(speed, timeControl?.let { readableClock(it) }, opening)
            .joinToString(" · ")

    companion object {
        /** "300+3" is how the archive writes it; "5+3" is how players say it. */
        internal fun readableClock(control: String): String {
            val parts = swiftSplit(control, '+')
            val seconds = swiftInt(parts.firstOrNull() ?: "") ?: return control
            val increment = if (parts.size > 1) parts[1] else "0"
            return if (seconds % 60 == 0) "${seconds / 60}+$increment" else "${seconds}s+$increment"
        }
    }
}

// MARK: - Loading

/**
 * The libraries the trainer draws on.
 *
 * The iPhone app reads the five JSON files out of its bundle. Nothing here
 * knows where an Android app keeps its assets, so the text comes in from
 * outside: as strings, as streams, through a function that opens a file by
 * name, or from a directory.
 */
class ContentLibrary(
    val puzzles: List<Puzzle> = emptyList(),
    val exercises: List<PositionalExercise> = emptyList(),
    val drills: List<EndgameDrill> = emptyList(),
    val games: List<AnnotatedGame> = emptyList(),
    val classics: List<ClassicGame> = emptyList(),
) {
    @Serializable private class PuzzleFile(val puzzles: List<Puzzle>)
    @Serializable private class ExerciseFile(val exercises: List<PositionalExercise>)
    @Serializable private class DrillFile(val drills: List<EndgameDrill>)
    @Serializable private class GameFile(val games: List<AnnotatedGame>)
    @Serializable private class ClassicFile(val games: List<ClassicGame>)

    companion object {
        const val tacticsFile = "tactics.json"
        const val positionsFile = "positions.json"
        const val endgamesFile = "endgames.json"
        const val gamesFile = "games.json"
        const val classicsFile = "classics.json"

        /**
         * The files carry more than the app reads — when they were generated,
         * where from, fields only the generator's own checks look at — and all
         * of it is passed over.
         */
        private val json = Json {
            ignoreUnknownKeys = true
            explicitNulls = false
        }

        // One file at a time. Each of these throws `SerializationException`
        // for text that is not the file it should be; the `load` functions
        // below are the ones that shrug.

        fun decodePuzzles(text: String): List<Puzzle> =
            shareThemes(json.decodeFromString(PuzzleFile.serializer(), text).puzzles)

        fun decodePuzzles(stream: InputStream): List<Puzzle> =
            shareThemes(json.decodeFromStream(PuzzleFile.serializer(), stream).puzzles)

        fun decodeExercises(text: String): List<PositionalExercise> =
            json.decodeFromString(ExerciseFile.serializer(), text).exercises

        fun decodeExercises(stream: InputStream): List<PositionalExercise> =
            json.decodeFromStream(ExerciseFile.serializer(), stream).exercises

        fun decodeDrills(text: String): List<EndgameDrill> =
            json.decodeFromString(DrillFile.serializer(), text).drills

        fun decodeDrills(stream: InputStream): List<EndgameDrill> =
            json.decodeFromStream(DrillFile.serializer(), stream).drills

        fun decodeGames(text: String): List<AnnotatedGame> =
            json.decodeFromString(GameFile.serializer(), text).games

        fun decodeGames(stream: InputStream): List<AnnotatedGame> =
            json.decodeFromStream(GameFile.serializer(), stream).games

        fun decodeClassics(text: String): List<ClassicGame> =
            json.decodeFromString(ClassicFile.serializer(), text).games

        fun decodeClassics(stream: InputStream): List<ClassicGame> =
            json.decodeFromStream(ClassicFile.serializer(), stream).games

        /**
         * Load the data files, tolerating any of them being absent — a build
         * without the generated tactics should still run the endgames rather
         * than refuse to start.
         *
         * `open` is handed a file name ([tacticsFile] and the rest) and returns
         * the file's bytes, or null when there is no such file; on Android,
         * `{ name -> assets.open(name) }` with the exception for a missing
         * asset turned into null. Each stream is closed once it has been read.
         * A file that is missing, cannot be read or is not what it should be
         * leaves its library empty, and the others load.
         */
        fun load(open: (name: String) -> InputStream?): ContentLibrary {
            fun <T> decode(name: String, read: (InputStream) -> List<T>): List<T> =
                try {
                    open(name)?.use(read) ?: emptyList()
                } catch (_: SerializationException) {
                    emptyList()
                } catch (_: IllegalArgumentException) {
                    emptyList()
                } catch (_: IOException) {
                    emptyList()
                }

            return ContentLibrary(
                puzzles = decode(tacticsFile, ::decodePuzzles),
                exercises = decode(positionsFile, ::decodeExercises),
                drills = decode(endgamesFile, ::decodeDrills),
                games = decode(gamesFile, ::decodeGames),
                classics = decode(classicsFile, ::decodeClassics),
            )
        }

        /** Load the data files from a directory, tolerating any of them being absent. */
        fun load(from: File): ContentLibrary = load { name ->
            val file = File(from, name)
            if (file.isFile) file.inputStream().buffered() else null
        }

        /**
         * Load from the text of each file, for a caller that has already read
         * them. Null for a file there is none of; text that is not what it
         * should be leaves that library empty.
         */
        fun load(
            tactics: String? = null,
            positions: String? = null,
            endgames: String? = null,
            games: String? = null,
            classics: String? = null,
        ): ContentLibrary {
            fun <T> decode(text: String?, read: (String) -> List<T>): List<T> =
                try {
                    text?.let(read) ?: emptyList()
                } catch (_: SerializationException) {
                    emptyList()
                } catch (_: IllegalArgumentException) {
                    emptyList()
                }

            return ContentLibrary(
                puzzles = decode(tactics, ::decodePuzzles),
                exercises = decode(positions, ::decodeExercises),
                drills = decode(endgames, ::decodeDrills),
                games = decode(games, ::decodeGames),
                classics = decode(classics, ::decodeClassics),
            )
        }

        /**
         * Fourteen thousand puzzles name the same few dozen themes seventy
         * thousand times. Decoded as they come, that is seventy thousand
         * strings; shared, it is a few dozen — which matters on a phone and
         * costs nothing to do once.
         */
        private fun shareThemes(puzzles: List<Puzzle>): List<Puzzle> {
            val shared = HashMap<String, String>()
            return puzzles.map { puzzle ->
                puzzle.copy(themes = puzzle.themes.map { theme -> shared.getOrPut(theme) { theme } })
            }
        }
    }
}

// MARK: - Themes

object Themes {
    /**
     * Themes that describe a puzzle rather than name a skill: which phase it is
     * from, how long the line is, how big the resulting advantage is, who
     * played the original game. Useful for filtering a set; useless as a
     * measure of you, since every puzzle is "short" or "long".
     */
    internal val descriptive: Set<String> = setOf(
        "opening", "middlegame", "endgame",
        "oneMove", "short", "long", "veryLong",
        "crushing", "advantage", "equality", "mate",
        "master", "masterVsMaster", "superGM",
    )

    fun isMotif(theme: String): Boolean = !descriptive.contains(theme)

    /**
     * "mateIn2" -> "Mate in 2", "knightFork" -> "Knight fork" — or whatever a
     * translator called it. Splitting the camel case is the fallback for a
     * theme the catalogue has never seen, which is what a fresh Lichess import
     * brings in.
     */
    fun readable(theme: String): String = L.t("theme.$theme", spaced(theme))

    private fun spaced(theme: String): String {
        val spaced = StringBuilder()
        for (character in theme) {
            if ((character.isUpperCase() || isNumber(character)) && spaced.isNotEmpty() && spaced.last() != ' ') {
                spaced.append(' ')
            }
            spaced.append(character.lowercase())
        }
        return spaced.take(1).toString().uppercase() + spaced.drop(1)
    }

    /** Swift's `Character.isNumber`: a digit, a letter number or any other numeric character. */
    private fun isNumber(character: Char): Boolean = when (Character.getType(character).toByte()) {
        Character.DECIMAL_DIGIT_NUMBER, Character.LETTER_NUMBER, Character.OTHER_NUMBER -> true
        else -> false
    }
}

/**
 * A game somebody played, kept to be watched.
 *
 * Every one is a real game from a published collection of its players' own
 * games, and the moves are the moves as recorded — in the notation a book
 * prints, not pre-chewed into coordinates, so the app's own move generator has
 * to agree with the record before anything can be shown.
 */
@Serializable
data class ClassicGame(
    val id: String,
    val white: String,
    val black: String,
    val event: String,
    val site: String? = null,
    val year: Int,
    val result: String,
    val eco: String? = null,
    /**
     * True for the games named in the importer's own list — the ones nobody
     * needs a reason to watch.
     */
    val notable: Boolean,
    /** SAN, space separated. */
    val moves: String,
) {
    val players: String get() = "$white — $black"

    /** "Hastings, 1895 · 1–0" */
    val occasion: String
        get() = listOfNotNull(if (event.isEmpty()) null else event, year.toString())
            .joinToString(", ") + " · " + result

    val plyCount: Int get() = swiftSplit(moves, ' ').size
    val moveCount: Int get() = (plyCount + 1) / 2

    /** Everything a search box should match: the two players, where and when. */
    val haystack: String
        get() = "$white $black $event $year ${eco ?: ""}".lowercase()
}
