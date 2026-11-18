package com.artesoft.brasspawn.chess

/**
 * Standard algebraic notation for a legal move in this position: "Nxe5+".
 *
 * The fiddly part is disambiguation. When two identical pieces can reach
 * the same square the notation must say which one moved, using the file if
 * that distinguishes them, otherwise the rank, otherwise both.
 */
internal fun Position.sanFor(move: Move): String {
    if (move.kind == Move.Kind.KINGSIDE_CASTLE) return withSuffix("O-O", move)
    if (move.kind == Move.Kind.QUEENSIDE_CASTLE) return withSuffix("O-O-O", move)

    val piece = pieceAt(move.from) ?: return move.uci

    val text = StringBuilder(8)

    if (piece.kind == PieceKind.PAWN) {
        if (move.isCapture) {
            text.append('a' + move.from.file)
            text.append('x')
        }
        text.append(move.to.name)
        if (move.promotion != null) {
            text.append('=').append(move.promotion.letter.uppercaseChar())
        }
    } else {
        text.append(piece.kind.letter.uppercaseChar())
        text.append(disambiguation(move, piece))
        if (move.isCapture) text.append('x')
        text.append(move.to.name)
    }

    return withSuffix(text.toString(), move)
}

private fun Position.disambiguation(move: Move, piece: Piece): String {
    val rivals = legalMoves().filter { candidate ->
        candidate.to == move.to &&
            candidate.from != move.from &&
            pieceAt(candidate.from) == piece
    }
    if (rivals.isEmpty()) return ""

    val fileIsUnique = rivals.all { it.from.file != move.from.file }
    if (fileIsUnique) {
        return ('a' + move.from.file).toString()
    }

    val rankIsUnique = rivals.all { it.from.rank != move.from.rank }
    if (rankIsUnique) {
        return (move.from.rank + 1).toString()
    }

    return move.from.name
}

/** Appends "+" or "#" by looking at the position the move produces. */
private fun Position.withSuffix(text: String, move: Move): String {
    val next = makeUnchecked(move)
    if (next.isCheckmate) return "$text#"
    if (next.isCheck) return "$text+"
    return text
}

private val sanNoise = listOf("!", "?", "+", "#", "e.p.", " ")
private val printedNoise = listOf("!", "?", "+", "#")

/**
 * Parse SAN against this position. Lenient about decorations like "!?" and
 * the "e.p." suffix, strict about the move itself being legal.
 */
internal fun Position.parseSan(notation: String): Move? {
    var text = notation.trim { it == '\t' || Character.isSpaceChar(it) }
    for (noise in sanNoise) {
        text = text.replace(noise, "")
    }
    if (text.isEmpty()) return null

    val moves = legalMoves()

    if (text == "O-O" || text == "0-0") {
        return moves.firstOrNull { it.kind == Move.Kind.KINGSIDE_CASTLE }
    }
    if (text == "O-O-O" || text == "0-0-0") {
        return moves.firstOrNull { it.kind == Move.Kind.QUEENSIDE_CASTLE }
    }

    // Only the moves that could be this one are printed: those landing on
    // the square the text names, made by the piece it names. Printing is
    // what costs — each printed move is played to see whether it checks
    // or mates — and doing it for all thirty-odd legal moves, at every ply
    // of every game in a feed, was seconds of a phone's time before a
    // single story appeared.
    val destination: Square? = (text.length - 2 downTo 0).firstNotNullOfOrNull { index ->
        Square.parse(text.subSequence(index, index + 2))
    }
    val first = text[0]
    val kind = if (first in "KQRBN") PieceKind.fromLetter(first) ?: PieceKind.PAWN else PieceKind.PAWN
    val candidates = moves.filter { move ->
        (destination == null || move.to == destination) && pieceAt(move.from)?.kind == kind
    }

    // Matching by regenerating notation is slower than parsing the string,
    // but it cannot disagree with `san` — and a parser that disagrees
    // with its own printer is a bug that surfaces only in stored games.
    return candidates.firstOrNull { candidate ->
        var printed = sanFor(candidate)
        for (noise in printedNoise) {
            printed = printed.replace(noise, "")
        }
        printed == text
    }
}
