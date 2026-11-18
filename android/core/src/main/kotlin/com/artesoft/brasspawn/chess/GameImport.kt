package com.artesoft.brasspawn.chess

/**
 * A game or a position, read out of whatever somebody pasted in.
 *
 * People arrive with what they have: a FEN copied from an engine, a PGN saved
 * from a site, the bare moves typed out of a book, or a list of UCI moves from
 * a log. All four are the same question — *what position is this, and how did
 * it get there* — so all four are read here rather than in four places.
 */
class GameImport internal constructor(
    /** Where the line starts. The standard array unless a FEN said otherwise. */
    val start: Position,
    /** The moves that were readable, in order. */
    val moves: List<Move>,
    /** The position after the last readable move. */
    val final: Position,
    /**
     * Set when the text ran out mid-line: the token that could not be played,
     * and how far it got. A paste with a typo in move thirty should give back
     * twenty-nine moves and say so, not nothing and no reason.
     */
    val stoppedAt: StoppedAt?,
) {
    data class StoppedAt(val token: String, val afterMoves: Int)

    val isEmpty: Boolean get() = moves.isEmpty()

    override fun equals(other: Any?): Boolean =
        other is GameImport &&
            start.fen == other.start.fen && moves == other.moves &&
            final.fen == other.final.fen &&
            stoppedAt == other.stoppedAt

    override fun hashCode(): Int {
        var result = start.fen.hashCode()
        result = 31 * result + moves.hashCode()
        result = 31 * result + final.fen.hashCode()
        result = 31 * result + (stoppedAt?.hashCode() ?: 0)
        return result
    }

    companion object {
        /**
         * Reads a paste. Returns null only when there is no position to be had at
         * all — not when some of the moves failed, which is reported instead.
         */
        fun read(text: String): GameImport? {
            val headers = pgnHeaders(text)
            val bare = bareFen(text)
            val start = headers["FEN"]?.let { Position.fromFen(it) }
                ?: bare
                ?: Position.start

            var position = start
            val moves = ArrayList<Move>()
            var stopped: StoppedAt? = null

            for (token in tokens(text)) {
                val move = move(token, position)
                if (move == null) {
                    stopped = StoppedAt(token, moves.size)
                    break
                }
                val next = position.makeOrNull(move)
                if (next == null) {
                    stopped = StoppedAt(token, moves.size)
                    break
                }
                position = next
                moves.add(move)
            }

            // A paste that yields neither a position of its own nor a single move
            // is not an import, it is a typo.
            if (moves.isEmpty() && start.fen == Position.start.fen && bare == null &&
                headers["FEN"] == null
            ) {
                return null
            }
            return GameImport(start, moves, position, stopped)
        }

        /** One move, in either of the two ways they are written down. */
        private fun move(token: String, position: Position): Move? {
            position.moveFromSan(token)?.let { return it }
            // UCI: e2e4, or e7e8q for a promotion.
            if (token.length != 4 && token.length != 5) return null
            val uci = Move.fromUci(token) ?: return null
            return position.legalMove(uci)
        }

        /** `[Event "..."]` and friends. */
        private fun pgnHeaders(text: String): Map<String, String> {
            val headers = HashMap<String, String>()
            for (line in lines(text)) {
                val trimmed = line.trim { isBlank(it) }
                if (!trimmed.startsWith("[") || !trimmed.endsWith("]")) continue
                val body = trimmed.drop(1).dropLast(1)
                val space = body.indexOf(' ')
                if (space < 0) continue
                val name = body.substring(0, space)
                val value = body.substring(space + 1).trim('"')
                headers[name] = value
            }
            return headers
        }

        /** A FEN pasted on its own, with no PGN around it. */
        private fun bareFen(text: String): Position? {
            for (line in lines(text)) {
                val trimmed = line.trim { isBlank(it) }
                // Six fields and a slash in the first is what makes a FEN a FEN.
                val fields = trimmed.split(' ').filter { it.isNotEmpty() }
                if (fields.size < 4 || !fields[0].contains('/')) continue
                Position.fromFen(trimmed)?.let { return it }
            }
            return null
        }

        /**
         * The move tokens, with everything a PGN carries around them removed.
         *
         * Headers, comments in braces, variations in brackets, the numbers, the
         * glyphs and the result. What is left is the mainline, which is the line
         * somebody meant to give us — a variation is somebody else's idea about a
         * move that was not played.
         */
        private fun tokens(text: String): List<String> {
            val stripped = StringBuilder(text.length)
            var braces = 0
            var brackets = 0
            var inHeader = false

            var index = 0
            while (index < text.length) {
                val character = text[index]
                index += 1

                // A carriage return and line feed together are one character to
                // Swift, and that character is not "\n": it separates tokens, but
                // it does not end a comment the way a bare line feed does below.
                // Read the same way here, so that a file with Windows line
                // endings imports as it does on the iPhone.
                if (character == '\r' && index < text.length && text[index] == '\n') {
                    index += 1
                    if (braces == 0 && brackets == 0 && !inHeader) stripped.append(' ')
                    continue
                }

                when (character) {
                    '{' -> braces += 1
                    '}' -> braces = maxOf(0, braces - 1)
                    '(' -> brackets += 1
                    ')' -> brackets = maxOf(0, brackets - 1)
                    '[' -> inHeader = true
                    ']' -> inHeader = false
                    ';' ->
                        // A semicolon comments out the rest of its line.
                        braces += 1
                    '\n' -> {
                        if (braces > 0) braces = 0
                        stripped.append(' ')
                    }
                    else -> if (braces == 0 && brackets == 0 && !inHeader) stripped.append(character)
                }
            }

            val result = ArrayList<String>()
            for (raw in splitOnWhitespace(stripped)) {
                token(raw)?.let { result.add(it) }
            }
            return result
        }

        /** One raw word of the mainline, cleaned up — or null when it is not a move at all. */
        private fun token(raw: String): String? {
            var token = raw
            // "12." and "12..." are numbering, and "12.e4" is numbering with a
            // move stuck to it.
            while (token.isNotEmpty() && (isNumber(token[0]) || token[0] == '.')) {
                val dot = token.indexOf('.')
                if (dot >= 0 && token.substring(0, dot).all { isNumber(it) }) {
                    token = token.substring(dot + 1).trimStart('.')
                } else if (token.all { isNumber(it) || it == '.' || it == '-' || it == '/' }) {
                    return null          // a move number, or a result like 1-0
                } else {
                    break
                }
            }
            if (token.isEmpty() || token == "*" || token.startsWith("$")) return null
            if (token in results) return null
            return token
        }

        private val results = listOf("1-0", "0-1", "1/2-1/2", "½-½")

        private val newline = Regex("\r\n|[\n\r\u000B\u000C\u0085  ]")

        /** The lines of a paste, blank ones left out. */
        private fun lines(text: String): List<String> = text.split(newline).filter { it.isNotEmpty() }

        /** A space or a tab: what is trimmed from the ends of a line. */
        private fun isBlank(character: Char): Boolean = character == '\t' || Character.isSpaceChar(character)

        private fun isWhitespace(character: Char): Boolean = character.isWhitespace() || character == '\u0085'

        /** Digits, and the other characters that stand for a number: "½" is one. */
        private fun isNumber(character: Char): Boolean = when (Character.getType(character).toByte()) {
            Character.DECIMAL_DIGIT_NUMBER, Character.LETTER_NUMBER, Character.OTHER_NUMBER -> true
            else -> false
        }

        private fun splitOnWhitespace(text: CharSequence): List<String> {
            val words = ArrayList<String>()
            var start = -1
            for (index in 0..text.length) {
                val boundary = index == text.length || isWhitespace(text[index])
                if (boundary) {
                    if (start >= 0) words.add(text.substring(start, index))
                    start = -1
                } else if (start < 0) {
                    start = index
                }
            }
            return words
        }
    }
}
