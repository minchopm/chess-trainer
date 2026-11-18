package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.Piece
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.PieceKind
import com.artesoft.brasspawn.chess.Square
import com.artesoft.brasspawn.match.ChessClock.PieceColorKey
import com.artesoft.brasspawn.match.MatchResult.Outcome
import com.artesoft.brasspawn.match.MatchResult.Reason
import com.artesoft.brasspawn.match.MatchSession.Phase
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Hands every packet straight to the other session, so a whole game can be
 * played in a test without a server, two devices or two accounts.
 */
class LoopbackTransport : MatchTransport {
    var peer: MatchSession? = null
    var dropped = false

    /** Everything said, whether or not it was heard. */
    val sent = ArrayList<String>()

    override fun send(data: String) {
        sent.add(data)
        if (dropped) return
        peer?.receive(data)
    }
}

/** Two sessions, each other's opponent. */
class MatchPair(timeControl: TimeControl = TimeControl.FIVE, openPool: Boolean = true) {
    val hostTransport = LoopbackTransport()
    val guestTransport = LoopbackTransport()
    val host = MatchSession(
        transport = hostTransport,
        me = MatchPacket.Hello(playerID = "A", name = "Ann", rating = 1200, games = 0),
        isHost = true, timeControl = timeControl, openPool = openPool,
    )
    val guest = MatchSession(
        transport = guestTransport,
        me = MatchPacket.Hello(playerID = "B", name = "Bo", rating = 1200, games = 0),
        isHost = false, timeControl = timeControl, openPool = openPool,
    )

    init {
        hostTransport.peer = guest
        guestTransport.peer = host
    }

    /** Both devices announce themselves; only the host deals the colours. */
    fun begin(hostPlaysWhite: Boolean = true) {
        guest.begin()
        host.begin(whiteIsHost = hostPlaysWhite)
    }
}

private fun makePair(timeControl: TimeControl = TimeControl.FIVE, openPool: Boolean = true): MatchPair =
    MatchPair(timeControl, openPool)

private fun square(name: String): Square = Square.parse(name)!!

private fun MatchSession.play(from: String, to: String): Boolean = play(square(from), square(to), promotion = null)

private fun finished(outcome: Outcome, reason: Reason): Phase = Phase.Finished(MatchResult(outcome, reason))

/** Online match. */
class MatchTests {
    /**
     * Neither device knows which of them will be ready first.
     *
     * Game Center hands both ends a match at more or less the same moment, but
     * "more or less" is the whole problem: whichever session is built second
     * misses anything the first one said. The deal therefore waits for the
     * guest's hello rather than going out with the host's, and it has to work
     * whichever order the two arrive in.
     */
    @Test
    fun `The host waits for the guest before dealing`() {
        val pair = makePair()

        pair.host.begin(whiteIsHost = true)
        assertEquals(Phase.Waiting, pair.host.phase, "nobody has answered yet")
        assertEquals(Phase.Waiting, pair.guest.phase)

        pair.guest.begin()
        assertEquals(Phase.Playing, pair.host.phase)
        assertEquals(Phase.Playing, pair.guest.phase)
        assertEquals(PieceColor.WHITE, pair.host.myColor)
        assertEquals(PieceColor.BLACK, pair.guest.myColor)
    }

    /**
     * And a hello spoken into a void is said again.
     *
     * This is the case that hung: the guest's first hello goes out before the
     * host has a session to hand it to, so it is dropped — not queued, not
     * resent by anything underneath. Without the repeat both ends wait for the
     * other to speak first, which is a game that never starts and never fails.
     */
    @Test
    fun `A hello lost before the other side is listening is said again`() {
        val pair = makePair()

        pair.guestTransport.dropped = true
        pair.guest.begin()
        pair.host.begin(whiteIsHost = true)
        assertEquals(Phase.Waiting, pair.host.phase, "the host never heard the guest")
        assertEquals(Phase.Waiting, pair.guest.phase)

        pair.guestTransport.dropped = false
        pair.guest.tick(now = nowSeconds())
        assertEquals(Phase.Playing, pair.host.phase)
        assertEquals(Phase.Playing, pair.guest.phase)
        assertEquals("Ann", pair.guest.opponent?.name, "and the host says who it is")
    }

