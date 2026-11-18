package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import com.artesoft.brasspawn.match.nowSeconds
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class FeatureTests {
    private fun parse(fen: String): Position = assertNotNull(Position.fromFen(fen), "FEN should parse: $fen")

    @Test
    fun `Open and half-open files are identified`() {
        // White has no d-pawn, Black has no e-pawn; the c-file is empty of both.
        val position = parse("r3k2r/pp1p1ppp/8/8/8/8/PP2PPPP/R3K2R w KQkq - 0 1")
        val features = PositionFeatures(position)

        val byName = features.files.associateBy { it.name }
        assertEquals(true, byName["c"]?.isOpen)
        assertEquals(PieceColor.WHITE, byName["d"]?.halfOpenFor)
        assertEquals(false, byName["a"]?.isOpen)
    }

    @Test
    fun `A rook on an open file is recognised`() {
        val position = parse("4k3/pp4pp/8/8/8/8/PP4PP/3RK3 w - - 0 1")
        val features = PositionFeatures(position)
        val rook = assertNotNull(features.heavyPieces.firstOrNull { it.square == Square.parse("d1")!! })
        assertTrue(rook.onOpenFile)
        assertFalse(rook.onSeventhRank)
    }

    @Test
    fun `An outpost needs a defender and no pawn that can chase it`() {
        // Knight on e5, defended by the d4 pawn. Black has no d- or f-pawn left
        // to drive it away, so it is a genuine outpost.
        val secure = parse("4k3/pp4pp/8/4N3/3P4/8/PP4PP/4K3 w - - 0 1")
        assertEquals(true, PositionFeatures(secure).knights.firstOrNull()?.isOutpost)

        // Same knight, but now a black f-pawn can play f6 and evict it.
        val contested = parse("4k3/pp3ppp/8/4N3/3P4/8/PP4PP/4K3 w - - 0 1")
        assertEquals(false, PositionFeatures(contested).knights.firstOrNull()?.isOutpost)

        // Undefended knight is not an outpost however deep it sits.
        val loose = parse("4k3/pp4pp/8/4N3/8/8/PP4PP/4K3 w - - 0 1")
        assertEquals(false, PositionFeatures(loose).knights.firstOrNull()?.isOutpost)
    }

    @Test
    fun `Pawn structure faults are found`() {
        // White a-pawn is isolated; the White d-pawn on d5 is passed.
        val position = parse("4k3/1p4pp/8/3P4/8/8/P5PP/4K3 w - - 0 1")
        val structure = assertNotNull(PositionFeatures(position).structure[PieceColor.WHITE])
        assertTrue(structure.isolated.contains(Square.parse("a2")!!))
        assertTrue(structure.passed.contains(Square.parse("d5")!!))
    }

    @Test
    fun `Mobility is measured for both sides`() {
        val position = parse(Position.startFen)
        val features = PositionFeatures(position)
        assertEquals(20, features.mobility[PieceColor.WHITE])
        assertEquals(20, features.mobility[PieceColor.BLACK])
    }

    @Test
    fun `Mobility is nought for a side that could not be handed the move`() {
        // Black is in check, so White cannot be given the move: the position
        // that would make is not one, and the count is nought rather than a guess.
        val position = parse("4k3/8/8/8/8/8/4R3/4K3 b - - 0 1")
        val features = PositionFeatures(position)
        assertEquals(0, features.mobility[PieceColor.WHITE])
        assertEquals(4, features.mobility[PieceColor.BLACK])
    }
}

class MoveDescriptionTests {
    private fun describe(fen: String, san: String): List<String> {
        val position = assertNotNull(Position.fromFen(fen))
        val move = assertNotNull(position.moveFromSan(san), "should parse $san")
        val resulting = position.make(move)
        return MoveDescription.clauses(
            before = PositionFeatures(position),
            after = PositionFeatures(resulting),
            move = move,
            position = position,
            resulting = resulting,
        )
    }

