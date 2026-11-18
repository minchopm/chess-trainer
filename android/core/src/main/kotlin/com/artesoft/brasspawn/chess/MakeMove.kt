package com.artesoft.brasspawn.chess

/**
 * Apply a move that is already known to be generated from this position, and
 * hand back the position after it.
 *
 * Used where the move has just come out of the legal list, so it must not
 * itself check legality — that is the caller's job and the reason this is not
 * public. `Position.make` is the checked way in.
 */
internal fun Position.makeUnchecked(move: Move): Position {
    val squares = board.copyOf()
    var hash = hash
    val from = move.from.index
    val to = move.to.index

    val moving = Piece.fromCode(squares[from].toInt())
        ?: throw IllegalArgumentException("no piece on ${move.from} to play $move in $fen")
    val previousEnPassant = enPassantIndex

    // Remove the captured piece first; en passant takes from a square the
    // moving pawn never lands on.
    var captured: Piece? = null
    if (move.kind == Move.Kind.EN_PASSANT) {
        val capturedSquare = Square.of(move.to.file, move.from.rank).index
        captured = Piece.fromCode(squares[capturedSquare].toInt())
        squares[capturedSquare] = EMPTY
        if (captured != null) hash = hash xor Zobrist.pieces[Zobrist.index(captured)][capturedSquare]
    } else {
        val occupant = Piece.fromCode(squares[to].toInt())
        if (occupant != null) {
            captured = occupant
            hash = hash xor Zobrist.pieces[Zobrist.index(occupant)][to]
        }
    }

    squares[from] = EMPTY
    hash = hash xor Zobrist.pieces[Zobrist.index(moving)][from]

    val placed = if (move.promotion != null) Piece.of(moving.color, move.promotion) else moving
    squares[to] = placed.code
    hash = hash xor Zobrist.pieces[Zobrist.index(placed)][to]

    // The rook hops over the king; the king move above already happened.
    if (move.isCastle) {
        val backRank = if (moving.color == PieceColor.WHITE) 0 else 7
        val kingside = move.kind == Move.Kind.KINGSIDE_CASTLE
        val rookFrom = Square.of(if (kingside) 7 else 0, backRank).index
        val rookTo = Square.of(if (kingside) 5 else 3, backRank).index
        val rook = Piece.fromCode(squares[rookFrom].toInt())
            ?: throw IllegalArgumentException("no rook to castle with for $move in $fen")
        squares[rookFrom] = EMPTY
        squares[rookTo] = rook.code
        hash = hash xor Zobrist.pieces[Zobrist.index(rook)][rookFrom]
        hash = hash xor Zobrist.pieces[Zobrist.index(rook)][rookTo]
    }

    val nextCastling = updatedCastlingRights(castling, moving, move)

    val nextEnPassant = if (move.kind == Move.Kind.DOUBLE_PAWN_PUSH) {
        Square.of(move.from.file, (move.from.rank + move.to.rank) / 2).index
    } else {
        -1
    }

    if (previousEnPassant >= 0) hash = hash xor Zobrist.enPassantFile[previousEnPassant and 7]
    if (nextEnPassant >= 0) hash = hash xor Zobrist.enPassantFile[nextEnPassant and 7]
    if (castling != nextCastling) {
        hash = hash xor Zobrist.castling[castling.rawValue]
        hash = hash xor Zobrist.castling[nextCastling.rawValue]
    }

    val nextHalfmoveClock = if (moving.kind == PieceKind.PAWN || captured != null) 0 else halfmoveClock + 1
    val nextFullmoveNumber = if (sideToMove == PieceColor.BLACK) fullmoveNumber + 1 else fullmoveNumber
    hash = hash xor Zobrist.sideToMove

    // A pawn move or capture makes every earlier position unreachable, so
    // the repetition window can be cleared with it.
    val nextHistory = if (nextHalfmoveClock == 0) longArrayOf(hash) else history + hash

    return Position(
        board = squares,
        sideToMove = sideToMove.opponent,
        castling = nextCastling,
        enPassantIndex = nextEnPassant,
        halfmoveClock = nextHalfmoveClock,
        fullmoveNumber = nextFullmoveNumber,
        hash = hash,
        history = nextHistory,
    )
}

/**
 * Castling rights die when the king moves, when a rook leaves its corner,
 * and — easy to forget — when a rook is captured on its corner.
 */
private fun updatedCastlingRights(rights: CastlingRights, moving: Piece, move: Move): CastlingRights {
    var castling = rights
    if (moving.kind == PieceKind.KING) {
        castling -= if (moving.color == PieceColor.WHITE) {
            CastlingRights.whiteKingside + CastlingRights.whiteQueenside
        } else {
            CastlingRights.blackKingside + CastlingRights.blackQueenside
        }
    }

    castling -= cornerRight(move.from.index)
    castling -= cornerRight(move.to.index)
    return castling
}

/** The right that lives on a corner square, or none for any other square. */
private fun cornerRight(index: Int): CastlingRights = when (index) {
    0 -> CastlingRights.whiteQueenside
    7 -> CastlingRights.whiteKingside
    56 -> CastlingRights.blackQueenside
    63 -> CastlingRights.blackKingside
    else -> CastlingRights.none
}