    @Test
    fun `While waiting, hello is said once a second and no more`() {
        val pair = makePair()
        pair.guestTransport.dropped = true
        pair.guest.begin()
        assertEquals(1, pair.guestTransport.sent.size)

        pair.guest.tick(now = 1000.0)
        pair.guest.tick(now = 1000.5)
        assertEquals(2, pair.guestTransport.sent.size, "half a second later is too soon")
        pair.guest.tick(now = 1001.0)
        assertEquals(3, pair.guestTransport.sent.size)
        assertTrue(pair.guestTransport.sent.all { MatchPacket.fromJson(it) is MatchPacket.Hello })
    }

    @Test
    fun `The host deals the colours and both sides agree`() {
        val pair = makePair()
        pair.begin()

        assertEquals(PieceColor.WHITE, pair.host.myColor)
        assertEquals(PieceColor.BLACK, pair.guest.myColor)
        assertTrue(pair.host.isMyTurn)
        assertFalse(pair.guest.isMyTurn)
        assertEquals("Ann", pair.guest.opponent?.name)
        assertEquals("Bo", pair.host.opponent?.name)
    }

    @Test
    fun `Left to chance, the colours still agree`() {
        repeat(8) {
            val pair = makePair()
            pair.guest.begin()
            pair.host.begin()
            assertEquals(pair.host.myColor.opponent, pair.guest.myColor)
            assertEquals(Phase.Playing, pair.guest.phase)
        }
    }

    @Test
    fun `A move made on one board appears on the other`() {
        val pair = makePair()
        pair.begin()

        assertTrue(pair.host.play("e2", "e4"))
        assertEquals(pair.host.position.fen, pair.guest.position.fen)
        assertEquals(listOf("e4"), pair.guest.moves)
        assertTrue(pair.guest.isMyTurn)
        assertFalse(pair.host.isMyTurn)
        assertEquals(MatchSession.LastMove(square("e2"), square("e4")), pair.guest.lastMove)
        assertTrue(pair.host.legalDestinations.isEmpty(), "nothing to tap while it is not your move")
        assertEquals(listOf(square("e6"), square("e5")), pair.guest.legalDestinations[square("e7")])
    }

    @Test
    fun `A move out of turn is refused rather than sent`() {
        val pair = makePair()
        pair.begin()

        assertFalse(pair.guest.play("e7", "e5"))
        assertTrue(pair.guest.moves.isEmpty())
        assertTrue(pair.host.moves.isEmpty())
    }

    @Test
    fun `Checkmate ends both sides, one as a win and one as a loss`() {
        val pair = makePair()
        pair.begin()

        // Fool's mate: 1.f3 e5 2.g4 Qh4#
        pair.host.play("f2", "f3")
        pair.guest.play("e7", "e5")
        pair.host.play("g2", "g4")
        pair.guest.play("d8", "h4")

        assertEquals(finished(Outcome.WIN, Reason.CHECKMATE), pair.guest.phase)
        assertEquals(finished(Outcome.LOSS, Reason.CHECKMATE), pair.host.phase)
        assertEquals(listOf("f3", "e5", "g4", "Qh4#"), pair.host.moves)
        assertFalse(pair.host.clock.isRunning)
    }

    /**
     * A flag has to end the game even when the device it belongs to is asleep.
     *
     * Only the owner used to claim it, which reads well and assumes the owner
     * is awake to say so. A phone whose screen has locked is not, and the game
     * then ran on past zero with the clock showing nothing left — decided by
     * whatever happened after, on a board that should have been over.
     */
    @Test
    fun `A flag the other device never reports is claimed here`() {
        val pair = makePair(timeControl = TimeControl.THREE)
        pair.begin()
        // One move, so that it is the guest thinking and the guest's clock
        // that runs out.
        assertTrue(pair.host.play("e2", "e4"))

        val out = nowSeconds() + TimeControl.THREE.seconds + 1
        pair.host.tick(now = out)
        assertEquals(Phase.Playing, pair.host.phase, "not on sight: their move may be on the wire")

        pair.host.tick(now = out + 4)
        assertEquals(finished(Outcome.WIN, Reason.TIMEOUT), pair.host.phase)
        assertEquals(
            finished(Outcome.LOSS, Reason.TIMEOUT), pair.guest.phase,
            "and the other device is told, rather than left on a dead board",
        )
    }

