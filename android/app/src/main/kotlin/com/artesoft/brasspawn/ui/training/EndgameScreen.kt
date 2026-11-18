package com.artesoft.brasspawn.ui.training

import android.content.Context
import android.util.Log
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.BuildConfig
import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import com.artesoft.brasspawn.data.Settings
import com.artesoft.brasspawn.data.SoundBoard
import com.artesoft.brasspawn.data.TrainingStore
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.engine.CoachService
import com.artesoft.brasspawn.engine.EngineScore
import com.artesoft.brasspawn.engine.SearchBudget
import com.artesoft.brasspawn.engine.StockfishEngine
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.training.EndgameDrill
import com.artesoft.brasspawn.training.ItemSelector
import com.artesoft.brasspawn.training.Themes
import com.artesoft.brasspawn.training.TrainingMode
import com.artesoft.brasspawn.ui.ActionBar
import com.artesoft.brasspawn.ui.ActionButton
import com.artesoft.brasspawn.ui.BoardArrow
import com.artesoft.brasspawn.ui.BoardColors
import com.artesoft.brasspawn.ui.Body
import com.artesoft.brasspawn.ui.BrassIcon
import com.artesoft.brasspawn.ui.ChessBoard
import com.artesoft.brasspawn.ui.ChipButton
import com.artesoft.brasspawn.ui.EvaluationBar
import com.artesoft.brasspawn.ui.Label
import com.artesoft.brasspawn.ui.LocalFaces
import com.artesoft.brasspawn.ui.Navigator
import com.artesoft.brasspawn.ui.Panel
import com.artesoft.brasspawn.ui.PlayerBar
import com.artesoft.brasspawn.ui.Screen
import com.artesoft.brasspawn.ui.Theatre
import kotlinx.coroutines.launch

class EndgameModel(context: Context) {
    private val sounds = SoundBoard.shared(context)

    data class LostMark(val move: String, val reason: String)

    data class Outcome(
        val success: Boolean,
        val title: String,
        val lines: List<String>,
        val ratingDelta: Pair<Int, Int>? = null,
    )

    var drill by mutableStateOf<EndgameDrill?>(null)
        private set
    var position by mutableStateOf(Position.start)
        private set
    var side by mutableStateOf(PieceColor.WHITE)
        private set
    var lastMove by mutableStateOf<Pair<Square, Square>?>(null)
        private set
    var arrows by mutableStateOf<List<BoardArrow>>(emptyList())
        private set
    /** UCI evaluation from `position.sideToMove`'s point of view. */
    var evaluation by mutableStateOf<EngineScore?>(null)
        private set
    var isThinking by mutableStateOf(false)
        private set
    var isFinished by mutableStateOf(false)
        private set
    var plies by mutableIntStateOf(0)
        private set
    var lostAt by mutableStateOf<LostMark?>(null)
        private set
    var outcome by mutableStateOf<Outcome?>(null)
        private set
    var usedHint by mutableStateOf(false)
        private set

    val orientation: PieceColor get() = side

    /** Evaluation converted to the player's own perspective for [EvaluationBar]. */
    val playerEvaluation: EngineScore?
        get() = evaluation?.pointOfView(sideToMove = position.sideToMove == side)

    val legalMoves: List<Move>
        get() = if (drill != null && !isFinished && !isThinking && position.sideToMove == side) {
            position.legalMoves()
        } else emptyList()

    val goalText: String
        get() {
            val current = drill ?: return ""
            val colour = L.color(side)
            return if (current.goal == EndgameDrill.Goal.WIN) {
                t("endgame.winAs", "Win as %@.", colour)
            } else {
                t("endgame.holdAs", "Hold the draw as %@.", colour)
            }
        }

    fun load(next: EndgameDrill?) {
        val start = next?.let { Position.fromFen(it.fen) }
        if (next == null || start == null) {
            drill = null
            return
        }
        drill = next
        position = start
        side = start.sideToMove
        plies = 0
        isFinished = false
        isThinking = false
        lostAt = null
        outcome = null
        lastMove = null
        arrows = emptyList()
        usedHint = false
        evaluation = if (next.goal == EndgameDrill.Goal.WIN) EngineScore.Centipawns(350) else EngineScore.Centipawns(0)
        if (BuildConfig.DEBUG) {
            Log.d("BrassPawn", "Endgame id=${next.id} name=${next.name} goal=${next.goal} side=$side fen=${next.fen}")
        }
    }