    @Test
    fun `Checkmate is described on its own`() {
        val clauses = describe("6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1", "Ra8#")
        assertEquals(listOf("delivers checkmate"), clauses)
    }

    @Test
    fun `Taking the open file is named`() {
        val clauses = describe("4k3/pp4pp/8/8/8/8/PP4PP/R3K3 w - - 0 1", "Rd1")
        assertTrue(clauses.any { it.contains("open d-file") })
    }

    @Test
    fun `Winning material is distinguished from an even trade`() {
        val clauses = describe("4k3/8/8/8/3q4/8/8/3RK3 w - - 0 1", "Rxd4")
        assertTrue(clauses.any { it.contains("wins material") })
    }

    @Test
    fun `Compact notation is expanded into a readable move`() {
        val position = assertNotNull(Position.fromFen("3kq3/pQ6/8/3p4/3P2p1/2P5/PP4PP/4rNK1 b - - 2 37"))
        val move = assertNotNull(position.moveFromSan("Rxf1+"))
        val resulting = position.make(move)
        val sentence = assertNotNull(
            MoveDescription.detailedSentence(san = "Rxf1+", move = move, position = position, resulting = resulting)
        )

        assertTrue(sentence.contains("rook from e1 to f1"))
        assertTrue(sentence.contains("capturing the knight"))
        assertTrue(sentence.contains("giving check"))
        assertEquals("Rxf1+ — Black moves the rook from e1 to f1, capturing the knight, giving check.", sentence)
    }

    @Test
    fun `A summary reads the position`() {
        val position = assertNotNull(Position.fromFen("4k3/pp4pp/8/4N3/3P4/8/PP4PP/3RK3 w - - 0 1"))
        val points = MoveDescription.summary(PositionFeatures(position))
        assertTrue(points.any { it.contains("secure knight on e5") })
        assertTrue(points.any { it.contains("Material") })
        assertTrue(points.contains("Material: White is up roughly 9.00 points."), points.toString())
    }

    /**
     * `Position.make` takes a move straight from notation, which says neither
     * that it is a capture en passant nor that it is a castle. The description
     * has to find that out for itself.
     */
    @Test
    fun `A move given as bare notation is described as what it is`() {
        val position = assertNotNull(Position.fromFen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 2"))
        val bare = assertNotNull(com.artesoft.brasspawn.chess.Move.fromUci("e5d6"))
        val resulting = position.make(bare)
        val sentence = MoveDescription.detailedSentence(san = "exd6", move = bare, position = position, resulting = resulting)
        assertEquals("exd6 — White moves the pawn from e5 to d6, capturing the pawn.", sentence)

        val castling = assertNotNull(Position.fromFen("4k3/8/8/8/8/8/8/4K2R w K - 0 1"))
        val short = assertNotNull(com.artesoft.brasspawn.chess.Move.fromUci("e1g1"))
        assertEquals(
            "O-O — White castles kingside.",
            MoveDescription.detailedSentence(san = "O-O", move = short, position = castling, resulting = castling.make(short)),
        )
    }

    @Test
    fun `Clauses are joined into a sentence`() {
        assertEquals("", MoveDescription.join(emptyList()))
        assertEquals("gives check", MoveDescription.join(listOf("gives check")))
        assertEquals("a and b", MoveDescription.join(listOf("a", "b")))
        assertEquals("a, b and c", MoveDescription.join(listOf("a", "b", "c")))
    }
}

class ProgressTests {
    @Test
    fun `Rating rises on a win and falls on a loss`() {
        var progress = TrainingProgress()
        val start = progress.rating(TrainingMode.TACTICS)

        progress = progress.record(mode = TrainingMode.TACTICS, itemID = "a", itemRating = 1500, correct = true)
        assertTrue(progress.rating(TrainingMode.TACTICS) > start)

        val losing = TrainingProgress()
            .record(mode = TrainingMode.TACTICS, itemID = "a", itemRating = 900, correct = false)
        assertTrue(losing.rating(TrainingMode.TACTICS) < start)
    }