    /**
     * Each device is a network hop kinder to itself than the other is, so a
     * move carries both readings and each is taken downwards. Without it the
     * two screens disagree, and one player can be out of time on the other's
     * while still thinking on their own.
     */
    @Test
    fun `A move's reading of your own clock is taken, downwards only`() {
        val pair = makePair()
        pair.begin()
        assertTrue(pair.host.play("e2", "e4"))

        fun answer(yours: Double): String =
            MatchPacket.MovePacket(uci = "e7e5", ply = 2, remaining = 280.0, yours = yours).toJson()

        // Their reading of the host's clock is lower than the host's own, which
        // is what a slow link looks like from the other end.
        pair.host.receive(answer(yours = 120.0))
        val now = nowSeconds()
        assertEquals(listOf("e4", "e5"), pair.host.moves)
        assertTrue(pair.host.clock.remaining(PieceColorKey.WHITE, at = now) <= 120.5)
        assertTrue(pair.host.clock.remaining(PieceColorKey.BLACK, at = now) <= 280.0)

        // And a reading that is higher is not taken: a modified build does not
        // get to hand itself time.
        val before = pair.host.clock.remaining(PieceColorKey.WHITE, at = now)
        pair.host.receive(MatchPacket.MovePacket(uci = "g8f6", ply = 4, remaining = 270.0, yours = 999.0).toJson())
        assertTrue(pair.host.clock.remaining(PieceColorKey.WHITE, at = now) <= before)
    }

    @Test
    fun `Resigning loses for the sender and wins for the receiver`() {
        val pair = makePair()
        pair.begin()
        pair.host.resign()

        assertEquals(finished(Outcome.LOSS, Reason.RESIGNATION), pair.host.phase)
        assertEquals(finished(Outcome.WIN, Reason.RESIGNATION), pair.guest.phase)
    }

    @Test
    fun `A draw is agreed only when the offer is accepted`() {
        val pair = makePair()
        pair.begin()

        pair.host.offerDraw()
        assertTrue(pair.guest.drawOffered)

        pair.guest.respondToDraw(accept = false)
        assertFalse(pair.guest.drawOffered)
        assertEquals(Phase.Playing, pair.host.phase)

        pair.host.offerDraw()
        pair.guest.respondToDraw(accept = true)
        assertEquals(finished(Outcome.DRAW, Reason.AGREEMENT), pair.host.phase)
        assertEquals(finished(Outcome.DRAW, Reason.AGREEMENT), pair.guest.phase)
    }

    @Test
    fun `Your own flag ends the game at once, the opponent's waits a moment`() {
        val pair = makePair(timeControl = TimeControl.THREE)
        pair.begin()
        val later = nowSeconds() + TimeControl.THREE.seconds + 1

        // The guest can see the host is out of time, but not yet: their move
        // may be on the wire, and this device's reading of their clock is the
        // lower of the two. See `A flag the other device never reports is
        // claimed here` for the other end of this — the grace runs out and
        // the claim is made.
        pair.guest.tick(now = later)
        assertEquals(Phase.Playing, pair.guest.phase)

        // The owner of the clock has no such doubt.
        pair.host.tick(now = later)
        assertEquals(finished(Outcome.LOSS, Reason.TIMEOUT), pair.host.phase)
        assertEquals(finished(Outcome.WIN, Reason.TIMEOUT), pair.guest.phase)
    }

