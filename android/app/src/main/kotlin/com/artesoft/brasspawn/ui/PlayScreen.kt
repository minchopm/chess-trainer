package com.artesoft.brasspawn.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.width
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.data.Settings
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.engine.StockfishEngine
import kotlinx.coroutines.launch

/** A full game against Stockfish at a strength the player chooses. */
@Composable
fun PlayScreen(navigator: Navigator) {
    val context = LocalContext.current
    val settings = remember { Settings.shared(context) }
    val model = remember { PlayModel(context.applicationContext) }
    val scope = rememberCoroutineScope()
    var engine by remember { mutableStateOf<StockfishEngine?>(null) }
    var engineFailed by remember { mutableStateOf(false) }
    var preparing by remember { mutableFloatStateOf(0f) }

    LaunchedEffect(Unit) {
        engine = runCatching { StockfishEngine.shared(context) { preparing = it } }
            .onFailure { engineFailed = true }.getOrNull()
    }

    Screen(title = t("progress.play", "Play"), onBack = navigator::back) {
        val ready = engine
        BoardScreenLayout(
            board = {
                Column {
                    PlayerBar(
                        name = if (model.level.elo == null) engine?.name ?: "Stockfish" else model.level.name,
                        rating = model.level.elo, color = if (model.side == PieceColor.WHITE) PieceColor.BLACK else PieceColor.WHITE,
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(Modifier.fillMaxWidth().height(androidx.compose.foundation.layout.IntrinsicSize.Min)) {
                        EvaluationBar(model.evaluation?.winProbability, playerIsWhite = model.side == PieceColor.WHITE)
                        Spacer(Modifier.width(6.dp))
                        ChessBoard(
                            position = model.position,
                            orientation = model.side,
                            legalMoves = model.legalMoves,
                            lastMove = model.lastMove,
                            arrows = model.arrows,
                            showCoordinates = settings.coordinates,
                            darkSet = settings.darkSet,
                            modifier = Modifier.weight(1f),
                            onMove = { move -> engine?.let { r -> scope.launch { model.play(move, r) } } },
                        )
                    }
                    Spacer(Modifier.height(8.dp))
                    PlayerBar(name = t("play.you", "You"), rating = null, color = model.side)
                }
            },
            panel = {
                when {
                    engineFailed -> Panel(Modifier.fillMaxWidth()) {
                        Body(t("engine.failed", "The engine could not be started."), color = Theatre.bad)
                    }
                    ready == null -> Panel(Modifier.fillMaxWidth()) {
                        Body(t("engine.preparing", "Preparing the engine…") + "  ${(preparing * 100).toInt()}%", color = Theatre.ivoryDim)
                    }
                    !model.hasStarted -> SetupPanel(model) { scope.launch { model.start(ready) } }
                    else -> {
                        Panel(Modifier.fillMaxWidth()) {
                            BasicText(model.statusText, style = LocalFaces.current.display(24))
                            Body(
                                t("play.opponentIs", "Opponent: %@", model.level.elo?.let { "${model.level.name} ($it)" } ?: ready.name),
                                size = 13, color = Theatre.ivoryDim,
                            )
                        }
                        model.summary?.let { summary ->
                            Panel(Modifier.fillMaxWidth()) {
                                BasicText(
                                    when (summary.result) {
                                        "win" -> t("play.gameOverWon", "Game over — you won")
                                        "loss" -> t("play.gameOverLost", "Game over — you lost")
                                        else -> t("play.gameOverDraw", "Game over — draw")
                                    },
                                    style = LocalFaces.current.display(22),
                                )
                                Spacer(Modifier.height(6.dp))
                                Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                                    Stat(t("progress.accuracy", "Accuracy"), "${summary.accuracy}%")
                                    Stat(com.artesoft.brasspawn.training.MoveGrade.BLUNDER.label, summary.blunders.toString())
                                    Stat(com.artesoft.brasspawn.training.MoveGrade.MISTAKE.label, summary.mistakes.toString())
                                    Stat(com.artesoft.brasspawn.training.MoveGrade.INACCURACY.label, summary.inaccuracies.toString())
                                }
                            }
                        }
                        model.latestReview?.takeIf { model.coachingEnabled }?.let { review ->
                            Panel(Modifier.fillMaxWidth()) {
                                Label(t("play.coach", "Coach"))
                                Spacer(Modifier.height(6.dp))
                                val grade = review.assessment.grade
                                Body(
                                    "${review.playedSan} — ${grade.label}", size = 15,
                                    style = LocalFaces.current.body(
                                        15, weight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                        color = when {
                                            grade == com.artesoft.brasspawn.training.MoveGrade.BLUNDER || grade == com.artesoft.brasspawn.training.MoveGrade.MISTAKE -> Theatre.bad
                                            grade == com.artesoft.brasspawn.training.MoveGrade.INACCURACY -> Theatre.warn
                                            else -> Theatre.good
                                        },
                                    ),
                                )
                                if (review.sentence.isNotBlank()) {
                                    Spacer(Modifier.height(4.dp))
                                    Body(review.sentence, size = 13, color = Theatre.ivoryDim)
                                }
                                if (grade.isMistake && review.principalVariation.isNotBlank()) {
                                    Spacer(Modifier.height(4.dp))
                                    Body(t("play.mainLine", "Main line: %@", review.principalVariation), size = 12, color = Theatre.ivoryFaint)
                                }
                            }
                        }
                        if (model.moves.isNotEmpty()) {
                            Panel(Modifier.fillMaxWidth()) {
                                Label(t("play.moves", "Moves"))
                                Spacer(Modifier.height(6.dp))
                                Body(moveText(model.moves.map { it.san }), style = LocalFaces.current.figures(13, Theatre.ivoryDim))
                            }
                        }
                    }
                }
            },
            controls = if (ready != null && model.hasStarted) {
                {
                    ActionBar {
                        ActionButton(t("play.takeback", "Takeback"), "arrow.uturn.backward", enabled = model.moves.size >= 2 && !model.isThinking) { model.takeBack() }
                        ActionButton(t("play.hint", "Hint"), "lightbulb", enabled = !model.isThinking && !model.isOver) { scope.launch { model.hint(ready) } }
                        ActionButton(t("play.newGame", "New game"), "plus.circle", primary = true) { scope.launch { model.start(ready) } }
                    }
                }
            } else null,
        )
    }
}