    @Test
    fun `A hint means the attempt does not count towards rating`() {
        val progress = TrainingProgress()
            .record(mode = TrainingMode.TACTICS, itemID = "a", itemRating = 1500, correct = true, usedHint = true)
        assertTrue(progress.rating(TrainingMode.TACTICS) < 1200)  // scored as a miss for rating purposes
    }

    @Test
    fun `A missed puzzle returns tomorrow, a solved one later`() {
        val now = nowSeconds()
        var progress = TrainingProgress()

        progress = progress.record(mode = TrainingMode.TACTICS, itemID = "missed", itemRating = 1200, correct = false, now = now)
        val missed = progress.cards["missed"]!!
        assertEquals(1, missed.intervalDays)

        progress = progress.record(mode = TrainingMode.TACTICS, itemID = "solved", itemRating = 1200, correct = true, now = now)
        progress = progress.record(
            mode = TrainingMode.TACTICS, itemID = "solved", itemRating = 1200, correct = true,
            now = now + 86_400 * 2,
        )
        assertTrue(progress.cards["solved"]!!.intervalDays >= 4)
    }

    @Test
    fun `Descriptive themes are not counted as skills`() {
        val progress = TrainingProgress().record(
            mode = TrainingMode.TACTICS, itemID = "a", itemRating = 1200, correct = true,
            themes = listOf("pin", "short", "middlegame", "crushing"),
        )
        assertNotNull(progress.themes["pin"])
        assertNull(progress.themes["short"])
        assertNull(progress.themes["middlegame"])
    }

    @Test
    fun `Confidence, not raw accuracy, ranks weaknesses`() {
        val oneMiss = ThemeRecord(seen = 1, solved = 0)
        val manyMisses = ThemeRecord(seen = 20, solved = 5)

        // Both are 0% and 25%, but only the second is evidence of a weakness.
        assertTrue(manyMisses.ceiling < oneMiss.ceiling)
    }

    @Test
    fun `Targets are motifs below your own baseline`() {
        val progress = TrainingProgress(
            themes = mapOf(
                "pin" to ThemeRecord(seen = 12, solved = 3),
                "deflection" to ThemeRecord(seen = 9, solved = 3),
                "fork" to ThemeRecord(seen = 14, solved = 12),
                "discoveredAttack" to ThemeRecord(seen = 10, solved = 9),
            ),
        )
        val names = progress.trainingTargets().map { it.name }.toSet()
        assertTrue(names.contains("pin"))
        assertTrue(names.contains("deflection"))
        assertFalse(names.contains("fork"))
    }

    @Test
    fun `Streaks count consecutive days only`() {
        var progress = TrainingProgress()
        val day = 1_700_000_000.0
        progress = progress.record(mode = TrainingMode.TACTICS, itemID = "a", itemRating = 1200, correct = true, now = day)
        progress = progress.record(
            mode = TrainingMode.TACTICS, itemID = "b", itemRating = 1200, correct = true,
            now = day + 86_400,
        )
        assertEquals(2, progress.currentStreak)

        // Skipping a day resets it.
        progress = progress.record(
            mode = TrainingMode.TACTICS, itemID = "c", itemRating = 1200, correct = true,
            now = day + 86_400 * 4,
        )
        assertEquals(1, progress.currentStreak)
        assertEquals(2, progress.bestStreak)
    }

    /** Recording hands back the progress afterwards; the one it was asked of is as it was. */
    @Test
    fun `Recording leaves the progress it started from alone`() {
        val before = TrainingProgress()
        val after = before.record(mode = TrainingMode.TACTICS, itemID = "a", itemRating = 1500, correct = true, themes = listOf("pin"))
        assertTrue(before.cards.isEmpty() && before.history.isEmpty() && before.themes.isEmpty() && before.pools.isEmpty())
        assertEquals(1, after.history.size)
        assertEquals(after.rating(TrainingMode.TACTICS), after.history[0].ratingAfter)
        assertTrue(after.hasSeen("a"))
    }