    @Test
    fun `A packet from a peer that lies is dropped, not played`() {
        val pair = makePair()
        pair.begin()
        pair.host.play("e2", "e4")

        // A rook teleporting off its starting square, with the right ply.
        val lie = MatchPacket.MovePacket(uci = "a8a5", ply = 2, remaining = 100.0)
        pair.host.receive(lie.toJson())

        assertEquals(listOf("e4"), pair.host.moves)
        assertEquals(Piece(PieceColor.BLACK, PieceKind.ROOK), pair.host.position[square("a8")])
    }

    @Test
    fun `A packet that is not one is dropped without a word`() {
        val pair = makePair()
        pair.begin()
        for (noise in listOf("", "hello", "{", "[]", """{"teleport":{}}""", """{"move":{"_0":{"uci":"e7e5"}}}""")) {
            pair.guest.receive(noise)
        }
        assertEquals(Phase.Playing, pair.guest.phase)
        assertTrue(pair.guest.moves.isEmpty())
    }

    @Test
    fun `A move replayed after a retry is not played twice`() {
        val pair = makePair()
        pair.begin()
        pair.host.play("e2", "e4")
        pair.guest.play("e7", "e5")

        val repeated = MatchPacket.MovePacket(uci = "e7e5", ply = 2, remaining = 100.0)
        pair.host.receive(repeated.toJson())

        assertEquals(listOf("e4", "e5"), pair.host.moves)
    }

    @Test
    fun `The opponent's clock is trusted downwards only`() {
        val pair = makePair(timeControl = TimeControl.THREE)
        pair.begin()
        pair.host.play("e2", "e4")

        val generous = MatchPacket.MovePacket(uci = "e7e5", ply = 2, remaining = 9_999.0)
        pair.host.receive(generous.toJson())

        assertEquals(listOf("e4", "e5"), pair.host.moves)
        assertTrue(pair.host.clock.remaining(PieceColorKey.BLACK) <= TimeControl.THREE.seconds)
    }

    @Test
    fun `The rating moves by Glicko, once, from the two records`() {
        val pair = makePair()
        pair.begin()
        pair.host.resign()

        // Two new players: wide deviations, so the first result moves a lot.
        val settled = assertNotNull(pair.guest.settle(OnlineRecord.new, against = OnlineRecord.new))
        assertEquals(162, settled.result.ratingDelta)
        assertEquals(1362, settled.record.rating)
        assertEquals(1, settled.record.games)
        assertTrue(abs(settled.record.deviation - 290.2) < 0.1, "and the rating is surer for it")
        assertEquals(Phase.Finished(settled.result), pair.guest.phase, "and the result on show carries the change")
        assertNull(pair.guest.settle(settled.record, against = OnlineRecord.new), "once")
    }

    @Test
    fun `Nothing is scored before the game is over`() {
        val pair = makePair()
        pair.begin()
        assertNull(pair.host.settle(OnlineRecord.new, against = OnlineRecord.new))
        assertNull(pair.host.applyServerResult(ratingDelta = 10, deviation = 200.0))
        assertEquals(Phase.Playing, pair.host.phase)
    }

    /** Not in the Swift suite: on Android the server referees, and says what the game did to the rating. */
    @Test
    fun `The server's word for the rating goes on the finished result`() {
        val pair = makePair()
        pair.begin()
        pair.host.resign()

        val result = assertNotNull(pair.guest.applyServerResult(ratingDelta = 14, deviation = 187.5))
        assertEquals(MatchResult(Outcome.WIN, Reason.RESIGNATION, ratingDelta = 14, deviation = 187.5), result)
        assertEquals(Phase.Finished(result), pair.guest.phase)
        assertNull(pair.guest.settle(OnlineRecord.new, against = OnlineRecord.new), "the game has been scored")
        assertEquals(Phase.Finished(result), pair.guest.phase)

        // And it is the server's word that stands, over this device's own sum.
        assertEquals(-162, pair.host.settle(OnlineRecord.new, against = OnlineRecord.new)?.result?.ratingDelta)
        val corrected = assertNotNull(pair.host.applyServerResult(ratingDelta = -12, deviation = null))
        assertEquals(MatchResult(Outcome.LOSS, Reason.RESIGNATION, ratingDelta = -12, deviation = null), corrected)
        assertEquals(Phase.Finished(corrected), pair.host.phase)
    }

