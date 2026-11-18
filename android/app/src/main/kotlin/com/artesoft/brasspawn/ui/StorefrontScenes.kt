package com.artesoft.brasspawn.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import com.artesoft.brasspawn.data.Strings
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.engine.CoachService
import com.artesoft.brasspawn.engine.EngineScore
import com.artesoft.brasspawn.engine.notation
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.match.TimeControl
import com.artesoft.brasspawn.training.Coach
import com.artesoft.brasspawn.training.MoveDescription
import com.artesoft.brasspawn.training.MoveGrade
import com.artesoft.brasspawn.training.PositionFeatures
import com.artesoft.brasspawn.training.Themes
import com.artesoft.brasspawn.ui.training.FeedbackTone
import com.artesoft.brasspawn.ui.training.RatingDeltaRow
import com.artesoft.brasspawn.ui.training.TagRow
import com.artesoft.brasspawn.ui.training.TrainingLayout
import com.artesoft.brasspawn.ui.training.VerdictCard

/**
 * Deterministic storefront scenes for automated multi-locale screenshots.
 * Only reachable when `BuildConfig.INTERNAL_TOOLS` is enabled (debug builds).
 */
enum class StorefrontScene(val slug: String) {
    MENU("01-menu"),
    PLAY_MISTAKE("02-playMistake"),
    TACTICS("03-tactics"),
    ONLINE("04-online"),
    POSITIONAL("05-positional"),
    PLAY_COACHED("06-playCoached"),
    PLAY_SETUP("07-playSetup");

    companion object {
        fun parse(raw: String?): StorefrontScene? {
            if (raw.isNullOrBlank()) return null
            val cleaned = raw.trim().replace(Regex("^\\d+-"), "")
            return entries.firstOrNull {
                it.slug.equals(raw.trim(), ignoreCase = true) ||
                    it.slug.substringAfter('-').equals(cleaned, ignoreCase = true) ||
                    it.name.replace("_", "").equals(cleaned, ignoreCase = true)
            }
        }
    }
}

@Composable
fun StorefrontSceneScreen(scene: StorefrontScene, navigator: Navigator) {
    when (scene) {
        StorefrontScene.MENU -> MenuScreen(navigator)
        StorefrontScene.PLAY_MISTAKE -> StorefrontPlayMistake(navigator)
        StorefrontScene.TACTICS -> StorefrontTactics(navigator)
        StorefrontScene.ONLINE -> StorefrontOnline(navigator)
        StorefrontScene.POSITIONAL -> StorefrontPositional(navigator)
        StorefrontScene.PLAY_COACHED -> StorefrontPlayCoached(navigator)
        StorefrontScene.PLAY_SETUP -> StorefrontPlaySetup(navigator)
    }
}

@Composable
private fun StorefrontPlayMistake(navigator: Navigator) {
    val start = Position.start
    val badMove = start.legalMove(Move.fromUci("g2g4")!!)!!
    val bestMove = start.legalMove(Move.fromUci("e2e4")!!)!!
    val afterBad = start.make(badMove)
    val reply = afterBad.legalMove(Move.fromUci("d7d5")!!)!!
    val current = afterBad.make(reply)

    val assessment = Coach.assess(before = 30, after = -123, wasEngineChoice = false)
    val sentence = CoachService.explain(
        position = start,
        move = badMove,
        playedSan = "g4",
        assessment = assessment,
        bestMove = bestMove,
        wasEngineChoice = false,
    )
    val pv = CoachService.notation(start, listOf("e2e4", "c7c5"), limit = 2)
    val level = OpponentLevel.all[1] // Club (1800)
    val evalScore = EngineScore.Centipawns(-123)

    Screen(title = t("progress.play", "Play"), onBack = navigator::back) {
        BoardScreenLayout(
            board = {
                Column {
                    PlayerBar(name = level.name, rating = level.elo, color = PieceColor.BLACK)
                    Spacer(Modifier.height(8.dp))
                    Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
                        EvaluationBar(evalScore.winProbability, playerIsWhite = true)
                        Spacer(Modifier.width(6.dp))
                        ChessBoard(
                            position = current,
                            orientation = PieceColor.WHITE,
                            lastMove = reply.from to reply.to,
                            arrows = listOf(BoardArrow(Square.parse("e2")!!, Square.parse("e4")!!, BoardColors.coachArrow)),
                            showCoordinates = true,
                            darkSet = "black",
                            modifier = Modifier.weight(1f),
                        )
                    }
                    Spacer(Modifier.height(8.dp))
                    PlayerBar(name = t("play.you", "You"), rating = null, color = PieceColor.WHITE)
                }
            },
            panel = {
                Panel(Modifier.fillMaxWidth()) {
                    BasicText(t("play.yourMove", "Your move."), style = LocalFaces.current.display(24))
                    Body(
                        t("play.opponentIs", "Opponent: %@", "${level.name} (${level.elo})"),
                        size = 13, color = Theatre.ivoryDim,
                    )
                }
                Panel(Modifier.fillMaxWidth()) {
                    Label(t("play.coach", "Coach"))
                    Spacer(Modifier.height(6.dp))
                    Body(
                        "g4 — ${MoveGrade.MISTAKE.label}",
                        size = 15,
                        style = LocalFaces.current.body(15, weight = FontWeight.SemiBold, color = Theatre.bad),
                    )
                    if (sentence.isNotBlank()) {
                        Spacer(Modifier.height(4.dp))
                        Body(sentence, size = 13, color = Theatre.ivoryDim)
                    }
                    Spacer(Modifier.height(4.dp))
                    Body(t("play.mainLine", "Main line: %@", pv.notation), size = 12, color = Theatre.ivoryFaint)
                }
                Panel(Modifier.fillMaxWidth()) {
                    Label(t("play.moves", "Moves"))
                    Spacer(Modifier.height(6.dp))
                    Body(moveText(listOf("g4", "d5")), style = LocalFaces.current.figures(13, Theatre.ivoryDim))
                }
            },
            controls = {
                ActionBar {
                    ActionButton(t("play.takeback", "Takeback"), "arrow.uturn.backward", enabled = true) {}
                    ActionButton(t("play.hint", "Hint"), "lightbulb", enabled = true) {}
                    ActionButton(t("play.newGame", "New game"), "plus.circle", primary = true) {}
                }
            },
        )
    }
}