    @Test
    fun `The history keeps the last two thousand attempts`() {
        var progress = TrainingProgress()
        for (index in 0 until 2003) {
            progress = progress.record(
                mode = TrainingMode.POSITIONAL, itemID = "i$index", itemRating = 1200, correct = index % 2 == 0,
                now = 1_700_000_000.0 + index,
            )
        }
        assertEquals(2000, progress.history.size)
        assertEquals("i3", progress.history.first().itemID)
        assertEquals("i2002", progress.history.last().itemID)
    }

    @Test
    fun `Only one rated game a day against the same opponent`() {
        val at = 1_700_000_000.0
        val progress = TrainingProgress().noteRated(against = "G:1", at = at)
        assertFalse(progress.canRate(against = "G:1", at = at + 86_399))
        assertTrue(progress.canRate(against = "G:1", at = at + 86_400))
        assertTrue(progress.canRate(against = "G:2", at = at))
        assertTrue(progress.canRate(against = "", at = at))
        // Noting another a day later drops the first.
        assertEquals(setOf("G:2"), progress.noteRated(against = "G:2", at = at + 86_400).ratedOpponents.keys)
        assertEquals(progress, progress.noteRated(against = "", at = at))
    }

    @Test
    fun `A recording is only ever marked forward`() {
        var progress = TrainingProgress().mark(watched = "g", ply = 20, of = 40, at = 100.0)
        progress = progress.mark(watched = "g", ply = 5, of = 40, at = 200.0)
        val mark = assertNotNull(progress.watchMark("g"))
        assertEquals(20, mark.ply)
        assertEquals(200.0, mark.at)
        assertEquals(0.5, mark.fraction)
        assertFalse(mark.isFinished)
        assertTrue(WatchMark(ply = 41, of = 40, at = 0.0).isFinished)
        assertEquals(1.0, WatchMark(ply = 41, of = 40, at = 0.0).fraction)
        assertEquals(0.0, WatchMark(ply = 3, of = 0, at = 0.0).fraction)

        // Four hundred are kept; the ones longest unopened go first.
        for (index in 0 until 405) {
            progress = progress.mark(watched = "n$index", ply = 1, of = 10, at = 1_000.0 + index)
        }
        assertEquals(400, progress.watched.size)
        assertNull(progress.watchMark("g"))
        assertNull(progress.watchMark("n4"))
        assertNotNull(progress.watchMark("n5"))
    }

    @Test
    fun `Favourites toggle`() {
        var progress = TrainingProgress().toggleFavourite("a")
        assertTrue(progress.isFavourite("a"))
        progress = progress.toggleFavourite("a")
        assertFalse(progress.isFavourite("a"))
    }
}

class SelectionTests {
    private fun puzzle(id: String, rating: Int, themes: List<String>): Puzzle =
        Puzzle(
            id = id, fen = Position.startFen, solution = listOf("e2e4"), themes = themes,
            rating = rating, mate = false, source = null,
        )

    @Test
    fun `Due reviews come before anything else`() {
        val now = nowSeconds()
        val progress = TrainingProgress().record(
            mode = TrainingMode.TACTICS, itemID = "old", itemRating = 1200, correct = false,
            now = now - 86_400 * 3,
        )

        val puzzles = listOf(
            puzzle("old", rating = 1200, themes = listOf("pin")),
            puzzle("new", rating = 1250, themes = listOf("fork")),
        )
        val selection = ItemSelector.nextPuzzle(from = puzzles, progress = progress, now = now)
        assertEquals("old", selection?.item?.id)
        assertEquals(SelectionReason.Review, selection?.reason)
    }