    @Test
    fun `Another game, when both want one, swaps the colours and starts again`() {
        val pair = makePair()
        pair.begin(hostPlaysWhite = true)
        pair.host.resign()
        assertEquals(162, pair.guest.settle(OnlineRecord.new, against = OnlineRecord.new)?.result?.ratingDelta)

        // The winner asks, with the rating the game left.
        pair.guest.offerRematch(MatchPacket.Hello(playerID = "B", name = "Bo", rating = 1362, games = 1, deviation = 290.0))
        assertTrue(pair.guest.rematchOfferSent)
        assertTrue(pair.host.rematchOffered)

        pair.host.respondToRematch(accept = true)
        assertEquals(Phase.Playing, pair.host.phase)
        assertEquals(Phase.Playing, pair.guest.phase)
        assertEquals(PieceColor.BLACK, pair.host.myColor)
        assertEquals(PieceColor.WHITE, pair.guest.myColor)
        assertTrue(pair.host.gameNumber == 2 && pair.guest.gameNumber == 2)
        assertEquals(1362, pair.host.opponent?.rating, "the new game is scored against the new rating")
        assertTrue(pair.host.moves.isEmpty() && !pair.guest.rematchOfferSent && !pair.host.rematchOffered)

        // And it is a game: White moves first, on both boards.
        assertTrue(pair.guest.play("e2", "e4"))
        assertEquals(listOf("e4"), pair.host.moves)

        // A new game is scored anew.
        pair.guest.resign()
        assertNotNull(pair.host.settle(OnlineRecord.new, against = OnlineRecord.new))
    }

    @Test
    fun `Asking for another game at the same moment is a yes from both`() {
        val pair = makePair()
        pair.begin(hostPlaysWhite = false)
        pair.host.resign()
        // Each asks before hearing the other: the packets cross.
        pair.hostTransport.dropped = true
        pair.host.offerRematch()
        pair.hostTransport.dropped = false
        pair.guest.offerRematch()             // reaches the host, who had asked
        assertEquals(Phase.Playing, pair.host.phase)
        assertEquals(Phase.Playing, pair.guest.phase)
        assertTrue(pair.host.myColor == PieceColor.WHITE && pair.guest.myColor == PieceColor.BLACK)
        assertTrue(pair.host.gameNumber == 2 && pair.guest.gameNumber == 2)
    }

    @Test
    fun `A declined rematch, and an opponent who has left, end the asking`() {
        val pair = makePair()
        pair.begin()
        pair.guest.resign()
        pair.host.offerRematch()
        pair.guest.respondToRematch(accept = false)
        assertTrue(pair.host.rematchDeclined)
        assertFalse(pair.host.rematchOfferSent)
        assertIs<Phase.Finished>(pair.host.phase, "no new game was started")

        pair.guest.leave()
        assertTrue(pair.host.opponentLeft)
        pair.host.offerRematch()
        assertFalse(pair.host.rematchOfferSent, "nobody is there to ask")
    }

    @Test
    fun `Saying goodbye in the middle of a game loses it`() {
        val pair = makePair()
        pair.begin()
        pair.guest.leave()
        assertEquals(finished(Outcome.WIN, Reason.DISCONNECTED), pair.host.phase)
    }

    // MARK: - What counts for the rating

    @Test
    fun `A game from the open search counts, an invitation's and a rematch's do not`() {
        val open = makePair()
        open.begin()
        assertTrue(open.host.unratedByMatch == null && open.guest.unratedByMatch == null)
        open.host.resign()
        open.guest.offerRematch()
        open.host.respondToRematch(accept = true)
        assertEquals(2, open.host.gameNumber)
        assertTrue(open.host.unratedByMatch == UnratedReason.REMATCH && open.guest.unratedByMatch == UnratedReason.REMATCH)

        val invited = makePair(openPool = false)
        invited.begin()
        assertTrue(invited.host.unratedByMatch == UnratedReason.INVITATION && invited.guest.unratedByMatch == UnratedReason.INVITATION)
    }

