package com.artesoft.brasspawn.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.Piece
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.PieceKind
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import com.artesoft.brasspawn.data.t
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.min

/** Colours for the board, chosen to read on the photographed wood. */
object BoardColors {
    val light = Color(0xFFE9D2A6)
    val dark = Color(0xFF8A6238)
    val lastMove = Color(1.0f, 0.839f, 0.361f, 0.5f)
    val selection = Color(0.20f, 0.48f, 0.85f, 0.42f)
    val check = Color(0.851f, 0.439f, 0.373f)
    /** The dot on a square a piece may move to: dark on light squares, light on dark ones. */
    val hint = Color(0f, 0f, 0f, 0.32f)
    val hintOnDark = Color(1f, 0.98f, 0.94f, 0.46f)
    val coachArrow = Color(0.424f, 0.749f, 0.451f)
    val suggestion = Color(0.357f, 0.608f, 0.835f)
    val premove = Color(0.357f, 0.608f, 0.835f, 0.42f)
}

/** An arrow the coach draws: the move it would have played. */
data class BoardArrow(val from: Square, val to: Square, val color: Color = BoardColors.coachArrow)

/** A ring around a square: the first hint names the piece without giving away where it goes. */
data class BoardRing(val square: Square, val color: Color = BoardColors.suggestion)

/** The image of a piece, from the photographed set: light side boxwood, dark side `darkSet`. */
fun pieceArt(piece: Piece, darkSet: String = "black"): String {
    val side = if (piece.color == PieceColor.WHITE) "white" else darkSet
    val kind = when (piece.kind) {
        PieceKind.KING -> "king"
        PieceKind.QUEEN -> "queen"
        PieceKind.BISHOP -> "bishop"
        PieceKind.KNIGHT -> "knight"
        PieceKind.ROOK -> "rook"
        PieceKind.PAWN -> "pawn"
    }
    return "pieces/$side-$kind.png"
}

/**
 * The board, read from above.
 *
 * It shows a position and, when `legalMoves` is not empty, lets the player
 * make one of them: tap a piece then a square, or drag the piece there. A
 * pawn reaching the last rank asks what it becomes. The board never changes
 * the position itself — it reports the move and the owner decides.
 */
