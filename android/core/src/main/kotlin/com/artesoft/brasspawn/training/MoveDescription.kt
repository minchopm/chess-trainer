package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.Piece
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.PieceKind
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import com.artesoft.brasspawn.match.L
import java.math.BigDecimal
import java.math.RoundingMode
import kotlin.math.abs

/** Turns a move into the reasons a coach would give for it. */
object MoveDescription {
    /**
     * Compare the positions either side of a move and name what it achieved.
     * Returns short clauses meant to be joined into one sentence.
     *
     * `move` is looked up among the legal moves of `position` first, so one
     * that came from notation — a UCI string, two taps on the board — and does
     * not yet say whether it is a capture or a castle is described as what it
     * is. (In the Swift code a move always carries its kind by the time it
     * gets here; in Kotlin `Position.make` takes either.)
     */
    fun clauses(
        before: PositionFeatures,
        after: PositionFeatures,
        move: Move,
        position: Position,
        resulting: Position,
    ): List<String> {
        @Suppress("NAME_SHADOWING")
        val move = position.legalMove(move) ?: move
        val piece = position[move.from] ?: return emptyList()
        val mover = piece.color
        val them = mover.opponent
        val captured = capturedPiece(move, position)

        // Checkmate ends the game, so nothing else about the move matters.
        // Listing pawn structure beside "delivers checkmate" reads as noise.
        if (resulting.isCheckmate) {
            return if (captured != null) {
                listOf(L.t("coach.mateCapturing", "delivers checkmate, capturing the %@", name(captured.kind)))
            } else {
                listOf(L.t("coach.mate", "delivers checkmate"))
            }
        }

        val clauses = ArrayList<String>()

        when (move.kind) {
            Move.Kind.KINGSIDE_CASTLE -> clauses.add(L.t("coach.castlesKingside", "castles kingside, tucking the king away"))
            Move.Kind.QUEENSIDE_CASTLE -> clauses.add(L.t("coach.castlesQueenside", "castles queenside"))
            else -> Unit
        }

        if (resulting.isCheck) clauses.add(L.t("coach.givesCheck", "gives check"))

        if (captured != null) {
            val gained = captured.kind.value
            val risked = piece.kind.value
            clauses.add(
                if (gained > risked + 50) {
                    L.t("coach.winsMaterial", "wins material — takes the %@", name(captured.kind))
                } else {
                    L.t("coach.captures", "captures the %@", name(captured.kind))
                }
            )
        }

        move.promotion?.let { promotion ->
            clauses.add(L.t("coach.promotes", "promotes to a %@", name(promotion)))
        }

        if (piece.kind == PieceKind.ROOK) {
            val landed = after.heavyPieces.firstOrNull { it.square == move.to }
            val departed = before.heavyPieces.firstOrNull { it.square == move.from }
            if (landed?.onOpenFile == true && departed?.onOpenFile != true) {
                clauses.add(L.t("coach.takesOpenFile", "takes the open %@-file", fileName(move.to.file)))
            } else if (landed?.onHalfOpenFile == true && departed?.onHalfOpenFile != true) {
                clauses.add(L.t("coach.halfOpenFile", "puts the rook on the half-open %@-file", fileName(move.to.file)))
            }
            if (landed?.onSeventhRank == true && departed?.onSeventhRank != true) {
                clauses.add(L.t("coach.seventhRank", "lands the rook on the seventh rank"))
            }
            val stacked = after.heavyPieces.filter {
                it.color == mover && it.kind == PieceKind.ROOK && it.square.file == move.to.file
            }
            if (stacked.size > 1) clauses.add(L.t("coach.doublesRooks", "doubles the rooks"))
        }

        if (piece.kind == PieceKind.KNIGHT && after.knights.firstOrNull { it.square == move.to }?.isOutpost == true) {
            clauses.add(L.t("coach.outpost", "plants the knight on the %@ outpost, where no pawn can dislodge it", move.to.name))
        }

        val ours = after.structure[mover]
        val wasOurs = before.structure[mover]
        if (ours != null && wasOurs != null && ours.passed.size > wasOurs.passed.size) {
            clauses.add(L.t("coach.passedPawn", "creates a passed pawn"))
        }

        val theirs = after.structure[them]
        val wasTheirs = before.structure[them]
        if (theirs != null && wasTheirs != null && theirs.isolated.size > wasTheirs.isolated.size) {
            clauses.add(L.t("coach.isolatesOpponent", "leaves the opponent with an isolated pawn"))
        }

        if (before.hasBishopPair[them] == true && after.hasBishopPair[them] == false) {
            clauses.add(L.t("coach.breaksBishopPair", "breaks up the enemy bishop pair"))
        }

        for ((index, file) in after.files.withIndex()) {
            if (file.isOpen && !before.files[index].isOpen) {
                clauses.add(L.t("coach.opensFile", "opens the %@-file", file.name))
            }
        }

        val mobilityNow = after.mobility[mover]
        val mobilityWas = before.mobility[mover]
        if (mobilityNow != null && mobilityWas != null && mobilityNow - mobilityWas >= 6) {
            clauses.add(L.t("coach.moreActivity", "sharply increases the activity of the pieces"))
        }

        val linesNow = after.kingSafety[them]?.openFilesNearby
        val linesWere = before.kingSafety[them]?.openFilesNearby
        if (linesNow != null && linesWere != null && linesNow > linesWere) {
            clauses.add(L.t("coach.opensKingLines", "pries open lines toward the enemy king"))
        }

        return clauses
    }

