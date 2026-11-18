package com.artesoft.brasspawn.ui.training

import android.content.Context
import android.util.Log
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.training.ItemSelector
import com.artesoft.brasspawn.training.MoveDescription
import com.artesoft.brasspawn.training.PositionFeatures
import com.artesoft.brasspawn.training.Puzzle
import com.artesoft.brasspawn.training.Selection
import com.artesoft.brasspawn.training.SelectionReason
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
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Tactics puzzle training: spaced repetition, motif targeting, hint ladder,
 * opponent reply animation, and move-by-move solution walkthrough.
 */
class TacticsModel(context: Context) {
    private val sounds = SoundBoard.shared(context)

    data class Feedback(val tone: FeedbackTone, val title: String, val lines: List<String>)

    enum class Verdict {
        SUCCESS, PARTIAL, FAILURE;

        val symbol: String
            get() = when (this) {
                SUCCESS -> "checkmark.circle.fill"
                PARTIAL -> "checkmark.circle"
                FAILURE -> "xmark.circle.fill"
            }

        val tint: Color
            get() = when (this) {
                SUCCESS -> Theatre.good
                PARTIAL -> Theatre.warn
                FAILURE -> Theatre.bad
            }
    }

    data class Completion(
        val verdict: Verdict,
        val title: String,
        val detail: String?,
        val line: String?,
        val themes: List<String>,
        val ratingDelta: Pair<Int, Int>? = null,
    )

    data class Outcome(val solved: Boolean, val usedHint: Boolean)

    data class ReplayPly(
        val position: Position,
        val lastMove: Pair<Square, Square>?,
        val description: String?,
    )

    var puzzle by mutableStateOf<Puzzle?>(null)
        private set
    var reason by mutableStateOf<SelectionReason>(SelectionReason.Level)
        private set
    var position by mutableStateOf(Position.start)
        private set
    var lastMove by mutableStateOf<Pair<Square, Square>?>(null)
        private set
    var rings by mutableStateOf<List<BoardRing>>(emptyList())
        private set
    var arrows by mutableStateOf<List<BoardArrow>>(emptyList())
        private set
    var feedback by mutableStateOf<Feedback?>(null)
        private set
    var completion by mutableStateOf<Completion?>(null)
        private set
    var isFinished by mutableStateOf(false)
        private set
    var isReplying by mutableStateOf(false)
        private set

    var replaySteps by mutableStateOf<List<ReplayPly>>(emptyList())
        private set
    var isReplaying by mutableStateOf(false)
        private set
    var replayIndex by mutableIntStateOf(0)
        private set

    private var step = 0
    private var mistakes = 0
    private var hintLevel = 0

    val orientation: PieceColor get() = puzzle?.sideToMove ?: PieceColor.WHITE

    val displayPosition: Position
        get() = if (isReplaying && replayIndex in replaySteps.indices) replaySteps[replayIndex].position else position

    val displayLastMove: Pair<Square, Square>?
        get() = if (isReplaying && replayIndex in replaySteps.indices) replaySteps[replayIndex].lastMove else lastMove

    val legalMoves: List<Move>
        get() = if (puzzle != null && !isFinished && !isReplying && !isReplaying) position.legalMoves() else emptyList()

    val wrongFeedback: Feedback?
        get() = feedback?.takeIf { completion == null && it.tone == FeedbackTone.WRONG }

    val prompt: String
        get() {
            val current = puzzle ?: return ""
            val side = L.color(current.sideToMove)
            return if (isFinished) t("tactics.sideToPlaySolution", "%@ to play — solution", side)
            else t("common.sideToPlay", "%@ to play", side)
        }

    val objective: String
        get() {
            val current = puzzle ?: return ""
            val themes = current.themes.toSet()
            if (current.mate || "mate" in themes) {
                val inN = current.themes.firstOrNull { it.startsWith("mateIn") }
                if (inN != null) return t("tactics.mateIn", "Mate in %@.", inN.removePrefix("mateIn"))
                return t("tactics.findForcedMate", "Find the forced mate.")
            }
            if ("defensiveMove" in themes || "equality" in themes) {
                return t("tactics.findTheSave", "Find the move that saves the position.")
            }
            if ("crushing" in themes) return t("tactics.crushingBlow", "Find the crushing blow.")
            if ("winsMaterial" in themes || "hangingPiece" in themes) {
                return t("tactics.winMaterial", "Win material.")
            }
            if ("advantage" in themes) {
                return t("tactics.oneMoveBetter", "One move is clearly better than the rest.")
            }
            return t("tactics.strongestContinuation", "Find the strongest continuation.")
        }