@Composable
fun ChessBoard(
    position: Position,
    modifier: Modifier = Modifier,
    orientation: PieceColor = PieceColor.WHITE,
    legalMoves: List<Move> = emptyList(),
    lastMove: Pair<Square, Square>? = null,
    rings: List<BoardRing> = emptyList(),
    arrows: List<BoardArrow> = emptyList(),
    showCoordinates: Boolean = true,
    darkSet: String = "black",
    onMove: (Move) -> Unit = {},
) {
    val context = LocalContext.current.applicationContext
    val pieces = remember(darkSet) {
        buildMap {
            for (color in PieceColor.entries) for (kind in PieceKind.entries) {
                val piece = Piece.of(color, kind)
                Art.load(context, pieceArt(piece, darkSet))?.let { put(piece, it) }
            }
        }
    }
    val lightWood = rememberArt("board/wood-light.png")
    val darkWood = rememberArt("board/wood-dark.png")
    val measurer = rememberTextMeasurer()

    var selected by remember { mutableStateOf<Square?>(null) }
    var dragging by remember { mutableStateOf<Square?>(null) }
    var dragAt by remember { mutableStateOf(Offset.Zero) }
    var promotion by remember { mutableStateOf<List<Move>?>(null) }
    val moves by rememberUpdatedState(legalMoves)
    val report by rememberUpdatedState(onMove)
    val side by rememberUpdatedState(orientation)

    // A new position ends whatever was half done on the old one.
    LaunchedEffect(position) {
        selected = null
        dragging = null
        promotion = null
    }

    // The piece that just moved slides in from where it came.
    val slide = remember { Animatable(1f) }
    LaunchedEffect(lastMove, position) {
        if (lastMove != null) {
            slide.snapTo(0f)
            slide.animateTo(1f, tween(140))
        }
    }

    fun attempt(from: Square, to: Square) {
        val candidates = moves.filter { it.from == from && it.to == to }
        when {
            candidates.isEmpty() -> Unit
            candidates.size == 1 -> report(candidates[0])
            else -> promotion = candidates
        }
    }

    // The chessboard itself is never mirrored in right-to-left locales: a1 is always at the bottom-left for White.
    androidx.compose.runtime.CompositionLocalProvider(
        androidx.compose.ui.platform.LocalLayoutDirection provides androidx.compose.ui.unit.LayoutDirection.Ltr,
    ) {
    Box(
        modifier
            .aspectRatio(1f)
            .clip(RoundedCornerShape(6.dp))
            .semantics { contentDescription = t("play.board", "Board") }
    ) {
        Canvas(
            Modifier
                .fillMaxSize()
                .pointerInput(Unit) {
                    awaitEachGesture {
                        val down = awaitFirstDown()
                        val cell = size.width / 8f
                        val start = squareAt(down.position, cell, side) ?: return@awaitEachGesture
                        val ownPiece = moves.any { it.from == start }
                        var moved = false
                        if (ownPiece) {
                            dragging = start
                            dragAt = down.position
                        }
                        while (true) {
                            val event = awaitPointerEvent()
                            val change = event.changes.firstOrNull { it.id == down.id } ?: break
                            if (!change.pressed) {
                                val end = squareAt(change.position, cell, side)
                                val from = dragging
                                dragging = null
                                when {
                                    // Dragged to another square: that is the move.
                                    from != null && moved && end != null && end != from -> {
                                        selected = null
                                        attempt(from, end)
                                    }
                                    // Tapped a square the selected piece can go to.
                                    selected != null && end != null && moves.any { it.from == selected && it.to == end } -> {
                                        val origin = selected!!
                                        selected = null
                                        attempt(origin, end)
                                    }
                                    // Tapped a piece that can move: select it (or let go of it).
                                    ownPiece -> selected = if (selected == start) null else start
                                    else -> selected = null
                                }
                                break
                            }
                            if (dragging != null) {
                                val delta = change.positionChange()
                                if (hypot(change.position.x - down.position.x, change.position.y - down.position.y) > cell * 0.18f) moved = true
                                if (delta != Offset.Zero) {
                                    dragAt = change.position
                                    change.consume()
                                }
                            }
                        }
                    }
                }
        ) {
            val cell = size.width / 8f
            drawSquares(cell, lightWood, darkWood)

            fun origin(square: Square): Offset {
                val file = if (orientation == PieceColor.WHITE) square.file else 7 - square.file
                val rank = if (orientation == PieceColor.WHITE) 7 - square.rank else square.rank
                return Offset(file * cell, rank * cell)
            }
            fun fill(square: Square, color: Color) = drawRect(color, origin(square), Size(cell, cell))

            lastMove?.let { (from, to) ->
                fill(from, BoardColors.lastMove)
                fill(to, BoardColors.lastMove)
            }
            (dragging ?: selected)?.let { fill(it, BoardColors.selection) }
            if (position.isCheck) position.king(position.sideToMove)?.let { king ->
                val centre = origin(king) + Offset(cell / 2, cell / 2)
                drawCircle(
                    androidx.compose.ui.graphics.Brush.radialGradient(
                        listOf(BoardColors.check, BoardColors.check.copy(alpha = 0.55f), Color.Transparent), centre, cell * 0.62f,
                    ),
                    cell * 0.62f, centre,
                )
            }
            if (showCoordinates) drawCoordinates(cell, orientation, measurer)

            // Pieces, the moving one last so it passes over the others.
            val sliding = lastMove?.takeIf { slide.value < 1f }
            for (index in 0 until 64) {
                val square = Square(index)
                val piece = position.pieceAt(square) ?: continue
                if (square == dragging || square == sliding?.second) continue
                drawPiece(pieces[piece], origin(square), cell)
            }
            sliding?.let { (from, to) ->
                position.pieceAt(to)?.let { piece ->
                    val a = origin(from)
                    val b = origin(to)
                    drawPiece(pieces[piece], a + (b - a) * slide.value, cell)
                }
            }

            // Where the chosen piece may go.
            (dragging ?: selected)?.let { from ->
                for (move in moves) {
                    if (move.from != from) continue
                    val centre = origin(move.to) + Offset(cell / 2, cell / 2)
                    val onDark = (move.to.file + move.to.rank) % 2 == 0
                    val color = if (onDark || position.pieceAt(move.to) != null) BoardColors.hintOnDark else BoardColors.hint
                    if (position.pieceAt(move.to) != null) drawCircle(color, cell * 0.44f, centre, style = Stroke(cell * 0.07f))
                    else drawCircle(color, cell * 0.16f, centre)
                }
            }

            for (ring in rings) {
                val centre = origin(ring.square) + Offset(cell / 2, cell / 2)
                drawCircle(ring.color.copy(alpha = 0.92f), cell * 0.42f, centre, style = Stroke(cell * 0.08f))
            }
            for (arrow in arrows) drawArrow(origin(arrow.from) + Offset(cell / 2, cell / 2), origin(arrow.to) + Offset(cell / 2, cell / 2), cell, arrow.color)

            dragging?.let { from ->
                position.pieceAt(from)?.let { piece ->
                    // Lifted: a little larger, and above the finger so it can be seen.
                    val lifted = cell * 1.35f
                    drawPiece(pieces[piece], Offset(dragAt.x - lifted / 2, dragAt.y - lifted * 0.85f), lifted)
                }
            }
        }

        promotion?.let { choices ->
            Box(
                Modifier.fillMaxSize().background(Theatre.ink.copy(alpha = 0.6f)).clickable { promotion = null },
                contentAlignment = Alignment.Center,
            ) {
                Row(
                    Modifier
                        .clip(RoundedCornerShape(14.dp)).background(Theatre.ink3)
                        .border(1.dp, Theatre.brass.copy(alpha = 0.6f), RoundedCornerShape(14.dp))
                        .padding(10.dp)
                        .semantics { contentDescription = t("board.promoteTo", "Promote to") },
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    for (kind in listOf(PieceKind.QUEEN, PieceKind.ROOK, PieceKind.BISHOP, PieceKind.KNIGHT)) {
                        val move = choices.firstOrNull { it.promotion == kind } ?: continue
                        val art = pieces[Piece.of(position.sideToMove, kind)] ?: continue
                        Image(
                            art, contentDescription = kind.name.lowercase(),
                            modifier = Modifier.size(58.dp).clip(RoundedCornerShape(10.dp)).clickable {
                                promotion = null
                                report(move)
                            },
                        )
                    }
                }
            }
        }
    }
    }
}