    /** A full sentence, or null when the move achieved nothing worth naming. */
    fun sentence(
        san: String,
        before: PositionFeatures,
        after: PositionFeatures,
        move: Move,
        position: Position,
        resulting: Position,
    ): String? {
        val parts = clauses(
            before = before, after = after, move = move,
            position = position, resulting = resulting,
        )
        if (parts.isEmpty()) return null
        return "$san ${join(parts)}."
    }

    /**
     * Expands compact algebraic notation into a sentence that can be read by
     * someone who does not yet know that `Rxf1+` means a rook capture on f1
     * with check. SAN is retained first so the explanation also teaches the
     * notation rather than replacing it.
     */
    fun detailedSentence(
        san: String,
        move: Move,
        position: Position,
        resulting: Position,
    ): String? {
        @Suppress("NAME_SHADOWING")
        val move = position.legalMove(move) ?: move
        val piece = position[move.from] ?: return null

        val side = L.color(piece.color)
        var sentence: String
        when (move.kind) {
            Move.Kind.KINGSIDE_CASTLE ->
                sentence = L.t("coach.detailedCastleKingside", "%@ — %@ castles kingside", san, side)
            Move.Kind.QUEENSIDE_CASTLE ->
                sentence = L.t("coach.detailedCastleQueenside", "%@ — %@ castles queenside", san, side)
            else -> {
                val captured = capturedPiece(move, position)
                sentence = if (captured != null) {
                    L.t(
                        "coach.detailedCapture",
                        "%@ — %@ moves the %@ from %@ to %@, capturing the %@",
                        san, side, name(piece.kind), move.from.name, move.to.name, name(captured.kind),
                    )
                } else {
                    L.t(
                        "coach.detailedMove",
                        "%@ — %@ moves the %@ from %@ to %@",
                        san, side, name(piece.kind), move.from.name, move.to.name,
                    )
                }
            }
        }

        move.promotion?.let { promotion ->
            sentence += L.t("coach.detailedPromotion", ", promoting to a %@", name(promotion))
        }

        if (resulting.isCheckmate) {
            sentence += L.t("coach.detailedCheckmate", ", delivering checkmate")
        } else if (resulting.isCheck) {
            sentence += L.t("coach.detailedCheck", ", giving check")
        } else if (position.isCheck) {
            sentence += L.t("coach.detailedEscape", ", escaping the check")
        }

        return "$sentence."
    }