    @Test
    fun `Weak motifs are targeted most of the time`() {
        val progress = TrainingProgress(
            pools = mapOf(RatedPool.Training(TrainingMode.TACTICS).id to PoolRating(rating = 1500)),
            themes = mapOf(
                "pin" to ThemeRecord(seen = 12, solved = 3),
                "fork" to ThemeRecord(seen = 14, solved = 12),
                "discoveredAttack" to ThemeRecord(seen = 10, solved = 9),
            ),
        )

        val puzzles = (0 until 40).map { index ->
            puzzle("p$index", rating = 1500, themes = if (index % 2 == 0) listOf("pin") else listOf("fork"))
        }

        // Force the targeting branch; the share itself is a product decision,
        // not something a test should pin down.
        val selection = ItemSelector.nextPuzzle(
            from = puzzles, progress = progress,
            random = { 0 }, chance = { 0.0 },
        )
        assertEquals(true, selection?.item?.themes?.contains("pin"))
        val reason = assertIs<SelectionReason.Weakness>(selection?.reason, "expected a weakness selection, got ${selection?.reason}")
        assertEquals("pin", reason.motif)
        assertEquals("Chosen for you: pin — 25% of 12 so far.", reason.explanation)
    }

    @Test
    fun `Without enough evidence it just tracks your level`() {
        val progress = TrainingProgress(
            pools = mapOf(RatedPool.Training(TrainingMode.TACTICS).id to PoolRating(rating = 1500)),
        )
        val puzzles = listOf(
            puzzle("near", rating = 1540, themes = listOf("pin")),
            puzzle("far", rating = 2400, themes = listOf("pin")),
        )
        val selection = ItemSelector.nextPuzzle(
            from = puzzles, progress = progress, random = { 0 }, chance = { 0.0 },
        )
        assertEquals("near", selection?.item?.id)
        assertEquals(SelectionReason.Level, selection?.reason)
        assertNull(selection?.reason?.explanation)
    }

    @Test
    fun `Nothing to choose from is nothing chosen`() {
        val progress = TrainingProgress()
        assertNull(ItemSelector.nextPuzzle(from = emptyList(), progress = progress))
        assertNull(ItemSelector.nextExercise(from = emptyList(), progress = progress))
        assertNull(ItemSelector.nextDrill(from = emptyList(), progress = progress))
        assertNull(ItemSelector.nextRushPuzzle(from = emptyList(), targetRating = 1200, excluding = emptySet()))
    }
}

class GradingTests {
    @Test
    fun `A move is graded by the winning chance it gave up`() {
        assertEquals(MoveGrade.BEST, Coach.assess(before = 30, after = 30, wasEngineChoice = false).grade)
        // The same hundred centipawns: decisive when level, nothing when a queen up.
        val level = Coach.assess(before = 0, after = -100, wasEngineChoice = false)
        val winning = Coach.assess(before = 900, after = 800, wasEngineChoice = false)
        assertEquals(MoveGrade.INACCURACY, level.grade)
        assertEquals(MoveGrade.EXCELLENT, winning.grade)
        assertEquals(100, level.centipawnsLost)
        assertTrue(level.grade.isMistake)
        assertFalse(winning.grade.isMistake)
        // The engine's own choice is the best move whatever the numbers say.
        assertEquals(MoveGrade.BEST, Coach.assess(before = 50, after = -400, wasEngineChoice = true).grade)
        assertEquals(MoveGrade.BLUNDER, Coach.assess(before = 0, after = -600, wasEngineChoice = false).grade)
        assertEquals("Best move", MoveGrade.BEST.label)
    }

    @Test
    fun `Win probability is the logistic fit, clamped`() {
        assertEquals(0.5, Coach.winProbability(0))
        assertEquals(Coach.winProbability(1000), Coach.winProbability(5000))
        assertEquals(1.0, Coach.winProbability(300) + Coach.winProbability(-300), 1e-12)
    }

