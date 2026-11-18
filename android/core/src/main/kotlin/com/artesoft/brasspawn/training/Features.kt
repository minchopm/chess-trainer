package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.chess.Piece
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.PieceKind
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import kotlin.math.abs

/**
 * Positional features of a position.
 *
 * The engine says which move is best; these say why, in the vocabulary a coach
 * would use — open files, rook placement, outposts, pawn structure, king
 * safety. Those are the handles a human can carry to the next game, which a
 * centipawn number is not.
 */
class PositionFeatures(position: Position) {
    data class FileInfo(
        val index: Int,
        val whitePawns: Int,
        val blackPawns: Int,
    ) {
        val name: String get() = ('a' + index).toString()
        val isOpen: Boolean get() = whitePawns == 0 && blackPawns == 0

        /** Half-open for the side that has no pawn on it. */
        val halfOpenFor: PieceColor?
            get() {
                if (whitePawns == 0 && blackPawns > 0) return PieceColor.WHITE
                if (blackPawns == 0 && whitePawns > 0) return PieceColor.BLACK
                return null
            }
    }

    data class HeavyPiece(
        val square: Square,
        val color: PieceColor,
        val kind: PieceKind,
        val onOpenFile: Boolean,
        val onHalfOpenFile: Boolean,
        val onSeventhRank: Boolean,
    )

    data class Knight(
        val square: Square,
        val color: PieceColor,
        val isOutpost: Boolean,
    )

    data class PawnStructure(
        val isolated: List<Square>,
        val doubled: List<Square>,
        val passed: List<Square>,
        val backward: List<Square>,
        val count: Int,
    )

    data class KingSafety(
        val square: Square?,
        /** Pawns shielding the king, counting those directly in front double. */
        val shield: Double,
        val openFilesNearby: Int,
        val hasCastled: Boolean,
    )

    enum class Phase(val rawValue: String) { OPENING("opening"), MIDDLEGAME("middlegame"), ENDGAME("endgame") }

    val files: List<FileInfo>
    val heavyPieces: List<HeavyPiece>
    val knights: List<Knight>
    val structure: Map<PieceColor, PawnStructure>
    val hasBishopPair: Map<PieceColor, Boolean>
    val material: Map<PieceColor, Int>
    val kingSafety: Map<PieceColor, KingSafety>
    val mobility: Map<PieceColor, Int>
    val phase: Phase

    /** Material in centipawns, positive when White is ahead. */
    val materialBalance: Int get() = (material[PieceColor.WHITE] ?: 0) - (material[PieceColor.BLACK] ?: 0)