    suspend fun play(move: Move, engine: StockfishEngine): Boolean? {
        val current = drill ?: return null
        if (isFinished || isThinking || position.sideToMove != side) return null
        val legal = position.legalMove(move) ?: return null
        val activeId = current.id

        val playedSan = position.san(legal)
        val captured = position.pieceAt(legal.to) != null || legal.isCapture
        position = position.make(legal)
        lastMove = legal.from to legal.to
        arrows = emptyList()
        plies += 1
        sounds.play(legal, captured, position)

        checkOutcome()?.let { return it }

        isThinking = true
        try {
            updateEvaluation(engine)
            if (drill?.id != activeId) return null

            if (lostAt == null) {
                val cp = evaluation?.let { CoachService.score(it, side, position.sideToMove) } ?: 0
                if (current.goal == EndgameDrill.Goal.WIN && cp < 180) {
                    lostAt = LostMark(playedSan, t("endgame.theWinIsGone", "the win is gone"))
                } else if (current.goal == EndgameDrill.Goal.DRAW && cp < -300) {
                    lostAt = LostMark(playedSan, t("endgame.theDrawIsGone", "the draw is gone"))
                }
            }

            val replyUci = runCatching {
                engine.chooseMove(position.fen, elo = null, SearchBudget.fullStrength)
            }.getOrNull()
            if (drill?.id != activeId) return null

            val replyMove = replyUci?.let(Move::fromUci)?.let(position::legalMove)
            if (replyMove != null) {
                val replyCap = position.pieceAt(replyMove.to) != null || replyMove.isCapture
                position = position.make(replyMove)
                lastMove = replyMove.from to replyMove.to
                plies += 1
                sounds.play(replyMove, replyCap, position)
            }

            updateEvaluation(engine)
            if (drill?.id != activeId) return null

            checkOutcome()?.let { return it }

            if (plies > 160) {
                return conclude(
                    success = current.goal == EndgameDrill.Goal.DRAW,
                    how = t("endgame.moveLimit", "The 80-move limit ran out."),
                )
            }
            return null
        } finally {
            isThinking = false
        }
    }

    suspend fun hint(engine: StockfishEngine) {
        if (drill == null || isFinished || isThinking || position.sideToMove != side) return
        usedHint = true
        isThinking = true
        try {
            val analysis = engine.analyse(position.fen, SearchBudget.hint)
            val best = analysis.lines.firstOrNull()?.bestMove?.let(Move::fromUci)?.let(position::legalMove) ?: return
            arrows = listOf(BoardArrow(best.from, best.to, BoardColors.suggestion))
        } catch (_: Exception) {
        } finally {
            isThinking = false
        }
    }

    fun attachRatingDelta(before: Int, after: Int) {
        outcome = outcome?.copy(ratingDelta = before to after)
    }

    private suspend fun updateEvaluation(engine: StockfishEngine) {
        if (position.isGameOver) {
            evaluation = if (position.isCheckmate) {
                EngineScore.Mate(-1)
            } else {
                EngineScore.Centipawns(0)
            }
            return
        }
        runCatching { engine.analyse(position.fen, SearchBudget.verdict, multiPV = 1) }
            .getOrNull()?.lines?.firstOrNull()?.score?.let { evaluation = it }
    }

    private fun checkOutcome(): Boolean? {
        if (!position.isGameOver) return null
        val current = drill ?: return null

        if (position.isCheckmate) {
            val winner = position.sideToMove.opponent
            return conclude(
                success = winner == side && current.goal == EndgameDrill.Goal.WIN,
                how = if (winner == side) t("endgame.youMated", "Checkmate — you delivered it.")
                else t("endgame.youWereMated", "You were checkmated."),
            )
        }

        val how = when {
            position.isStalemate -> t("endgame.stalemate", "Stalemate.")
            position.isInsufficientMaterial -> t("endgame.insufficient", "Insufficient material.")
            position.isThreefoldRepetition -> t("endgame.repetition", "Threefold repetition.")
            else -> t("endgame.fiftyMove", "Fifty-move rule.")
        }
        return conclude(success = current.goal == EndgameDrill.Goal.DRAW, how = how)
    }

    private fun conclude(success: Boolean, how: String): Boolean {
        val current = drill
        isFinished = true
        val tail = when {
            success -> t("endgame.android.resultNeeded", "That is the result you needed.")
            current?.goal == EndgameDrill.Goal.WIN -> t("endgame.android.neededWin", "You needed to win this.")
            else -> t("endgame.android.neededDraw", "You needed to draw this.")
        }
        val lines = buildList {
            add("$how $tail")
            lostAt?.takeIf { !success }?.let { add(t("endgame.wentWrongAt", "It went wrong at %@.", it.move)) }
            if (current != null) add(current.idea)
        }
        outcome = Outcome(
            success = success,
            title = if (success) t("endgame.drillPassed", "Drill passed") else t("endgame.drillFailed", "Drill failed"),
            lines = lines,
        )
        return success
    }
}

