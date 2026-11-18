package com.artesoft.brasspawn.ui.training

import android.content.Context
import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.BuildConfig
import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.data.Settings
import com.artesoft.brasspawn.data.SoundBoard
import com.artesoft.brasspawn.data.TrainingStore
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.engine.CoachService
import com.artesoft.brasspawn.engine.EngineScore
import com.artesoft.brasspawn.engine.SearchBudget
import com.artesoft.brasspawn.engine.StockfishEngine
import com.artesoft.brasspawn.engine.notation
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.training.Coach
import com.artesoft.brasspawn.training.ItemSelector
import com.artesoft.brasspawn.training.MoveDescription
import com.artesoft.brasspawn.training.PositionFeatures
import com.artesoft.brasspawn.training.PositionalExercise
import com.artesoft.brasspawn.training.Themes
import com.artesoft.brasspawn.training.TrainingMode
import com.artesoft.brasspawn.ui.ActionBar
import com.artesoft.brasspawn.ui.ActionButton
import com.artesoft.brasspawn.ui.BoardArrow
import com.artesoft.brasspawn.ui.BoardColors
import com.artesoft.brasspawn.ui.BoardRing
import com.artesoft.brasspawn.ui.Body
import com.artesoft.brasspawn.ui.BrassIcon
import com.artesoft.brasspawn.ui.ChessBoard
import com.artesoft.brasspawn.ui.Label
import com.artesoft.brasspawn.ui.LocalFaces
import com.artesoft.brasspawn.ui.Navigator
import com.artesoft.brasspawn.ui.Panel
import com.artesoft.brasspawn.ui.PlayerBar
import com.artesoft.brasspawn.ui.Screen
import com.artesoft.brasspawn.ui.Theatre
import kotlinx.coroutines.launch

/**
 * The five positional assessments, in centipawns from White's point of view.
 */
enum class Judgement {
    WHITE_CLEAR, WHITE_SLIGHT, BALANCED, BLACK_SLIGHT, BLACK_CLEAR;

    val label: String
        get() = when (this) {
            WHITE_CLEAR -> t("positional.whiteClear", "White is clearly better")
            WHITE_SLIGHT -> t("positional.whiteSlight", "White is slightly better")
            BALANCED -> t("positional.balanced", "Balanced")
            BLACK_SLIGHT -> t("positional.blackSlight", "Black is slightly better")
            BLACK_CLEAR -> t("positional.blackClear", "Black is clearly better")
        }

    companion object {
        fun correct(centipawns: Int): Judgement = when {
            centipawns >= 120 -> WHITE_CLEAR
            centipawns >= 35 -> WHITE_SLIGHT
            centipawns >= -35 -> BALANCED
            centipawns >= -120 -> BLACK_SLIGHT
            else -> BLACK_CLEAR
        }
    }
}

class PositionalModel(context: Context) {
    enum class Phase { JUDGING, CHOOSING, DONE }

    data class MoveResult(
        val tone: FeedbackTone,
        val title: String,
        val lines: List<String>,
        val ratingDelta: Pair<Int, Int>? = null,
    )

    private val sounds = SoundBoard.shared(context)

    var exercise by mutableStateOf<PositionalExercise?>(null)
        private set
    var position by mutableStateOf(Position.start)
        private set
    var rings by mutableStateOf<List<BoardRing>>(emptyList())
        private set
    var arrows by mutableStateOf<List<BoardArrow>>(emptyList())
        private set
    var phase by mutableStateOf(Phase.JUDGING)
        private set
    var chosenJudgement by mutableStateOf<Judgement?>(null)
        private set
    var judgementWasRight by mutableStateOf(false)
        private set
    var summary by mutableStateOf<List<String>>(emptyList())
        private set
    var result by mutableStateOf<MoveResult?>(null)
        private set
    var isThinking by mutableStateOf(false)
        private set

    val orientation: PieceColor get() = exercise?.sideToMove ?: PieceColor.WHITE

    val correctJudgement: Judgement? get() = exercise?.let { Judgement.correct(it.cp) }

    val legalMoves: List<Move>
        get() = if (exercise != null && phase == Phase.CHOOSING && !isThinking) position.legalMoves() else emptyList()

    fun load(next: PositionalExercise?) {
        val start = next?.let { Position.fromFen(it.fen) }
        if (next == null || start == null) {
            exercise = null
            return
        }
        exercise = next
        position = start
        phase = Phase.JUDGING
        chosenJudgement = null
        judgementWasRight = false
        summary = emptyList()
        result = null
        rings = emptyList()
        arrows = emptyList()
        isThinking = false
        if (BuildConfig.DEBUG) {
            Log.d(
                "BrassPawn",
                "Positional id=${next.id} rating=${next.rating} cp=${next.cp} (${Judgement.correct(next.cp)}) side=${next.sideToMove} best=${next.best.uci}"
            )
        }
    }