    fun load(selection: Selection<Puzzle>?) {
        val chosen = selection?.item
        val start = chosen?.let { Position.fromFen(it.fen) }
        if (chosen == null || start == null) {
            puzzle = null
            return
        }
        puzzle = chosen
        reason = selection.reason
        position = start
        step = 0
        mistakes = 0
        hintLevel = 0
        isFinished = false
        isReplying = false
        isReplaying = false
        replaySteps = emptyList()
        replayIndex = 0
        feedback = null
        completion = null
        rings = emptyList()
        arrows = emptyList()
        lastMove = null
        if (BuildConfig.DEBUG) {
            Log.d("BrassPawn", "Tactics puzzle=${chosen.id} rating=${chosen.rating} side=${chosen.sideToMove} solution=${chosen.solution}")
        }
    }

    suspend fun play(move: Move): Outcome? {
        val current = puzzle ?: return null
        if (isFinished || isReplying || step >= current.solution.size) return null

        val expected = current.solution[step]
        val attempted = move.uci
        val matches = if (move.promotion != null) {
            attempted == expected
        } else {
            attempted == expected || expected.startsWith(attempted)
        }
        if (!matches) {
            registerWrongMove(move)
            return null
        }

        val activeId = current.id
        applyUci(expected)
        step += 1

        if (step >= current.solution.size) return finish(solved = true)

        isReplying = true
        delay(420)
        if (puzzle?.id != activeId || isFinished) return null
        isReplying = false

        if (step < current.solution.size) {
            applyUci(current.solution[step])
            step += 1
        }
        if (step >= current.solution.size) return finish(solved = true)

        feedback = Feedback(
            tone = FeedbackTone.NEUTRAL,
            title = t("tactics.goodKeepGoing", "Good — keep going."),
            lines = emptyList(),
        )
        return null
    }

    fun retry() {
        val current = puzzle ?: return
        val start = Position.fromFen(current.fen) ?: return
        position = start
        step = 0
        mistakes = 0
        hintLevel = 0
        isFinished = false
        isReplying = false
        isReplaying = false
        feedback = null
        completion = null
        rings = emptyList()
        arrows = emptyList()
        lastMove = null
    }

    fun revealSolution(): Outcome? {
        if (isFinished || puzzle == null) return null
        return finish(solved = false, revealed = true)
    }

    fun requestHint() {
        val current = puzzle ?: return
        if (isFinished || isReplying || step >= current.solution.size) return
        hintLevel += 1
        val uci = current.solution[step]
        val parsed = Move.fromUci(uci) ?: return
        if (hintLevel == 1) {
            rings = listOf(BoardRing(parsed.from, BoardColors.suggestion))
            arrows = emptyList()
        } else {
            rings = emptyList()
            arrows = listOf(BoardArrow(parsed.from, parsed.to, BoardColors.suggestion))
        }
        feedback = null
    }

    fun dismissWrongFeedback() {
        if (wrongFeedback != null) feedback = null
    }

    fun attachRatingDelta(before: Int, after: Int) {
        completion = completion?.copy(ratingDelta = before to after)
    }

    fun startSolutionReplay() {
        val steps = buildReplaySteps()
        if (steps.isEmpty()) return
        replaySteps = steps
        replayIndex = 0
        isReplaying = true
    }

    fun closeSolutionReplay() {
        isReplaying = false
    }

    fun stepReplay(to: Int) {
        if (replaySteps.isEmpty()) return
        replayIndex = to.coerceIn(0, replaySteps.lastIndex)
    }

    private fun registerWrongMove(move: Move) {
        mistakes += 1
        val legal = position.legalMove(move)
        val resulting = legal?.let(position::make)
        val san = legal?.let(position::san) ?: move.uci
        val moveExplanation = if (legal != null && resulting != null) {
            MoveDescription.detailedSentence(san = san, move = legal, position = position, resulting = resulting)
        } else null

        val lines = buildList {
            if (moveExplanation != null) add(moveExplanation)
            add(
                if (mistakes == 1) {
                    t("tactics.tryForcing", "There is a stronger move here. Look at the most forcing options first — checks, captures, threats.")
                } else {
                    t("tactics.stillNotIt", "Still not it. Try a hint, or reveal the solution and study the idea.")
                }
            )
        }
        feedback = Feedback(
            tone = FeedbackTone.WRONG,
            title = t("tactics.notTheOne", "%@ is not the one", san),
            lines = lines,
        )
    }

