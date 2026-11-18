package com.artesoft.brasspawn.chess

/**
 * Every legal move in this position: the pseudo-legal ones, less those that
 * leave the mover's own king attacked.
 *
 * The Swift filter plays each candidate on a copy of the whole position. Here
 * it is played on one scratch board and taken back, which asks the same
 * question — is my king attacked once this move is made — without making a
 * position per candidate; the board is all the answer depends on.
 */
internal fun Position.generateLegalMoves(): List<Move> {
    val candidates = pseudoLegalMoves()
    val scratch = board.copyOf()
    val king = kingIndex(sideToMove)
    val enemy = sideToMove.opponent
    val moves = ArrayList<Move>(candidates.size)
    for (move in candidates) {
        if (!leavesKingAttacked(scratch, move, king, enemy)) moves.add(move)
    }
    return moves
}

/**
 * Plays `move` on the scratch board, looks at the king, and puts the board
 * back. `king` is where the mover's king stands before the move, or -1 for a
 * board without one — which cannot be in check, and so allows everything.
 */
private fun Position.leavesKingAttacked(scratch: ByteArray, move: Move, king: Int, enemy: PieceColor): Boolean {
    val from = move.from.index
    val to = move.to.index
    val moving = scratch[from]

    // En passant takes from a square the moving pawn never lands on.
    val capturedSquare = if (move.kind == Move.Kind.EN_PASSANT) Square.of(move.to.file, move.from.rank).index else -1
    if (capturedSquare >= 0) scratch[capturedSquare] = EMPTY

    scratch[from] = EMPTY
    scratch[to] = if (move.promotion != null) pieceCode(sideToMove, move.promotion) else moving

    var rookFrom = -1
    var rookTo = -1
    if (move.isCastle) {
        val backRank = move.from.rank
        rookFrom = backRank * 8 + if (move.kind == Move.Kind.KINGSIDE_CASTLE) 7 else 0
        rookTo = backRank * 8 + if (move.kind == Move.Kind.KINGSIDE_CASTLE) 5 else 3
        scratch[rookTo] = scratch[rookFrom]
        scratch[rookFrom] = EMPTY
    }

    // Only a king move changes where the king is. It is looked for rather than
    // taken to be on `to`, so that a board somebody set up with two kings is
    // judged by the same one the Swift code would find.
    val kingCode = pieceCode(sideToMove, PieceKind.KING)
    val kingNow = if (moving == kingCode) scratch.indexOf(kingCode) else king
    val attacked = kingNow >= 0 && Position.isAttacked(scratch, kingNow, enemy)

    scratch[from] = board[from]
    scratch[to] = board[to]
    if (capturedSquare >= 0) scratch[capturedSquare] = board[capturedSquare]
    if (rookFrom >= 0) {
        scratch[rookFrom] = board[rookFrom]
        scratch[rookTo] = board[rookTo]
    }
    return attacked
}

/** Moves that respect piece movement rules but may leave the king in check. */
internal fun Position.pseudoLegalMoves(): ArrayList<Move> {
    val moves = ArrayList<Move>(48)

    for (index in 0 until 64) {
        val piece = Piece.fromCode(board[index].toInt()) ?: continue
        if (piece.color != sideToMove) continue
        val square = Square(index)
        when (piece.kind) {
            PieceKind.PAWN -> generatePawnMoves(square, moves)
            PieceKind.KNIGHT -> generateStepMoves(square, knightOffsets, moves)
            PieceKind.KING -> generateStepMoves(square, kingOffsets, moves)
            PieceKind.BISHOP -> generateSlidingMoves(square, bishopDirections, moves)
            PieceKind.ROOK -> generateSlidingMoves(square, rookDirections, moves)
            PieceKind.QUEEN -> {
                generateSlidingMoves(square, rookDirections, moves)
                generateSlidingMoves(square, bishopDirections, moves)
            }
        }
    }

    generateCastlingMoves(moves)
    return moves
}

/** Whether the piece with this board code belongs to `color`. Not to be asked of an empty square. */
private fun isColor(code: Byte, color: PieceColor): Boolean = (code <= 6) == (color == PieceColor.WHITE)

private fun Position.generateStepMoves(square: Square, offsets: IntArray, moves: MutableList<Move>) {
    for (i in offsets.indices step 2) {
        val file = square.file + offsets[i]
        val rank = square.rank + offsets[i + 1]
        if (file < 0 || file >= 8 || rank < 0 || rank >= 8) continue
        val target = Square.of(file, rank)
        val occupant = board[target.index]
        if (occupant != EMPTY) {
            if (!isColor(occupant, sideToMove)) {
                moves.add(Move(square, target, kind = Move.Kind.CAPTURE))
            }
        } else {
            moves.add(Move(square, target, kind = Move.Kind.QUIET))
        }
    }
}