private fun squareAt(point: Offset, cell: Float, orientation: PieceColor): Square? {
    val column = (point.x / cell).toInt()
    val row = (point.y / cell).toInt()
    if (column !in 0..7 || row !in 0..7 || point.x < 0 || point.y < 0) return null
    return if (orientation == PieceColor.WHITE) Square.of(column, 7 - row) else Square.of(7 - column, row)
}

private fun DrawScope.drawSquares(cell: Float, light: ImageBitmap?, dark: ImageBitmap?) {
    for (row in 0 until 8) for (column in 0 until 8) {
        val isLight = (row + column) % 2 == 0
        val topLeft = Offset(column * cell, row * cell)
        val wood = if (isLight) light else dark
        if (wood != null) {
            drawImage(
                wood, dstOffset = IntOffset(topLeft.x.toInt(), topLeft.y.toInt()),
                // One pixel over, so no seam shows between squares at fractional sizes.
                dstSize = IntSize(cell.toInt() + 1, cell.toInt() + 1), filterQuality = FilterQuality.Medium,
            )
        } else {
            drawRect(if (isLight) BoardColors.light else BoardColors.dark, topLeft, Size(cell, cell))
        }
    }
}

private fun DrawScope.drawPiece(image: ImageBitmap?, topLeft: Offset, cell: Float) {
    if (image == null) return
    drawImage(
        image, dstOffset = IntOffset(topLeft.x.toInt(), topLeft.y.toInt()),
        dstSize = IntSize(cell.toInt(), cell.toInt()), filterQuality = FilterQuality.High,
    )
}

private fun DrawScope.drawCoordinates(cell: Float, orientation: PieceColor, measurer: TextMeasurer) {
    val size = (cell / density / 5.2f).coerceIn(8f, 13f).sp
    for (i in 0 until 8) {
        val file = if (orientation == PieceColor.WHITE) i else 7 - i
        val rank = if (orientation == PieceColor.WHITE) 7 - i else i
        // Each label takes the colour of the other kind of square, so it reads on its own.
        val fileOnLight = (7 + i) % 2 == 0
        val rankOnLight = i % 2 == 0
        fun style(onLight: Boolean) = androidx.compose.ui.text.TextStyle(
            fontSize = size, fontWeight = FontWeight.SemiBold,
            color = if (onLight) BoardColors.dark.copy(alpha = 0.95f) else BoardColors.light.copy(alpha = 0.9f),
        )
        val letter = measurer.measure(('a' + file).toString(), style(fileOnLight))
        drawText(letter, topLeft = Offset((i + 1) * cell - letter.size.width - cell * 0.06f, 8 * cell - letter.size.height - cell * 0.02f))
        val number = measurer.measure(('1' + rank).toString(), style(rankOnLight))
        drawText(number, topLeft = Offset(cell * 0.06f, i * cell + cell * 0.03f))
    }
}

private fun DrawScope.drawArrow(from: Offset, to: Offset, cell: Float, color: Color) {
    val length = hypot(to.x - from.x, to.y - from.y)
    if (length < 1f) return
    val head = min(cell * 0.42f, length * 0.5f)
    val angle = Math.toDegrees(atan2((to.y - from.y).toDouble(), (to.x - from.x).toDouble())).toFloat()
    rotate(angle, pivot = from) {
        val start = Offset(from.x + cell * 0.28f, from.y)
        val neck = Offset(from.x + length - head, from.y)
        drawLine(color.copy(alpha = 0.85f), start, neck, strokeWidth = cell * 0.16f, cap = StrokeCap.Round)
        drawPath(
            Path().apply {
                moveTo(from.x + length, from.y)
                lineTo(neck.x, neck.y - head * 0.5f)
                lineTo(neck.x, neck.y + head * 0.5f)
                close()
            },
            color.copy(alpha = 0.92f),
        )
    }
}