@Composable
fun EndgameScreen(navigator: Navigator) {
    val context = LocalContext.current
    val store = remember { TrainingStore.shared(context) }
    val settings = remember { Settings.shared(context) }
    val model = remember { EndgameModel(context.applicationContext) }
    val scope = rememberCoroutineScope()

    var engine by remember { mutableStateOf<StockfishEngine?>(null) }
    var engineFailed by remember { mutableStateOf(false) }
    var preparing by remember { mutableFloatStateOf(0f) }
    var choosingDrill by remember { mutableStateOf(false) }
    var hasRecordedCurrent by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        engine = runCatching { StockfishEngine.shared(context) { preparing = it } }
            .onFailure { engineFailed = true }.getOrNull()
    }

    fun selectDrill(drill: EndgameDrill?) {
        hasRecordedCurrent = false
        choosingDrill = false
        model.load(drill)
        engine?.let { scope.launch { it.newGame() } }
    }

    fun nextDrill() {
        selectDrill(ItemSelector.nextDrill(from = store.library.drills, progress = store.progress))
    }

    LaunchedEffect(store.isLibraryLoaded, store.library.drills.size) {
        if (model.drill == null && store.library.drills.isNotEmpty()) {
            nextDrill()
        }
    }

    if (choosingDrill) {
        BackHandler { choosingDrill = false }
        DrillPickerScreen(
            drills = store.library.drills,
            currentId = model.drill?.id,
            solvedIds = store.progress.cards.filterValues { it.lastSolved }.keys,
            onChoose = ::selectDrill,
            onBack = { choosingDrill = false },
        )
        return
    }

    Screen(
        title = t("progress.endgames", "Endgames"),
        onBack = navigator::back,
        trailing = {
            if (store.library.drills.isNotEmpty()) {
                ChipButton(
                    title = t("endgame.android.chooseDrill", "Drills"),
                    enabled = !model.isThinking,
                ) { choosingDrill = true }
            }
        },
    ) {
        TrainingLayout(
            board = {
                Column {
                    PlayerBar(
                        name = t("endgame.drill", "Drill"),
                        rating = model.drill?.rating,
                        color = model.orientation.opponent,
                    )
                    Spacer(Modifier.height(6.dp))
                    Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
                        EvaluationBar(
                            share = model.playerEvaluation?.winProbability,
                            playerIsWhite = model.side == PieceColor.WHITE,
                        )
                        Spacer(Modifier.width(6.dp))
                        ChessBoard(
                            position = model.position,
                            orientation = model.orientation,
                            legalMoves = if (engine != null) model.legalMoves else emptyList(),
                            lastMove = model.lastMove,
                            arrows = model.arrows,
                            showCoordinates = settings.coordinates,
                            darkSet = settings.darkSet,
                            modifier = Modifier.weight(1f),
                            onMove = { move ->
                                val ready = engine ?: return@ChessBoard
                                scope.launch {
                                    val current = model.drill ?: return@launch
                                    val success = model.play(move, ready) ?: return@launch
                                    if (!hasRecordedCurrent) {
                                        hasRecordedCurrent = true
                                        val before = store.progress.rating(TrainingMode.ENDGAME)
                                        store.update { progress ->
                                            progress.record(
                                                mode = TrainingMode.ENDGAME,
                                                itemID = current.id,
                                                itemRating = current.rating,
                                                correct = success,
                                                themes = current.themes,
                                                usedHint = model.usedHint,
                                            )
                                        }
                                        val after = store.progress.rating(TrainingMode.ENDGAME)
                                        model.attachRatingDelta(before, after)
                                    }
                                }
                            },
                        )
                    }
                    Spacer(Modifier.height(6.dp))
                    PlayerBar(
                        name = t("endgame.you", "You"),
                        rating = store.progress.rating(TrainingMode.ENDGAME),
                        color = model.orientation,
                    )
                }
            },
            panel = {
                when {
                    engineFailed -> Panel(Modifier.fillMaxWidth()) {
                        Body(t("engine.failed", "The engine could not be started."), color = Theatre.bad)
                    }
                    engine == null -> Panel(Modifier.fillMaxWidth()) {
                        Body(
                            t("engine.preparing", "Preparing the engine…") + "  ${(preparing * 100).toInt()}%",
                            color = Theatre.ivoryDim,
                        )
                    }
                }

                val drill = model.drill
                if (drill == null) {
                    if (!store.isLibraryLoaded) {
                        LibraryNotice(isLoaded = false, what = t("progress.endgames", "Endgames").lowercase())
                    } else {
                        Panel(Modifier.fillMaxWidth()) {
                            Body(t("endgame.noEndgameDrillsBundled", "No endgame drills bundled"), color = Theatre.ivoryDim)
                        }
                    }
                } else {
                    Panel(Modifier.fillMaxWidth()) {
                        BasicText(drill.name, style = LocalFaces.current.display(22))
                        Spacer(Modifier.height(3.dp))
                        Body(model.goalText, size = 14, color = Theatre.ivoryDim)
                        Spacer(Modifier.height(8.dp))
                        val movesPlayed = (model.plies + 1) / 2
                        TagRow(
                            tags = buildList {
                                add(
                                    if (drill.goal == EndgameDrill.Goal.WIN) t("endgame.mustWin", "Must win")
                                    else t("endgame.mustDraw", "Must draw")
                                )
                                if (movesPlayed > 0) {
                                    add(
                                        if (movesPlayed == 1) t("common.oneMove", "1 move")
                                        else t("common.moveCount", "%lld moves", movesPlayed)
                                    )
                                }
                            }
                        )
                    }

                    if (model.isThinking) {
                        Panel(Modifier.fillMaxWidth()) {
                            Body(t("endgame.engineIsThinking", "Engine is thinking…"), size = 13, color = Theatre.ivoryDim)
                        }
                    }

                    model.lostAt?.takeIf { model.outcome == null }?.let { lost ->
                        VerdictCard(
                            tone = FeedbackTone.PARTIAL,
                            title = t("endgame.threwItAway", "%@ threw it away", lost.move),
                            lines = listOf(
                                t(
                                    "endgame.afterThatMove",
                                    "After that move %@. Play on if you like, or restart and try the correct plan.",
                                    lost.reason,
                                )
                            ),
                        )
                    }

                    model.outcome?.let { out ->
                        VerdictCard(
                            tone = if (out.success) FeedbackTone.CORRECT else FeedbackTone.WRONG,
                            title = out.title,
                            lines = out.lines,
                        ) {
                            out.ratingDelta?.let { (before, after) ->
                                Spacer(Modifier.height(4.dp))
                                RatingDeltaRow(before = before, after = after)
                            }
                        }
                    }

                    Panel(Modifier.fillMaxWidth()) {
                        Label(t("endgame.theIdea", "The idea"))
                        Spacer(Modifier.height(6.dp))
                        Body(drill.idea, size = 13, color = Theatre.ivoryDim)
                        if (drill.themes.isNotEmpty()) {
                            Spacer(Modifier.height(8.dp))
                            TagRow(tags = drill.themes.map(Themes::readable))
                        }
                    }
                }
            },
            controls = {
                ActionBar {
                    ActionButton(
                        title = t("endgame.restart", "Restart"),
                        icon = "arrow.counterclockwise",
                        enabled = model.drill != null && !model.isThinking,
                    ) { model.load(model.drill) }
                    ActionButton(
                        title = t("play.hint", "Hint"),
                        icon = "lightbulb",
                        enabled = engine != null && model.drill != null && !model.isFinished && !model.isThinking,
                    ) {
                        val ready = engine ?: return@ActionButton
                        scope.launch { model.hint(ready) }
                    }
                    ActionButton(
                        title = t("endgame.next", "Next"),
                        icon = "forward.end",
                        primary = true,
                        enabled = store.library.drills.isNotEmpty() && !model.isThinking,
                        onClick = ::nextDrill,
                    )
                }
            },
        )
    }
}