private fun Position.generateSlidingMoves(square: Square, directions: IntArray, moves: MutableList<Move>) {
    for (i in directions.indices step 2) {
        val fileOffset = directions[i]
        val rankOffset = directions[i + 1]
        var file = square.file + fileOffset
        var rank = square.rank + rankOffset
        while (file >= 0 && file < 8 && rank >= 0 && rank < 8) {
            val target = Square.of(file, rank)
            val occupant = board[target.index]
            if (occupant != EMPTY) {
                if (!isColor(occupant, sideToMove)) {
                    moves.add(Move(square, target, kind = Move.Kind.CAPTURE))
                }
                break
            }
            moves.add(Move(square, target, kind = Move.Kind.QUIET))
            file += fileOffset
            rank += rankOffset
        }
    }
}

private val promotionKinds = arrayOf(PieceKind.QUEEN, PieceKind.ROOK, PieceKind.BISHOP, PieceKind.KNIGHT)

private fun appendPawnMove(moves: MutableList<Move>, from: Square, to: Square, kind: Move.Kind, promoting: Boolean) {
    if (promoting) {
        for (promotion in promotionKinds) {
            moves.add(Move(from, to, promotion, kind))
        }
    } else {
        moves.add(Move(from, to, kind = kind))
    }
}

private fun Position.generatePawnMoves(square: Square, moves: MutableList<Move>) {
    val step = sideToMove.pawnStep
    val promotionRank = sideToMove.promotionRank
    val forward = square.index + step

    // Single and double pushes.
    if (forward >= 0 && forward < 64 && board[forward] == EMPTY) {
        val target = Square(forward)
        appendPawnMove(moves, square, target, Move.Kind.QUIET, promoting = target.rank == promotionRank)

        if (square.rank == sideToMove.pawnRank) {
            val double = forward + step
            if (double >= 0 && double < 64 && board[double] == EMPTY) {
                moves.add(Move(square, Square(double), kind = Move.Kind.DOUBLE_PAWN_PUSH))
            }
        }
    }

    // Captures, including en passant.
    for (fileOffset in -1..1 step 2) {
        val file = square.file + fileOffset
        val rank = square.rank + if (sideToMove == PieceColor.WHITE) 1 else -1
        if (file < 0 || file >= 8 || rank < 0 || rank >= 8) continue
        val target = Square.of(file, rank)

        val occupant = board[target.index]
        if (occupant != EMPTY) {
            if (isColor(occupant, sideToMove)) continue
            appendPawnMove(moves, square, target, Move.Kind.CAPTURE, promoting = target.rank == promotionRank)
        } else if (target.index == enPassantIndex) {
            moves.add(Move(square, target, kind = Move.Kind.EN_PASSANT))
        }
    }
}

private fun Position.generateCastlingMoves(moves: MutableList<Move>) {
    val kingSquare = king(sideToMove) ?: return
    if (isInCheck(sideToMove)) return

    val backRank = if (sideToMove == PieceColor.WHITE) 0 else 7
    if (kingSquare != Square.of(4, backRank)) return

    val kingsideRight = if (sideToMove == PieceColor.WHITE) CastlingRights.whiteKingside else CastlingRights.blackKingside
    val queensideRight = if (sideToMove == PieceColor.WHITE) CastlingRights.whiteQueenside else CastlingRights.blackQueenside
    val enemy = sideToMove.opponent
    val rook = pieceCode(sideToMove, PieceKind.ROOK)

    // Kingside: f and g empty, and the king may not start, pass through, or
    // land on an attacked square.
    if (kingsideRight in castling &&
        board[backRank * 8 + 5] == EMPTY && board[backRank * 8 + 6] == EMPTY &&
        board[backRank * 8 + 7] == rook &&
        !isAttacked(Square.of(5, backRank), enemy) &&
        !isAttacked(Square.of(6, backRank), enemy)
    ) {
        moves.add(Move(kingSquare, Square.of(6, backRank), kind = Move.Kind.KINGSIDE_CASTLE))
    }

    // Queenside: b, c and d empty. The king only travels through d and c, so
    // b may be attacked — only the rook passes over it.
    if (queensideRight in castling &&
        board[backRank * 8 + 1] == EMPTY && board[backRank * 8 + 2] == EMPTY && board[backRank * 8 + 3] == EMPTY &&
        board[backRank * 8 + 0] == rook &&
        !isAttacked(Square.of(3, backRank), enemy) &&
        !isAttacked(Square.of(2, backRank), enemy)
    ) {
        moves.add(Move(kingSquare, Square.of(2, backRank), kind = Move.Kind.QUEENSIDE_CASTLE))
    }
}