    init {
        val pawnsByFile: Map<PieceColor, List<MutableList<Square>>> = mapOf(
            PieceColor.WHITE to List(8) { mutableListOf() },
            PieceColor.BLACK to List(8) { mutableListOf() },
        )
        val pieces = ArrayList<Pair<Square, Piece>>(32)

        for (index in 0 until 64) {
            val square = Square(index)
            val piece = position[square] ?: continue
            pieces.add(square to piece)
            if (piece.kind == PieceKind.PAWN) pawnsByFile.getValue(piece.color)[square.file].add(square)
        }

        files = (0 until 8).map { file ->
            FileInfo(
                index = file,
                whitePawns = pawnsByFile.getValue(PieceColor.WHITE)[file].size,
                blackPawns = pawnsByFile.getValue(PieceColor.BLACK)[file].size,
            )
        }

        val fileTable = files
        heavyPieces = pieces.mapNotNull { (square, piece) ->
            if (piece.kind != PieceKind.ROOK && piece.kind != PieceKind.QUEEN) return@mapNotNull null
            val file = fileTable[square.file]
            HeavyPiece(
                square = square,
                color = piece.color,
                kind = piece.kind,
                onOpenFile = file.isOpen,
                onHalfOpenFile = file.halfOpenFor == piece.color,
                onSeventhRank = piece.kind == PieceKind.ROOK && square.relativeRank(piece.color) == 7,
            )
        }

        knights = pieces.mapNotNull { (square, piece) ->
            if (piece.kind != PieceKind.KNIGHT) return@mapNotNull null
            Knight(
                square = square,
                color = piece.color,
                isOutpost = isOutpost(square, piece.color, pieces),
            )
        }

        structure = mapOf(
            PieceColor.WHITE to pawnStructure(PieceColor.WHITE, pawnsByFile, pieces),
            PieceColor.BLACK to pawnStructure(PieceColor.BLACK, pawnsByFile, pieces),
        )

        val bishops = mutableMapOf(PieceColor.WHITE to 0, PieceColor.BLACK to 0)
        val materialCount = mutableMapOf(PieceColor.WHITE to 0, PieceColor.BLACK to 0)
        for ((_, piece) in pieces) {
            if (piece.kind == PieceKind.BISHOP) bishops[piece.color] = bishops.getValue(piece.color) + 1
            materialCount[piece.color] = materialCount.getValue(piece.color) + piece.kind.value
        }
        hasBishopPair = mapOf(
            PieceColor.WHITE to (bishops.getValue(PieceColor.WHITE) >= 2),
            PieceColor.BLACK to (bishops.getValue(PieceColor.BLACK) >= 2),
        )
        material = materialCount

        kingSafety = mapOf(
            PieceColor.WHITE to kingSafety(PieceColor.WHITE, pieces, fileTable),
            PieceColor.BLACK to kingSafety(PieceColor.BLACK, pieces, fileTable),
        )

        mobility = mapOf(
            PieceColor.WHITE to mobility(PieceColor.WHITE, position),
            PieceColor.BLACK to mobility(PieceColor.BLACK, position),
        )

        val heavy = pieces.count { it.second.kind.letter in "qrbn" }
        phase = if (heavy >= 12) Phase.OPENING else if (heavy >= 6) Phase.MIDDLEGAME else Phase.ENDGAME
    }

    // MARK: - Component analysis

