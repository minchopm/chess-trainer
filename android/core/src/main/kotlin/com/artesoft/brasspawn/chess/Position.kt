package com.artesoft.brasspawn.chess

import java.util.Collections

/**
 * A chess position and the rules that govern it.
 *
 * Move generation is pseudo-legal followed by a make/test/unmake legality
 * filter. That is slower than staying strictly legal during generation, but it
 * is far harder to get subtly wrong — and every awkward case (pinned pieces,
 * en passant exposing the king along a rank, castling through an attacked
 * square) falls out of it for free rather than needing its own special case.
 * Speed is not the constraint here: Stockfish does the searching.
 *
 * Immutable, where the Swift type is a struct that is copied and mutated:
 * [make] hands back the next position and leaves this one as it was, so a
 * position can be held by the screen, kept in a list or read from another
 * thread without anybody copying it first. Because nothing changes, the legal
 * moves are worked out once and remembered.
 */
class Position internal constructor(
    /** One byte a square, a1 first: 0 for empty, otherwise [Piece.code]. Never written to after construction. */
    internal val board: ByteArray,
    val sideToMove: PieceColor,
    val castling: CastlingRights,
    /** The en passant square's index, or -1: kept as an integer so it is not boxed. */
    internal val enPassantIndex: Int,
    val halfmoveClock: Int,
    val fullmoveNumber: Int,
    /** The Zobrist hash: the same 64 bits as the Swift `UInt64`, read as signed. */
    val hash: Long,
    /** Hashes reached since the last irreversible move, for repetition detection. */
    internal val history: LongArray,
) {
    /** The board as a list of 64, a1 first. Built on request; [pieceAt] is the cheap way to ask about one square. */
    val squares: List<Piece?> get() = List(64) { Piece.fromCode(board[it].toInt()) }

    val enPassant: Square? get() = if (enPassantIndex < 0) null else Square(enPassantIndex)

    // MARK: - FEN

    val fen: String
        get() {
            fenCache?.let { return it }
            val placement = StringBuilder(72)
            for (rank in 7 downTo 0) {
                var empty = 0
                for (file in 0 until 8) {
                    val piece = Piece.fromCode(board[rank * 8 + file].toInt())
                    if (piece != null) {
                        if (empty > 0) {
                            placement.append(empty)
                            empty = 0
                        }
                        placement.append(piece.character)
                    } else {
                        empty += 1
                    }
                }
                if (empty > 0) placement.append(empty)
                if (rank > 0) placement.append('/')
            }
            val ep = enPassant?.name ?: "-"
            val side = if (sideToMove == PieceColor.WHITE) "w" else "b"
            val text = "$placement $side ${castling.fenString} $ep $halfmoveClock $fullmoveNumber"
            fenCache = text
            return text
        }

    // Remembered answers. A position never changes, so each is worked out at
    // most once; two threads asking at the same moment both work it out and
    // get the same thing, which is why there is no lock.
    @Volatile private var fenCache: String? = null
    @Volatile private var legalMovesCache: List<Move>? = null

    // MARK: - Queries

    fun pieceAt(square: Square): Piece? = Piece.fromCode(board[square.index].toInt())

    operator fun get(square: Square): Piece? = pieceAt(square)

    /**
     * The same position, but with `color` to move.
     *
     * For planning a move before it is your turn. Deliberately unchecked: the
     * result can be a position no game could reach — both kings attacked, an
     * en passant square that no longer means anything — because it stands for
     * an intention rather than for a game. `legalMoves()` on it answers "what
     * could this piece do if it were my turn", which is exactly what a premove
     * is guessing at.
     */
    fun speculating(with: PieceColor): Position {
        val hash = computeHash(board, with, castling, -1)
        // The repetition history belongs to the real game, not to a sketch.
        return Position(board, with, castling, -1, halfmoveClock, fullmoveNumber, hash, longArrayOf(hash))
    }

    fun king(of: PieceColor): Square? {
        val index = kingIndex(of)
        return if (index < 0) null else Square(index)
    }

    /** Where `color`'s king stands, or -1. */
    internal fun kingIndex(color: PieceColor): Int {
        val king = pieceCode(color, PieceKind.KING)
        for (index in 0 until 64) {
            if (board[index] == king) return index
        }
        return -1
    }

    fun isInCheck(color: PieceColor): Boolean {
        val index = kingIndex(color)
        return index >= 0 && isAttacked(board, index, color.opponent)
    }

    val isCheck: Boolean get() = isInCheck(sideToMove)

    /**
     * Is `square` attacked by any piece of `color`?
     *
     * Looks outward from the square for attackers rather than generating every
     * enemy move, which keeps this cheap enough to call inside the legality
     * filter for every candidate move.
     */
    fun isAttacked(square: Square, by: PieceColor): Boolean = isAttacked(board, square.index, by)

    // MARK: - Moves

    /** Every legal move in this position. */
    fun legalMoves(): List<Move> {
        legalMovesCache?.let { return it }
        val moves = Collections.unmodifiableList(generateLegalMoves())
        legalMovesCache = moves
        return moves
    }

    /** Legal moves starting from a given square — what the board UI needs. */
    fun legalMoves(from: Square): List<Move> = legalMoves().filter { it.from == from }

    /**
     * The legal move a piece of notation stands for here, with its kind filled
     * in — or null when there is none. Notation alone (a tap from one square to
     * another, a UCI string) does not say whether a move is a capture or a
     * castle; the legal list does.
     */
    fun legalMove(notation: Move): Move? = legalMoves().firstOrNull { it.matchesNotation(of = notation) }

    /**
     * Play a move given in notation, and hand back the position it leads to.
     *
     * The move is matched against the legal list first, so it need not carry
     * its kind. One that is not legal here is an error in the caller, and is
     * thrown as one; use [makeOrNull] for a move that came from outside and
     * may be wrong.
     */
    fun make(move: Move): Position =
        makeOrNull(move) ?: throw IllegalArgumentException("$move is not legal in $fen")

    /** Play a move given in notation, if it is legal here. */
    fun makeOrNull(notation: Move): Position? {
        val move = legalMove(notation) ?: return null
        return makeUnchecked(move)
    }

    /** Play a move given as UCI text — "e2e4", "e7e8q" — if it reads and is legal here. */
    fun makeUci(uci: String): Position? {
        val parsed = Move.fromUci(uci) ?: return null
        return makeOrNull(parsed)
    }

    // MARK: - Notation

    /**
     * Standard algebraic notation for a legal move in this position: "Nxe5+".
     * The move has to be one of [legalMoves] — or run through [legalMove] first
     * — because the notation depends on the kind of move it is.
     */
    fun san(move: Move): String = sanFor(move)

    /**
     * Parse SAN against this position. Lenient about decorations like "!?" and
     * the "e.p." suffix, strict about the move itself being legal.
     */
    fun moveFromSan(san: String): Move? = parseSan(san)

    // MARK: - Game state

    val isCheckmate: Boolean get() = isCheck && legalMoves().isEmpty()
    val isStalemate: Boolean get() = !isCheck && legalMoves().isEmpty()

    val isFiftyMoveRule: Boolean get() = halfmoveClock >= 100

    val isThreefoldRepetition: Boolean
        get() {
            if (history.isEmpty()) return false
            val current = history[history.size - 1]
            var count = 0
            for (value in history) {
                if (value == current) count += 1
            }
            return count >= 3
        }

    /** Positions from which no sequence of legal moves can produce checkmate. */
    val isInsufficientMaterial: Boolean
        get() {
            var knights = 0
            var bishopsOnLight = 0
            var bishopsOnDark = 0

            for (index in 0 until 64) {
                val piece = Piece.fromCode(board[index].toInt()) ?: continue
                when (piece.kind) {
                    PieceKind.KING -> continue
                    PieceKind.KNIGHT -> knights += 1
                    PieceKind.BISHOP -> {
                        val square = Square(index)
                        if ((square.file + square.rank) % 2 == 0) bishopsOnDark += 1 else bishopsOnLight += 1
                    }
                    else -> return false // any pawn, rook or queen can still mate
                }
            }

            val bishops = bishopsOnLight + bishopsOnDark
            if (knights == 0 && bishops == 0) return true                 // bare kings
            if (knights == 1 && bishops == 0) return true                 // king and knight
            if (knights == 0 && bishops >= 1) {
                // Any number of bishops, all on one colour, can never mate.
                return bishopsOnLight == 0 || bishopsOnDark == 0
            }
            return false
        }

    val isDraw: Boolean
        get() = isStalemate || isInsufficientMaterial || isFiftyMoveRule || isThreefoldRepetition

    val isGameOver: Boolean get() = isCheckmate || isDraw

    // MARK: - Perft

    /**
     * Count leaf nodes at a fixed depth.
     *
     * This is the standard way to prove a move generator correct: the counts
     * for well-known positions are published and unforgiving. A generator that
     * mishandles en passant, castling rights or promotion under-promotion will
     * match at depth 1 and diverge by depth 3.
     */
    fun perft(depth: Int): Long = countLeaves(depth)

    /** Per-move breakdown, for locating exactly where a count diverges. */
    fun perftDivide(depth: Int): List<PerftCount> = divideLeaves(depth)

    override fun toString(): String = fen

    companion object {
        const val startFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

        /** The standard starting array. */
        val start: Position = fromFen(startFen)!!

        fun fromFen(fen: String): Position? {
            val fields = fen.split(' ').filter { it.isNotEmpty() }
            if (fields.size < 4) return null

            val board = ByteArray(64)
            var rank = 7
            var file = 0
            for (character in fields[0]) {
                val digit = character.digitToIntOrNull()
                if (character == '/') {
                    if (file != 8) return null
                    rank -= 1
                    file = 0
                    if (rank < 0) return null
                } else if (digit != null && digit >= 1 && digit <= 8) {
                    file += digit
                    if (file > 8) return null
                } else {
                    val piece = Piece.fromCharacter(character) ?: return null
                    if (file >= 8) return null
                    board[rank * 8 + file] = piece.code
                    file += 1
                }
            }
            if (rank != 0 || file != 8) return null

            val side = fields[1].first()
            if (side != 'w' && side != 'b') return null

            var rights = CastlingRights.none
            if (fields[2] != "-") {
                for (character in fields[2]) {
                    rights += when (character) {
                        'K' -> CastlingRights.whiteKingside
                        'Q' -> CastlingRights.whiteQueenside
                        'k' -> CastlingRights.blackKingside
                        'q' -> CastlingRights.blackQueenside
                        else -> return null
                    }
                }
            }

            var ep = -1
            if (fields[3] != "-") {
                val square = Square.parse(fields[3]) ?: return null
                ep = square.index
            }

            val sideToMove = if (side == 'w') PieceColor.WHITE else PieceColor.BLACK
            val hash = computeHash(board, sideToMove, rights, ep)
            val position = Position(
                board = board,
                sideToMove = sideToMove,
                castling = rights,
                enPassantIndex = ep,
                halfmoveClock = if (fields.size > 4) fields[4].toIntOrNull() ?: 0 else 0,
                fullmoveNumber = if (fields.size > 5) fields[5].toIntOrNull() ?: 1 else 1,
                hash = hash,
                // The position as given counts as the first occurrence for repetition.
                history = longArrayOf(hash),
            )

            // A position where both kings are not present, or where the side not to
            // move is in check, cannot arise in a game. Rejecting it here stops such
            // positions reaching the engine, which answers them with "bestmove
            // (none)" and looks like a crash.
            if (position.kingIndex(PieceColor.WHITE) < 0 || position.kingIndex(PieceColor.BLACK) < 0) return null
            if (position.isInCheck(sideToMove.opponent)) return null
            return position
        }

        internal fun computeHash(
            board: ByteArray, sideToMove: PieceColor, castling: CastlingRights, enPassantIndex: Int,
        ): Long {
            var value = 0L
            for (index in 0 until 64) {
                val code = board[index].toInt()
                if (code != 0) value = value xor Zobrist.pieces[code - 1][index]
            }
            value = value xor Zobrist.castling[castling.rawValue]
            if (enPassantIndex >= 0) value = value xor Zobrist.enPassantFile[enPassantIndex and 7]
            if (sideToMove == PieceColor.BLACK) value = value xor Zobrist.sideToMove
            return value
        }

        /**
         * [Position.isAttacked], on any board: the legality filter asks it of a
         * board with a candidate move played on it.
         */
        internal fun isAttacked(board: ByteArray, index: Int, color: PieceColor): Boolean {
            val file = index and 7
            val rank = index shr 3

            // Pawns: step back along the direction that colour's pawns capture.
            val pawn = pieceCode(color, PieceKind.PAWN)
            val pawnRank = rank + if (color == PieceColor.WHITE) -1 else 1
            if (pawnRank in 0..7) {
                if (file > 0 && board[pawnRank * 8 + file - 1] == pawn) return true
                if (file < 7 && board[pawnRank * 8 + file + 1] == pawn) return true
            }

            val knight = pieceCode(color, PieceKind.KNIGHT)
            for (i in knightOffsets.indices step 2) {
                val f = file + knightOffsets[i]
                val r = rank + knightOffsets[i + 1]
                if (f >= 0 && f < 8 && r >= 0 && r < 8 && board[r * 8 + f] == knight) return true
            }

            val king = pieceCode(color, PieceKind.KING)
            for (i in kingOffsets.indices step 2) {
                val f = file + kingOffsets[i]
                val r = rank + kingOffsets[i + 1]
                if (f >= 0 && f < 8 && r >= 0 && r < 8 && board[r * 8 + f] == king) return true
            }

            val queen = pieceCode(color, PieceKind.QUEEN)
            val rook = pieceCode(color, PieceKind.ROOK)
            for (i in rookDirections.indices step 2) {
                if (slidingAttacker(board, file, rank, rookDirections[i], rookDirections[i + 1], rook, queen)) return true
            }
            val bishop = pieceCode(color, PieceKind.BISHOP)
            for (i in bishopDirections.indices step 2) {
                if (slidingAttacker(board, file, rank, bishopDirections[i], bishopDirections[i + 1], bishop, queen)) return true
            }
            return false
        }

        /** Walks one ray; a queen counts as both a rook and a bishop. */
        private fun slidingAttacker(
            board: ByteArray, file: Int, rank: Int, fileOffset: Int, rankOffset: Int,
            slider: Byte, queen: Byte,
        ): Boolean {
            var f = file + fileOffset
            var r = rank + rankOffset
            while (f >= 0 && f < 8 && r >= 0 && r < 8) {
                val code = board[r * 8 + f]
                if (code != EMPTY) return code == slider || code == queen
                f += fileOffset
                r += rankOffset
            }
            return false
        }
    }
}

// Step and ray tables, as (file, rank) pairs laid end to end.
internal val knightOffsets = intArrayOf(1, 2, 2, 1, 2, -1, 1, -2, -1, -2, -2, -1, -2, 1, -1, 2)
internal val kingOffsets = intArrayOf(1, 0, 1, 1, 0, 1, -1, 1, -1, 0, -1, -1, 0, -1, 1, -1)
internal val rookDirections = intArrayOf(1, 0, -1, 0, 0, 1, 0, -1)
internal val bishopDirections = intArrayOf(1, 1, 1, -1, -1, 1, -1, -1)