/**
 * How the game stands, as a column beside the board: the player's share of it
 * rises from their own edge. `share` is the player's winning chance, 0…1.
 */
@Composable
fun EvaluationBar(share: Double?, playerIsWhite: Boolean) {
    val level by androidx.compose.animation.core.animateFloatAsState((share ?: 0.5).toFloat().coerceIn(0.03f, 0.97f), label = "evaluation")
    val mine = if (playerIsWhite) Theatre.ivory else Theatre.ink4
    val theirs = if (playerIsWhite) Theatre.ink4 else Theatre.ivory
    Column(
        Modifier.width(8.dp).fillMaxHeight()
            .clip(androidx.compose.foundation.shape.RoundedCornerShape(4.dp))
            .border(1.dp, Theatre.rule, androidx.compose.foundation.shape.RoundedCornerShape(4.dp))
    ) {
        Box(Modifier.fillMaxWidth().weight(1f - level).background(theirs))
        Box(Modifier.fillMaxWidth().weight(level).background(mine))
    }
}

@Composable
private fun Stat(title: String, value: String) {
    Column {
        BasicText(value, style = LocalFaces.current.figures(18, Theatre.ivory))
        Label(title, size = 9)
    }
}

@Composable
internal fun SetupPanel(model: PlayModel, onStart: () -> Unit) {
    Panel(Modifier.fillMaxWidth()) {
        BasicText(t("play.newGame", "New game"), style = LocalFaces.current.display(24))
        Spacer(Modifier.height(4.dp))
        Body(t("play.theEnginePlaysAtThe", "The engine plays at the strength you choose. Coaching grades each of your moves as you make it."), size = 13, color = Theatre.ivoryDim)
        Spacer(Modifier.height(12.dp))
        Label(t("play.strength", "Strength"))
        Spacer(Modifier.height(8.dp))
        val index = OpponentLevel.all.indexOf(model.level)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ChipButton("‹", enabled = index > 0) { model.level = OpponentLevel.all[index - 1] }
            Body(
                model.level.elo?.let { "${model.level.name} ($it)" } ?: model.level.name,
                Modifier.weight(1f), size = 16, align = androidx.compose.ui.text.style.TextAlign.Center,
            )
            ChipButton("›", enabled = index < OpponentLevel.all.lastIndex) { model.level = OpponentLevel.all[index + 1] }
        }
        Spacer(Modifier.height(12.dp))
        Segmented(
            listOf(t("play.white", "White"), t("play.black", "Black")),
            if (model.side == PieceColor.WHITE) 0 else 1, Modifier.fillMaxWidth(),
        ) { model.side = if (it == 0) PieceColor.WHITE else PieceColor.BLACK }
        Spacer(Modifier.height(6.dp))
        Toggle(t("play.coachingGradesEveryMove", "Coaching grades each of your moves as you make it."), model.coachingEnabled) { model.coachingEnabled = it }
        Spacer(Modifier.height(8.dp))
        ChipButton(t("play.startGame", "Start game"), primary = true, icon = "play.fill", onClick = onStart)
    }
}