@Composable
private fun StorefrontTactics(navigator: Navigator) {
    // Puzzle lUArAm: White to move, Qxg5xd5+ followed by Rf7 fork/pin (2 solver moves).
    val fen = "r1b4r/3kq1pp/p7/2pn2Q1/1p1nPR2/1B1P4/PPP3PP/R5K1 w - - 0 18"
    val position = remember { Position.fromFen(fen)!! }
    val arrow = BoardArrow(Square.parse("g5")!!, Square.parse("d5")!!, BoardColors.suggestion)
    val motifTags = listOf("fork", "pin", "middlegame").map(Themes::readable)

    Screen(title = t("progress.tactics", "Tactics"), onBack = navigator::back) {
        TrainingLayout(
            board = {
                Column {
                    PlayerBar(name = t("tactics.puzzle", "Puzzle"), rating = 1614, color = PieceColor.BLACK)
                    Spacer(Modifier.height(6.dp))
                    ChessBoard(
                        position = position,
                        orientation = PieceColor.WHITE,
                        arrows = listOf(arrow),
                        showCoordinates = true,
                        darkSet = "black",
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(Modifier.height(6.dp))
                    PlayerBar(name = t("tactics.you", "You"), rating = 1420, color = PieceColor.WHITE)
                }
            },
            panel = {
                Panel(Modifier.fillMaxWidth()) {
                    BasicText(
                        t("common.sideToPlay", "%@ to play", L.color(PieceColor.WHITE)),
                        style = LocalFaces.current.display(23),
                    )
                    Spacer(Modifier.height(4.dp))
                    Body(t("tactics.crushingBlow", "Find the crushing blow."), size = 14, color = Theatre.ivoryDim)
                    Spacer(Modifier.height(8.dp))
                    TagRow(tags = listOf(t("common.moveCount", "%lld moves", 2)))
                }
                Panel(Modifier.fillMaxWidth()) {
                    Label(t("tactics.themes", "Themes"))
                    Spacer(Modifier.height(8.dp))
                    TagRow(tags = motifTags)
                }
            },
            controls = {
                ActionBar {
                    ActionButton(t("tactics.hint", "Hint"), "lightbulb", enabled = true) {}
                    ActionButton(t("tactics.solution", "Solution"), "eye", enabled = true) {}
                    ActionButton(t("tactics.nextPuzzle", "Next puzzle"), "forward.end", primary = true, enabled = true) {}
                }
            },
        )
    }
}

@Composable
private fun StorefrontOnline(navigator: Navigator) {
    val uciMoves = listOf("e2e4", "e7e5", "g1f3", "b8c6", "f1c4", "f8c5", "c2c3", "g8f6")
    val (position, sanMoves, last) = remember {
        var pos = Position.start
        val sans = mutableListOf<String>()
        var lastMove: Pair<Square, Square>? = null
        for (uci in uciMoves) {
            val m = pos.legalMove(Move.fromUci(uci)!!)!!
            sans += pos.san(m)
            pos = pos.make(m)
            lastMove = m.from to m.to
        }
        Triple(pos, sans.toList(), lastMove)
    }
    val clock = TimeControl.FIVE

    Screen(
        title = null,
        onBack = navigator::back,
        trailing = { Label(t("online.android.rated", "Rated game"), color = Theatre.brass) },
    ) {
        BoardScreenLayout(
            board = {
                Column {
                    PlayerBar(
                        name = "Viktor",
                        rating = 1385,
                        color = PieceColor.BLACK,
                        clock = 4 * 60.0 + 51.0,
                        running = false,
                    )
                    Spacer(Modifier.height(8.dp))
                    ChessBoard(
                        position = position,
                        orientation = PieceColor.WHITE,
                        lastMove = last,
                        showCoordinates = true,
                        darkSet = "black",
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(Modifier.height(8.dp))
                    PlayerBar(
                        name = t("play.you", "You"),
                        rating = 1362,
                        color = PieceColor.WHITE,
                        clock = 4 * 60.0 + 42.0,
                        running = true,
                    )
                }
            },
            panel = {
                Panel(Modifier.fillMaxWidth()) {
                    BasicText(t("play.yourMove", "Your move."), style = LocalFaces.current.display(24))
                    Body(
                        t("online.gameSummary", "%@ · %@ · you are %@", clock.displayName, clock.label, L.color(PieceColor.WHITE).lowercase()),
                        size = 13, color = Theatre.ivoryDim,
                    )
                }
                Panel(Modifier.fillMaxWidth()) {
                    Label(t("online.moves", "Moves"))
                    Spacer(Modifier.height(6.dp))
                    Body(moveText(sanMoves), size = 14, style = LocalFaces.current.figures(13, Theatre.ivoryDim))
                }
            },
            controls = {
                ActionBar {
                    ActionButton(t("online.resign", "Resign"), "flag.fill", enabled = true) {}
                    ActionButton(t("online.offerDraw", "Offer draw"), "equal.circle", enabled = true) {}
                }
            },
        )
    }
}

@Composable
private fun StorefrontPositional(navigator: Navigator) {
    // Exercise q1xpyv3s: b7b5 best move (+0.39 for Black), static positional read + best-move praise.
    val fen = "r1bqkb1r/1p1npp1p/p2p1np1/3P4/8/2N1B3/PPPQBPPP/R3K1NR b KQkq - 1 8"
    val position = remember { Position.fromFen(fen)!! }
    val pvUci = listOf("b7b5", "a2a3", "d7b6", "a1d1", "c8b7", "e3d4", "f8g7", "h2h4")
    val pvNotation = remember { CoachService.notation(position, pvUci, limit = 8) }
    val summaryLines = MoveDescription.summary(PositionFeatures(position))
    val moveLines = listOf(
        t("positional.moveCost", "Your move: %.2f · best: %.2f · cost: %.1f%% win probability.", 0.39, 0.39, 0.0),
        t("play.mainLine", "Main line: %@", pvNotation.notation),
    )

    Screen(title = t("progress.positional", "Positional"), onBack = navigator::back) {
        TrainingLayout(
            board = {
                Column {
                    PlayerBar(name = t("positional.exercise", "Exercise"), rating = 1450, color = PieceColor.WHITE)
                    Spacer(Modifier.height(6.dp))
                    ChessBoard(
                        position = position,
                        orientation = PieceColor.BLACK,
                        arrows = listOf(BoardArrow(Square.parse("b7")!!, Square.parse("b5")!!, BoardColors.coachArrow)),
                        showCoordinates = true,
                        darkSet = "black",
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(Modifier.height(6.dp))
                    PlayerBar(name = t("positional.you", "You"), rating = 1248, color = PieceColor.BLACK)
                }
            },
            panel = {
                VerdictCard(
                    tone = FeedbackTone.CORRECT,
                    title = t("positional.android.rightRead", "Right read"),
                    lines = summaryLines,
                )
                VerdictCard(
                    tone = FeedbackTone.CORRECT,
                    title = t("positional.android.sameChoice", "%@ — the engine's choice too", "b5".notation),
                    lines = moveLines,
                ) {
                    Spacer(Modifier.height(4.dp))
                    RatingDeltaRow(before = 1200, after = 1248)
                    Spacer(Modifier.height(6.dp))
                    TagRow(tags = listOf("judgement", "middlegame").map(Themes::readable))
                }
            },
            controls = {
                ActionBar {
                    ActionButton(
                        title = t("common.next", "Next"),
                        icon = "forward.end",
                        primary = true,
                        enabled = true,
                    ) {}
                }
            },
        )
    }
}

@Composable
private fun StorefrontPlayCoached(navigator: Navigator) {
    val p0 = Position.start
    val e4 = p0.legalMove(Move.fromUci("e2e4")!!)!!
    val p1 = p0.make(e4)
    val c5 = p1.legalMove(Move.fromUci("c7c5")!!)!!
    val p2 = p1.make(c5)
    val nf3 = p2.legalMove(Move.fromUci("g1f3")!!)!!
    val p3 = p2.make(nf3)
    val d6 = p3.legalMove(Move.fromUci("d7d6")!!)!!
    val current = p3.make(d6)

    val assessment = Coach.assess(before = 32, after = 35, wasEngineChoice = true)
    val sentence = CoachService.explain(
        position = p2,
        move = nf3,
        playedSan = "Nf3",
        assessment = assessment,
        bestMove = nf3,
        wasEngineChoice = true,
    )
    val level = OpponentLevel.all[1] // Club (1800)
    val evalScore = EngineScore.Centipawns(35)

    Screen(title = t("progress.play", "Play"), onBack = navigator::back) {
        BoardScreenLayout(
            board = {
                Column {
                    PlayerBar(name = level.name, rating = level.elo, color = PieceColor.BLACK)
                    Spacer(Modifier.height(8.dp))
                    Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
                        EvaluationBar(evalScore.winProbability, playerIsWhite = true)
                        Spacer(Modifier.width(6.dp))
                        ChessBoard(
                            position = current,
                            orientation = PieceColor.WHITE,
                            lastMove = nf3.from to nf3.to,
                            arrows = listOf(BoardArrow(nf3.from, nf3.to, BoardColors.coachArrow)),
                            showCoordinates = true,
                            darkSet = "black",
                            modifier = Modifier.weight(1f),
                        )
                    }
                    Spacer(Modifier.height(8.dp))
                    PlayerBar(name = t("play.you", "You"), rating = null, color = PieceColor.WHITE)
                }
            },
            panel = {
                Panel(Modifier.fillMaxWidth()) {
                    BasicText(t("play.yourMove", "Your move."), style = LocalFaces.current.display(24))
                    Body(
                        t("play.opponentIs", "Opponent: %@", "${level.name} (${level.elo})"),
                        size = 13, color = Theatre.ivoryDim,
                    )
                }
                Panel(Modifier.fillMaxWidth()) {
                    Label(t("play.coach", "Coach"))
                    Spacer(Modifier.height(6.dp))
                    Body(
                        "Nf3 — ${MoveGrade.BEST.label}",
                        size = 15,
                        style = LocalFaces.current.body(15, weight = FontWeight.SemiBold, color = Theatre.good),
                    )
                    if (sentence.isNotBlank()) {
                        Spacer(Modifier.height(4.dp))
                        Body(sentence, size = 13, color = Theatre.ivoryDim)
                    }
                }
                Panel(Modifier.fillMaxWidth()) {
                    Label(t("play.moves", "Moves"))
                    Spacer(Modifier.height(6.dp))
                    Body(moveText(listOf("e4", "c5", "Nf3", "d6")), style = LocalFaces.current.figures(13, Theatre.ivoryDim))
                }
            },
            controls = {
                ActionBar {
                    ActionButton(t("play.takeback", "Takeback"), "arrow.uturn.backward", enabled = true) {}
                    ActionButton(t("play.hint", "Hint"), "lightbulb", enabled = true) {}
                    ActionButton(t("play.newGame", "New game"), "plus.circle", primary = true) {}
                }
            },
        )
    }
}

@Composable
private fun StorefrontPlaySetup(navigator: Navigator) {
    val context = LocalContext.current
    val model = remember(Strings.language) {
        PlayModel(context.applicationContext).apply {
            level = OpponentLevel.all[1] // Club (1800)
            side = PieceColor.WHITE
            coachingEnabled = true
        }
    }

    Screen(title = t("progress.play", "Play"), onBack = navigator::back) {
        BoardScreenLayout(
            board = {
                Column {
                    PlayerBar(name = model.level.name, rating = model.level.elo, color = PieceColor.BLACK)
                    Spacer(Modifier.height(8.dp))
                    Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
                        EvaluationBar(0.5, playerIsWhite = true)
                        Spacer(Modifier.width(6.dp))
                        ChessBoard(
                            position = Position.start,
                            orientation = PieceColor.WHITE,
                            showCoordinates = true,
                            darkSet = "black",
                            modifier = Modifier.weight(1f),
                        )
                    }
                    Spacer(Modifier.height(8.dp))
                    PlayerBar(name = t("play.you", "You"), rating = null, color = PieceColor.WHITE)
                }
            },
            panel = {
                SetupPanel(model = model, onStart = {})
            },
            controls = null,
        )
    }
}