    private fun applyUci(uci: String) {
        val parsed = Move.fromUci(uci) ?: return
        val legal = position.legalMove(parsed) ?: return
        val captured = position.pieceAt(legal.to) != null || legal.isCapture
        position = position.make(legal)
        lastMove = legal.from to legal.to
        rings = emptyList()
        arrows = emptyList()
        sounds.play(legal, captured, position)
    }

    private fun finish(solved: Boolean, revealed: Boolean = false): Outcome {
        val current = puzzle ?: return Outcome(solved = false, usedHint = false)
        isFinished = true
        isReplying = false
        rings = emptyList()
        arrows = emptyList()

        while (step < current.solution.size) {
            applyUci(current.solution[step])
            step += 1
        }

        val counted = solved && !revealed && mistakes == 0
        val reasons = explanation()
        val describedMoves = detailedSolution()
        val readableThemes = motifsFirst(current.themes).map(Themes::readable)
        val lineNotation = notation()

        feedback = Feedback(
            tone = when {
                counted -> FeedbackTone.CORRECT
                revealed -> FeedbackTone.WRONG
                else -> FeedbackTone.PARTIAL
            },
            title = when {
                revealed -> t("tactics.solutionTitle", "Solution")
                mistakes == 0 -> t("tactics.solved", "Solved")
                else -> t("tactics.solvedNotFirst", "Solved, but not first time")
            },
            lines = listOf(lineNotation) + reasons,
        )
        completion = Completion(
            verdict = when {
                counted -> Verdict.SUCCESS
                revealed -> Verdict.FAILURE
                else -> Verdict.PARTIAL
            },
            title = when {
                revealed -> t("tactics.solutionShown", "Solution shown")
                mistakes == 0 -> t("tactics.solved", "Solved")
                else -> t("tactics.solvedSecondTry", "Solved on the second try")
            },
            detail = describedMoves.firstOrNull()
                ?: reasons.firstOrNull()
                ?: if (revealed) t("tactics.studyTheIdea", "Study the idea — it will come back for review.") else null,
            line = if (describedMoves.size > 1) {
                lineNotation + "\n\n" + describedMoves.drop(1).joinToString("\n")
            } else lineNotation.takeIf { it.isNotBlank() },
            themes = readableThemes,
        )
        return Outcome(solved = counted, usedHint = hintLevel > 0)
    }

    fun notation(): String {
        val current = puzzle ?: return ""
        var replay = Position.fromFen(current.fen) ?: return ""
        val text = StringBuilder()
        for (uci in current.solution) {
            val legal = Move.fromUci(uci)?.let(replay::legalMove) ?: break
            val number = replay.fullmoveNumber
            val san = replay.san(legal)
            if (replay.sideToMove == PieceColor.WHITE) {
                text.append(number).append('.').append(san).append(' ')
            } else {
                text.append(if (text.isEmpty()) "$number...$san " else "$san ")
            }
            replay = replay.make(legal)
        }
        return text.toString().trim()
    }

    private fun detailedSolution(): List<String> {
        val current = puzzle ?: return emptyList()
        var replay = Position.fromFen(current.fen) ?: return emptyList()
        val lines = mutableListOf<String>()
        for (uci in current.solution) {
            val legal = Move.fromUci(uci)?.let(replay::legalMove) ?: break
            val san = replay.san(legal)
            val source = replay
            replay = replay.make(legal)
            MoveDescription.detailedSentence(san = san, move = legal, position = source, resulting = replay)
                ?.let(lines::add)
        }
        return lines
    }