    // `One rated game a day against the same opponent` is a test of
    // `TrainingProgress`, the iPhone's own file of ratings, which is not part
    // of this module.

    // MARK: - Glicko

    @Test
    fun `Beating somebody far below earns nothing, and drawing with them costs`() {
        fun after(rating: Int, against: Int, score: Double): Int =
            Glicko.updated(rating = rating, deviation = 50.0, against = against, opponentDeviation = 50.0, score = score).rating
        assertEquals(2000, after(2000, against = 1200, score = 1.0), "eight hundred points below: nothing")
        assertEquals(1802, after(1800, against = 1500, score = 1.0), "three hundred below: a little")
        assertEquals(1507, after(1500, against = 1500, score = 1.0), "an equal: the usual")
        assertEquals(1514, after(1500, against = 2300, score = 1.0), "far above: the most")
        assertEquals(1795, after(1800, against = 1500, score = 0.5), "a draw with somebody below loses points")
        assertEquals(1500, after(1500, against = 1500, score = 0.5))
        assertEquals(1505, after(1500, against = 1800, score = 0.5), "and gains them against somebody above")
    }

    @Test
    fun `No ceiling, a floor at a hundred`() {
        assertEquals(3007, Glicko.updated(rating = 3000, deviation = 50.0, against = 3000, opponentDeviation = 50.0, score = 1.0).rating)
        assertTrue(Glicko.updated(rating = 4100, deviation = 50.0, against = 4100, opponentDeviation = 50.0, score = 1.0).rating > 4100)
        assertEquals(Glicko.floor, Glicko.updated(rating = 105, deviation = 200.0, against = 110, opponentDeviation = 50.0, score = 0.0).rating)
        assertEquals(3008, Elo.updated(rating = 3000, games = 200, against = 3000, score = 1.0), "the training ratings have no ceiling either")
    }

    /** The half of the Swift test that is about Glicko; the other half is about `TrainingProgress`. */
    @Test
    fun `A rating grows surer with games and less sure without them`() {
        assertEquals(Glicko.newDeviation, Glicko.deviation(games = 0))
        assertEquals(Glicko.settledDeviation, Glicko.deviation(games = 500))
        assertEquals(50.0, Glicko.deviation(50.0, idle = 0.0))
        assertTrue(Glicko.deviation(50.0, idle = 30 * 86_400.0) > 100, "a month away")
        assertEquals(Glicko.newDeviation, Glicko.deviation(50.0, idle = 400 * 86_400.0), "a year away, and never wider than new")
    }

    @Test
    fun `Both sides keep the moves as UCI, and a rematch starts them again`() {
        val pair = makePair()
        pair.begin(hostPlaysWhite = true)
        assertTrue(pair.host.play("e2", "e4"))
        assertTrue(pair.guest.play("e7", "e5"))
        assertTrue(pair.host.uciMoves == listOf("e2e4", "e7e5") && pair.guest.uciMoves == listOf("e2e4", "e7e5"))
        pair.host.resign()
        pair.guest.offerRematch()
        pair.host.respondToRematch(accept = true)
        assertTrue(pair.host.uciMoves.isEmpty())
    }

    // MARK: - The record

    @Test
    fun `A record goes into a leaderboard entry's context and comes back`() {
        val day = 20_000 * 86_400.0
        val record = OnlineRecord(rating = 1834, deviation = 72.4, games = 131, lastPlayed = day)
        val back = OnlineRecord(score = record.rating, context = record.context)
        assertTrue(back.rating == 1834 && back.games == 131 && back.deviation == 72.0 && back.lastPlayed == day)
        assertTrue(record.context > 0)
        assertEquals((20_000L shl 32) or (131L shl 10) or 72L, record.context)

        // Written before the context carried anything: a rating of unknown certainty.
        val old = OnlineRecord(score = 1500, context = 0)
        assertTrue(old.rating == 1500 && old.deviation == Glicko.newDeviation && old.games == 0 && old.lastPlayed == null)
        assertEquals(Glicko.floor, OnlineRecord(score = 0, context = 0).rating)
        // A rating far past anything real still fits.
        val huge = OnlineRecord(rating = 4200, deviation = 350.0, games = 5_000_000, lastPlayed = day)
        assertEquals((1 shl 22) - 1, OnlineRecord(score = huge.rating, context = huge.context).games)
    }

