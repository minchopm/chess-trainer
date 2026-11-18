package com.artesoft.brasspawn.ui

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import com.artesoft.brasspawn.data.SoundBoard
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.engine.EngineScore
import com.artesoft.brasspawn.engine.SearchBudget
import com.artesoft.brasspawn.engine.CoachService
import com.artesoft.brasspawn.engine.MoveReview
import com.artesoft.brasspawn.engine.StockfishEngine
import com.artesoft.brasspawn.training.Coach
import com.artesoft.brasspawn.training.MoveGrade

/** A rung of the opponent ladder: a name and the rating Stockfish is held to. */
data class OpponentLevel(val id: Int, val key: String, val english: String, val elo: Int?) {
    val name: String get() = t(key, english)

    companion object {
        val fullStrength = OpponentLevel(5, "play.fullStrength", "Full strength", null)
        val all = listOf(
            OpponentLevel(0, "play.casual", "Casual", 1400),
            OpponentLevel(1, "play.club", "Club", 1800),
            OpponentLevel(2, "play.strongClub", "Strong club", 2100),
            OpponentLevel(3, "play.expert", "Expert", 2400),
            OpponentLevel(4, "play.master", "Master", 2700),
            fullStrength,
        )
    }
}

/** One move of the game as the list shows it: the notation and, once graded, how good it was. */
data class PlayedMove(val san: String, val grade: MoveGrade? = null)

/** How a finished game went, for the card that closes it. */
data class GameSummary(val result: String, val accuracy: Int, val blunders: Int, val mistakes: Int, val inaccuracies: Int)

/**
 * A game against the engine, with the coach grading each of the player's
 * moves as it is made — the same game the iOS app's PlayModel runs.
 */
class PlayModel(context: Context) {
    private val sounds = SoundBoard.shared(context)

    var position by mutableStateOf(Position.start)
        private set
    var lastMove by mutableStateOf<Pair<Square, Square>?>(null)
        private set
    var arrows by mutableStateOf<List<BoardArrow>>(emptyList())
        private set
    var evaluation by mutableStateOf<EngineScore?>(null)
        private set
    var moves by mutableStateOf<List<PlayedMove>>(emptyList())
        private set
    var isThinking by mutableStateOf(false)
        private set
    var hasStarted by mutableStateOf(false)
        private set
    var latestReview by mutableStateOf<MoveReview?>(null)
        private set
    var summary by mutableStateOf<GameSummary?>(null)
        private set
    var coachingEnabled by mutableStateOf(true)

    private var losses = listOf<Int>()

    var side by mutableStateOf(PieceColor.WHITE)
    var level by mutableStateOf(OpponentLevel.all[1])

    val isOver: Boolean get() = position.isGameOver
    val legalMoves: List<Move>
        get() = if (hasStarted && !isThinking && position.sideToMove == side && !isOver) position.legalMoves() else emptyList()

    val statusText: String
        get() = when {
            position.isCheckmate ->
                if (position.sideToMove == side) t("play.checkmateLost", "Checkmate — you lost.")
                else t("play.checkmateWon", "Checkmate — you won.")
            position.isDraw -> t("play.draw", "Draw.")
            isThinking -> t("play.engineThinking", "Engine is thinking…")
            position.sideToMove == side -> t("play.yourMove", "Your move.")
            else -> t("play.engineToMove", "Engine to move.")
        }

    suspend fun start(engine: StockfishEngine) {
        position = Position.start
        moves = emptyList()
        arrows = emptyList()
        lastMove = null
        evaluation = EngineScore.Centipawns(20)
        hintLevel = 0
        latestReview = null
        summary = null
        losses = emptyList()
        hasStarted = true
        engine.newGame()
        if (side == PieceColor.BLACK) {
            isThinking = true
            playEngineMove(engine)
            isThinking = false
        }
    }

    suspend fun play(move: Move, engine: StockfishEngine) {
        if (!hasStarted || isThinking || position.sideToMove != side || isOver) return
        val legal = position.legalMove(move) ?: return
        isThinking = true
        val before = position
        apply(legal)
        // Graded while the engine has not yet replied: the coach's two searches
        // and the opponent's move share the one engine, in that order.
        if (coachingEnabled) {
            runCatching { CoachService(engine).review(before, legal) }.getOrNull()?.let { review ->
                latestReview = review
                moves = moves.dropLast(1) + moves.last().copy(grade = review.assessment.grade)
                losses = losses + review.assessment.centipawnsLost
                evaluation = review.scoreAfter
            }
        }
        if (!isOver) playEngineMove(engine)
        isThinking = false
        if (isOver) finish()
    }

    private fun finish() {
        val graded = moves.mapNotNull { it.grade }
        summary = GameSummary(
            result = if (position.isCheckmate) (if (position.sideToMove == side) "loss" else "win") else "draw",
            accuracy = Coach.accuracy(losses),
            blunders = graded.count { it == MoveGrade.BLUNDER },
            mistakes = graded.count { it == MoveGrade.MISTAKE },
            inaccuracies = graded.count { it == MoveGrade.INACCURACY },
        )
    }

    private fun apply(move: Move) {
        val san = position.san(move)
        val captured = position.pieceAt(move.to) != null
        position = position.make(move)
        lastMove = move.from to move.to
        moves = moves + PlayedMove(san)
        arrows = emptyList()
        hintLevel = 0
        sounds.play(move, captured, position)
    }

    /**
     * A limited engine gets its strength from UCI_Elo, so it has no reason to
     * think for long; full strength is the only setting that needs the time.
     */
    private val budget: SearchBudget get() = if (level.elo == null) SearchBudget.fullStrength else SearchBudget.limited

    private suspend fun playEngineMove(engine: StockfishEngine) {
        val uci = runCatching { engine.chooseMove(position.fen, level.elo, budget) }.getOrNull() ?: return
        val move = Move.fromUci(uci)?.let(position::legalMove) ?: return
        apply(move)
    }

    fun takeBack() {
        if (isThinking || moves.size < 2) return
        // Undo is a position rebuild rather than a move stack: replaying from
        // the start is instant at these lengths and cannot drift out of step.
        val kept = moves.dropLast(2)
        var replay = Position.start
        for (entry in kept) replay = replay.moveFromSan(entry.san)?.let(replay::make) ?: break
        moves = kept
        losses = losses.dropLast(1)
        latestReview = null
        summary = null
        position = replay
        lastMove = null
        arrows = emptyList()
        hintLevel = 0
    }

    /** How many times a hint has been asked for in this position. */
    private var hintLevel = 0

    suspend fun hint(engine: StockfishEngine) {
        if (isThinking || position.sideToMove != side || isOver) return
        hintLevel++
        isThinking = true
        try {
            val analysis = engine.analyse(position.fen, SearchBudget.hint)
            val move = analysis.lines.firstOrNull()?.bestMove?.let(Move::fromUci)?.let(position::legalMove) ?: return
            arrows = listOf(BoardArrow(move.from, move.to))
        } catch (_: Exception) {
        } finally {
            isThinking = false
        }
    }
}