@Composable
private fun DrillPickerScreen(
    drills: List<EndgameDrill>,
    currentId: String?,
    solvedIds: Set<String>,
    onChoose: (EndgameDrill) -> Unit,
    onBack: () -> Unit,
) {
    Screen(title = t("progress.endgames", "Endgames"), onBack = onBack) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            for (drill in drills.sortedBy { it.rating }) {
                val solved = drill.id in solvedIds
                val active = drill.id == currentId
                Panel(
                    Modifier
                        .fillMaxWidth()
                        .clickable(role = Role.Button) { onChoose(drill) }
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Body(
                                drill.name,
                                size = 15,
                                style = LocalFaces.current.body(
                                    15,
                                    weight = FontWeight.SemiBold,
                                    color = if (active) Theatre.brassHot else Theatre.ivory,
                                ),
                            )
                            TagRow(
                                tags = listOf(
                                    if (drill.goal == EndgameDrill.Goal.WIN) t("endgame.mustWin", "Must win")
                                    else t("endgame.mustDraw", "Must draw")
                                ) + drill.themes.take(2).map(Themes::readable)
                            )
                        }
                        Spacer(Modifier.width(10.dp))
                        if (solved) {
                            BrassIcon("checkmark.circle.fill", 20.dp)
                            Spacer(Modifier.width(8.dp))
                        }
                        BasicText(drill.rating.toString(), style = LocalFaces.current.figures(14, Theatre.ivoryDim))
                    }
                }
            }
        }
    }
}