    @Test
    fun `A record's deviation widens with the days since its last game`() {
        val day = 20_000 * 86_400.0
        val record = OnlineRecord(rating = 1800, deviation = 50.0, games = 200, lastPlayed = day)
        assertEquals(50.0, record.deviation(at = day))
        assertTrue(record.deviation(at = day + 60 * 86_400.0) > 100)
        val after = record.after(1.0, against = OnlineRecord(rating = 1000, deviation = 50.0, games = 200, lastPlayed = day), at = day)
        assertTrue(after.rating == 1800 && after.games == 201 && after.lastPlayed == day, "far below: nothing, but a game played")
    }

    @Test
    fun `The opponent is scored as they said hello when there is nothing better`() {
        val pair = makePair()
        assertEquals(OnlineRecord.new, pair.host.opponentAsTheySaid, "nobody has said hello yet")
        pair.begin()
        assertEquals(OnlineRecord(rating = 1200, deviation = 350.0, games = 0, lastPlayed = null), pair.host.opponentAsTheySaid)

        // A build from before Glicko says no deviation, and is given one from its game count.
        val veteran = MatchPacket.Hello(playerID = "C", name = "Cy", rating = 1700, games = 500)
        assertEquals(Glicko.settledDeviation, veteran.ratingDeviation)
        assertEquals(120.0, veteran.copy(deviation = 120.0).ratingDeviation)
    }

    // MARK: - Draws by the rules

    @Test
    fun `A position repeated three times is a draw on both boards`() {
        val pair = makePair()
        pair.begin()
        // The knights go out and come home twice: the starting position, three times.
        repeat(2) {
            pair.host.play("g1", "f3")
            pair.guest.play("g8", "f6")
            pair.host.play("f3", "g1")
            pair.guest.play("f6", "g8")
        }
        assertEquals(finished(Outcome.DRAW, Reason.REPETITION), pair.host.phase)
        assertEquals(finished(Outcome.DRAW, Reason.REPETITION), pair.guest.phase)
        assertEquals("Drawn by repetition", (pair.host.phase as Phase.Finished).result.headline)
    }

    // MARK: - Observation

    /** What stands in for `@Observable`: the screen is told once per change, when the change is whole. */
    @Test
    fun `A change is reported once, when it is complete`() {
        val pair = makePair()
        var hostChanges = 0
        var guestChanges = 0
        var guestSawItsTurn = false
        pair.host.onChange = { hostChanges += 1 }
        pair.guest.onChange = {
            guestChanges += 1
            guestSawItsTurn = pair.guest.isMyTurn
        }

        pair.begin()
        assertTrue(hostChanges > 0 && guestChanges > 0)

        hostChanges = 0
        guestChanges = 0
        assertTrue(pair.host.play("e2", "e4"))
        assertEquals(1, hostChanges)
        assertEquals(1, guestChanges)
        assertTrue(guestSawItsTurn, "the position, the move list and the turn arrive together")

        // Nothing changed, nothing said.
        hostChanges = 0
        assertFalse(pair.host.play("e2", "e4"))
        pair.host.tick()
        assertEquals(0, hostChanges)

        // A whole exchange — the offer, the answer, the new game — is one change to each side.
        pair.host.resign()
        hostChanges = 0
        guestChanges = 0
        pair.guest.offerRematch()
        assertEquals(1, hostChanges)
        assertEquals(1, guestChanges)
        pair.host.respondToRematch(accept = true)
        assertEquals(Phase.Playing, pair.guest.phase)
        assertEquals(2, hostChanges)
        assertEquals(2, guestChanges)

        pair.guest.resign()
        hostChanges = 0
        pair.host.applyServerResult(ratingDelta = 9, deviation = 180.0)
        assertEquals(1, hostChanges)
    }
}