    private fun explanation(): List<String> {
        val current = puzzle ?: return emptyList()
        var replay = Position.fromFen(current.fen) ?: return emptyList()
        val lines = mutableListOf<String>()
        current.solution.forEachIndexed { index, uci ->
            val legal = Move.fromUci(uci)?.let(replay::legalMove) ?: return lines
            val before = PositionFeatures(replay)
            val san = replay.san(legal)
            val source = replay
            replay = replay.make(legal)
            if (index % 2 == 0) {
                MoveDescription.sentence(
                    san = san, before = before, after = PositionFeatures(replay),
                    move = legal, position = source, resulting = replay,
                )?.let(lines::add)
            }
        }
        return lines
    }

    private fun buildReplaySteps(): List<ReplayPly> {
        val current = puzzle ?: return emptyList()
        var replay = Position.fromFen(current.fen) ?: return emptyList()
        val steps = mutableListOf(ReplayPly(replay, null, null))
        for (uci in current.solution) {
            val legal = Move.fromUci(uci)?.let(replay::legalMove) ?: break
            val san = replay.san(legal)
            val source = replay
            replay = replay.make(legal)
            val desc = MoveDescription.detailedSentence(san = san, move = legal, position = source, resulting = replay)
            steps.add(ReplayPly(replay, legal.from to legal.to, desc))
        }
        return steps
    }

    companion object {
        fun motifsFirst(themes: List<String>): List<String> =
            (themes.filter(Themes::isMotif) + themes.filterNot(Themes::isMotif)).take(7)
    }
}