    /** A static read of a position, for the judgement exercises. */
    fun summary(features: PositionFeatures): List<String> {
        val points = ArrayList<String>()

        val openFiles = features.files.filter { it.isOpen }.map { it.name }
        if (openFiles.isNotEmpty()) {
            points.add(
                if (openFiles.size > 1) {
                    L.t("summary.openFiles", "Open files: %@.", openFiles.joinToString(", "))
                } else {
                    L.t("summary.openFile", "Open file: %@.", openFiles.joinToString(", "))
                }
            )
        }

        for (color in listOf(PieceColor.WHITE, PieceColor.BLACK)) {
            val side = L.color(color)

            val activeRooks = features.heavyPieces.filter {
                it.color == color && it.kind == PieceKind.ROOK && (it.onOpenFile || it.onHalfOpenFile)
            }
            if (activeRooks.isNotEmpty()) {
                val squares = activeRooks.joinToString(" and ") { it.square.name }
                points.add(
                    if (activeRooks.size > 1) {
                        L.t("summary.rooksOpenLines", "%@ rooks on %@ control open lines.", side, squares)
                    } else {
                        L.t("summary.rookOpenLines", "%@ rook on %@ controls open lines.", side, squares)
                    }
                )
            }

            val outposts = features.knights.filter { it.color == color && it.isOutpost }
            if (outposts.isNotEmpty()) {
                points.add(L.t(
                    "summary.secureKnight", "%@ has a secure knight on %@.",
                    side, outposts.joinToString(", ") { it.square.name },
                ))
            }

            val structure = features.structure[color]
            if (structure != null) {
                if (structure.passed.isNotEmpty()) {
                    points.add(L.t(
                        "summary.passedPawn", "%@ has a passed pawn on %@.",
                        side, structure.passed.joinToString(", ") { it.name },
                    ))
                }
                if (structure.isolated.isNotEmpty()) {
                    val squares = structure.isolated.joinToString(", ") { it.name }
                    val plural = structure.isolated.size > 1
                    points.add(
                        if (plural) {
                            L.t("summary.isolatedPawns", "%@'s pawns on %@ are isolated.", side, squares)
                        } else {
                            L.t("summary.isolatedPawn", "%@'s pawn on %@ is isolated.", side, squares)
                        }
                    )
                }
                if (structure.backward.isNotEmpty()) {
                    points.add(L.t(
                        "summary.backwardPawn", "%@ has a backward pawn on %@.",
                        side, structure.backward.joinToString(", ") { it.name },
                    ))
                }
            }
        }

        if (features.hasBishopPair[PieceColor.WHITE] != features.hasBishopPair[PieceColor.BLACK]) {
            points.add(L.t(
                "summary.bishopPair", "%@ holds the bishop pair.",
                L.color(if (features.hasBishopPair[PieceColor.WHITE] == true) PieceColor.WHITE else PieceColor.BLACK),
            ))
        }

        val balance = features.materialBalance
        if (abs(balance) >= 75) {
            val pawns = abs(balance).toDouble() / 100
            points.add(L.t(
                "summary.material", "Material: %@ is up roughly %@ points.",
                L.color(if (balance > 0) PieceColor.WHITE else PieceColor.BLACK), twoPlaces(pawns),
            ))
        } else {
            points.add(L.t("summary.materialLevel", "Material is level."))
        }

        val white = features.mobility[PieceColor.WHITE]
        val black = features.mobility[PieceColor.BLACK]
        if (white != null && black != null && abs(white - black) >= 6) {
            points.add(L.t(
                "summary.moreActive", "%@ has noticeably more active pieces (%lld versus %lld legal moves).",
                L.color(if (white > black) PieceColor.WHITE else PieceColor.BLACK), maxOf(white, black), minOf(white, black),
            ))
        }

        return points
    }

    // MARK: - Helpers

    internal fun capturedPiece(move: Move, position: Position): Piece? {
        if (move.kind == Move.Kind.EN_PASSANT) {
            return position[Square.of(move.to.file, move.from.rank)]
        }
        return position[move.to]
    }

    fun name(of: PieceKind): String = when (of) {
        PieceKind.PAWN -> L.t("piece.pawn", "pawn")
        PieceKind.KNIGHT -> L.t("piece.knight", "knight")
        PieceKind.BISHOP -> L.t("piece.bishop", "bishop")
        PieceKind.ROOK -> L.t("piece.rook", "rook")
        PieceKind.QUEEN -> L.t("piece.queen", "queen")
        PieceKind.KING -> L.t("piece.king", "king")
    }

    internal fun fileName(index: Int): String = ('a' + index).toString()

    fun join(clauses: List<String>): String {
        if (clauses.size <= 1) return clauses.firstOrNull() ?: ""
        return L.t(
            "coach.joinClauses", "%@ and %@",
            clauses.dropLast(1).joinToString(", "), clauses.last(),
        )
    }

    /**
     * `String(format: "%.2f")`: two places, a tie rounded to even on the exact
     * value, which is what the C formatter does and Java's own does not.
     */
    private fun twoPlaces(value: Double): String =
        BigDecimal(value).setScale(2, RoundingMode.HALF_EVEN).toPlainString()
}