    fun judge(judgement: Judgement) {
        val current = exercise ?: return
        if (phase != Phase.JUDGING) return
        chosenJudgement = judgement
        judgementWasRight = judgement == Judgement.correct(current.cp)
        summary = MoveDescription.summary(PositionFeatures(position))
        phase = Phase.CHOOSING
    }

    suspend fun choose(move: Move, appContext: Context): Boolean? {
        val current = exercise ?: return null
        if (phase != Phase.CHOOSING) return null
        val legal = position.legalMove(move) ?: return null
        val probe = position.make(legal)

        val captured = position.pieceAt(legal.to) != null || legal.isCapture
        sounds.play(legal, captured, probe)

        phase = Phase.DONE
        isThinking = true
        try {
            val uci = legal.uci
            val known = (listOf(current.best) + current.alternatives).firstOrNull { it.uci == uci }
            val playedCp = when {
                known != null -> known.cp
                probe.isCheckmate -> 10_000
                probe.isDraw -> 0
                else -> {
                    val analysis = runCatching {
                        val engine = StockfishEngine.shared(appContext)
                        engine.analyse(probe.fen, SearchBudget.assessment, multiPV = 1)
                    }.getOrNull()
                    val line = analysis?.lines?.firstOrNull()
                    if (line != null) CoachService.score(line.score, position.sideToMove, probe.sideToMove)
                    else current.best.cp
                }
            }

            val lost = maxOf(0.0, Coach.winProbability(current.best.cp) - Coach.winProbability(playedCp))
            val tone = when {
                lost <= 0.02 -> FeedbackTone.CORRECT
                lost <= 0.06 -> FeedbackTone.PARTIAL
                else -> FeedbackTone.WRONG
            }

            val bestMove = Move.fromUci(current.best.uci)?.let(position::legalMove)
            arrows = bestMove?.let { listOf(BoardArrow(it.from, it.to, BoardColors.coachArrow)) }.orEmpty()
            rings = if (bestMove == null || !bestMove.matchesNotation(legal)) {
                listOf(BoardRing(legal.to, tone.color))
            } else emptyList()

            val lines = buildList {
                if (tone != FeedbackTone.CORRECT && bestMove != null) {
                    val afterBest = position.make(bestMove)
                    val reasons = MoveDescription.clauses(
                        before = PositionFeatures(position),
                        after = PositionFeatures(afterBest),
                        move = bestMove,
                        position = position,
                        resulting = afterBest,
                    )
                    val bestSan = position.san(bestMove).notation
                    if (reasons.isEmpty()) {
                        add(t("positional.android.enginePrefers", "The engine prefers %@.", bestSan))
                    } else {
                        add(t("positional.android.enginePrefersWhy", "The engine prefers %1\$@ — it %2\$@.", bestSan, MoveDescription.join(reasons)))
                    }
                }
                add(
                    t(
                        "positional.moveCost",
                        "Your move: %.2f · best: %.2f · cost: %.1f%% win probability.",
                        playedCp / 100.0,
                        current.best.cp / 100.0,
                        lost * 100.0,
                    )
                )
                current.best.pv?.takeIf { it.isNotEmpty() }?.let { pv ->
                    add(t("play.mainLine", "Main line: %@", CoachService.notation(position, pv, limit = 8).notation))
                }
            }

            val playedSan = position.san(legal).notation
            val title = when (tone) {
                FeedbackTone.CORRECT -> t("positional.android.sameChoice", "%@ — the engine's choice too", playedSan)
                FeedbackTone.PARTIAL -> t("positional.android.playable", "%@ is playable", playedSan)
                else -> t("positional.android.makesWorse", "%@ makes it worse", playedSan)
            }

            result = MoveResult(tone = tone, title = title, lines = lines)
            return judgementWasRight && tone != FeedbackTone.WRONG
        } finally {
            isThinking = false
        }
    }

    fun attachRatingDelta(before: Int, after: Int) {
        result = result?.copy(ratingDelta = before to after)
    }
}