@Composable
fun TacticsScreen(navigator: Navigator) {
    val context = LocalContext.current
    val store = remember { TrainingStore.shared(context) }
    val settings = remember { Settings.shared(context) }
    val model = remember { TacticsModel(context.applicationContext) }
    val scope = rememberCoroutineScope()
    var hasRecordedCurrent by remember { mutableStateOf(false) }

    fun nextPuzzle() {
        hasRecordedCurrent = false
        model.load(ItemSelector.nextPuzzle(from = store.library.puzzles, progress = store.progress))
    }

    fun recordOutcome(outcome: TacticsModel.Outcome?) {
        val current = model.puzzle ?: return
        if (outcome == null || hasRecordedCurrent) return
        hasRecordedCurrent = true
        val ratingBefore = store.progress.rating(TrainingMode.TACTICS)
        store.update { progress ->
            progress.record(
                mode = TrainingMode.TACTICS,
                itemID = current.id,
                itemRating = current.rating,
                correct = outcome.solved,
                themes = current.themes,
                usedHint = outcome.usedHint,
            )
        }
        val ratingAfter = store.progress.rating(TrainingMode.TACTICS)
        model.attachRatingDelta(ratingBefore, ratingAfter)
    }

    LaunchedEffect(store.isLibraryLoaded, store.library.puzzles.size) {
        if (model.puzzle == null && store.library.puzzles.isNotEmpty()) {
            nextPuzzle()
        }
    }

    val skipsSummary = !store.progress.appearance.showsCompletionSummary &&
        model.completion?.verdict == TacticsModel.Verdict.SUCCESS

    LaunchedEffect(model.completion, skipsSummary) {
        if (skipsSummary && !model.isReplaying) {
            delay(900)
            if (skipsSummary && !model.isReplaying) nextPuzzle()
        }
    }

    if (model.isReplaying) {
        BackHandler { model.closeSolutionReplay() }
    } else if (model.wrongFeedback != null) {
        BackHandler { model.dismissWrongFeedback() }
    }

    Box(Modifier.fillMaxSize()) {
        Screen(
            title = t("progress.tactics", "Tactics"),
            onBack = {
                when {
                    model.isReplaying -> model.closeSolutionReplay()
                    else -> navigator.back()
                }
            },
        ) {
            TrainingLayout(
                board = {
                    Column {
                        PlayerBar(
                            name = t("tactics.puzzle", "Puzzle"),
                            rating = model.puzzle?.rating,
                            color = model.orientation.opponent,
                        )
                        Spacer(Modifier.height(6.dp))
                        ChessBoard(
                            position = model.displayPosition,
                            orientation = model.orientation,
                            legalMoves = model.legalMoves,
                            lastMove = model.displayLastMove,
                            rings = if (model.isReplaying) emptyList() else model.rings,
                            arrows = if (model.isReplaying) emptyList() else model.arrows,
                            showCoordinates = settings.coordinates,
                            darkSet = settings.darkSet,
                            modifier = Modifier.fillMaxWidth(),
                            onMove = { move -> scope.launch { recordOutcome(model.play(move)) } },
                        )
                        Spacer(Modifier.height(6.dp))
                        PlayerBar(
                            name = t("tactics.you", "You"),
                            rating = store.progress.rating(TrainingMode.TACTICS),
                            color = model.orientation,
                        )
                    }
                },
                panel = {
                    val puzzle = model.puzzle
                    if (puzzle == null) {
                        LibraryNotice(
                            isLoaded = store.isLibraryLoaded,
                            what = t("progress.tacticsPuzzles", "Tactics puzzles").lowercase(),
                        )
                    } else if (model.isReplaying) {
                        SolutionReplayPanel(model = model, puzzle = puzzle)
                    } else {
                        Panel(Modifier.fillMaxWidth()) {
                            BasicText(model.prompt, style = LocalFaces.current.display(23))
                            Spacer(Modifier.height(4.dp))
                            Body(model.objective, size = 14, color = Theatre.ivoryDim)
                            model.reason.explanation?.let { why ->
                                Spacer(Modifier.height(4.dp))
                                Body(why, size = 12, color = Theatre.brass)
                            }
                            if (model.isReplying) {
                                Spacer(Modifier.height(6.dp))
                                Body(t("tactics.opponentReplies", "Opponent replies…"), size = 13, color = Theatre.ivoryDim)
                            }
                            Spacer(Modifier.height(8.dp))
                            TagRow(
                                tags = listOf(
                                    if (puzzle.solverMoveCount == 1) t("common.oneMove", "1 move")
                                    else t("common.moveCount", "%lld moves", puzzle.solverMoveCount)
                                )
                            )
                        }

                        model.feedback?.takeIf { model.completion == null && model.wrongFeedback == null }?.let { fb ->
                            VerdictCard(tone = fb.tone, title = fb.title, lines = fb.lines)
                        }

                        if (model.isFinished) {
                            model.feedback?.let { fb ->
                                VerdictCard(tone = fb.tone, title = fb.title, lines = fb.lines)
                            }
                            Panel(Modifier.fillMaxWidth()) {
                                Label(t("tactics.themes", "Themes"))
                                Spacer(Modifier.height(8.dp))
                                TagRow(tags = TacticsModel.motifsFirst(puzzle.themes).map(Themes::readable))
                            }
                        }
                    }
                },
                controls = {
                    if (model.isReplaying) {
                        val atStart = model.replayIndex <= 0
                        val atEnd = model.replayIndex >= model.replaySteps.lastIndex
                        ActionBar {
                            ActionButton("‹‹", "backward.end.fill", enabled = !atStart) { model.stepReplay(0) }
                            ActionButton("‹", "backward.frame", enabled = !atStart) { model.stepReplay(model.replayIndex - 1) }
                            ActionButton("›", "forward.frame", enabled = !atEnd) { model.stepReplay(model.replayIndex + 1) }
                            ActionButton(t("tactics.nextPuzzle", "Next puzzle"), "forward.end", primary = true) { nextPuzzle() }
                        }
                    } else {
                        ActionBar {
                            ActionButton(
                                title = t("tactics.hint", "Hint"),
                                icon = "lightbulb",
                                enabled = model.puzzle != null && !model.isFinished && !model.isReplying,
                            ) { model.requestHint() }
                            ActionButton(
                                title = t("tactics.solution", "Solution"),
                                icon = "eye",
                                enabled = model.puzzle != null && !model.isFinished && !model.isReplying,
                            ) { recordOutcome(model.revealSolution()) }
                            ActionButton(
                                title = if (model.isFinished) t("tactics.nextPuzzle", "Next puzzle") else t("tactics.skip", "Skip"),
                                icon = "forward.end",
                                primary = true,
                                enabled = model.puzzle != null && !model.isReplying,
                            ) { nextPuzzle() }
                        }
                    }
                },
            )
        }

        model.wrongFeedback?.let { wrong ->
            TrainingModal(tint = Theatre.bad, onBackdropTap = model::dismissWrongFeedback) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    BrassIcon("xmark.circle.fill", 26.dp)
                    BasicText(wrong.title, Modifier.weight(1f), style = LocalFaces.current.display(23))
                }
                for (line in wrong.lines) {
                    Body(line, size = 14, color = Theatre.ivoryDim)
                }
                ModalButton(
                    title = t("common.tryAgain", "Try again"),
                    modifier = Modifier.fillMaxWidth(),
                    primary = true,
                    onClick = model::dismissWrongFeedback,
                )
            }
        }

        val completion = model.completion
        if (completion != null && !model.isReplaying && !skipsSummary) {
            CompletionModal(
                completion = completion,
                showsSummary = store.progress.appearance.showsCompletionSummary,
                onToggleSummary = { keep ->
                    store.update { it.copy(appearance = it.appearance.copy(showsCompletionSummary = keep)) }
                },
                onWatchSolution = model::startSolutionReplay,
                onRetry = model::retry,
                onNext = ::nextPuzzle,
            )
        }
    }
}