    companion object {
        /** Squares a pawn of this colour attacks. */
        internal fun pawnAttacks(from: Square, color: PieceColor): List<Square> {
            val rank = from.rank + (if (color == PieceColor.WHITE) 1 else -1)
            if (rank < 0 || rank >= 8) return emptyList()
            return listOf(from.file - 1, from.file + 1)
                .filter { it >= 0 && it < 8 }
                .map { Square.of(it, rank) }
        }

        /**
         * A knight is on an outpost when it stands in enemy territory, a friendly
         * pawn defends it, and no enemy pawn can ever come to chase it away.
         */
        internal fun isOutpost(square: Square, color: PieceColor, pieces: List<Pair<Square, Piece>>): Boolean {
            val rank = square.relativeRank(color)
            if (rank < 4 || rank > 6) return false

            val defended = pieces.any { (candidateSquare, piece) ->
                piece.kind == PieceKind.PAWN && piece.color == color &&
                    pawnAttacks(candidateSquare, color).contains(square)
            }
            if (!defended) return false

            val enemy = color.opponent
            val canBeChased = pieces.any { (candidateSquare, piece) ->
                if (piece.kind != PieceKind.PAWN || piece.color != enemy) return@any false
                if (abs(candidateSquare.file - square.file) != 1) return@any false
                // Only a pawn that has not yet passed the square can still attack it.
                if (color == PieceColor.WHITE) {
                    candidateSquare.rank > square.rank
                } else {
                    candidateSquare.rank < square.rank
                }
            }
            return !canBeChased
        }

        internal fun pawnStructure(
            color: PieceColor,
            pawnsByFile: Map<PieceColor, List<List<Square>>>,
            pieces: List<Pair<Square, Piece>>,
        ): PawnStructure {
            val own = pawnsByFile.getValue(color)
            val enemy = pawnsByFile.getValue(color.opponent)
            val isolated = ArrayList<Square>()
            val doubled = ArrayList<Square>()
            val passed = ArrayList<Square>()
            val backward = ArrayList<Square>()

            for (file in 0 until 8) {
                if (own[file].isEmpty()) continue
                val neighbours = (if (file > 0) own[file - 1].size else 0) + (if (file < 7) own[file + 1].size else 0)
                if (neighbours == 0) isolated.addAll(own[file])
                if (own[file].size > 1) doubled.addAll(own[file])

                for (square in own[file]) {
                    val ahead: (List<Square>) -> Boolean = { list ->
                        list.any { if (color == PieceColor.WHITE) it.rank > square.rank else it.rank < square.rank }
                    }
                    val blocked = ahead(enemy[file]) ||
                        (file > 0 && ahead(enemy[file - 1])) ||
                        (file < 7 && ahead(enemy[file + 1]))
                    if (!blocked) passed.add(square)

                    // Backward: no friendly pawn on an adjacent file is level with
                    // or behind it, and an enemy pawn covers the square in front.
                    val supported = listOf(
                        if (file > 0) own[file - 1] else emptyList(),
                        if (file < 7) own[file + 1] else emptyList(),
                    ).any { list ->
                        list.any { if (color == PieceColor.WHITE) it.rank <= square.rank else it.rank >= square.rank }
                    }
                    val frontRank = square.rank + (if (color == PieceColor.WHITE) 1 else -1)
                    if (!supported && frontRank >= 0 && frontRank < 8) {
                        val front = Square.of(file, frontRank)
                        val contested = pieces.any { (candidateSquare, piece) ->
                            piece.kind == PieceKind.PAWN && piece.color != color &&
                                pawnAttacks(candidateSquare, piece.color).contains(front)
                        }
                        if (contested) backward.add(square)
                    }
                }
            }

            return PawnStructure(
                isolated = isolated, doubled = doubled, passed = passed, backward = backward,
                count = own.sumOf { it.size },
            )
        }

        internal fun kingSafety(
            color: PieceColor, pieces: List<Pair<Square, Piece>>, files: List<FileInfo>,
        ): KingSafety {
            val king = pieces.firstOrNull { it.second == Piece.of(color, PieceKind.KING) }?.first
                ?: return KingSafety(square = null, shield = 0.0, openFilesNearby = 0, hasCastled = false)

            var shield = 0.0
            for (fileOffset in -1..1) {
                val file = king.file + fileOffset
                if (file < 0 || file >= 8) continue
                for (step in 1..2) {
                    val rank = king.rank + (if (color == PieceColor.WHITE) step else -step)
                    if (rank < 0 || rank >= 8) continue
                    val square = Square.of(file, rank)
                    if (pieces.any { it.first == square && it.second == Piece.of(color, PieceKind.PAWN) }) {
                        shield += if (step == 1) 1.0 else 0.5
                        break
                    }
                }
            }

            var openNearby = 0
            for (fileOffset in -1..1) {
                val file = king.file + fileOffset
                if (file < 0 || file >= 8) continue
                if (files[file].isOpen || files[file].halfOpenFor == color.opponent) openNearby += 1
            }

            return KingSafety(
                square = king,
                shield = shield,
                openFilesNearby = openNearby,
                hasCastled = king.relativeRank(color) == 1 && (king.file <= 2 || king.file >= 6),
            )
        }

        /**
         * Legal moves for a colour, obtained by handing that side the move.
         * Returns 0 when that would be an illegal position, which happens whenever
         * the other side is currently giving check.
         */
        internal fun mobility(of: PieceColor, position: Position): Int {
            if (position.sideToMove == of) return position.legalMoves().size

            val fields = swiftSplit(position.fen, ' ').toMutableList()
            if (fields.size < 4) return 0
            fields[1] = if (of == PieceColor.WHITE) "w" else "b"
            fields[3] = "-"  // an en-passant square cannot be inherited by the other side
            val probe = Position.fromFen(fields.joinToString(" ")) ?: return 0
            return probe.legalMoves().size
        }
    }
}
