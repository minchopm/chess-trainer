package com.artesoft.brasspawn.chess

// Basic types. Squares are 0...63 with a1 = 0 and h8 = 63, so file and rank
// arithmetic is plain integer maths and the board is one flat array.

enum class PieceColor {
    WHITE, BLACK;

    val opponent: PieceColor get() = if (this == WHITE) BLACK else WHITE

    /** Direction a pawn of this colour advances, in squares. */
    val pawnStep: Int get() = if (this == WHITE) 8 else -8

    /** Rank a pawn of this colour starts on. */
    val pawnRank: Int get() = if (this == WHITE) 1 else 6

    /** Rank a pawn of this colour promotes on. */
    val promotionRank: Int get() = if (this == WHITE) 7 else 0
}

enum class PieceKind {
    PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING;

    val letter: Char
        get() = when (this) {
            PAWN -> 'p'
            KNIGHT -> 'n'
            BISHOP -> 'b'
            ROOK -> 'r'
            QUEEN -> 'q'
            KING -> 'k'
        }

    /** Rough material value in centipawns, used for explanations rather than search. */
    val value: Int
        get() = when (this) {
            PAWN -> 100
            KNIGHT -> 300
            BISHOP -> 325
            ROOK -> 500
            QUEEN -> 900
            KING -> 0
        }

    companion object {
        /** The kind a letter stands for, in either case: "n" and "N" are both a knight. */
        fun fromLetter(letter: Char): PieceKind? = when (letter.lowercaseChar()) {
            'p' -> PAWN
            'n' -> KNIGHT
            'b' -> BISHOP
            'r' -> ROOK
            'q' -> QUEEN
            'k' -> KING
            else -> null
        }
    }
}

data class Piece(val color: PieceColor, val kind: PieceKind) {
    /** The FEN letter: upper case for White, lower case for Black. */
    val character: Char
        get() = if (color == PieceColor.WHITE) kind.letter.uppercaseChar() else kind.letter

    /**
     * How the board stores this piece: 1...12, with 0 for an empty square.
     * One byte a square keeps a position cheap to copy, which matters because
     * every move makes a new one.
     */
    internal val code: Byte get() = pieceCode(color, kind)

    companion object {
        /** The twelve pieces, by board code; index 0 is the empty square. */
        private val byCode: Array<Piece?> = arrayOfNulls<Piece>(13).also { table ->
            for (color in PieceColor.entries) {
                for (kind in PieceKind.entries) {
                    table[pieceCode(color, kind).toInt()] = Piece(color, kind)
                }
            }
        }

        /** The shared instance for a colour and kind, so reading a board allocates nothing. */
        fun of(color: PieceColor, kind: PieceKind): Piece = byCode[pieceCode(color, kind).toInt()]!!

        fun fromCharacter(character: Char): Piece? {
            val kind = PieceKind.fromLetter(character) ?: return null
            return of(if (character.isUpperCase()) PieceColor.WHITE else PieceColor.BLACK, kind)
        }

        internal fun fromCode(code: Int): Piece? = byCode[code]
    }
}

/** The board code of an empty square. */
internal const val EMPTY: Byte = 0

/** The board code of a piece: colour times six, plus the kind, plus one. */
internal fun pieceCode(color: PieceColor, kind: PieceKind): Byte =
    (color.ordinal * 6 + kind.ordinal + 1).toByte()

/** A board square, 0...63, a1 = 0. */
@JvmInline
value class Square(val index: Int) {
    val file: Int get() = index and 7
    val rank: Int get() = index shr 3

    /** "e4". */
    val name: String get() = "${'a' + file}${'1' + rank}"

    /** Rank counted from a side's own back rank: a1 is rank 1 for White, a8 for Black. */
    fun relativeRank(color: PieceColor): Int = if (color == PieceColor.WHITE) rank + 1 else 8 - rank

    override fun toString(): String = name

    companion object {
        fun of(file: Int, rank: Int): Square = Square(rank * 8 + file)

        /** Reads "e4". Exactly two characters, a lower-case file and a rank; anything else is null. */
        fun parse(name: CharSequence): Square? {
            if (name.length != 2) return null
            val file = name[0]
            val rank = name[1]
            if (file < 'a' || file > 'h' || rank < '1' || rank > '8') return null
            return Square((rank - '1') * 8 + (file - 'a'))
        }
    }
}

@JvmInline
value class CastlingRights(val rawValue: Int) {
    val isEmpty: Boolean get() = rawValue == 0

    operator fun contains(other: CastlingRights): Boolean = rawValue and other.rawValue == other.rawValue

    operator fun plus(other: CastlingRights): CastlingRights = CastlingRights(rawValue or other.rawValue)

    operator fun minus(other: CastlingRights): CastlingRights = CastlingRights(rawValue and other.rawValue.inv())

    val fenString: String
        get() {
            if (isEmpty) return "-"
            var text = ""
            if (contains(whiteKingside)) text += "K"
            if (contains(whiteQueenside)) text += "Q"
            if (contains(blackKingside)) text += "k"
            if (contains(blackQueenside)) text += "q"
            return text
        }

    override fun toString(): String = fenString

    companion object {
        val none = CastlingRights(0)
        val whiteKingside = CastlingRights(1 shl 0)
        val whiteQueenside = CastlingRights(1 shl 1)
        val blackKingside = CastlingRights(1 shl 2)
        val blackQueenside = CastlingRights(1 shl 3)
        val all = CastlingRights(0b1111)
    }
}