@Composable
private fun SolutionReplayPanel(model: TacticsModel, puzzle: Puzzle) {
    Panel(Modifier.fillMaxWidth()) {
        BasicText(t("tactics.solutionTitle", "Solution"), style = LocalFaces.current.display(22))
        Spacer(Modifier.height(4.dp))
        Body(model.notation(), style = LocalFaces.current.figures(13, Theatre.brassHot))
        val stepDesc = model.replaySteps.getOrNull(model.replayIndex)?.description
        if (stepDesc != null) {
            Spacer(Modifier.height(6.dp))
            Body(stepDesc, size = 13, color = Theatre.ivoryDim)
        }
    }
    Panel(Modifier.fillMaxWidth()) {
        Label(t("tactics.themes", "Themes"))
        Spacer(Modifier.height(8.dp))
        TagRow(tags = TacticsModel.motifsFirst(puzzle.themes).map(Themes::readable))
    }
}

@Composable
private fun CompletionModal(
    completion: TacticsModel.Completion,
    showsSummary: Boolean,
    onToggleSummary: (Boolean) -> Unit,
    onWatchSolution: () -> Unit,
    onRetry: () -> Unit,
    onNext: () -> Unit,
) {
    TrainingModal(tint = completion.verdict.tint) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            BrassIcon(completion.verdict.symbol, 30.dp)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                BasicText(completion.title, style = LocalFaces.current.display(25))
                completion.ratingDelta?.let { (before, after) ->
                    RatingDeltaRow(before = before, after = after)
                }
            }
        }

        if (completion.detail != null) {
            Body(completion.detail, size = 14, color = Theatre.ivoryDim)
        }

        if (!completion.line.isNullOrBlank()) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .heightIn(max = 150.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(Theatre.ink.copy(alpha = 0.45f))
                    .border(1.dp, Theatre.ruleSoft, RoundedCornerShape(10.dp))
                    .padding(10.dp)
                    .verticalScroll(rememberScrollState()),
            ) {
                Body(completion.line, size = 13, color = Theatre.ivoryDim)
            }
        }

        if (completion.themes.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Label(t("tactics.themes", "Themes"), size = 9)
                TagRow(tags = completion.themes)
            }
        }

        ModalButton(
            title = t("tactics.watchSolution", "Watch solution"),
            modifier = Modifier.fillMaxWidth(),
            icon = "play.rectangle",
            onClick = onWatchSolution,
        )

        if (completion.verdict == TacticsModel.Verdict.SUCCESS) {
            val dontShow = !showsSummary
            Row(
                Modifier
                    .fillMaxWidth()
                    .clickable(role = Role.Checkbox) { onToggleSummary(!showsSummary) }
                    .padding(vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(
                    Modifier
                        .size(18.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(if (dontShow) Theatre.brassGlow else Theatre.ink2)
                        .border(1.dp, if (dontShow) Theatre.brass else Theatre.rule, RoundedCornerShape(4.dp)),
                    contentAlignment = Alignment.Center,
                ) {
                    if (dontShow) BrassIcon("checkmark.circle.fill", 14.dp)
                }
                Body(t("common.dontShowAgain", "Do not show this again"), size = 13, color = Theatre.ivoryDim)
            }
        }

        ModalButton(
            title = t("tactics.nextPuzzle", "Next puzzle"),
            modifier = Modifier.fillMaxWidth(),
            primary = true,
            icon = "forward.end",
            onClick = onNext,
        )
        ModalButton(
            title = t("common.tryAgain", "Try again"),
            modifier = Modifier.fillMaxWidth(),
            onClick = onRetry,
        )
    }
}