@Composable
fun PositionalScreen(navigator: Navigator) {
    val context = LocalContext.current
    val appContext = context.applicationContext
    val store = remember { TrainingStore.shared(context) }
    val settings = remember { Settings.shared(context) }
    val model = remember { PositionalModel(appContext) }
    val scope = rememberCoroutineScope()

    fun nextExercise() {
        model.load(ItemSelector.nextExercise(from = store.library.exercises, progress = store.progress))
    }

    LaunchedEffect(store.isLibraryLoaded, store.library.exercises.size) {
        if (model.exercise == null && store.library.exercises.isNotEmpty()) {
            nextExercise()
        }
    }

    Screen(title = t("progress.positional", "Positional"), onBack = navigator::back) {
        TrainingLayout(
            board = {
                Column {
                    PlayerBar(
                        name = t("positional.exercise", "Exercise"),
                        rating = model.exercise?.rating,
                        color = model.orientation.opponent,
                    )
                    Spacer(Modifier.height(6.dp))
                    ChessBoard(
                        position = model.position,
                        orientation = model.orientation,
                        legalMoves = model.legalMoves,
                        rings = model.rings,
                        arrows = model.arrows,
                        showCoordinates = settings.coordinates,
                        darkSet = settings.darkSet,
                        modifier = Modifier.fillMaxWidth(),
                        onMove = { move ->
                            scope.launch {
                                val current = model.exercise ?: return@launch
                                val correct = model.choose(move, appContext) ?: return@launch
                                val before = store.progress.rating(TrainingMode.POSITIONAL)
                                store.update { progress ->
                                    progress.record(
                                        mode = TrainingMode.POSITIONAL,
                                        itemID = current.id,
                                        itemRating = current.rating,
                                        correct = correct,
                                        themes = current.themes,
                                    )
                                }
                                val after = store.progress.rating(TrainingMode.POSITIONAL)
                                model.attachRatingDelta(before, after)
                            }
                        },
                    )
                    Spacer(Modifier.height(6.dp))
                    PlayerBar(
                        name = t("positional.you", "You"),
                        rating = store.progress.rating(TrainingMode.POSITIONAL),
                        color = model.orientation,
                    )
                }
            },
            panel = {
                val exercise = model.exercise
                if (exercise == null) {
                    LibraryNotice(
                        isLoaded = store.isLibraryLoaded,
                        what = t("positional.positionalExercises", "positional exercises"),
                    )
                } else {
                    Panel(Modifier.fillMaxWidth(), padding = PaddingValues(12.dp)) {
                        BasicText(
                            t("positional.assessPrompt", "%@ to move — how do you assess this?", L.color(model.orientation)),
                            style = LocalFaces.current.display(22),
                        )
                        Spacer(Modifier.height(3.dp))
                        Body(
                            t("positional.noTacticsHereWeighStructure", "No tactics here. Weigh structure, activity, king safety and space."),
                            size = 13,
                            color = Theatre.ivoryDim,
                        )
                    }

                    if (model.phase == PositionalModel.Phase.JUDGING) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            for (judgement in Judgement.entries) {
                                JudgementChoiceRow(judgement.label) { model.judge(judgement) }
                            }
                        }
                    } else {
                        val correct = model.correctJudgement
                        if (correct != null) {
                            val title = if (model.judgementWasRight) {
                                t("positional.android.rightRead", "Right read")
                            } else {
                                t(
                                    "positional.android.engineSays",
                                    "Engine says: %1\$@ (%2\$@)",
                                    correct.label.lowercase(),
                                    EngineScore.Centipawns(exercise.cp).text,
                                )
                            }
                            VerdictCard(
                                tone = if (model.judgementWasRight) FeedbackTone.CORRECT else FeedbackTone.PARTIAL,
                                title = title,
                                lines = model.summary,
                            ) {
                                if (model.phase == PositionalModel.Phase.CHOOSING) {
                                    Spacer(Modifier.height(4.dp))
                                    Body(
                                        t("positional.nowPlayTheMoveYou", "Now play the move you would choose."),
                                        size = 14,
                                        style = LocalFaces.current.body(14, weight = FontWeight.SemiBold, color = Theatre.brassHot),
                                    )
                                }
                            }
                        }
                    }

                    if (model.isThinking) {
                        Panel(Modifier.fillMaxWidth()) {
                            Body(
                                t("positional.checkingYourMoveWithThe", "Checking your move with the engine…"),
                                size = 13,
                                color = Theatre.ivoryDim,
                            )
                        }
                    }

                    model.result?.let { res ->
                        VerdictCard(tone = res.tone, title = res.title, lines = res.lines) {
                            res.ratingDelta?.let { (before, after) ->
                                Spacer(Modifier.height(4.dp))
                                RatingDeltaRow(before = before, after = after)
                            }
                            if (exercise.themes.isNotEmpty()) {
                                Spacer(Modifier.height(6.dp))
                                TagRow(tags = TacticsModel.motifsFirst(exercise.themes).map(Themes::readable))
                            }
                        }
                    }
                }
            },
            controls = {
                ActionBar {
                    ActionButton(
                        title = if (model.phase == PositionalModel.Phase.DONE) t("common.next", "Next") else t("common.skip", "Skip"),
                        icon = "forward.end",
                        primary = true,
                        enabled = model.exercise != null && !model.isThinking,
                        onClick = ::nextExercise,
                    )
                }
            },
        )
    }
}

@Composable
private fun JudgementChoiceRow(label: String, onClick: () -> Unit) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .heightIn(min = 38.dp)
            .clip(shape)
            .background(Theatre.ink3)
            .border(1.dp, Theatre.rule, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Body(label, Modifier.weight(1f), size = 14, color = Theatre.ivory)
        BrassIcon("chevron.right", 14.dp)
    }
}
