package com.artesoft.brasspawn.engine

import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.training.Coach
import com.artesoft.brasspawn.training.MoveAssessment
import com.artesoft.brasspawn.training.MoveDescription
import com.artesoft.brasspawn.training.PositionFeatures
import java.text.NumberFormat

class MoveReview(
    val played: Move,
    val playedSan: String,
    val assessment: MoveAssessment,
    val scoreAfter: EngineScore?,
    val bestSan: String?,
    val bestMove: Move?,
    val principalVariation: String,
    val sentence: String,
)

/**
 * Wraps the engine in the questions the trainer actually asks it.
 *
 * Everything here converts scores into the mover's point of view before
 * comparing them. UCI reports from the side to move, so a score taken after a
 * move belongs to the *opponent* — comparing the two raw is the single easiest
 * way to grade every move exactly backwards.
 */
class CoachService(private val engine: StockfishEngine) {

    suspend fun review(position: Position, move: Move, budget: SearchBudget = SearchBudget.coaching): MoveReview {
        val mover = position.sideToMove
        val playedSan = position.san(move)

        val before = engine.analyse(position.fen, budget, multiPV = 2)
        val bestUci = before.lines.firstOrNull()?.bestMove ?: before.bestMove
        val bestMove = bestUci?.let(Move::fromUci)?.let(position::legalMove)

        val scoreBefore = before.lines.firstOrNull()?.let { score(it.score, mover, mover) } ?: 0

        val after = position.make(move)
        val wasEngineChoice = bestMove?.matchesNotation(move) ?: false

        var scoreAfterValue = scoreBefore
        var scoreAfter: EngineScore? = before.lines.firstOrNull()?.score
        if (!wasEngineChoice) {
            if (after.isCheckmate) {
                scoreAfterValue = 10_000                       // you just mated them
                scoreAfter = EngineScore.Mate(1)
            } else if (after.isDraw) {
                scoreAfterValue = 0
                scoreAfter = EngineScore.Centipawns(0)
            } else {
                val result = engine.analyse(after.fen, budget, multiPV = 1)
                result.lines.firstOrNull()?.let { line ->
                    scoreAfterValue = score(line.score, mover, after.sideToMove)
                    scoreAfter = line.score.pointOfView(sideToMove = after.sideToMove == mover)
                }
            }
        }

        val assessment = Coach.assess(before = scoreBefore, after = scoreAfterValue, wasEngineChoice = wasEngineChoice)

        return MoveReview(
            played = move,
            playedSan = playedSan,
            assessment = assessment,
            scoreAfter = scoreAfter,
            bestSan = bestMove?.let(position::san),
            bestMove = bestMove,
            principalVariation = notation(position, before.lines.firstOrNull()?.moves.orEmpty()),
            sentence = explain(position, move, playedSan, assessment, bestMove, wasEngineChoice),
        )
    }

    companion object {
        /** Score for `color`, given a score reported for whoever is to move. */
        fun score(score: EngineScore, color: PieceColor, toMove: PieceColor): Int =
            score.pointOfView(sideToMove = color == toMove).comparable

        /** Render a principal variation as readable notation. */
        fun notation(position: Position, uciMoves: List<String>, limit: Int = 6): String {
            var replay = position
            val text = StringBuilder()
            for (uci in uciMoves.take(limit)) {
                val move = Move.fromUci(uci)?.let(replay::legalMove) ?: break
                val number = replay.fullmoveNumber
                val san = replay.san(move)
                if (replay.sideToMove == PieceColor.WHITE) text.append(number).append('.').append(san).append(' ')
                else if (text.isEmpty()) text.append(number).append("...").append(san).append(' ')
                else text.append(san).append(' ')
                replay = replay.make(move)
            }
            return text.toString().trim()
        }

        fun explain(
            position: Position, move: Move, playedSan: String,
            assessment: MoveAssessment, bestMove: Move?, wasEngineChoice: Boolean,
        ): String {
            val resulting = position.make(move)
            val parts = mutableListOf<String>()
            MoveDescription.sentence(
                san = playedSan, before = PositionFeatures(position), after = PositionFeatures(resulting),
                move = move, position = position, resulting = resulting,
            )?.let(parts::add)

            if (wasEngineChoice) {
                if (parts.isEmpty()) parts += L.t("coach.engineAgrees", "%@ is what the engine plays too.", playedSan.notation)
            } else if (bestMove != null) {
                val afterBest = position.make(bestMove)
                val reasons = MoveDescription.clauses(
                    before = PositionFeatures(position), after = PositionFeatures(afterBest),
                    move = bestMove, position = position, resulting = afterBest,
                )
                // Whole sentences with numbered arguments, not English
                // fragments glued together: word order is the translator's.
                val better = position.san(bestMove).notation
                val threwAwayMate = assessment.centipawnsLost >= 9000
                val cost = pawnFormatter().format(assessment.centipawnsLost / 100.0)
                parts += if (reasons.isEmpty()) {
                    if (threwAwayMate) L.t("coach.strongerMate", "%@ was stronger, and it throws away a forced mate.", better)
                    else L.t("coach.strongerCost", "%1\$@ was stronger, costing about %2\$@ pawns.", better, cost)
                } else {
                    val why = MoveDescription.join(reasons)
                    if (threwAwayMate) L.t("coach.strongerReasonMate", "%1\$@ was stronger — it %2\$@, and it throws away a forced mate.", better, why)
                    else L.t("coach.strongerReasonCost", "%1\$@ was stronger — it %2\$@, costing about %3\$@ pawns.", better, why, cost)
                }
            }
            return parts.joinToString(" ")
        }

        /** The cost in pawns, in the reader's own numerals. */
        private fun pawnFormatter(): NumberFormat = NumberFormat.getNumberInstance().apply {
            minimumFractionDigits = 2
            maximumFractionDigits = 2
        }
    }
}

/**
 * Chess notation, kept the way round it is written. A move dropped into a
 * right-to-left sentence is reordered by the bidirectional algorithm; an
 * isolate says: whatever surrounds this, read it forwards.
 */
val String.notation: String get() = "⁦$this⁩"