    @Test
    fun `Accuracy is capped per move`() {
        assertEquals(100, Coach.accuracy(emptyList()))
        assertEquals(100, Coach.accuracy(listOf(0)))
        assertEquals(94, Coach.accuracy(listOf(10, 20, 30)))
        assertEquals(67, Coach.accuracy(listOf(1000, 0, 0)))
        assertEquals(0, Coach.accuracy(listOf(900, 900)))
    }
}

class TrainingRatingPoolTests {
    @Test
    fun `A file from before the split keeps every rating it held`() {
        val old = """
            {
              "ratings": [ "tactics", 1740, "positional", 1310, "endgame", 980 ],
              "onlineRating": 1655,
              "onlineGames": 87,
              "onlineWins": 40, "onlineLosses": 39, "onlineDraws": 8,
              "currentStreak": 4, "bestStreak": 11
            }
        """.trimIndent()
        val progress = TrainingProgress.decode(old)

        assertEquals(1740, progress.rating(TrainingMode.TACTICS))
        assertEquals(1310, progress.rating(TrainingMode.POSITIONAL))
        assertEquals(980, progress.rating(TrainingMode.ENDGAME))

        for (control in com.artesoft.brasspawn.match.TimeControl.entries) {
            val pool = RatedPool.Online(control.minutes)
            assertEquals(1655, progress.rating(pool), "${control.minutes} min came out at ${progress.rating(pool)}")
            assertEquals(0, progress.gamesPlayed(pool))
        }

        assertEquals(40, progress.onlineWins)
        assertEquals(11, progress.bestStreak)
    }

    @Test
    fun `Clocks are rated apart from each other`() {
        var progress = TrainingProgress()
        val before = progress.rating(RatedPool.Online(30))

        repeat(5) {
            progress = progress.settle(RatedPool.Online(3), against = 1600, score = 1.0)
        }

        assertTrue(progress.rating(RatedPool.Online(3)) > 1200, "beating 1600s should move blitz")
        assertEquals(before, progress.rating(RatedPool.Online(30)), "and should not move classical")
        assertEquals(1200, progress.rating(RatedPool.Training(TrainingMode.TACTICS)))
        assertEquals(1200, progress.rating(RatedPool.Engine))
    }

    @Test
    fun `A rush run rates only its own length`() {
        var progress = TrainingProgress(
            pools = mapOf(RatedPool.Training(TrainingMode.TACTICS).id to PoolRating(rating = 1500)),
        )
        assertEquals(1500, progress.rating(RatedPool.Rush(5)))

        progress = progress.record(
            rush = RushRecord(solved = 3, bestStreak = 3, duration = 300.0, achievedAt = 1_700_000_000.0),
            attempts = List(3) { RushAttempt(rating = 1800, solved = true) },
        )

        assertTrue(progress.rating(RatedPool.Rush(5)) > 1500)
        assertEquals(1500, progress.rating(RatedPool.Rush(3)), "a different length is a different pool")
        assertEquals(1500, progress.rating(RatedPool.Training(TrainingMode.TACTICS)), "and untimed tactics is untouched")
    }

    @Test
    fun `The engine has a pool of its own`() {
        val progress = TrainingProgress().record(
            game = GameRecord(
                playedAt = 1_700_000_000.0,
                result = "win",
                accuracy = 90,
                blunders = 0,
                opponentElo = 2100,
            )
        )

        assertTrue(progress.rating(RatedPool.Engine) > 1200)
        assertEquals(1200, progress.rating(RatedPool.Online(5)))
        assertEquals(1, progress.gamesPlayed(RatedPool.Engine))
    }

    @Test
    fun `Every pool's identifier reads back as itself`() {
        val pools = listOf(
            RatedPool.Training(TrainingMode.TACTICS),
            RatedPool.Training(TrainingMode.ENDGAME),
            RatedPool.Rush(3),
            RatedPool.Online(15),
            RatedPool.Engine,
        )
        for (pool in pools) {
            assertEquals(pool, RatedPool.fromId(pool.id))
        }
        assertNull(RatedPool.fromId(""))
        assertNull(RatedPool.fromId("unknown.pool"))
        assertEquals("Strong club", LadderRung.current(1500).name)
    }
}
