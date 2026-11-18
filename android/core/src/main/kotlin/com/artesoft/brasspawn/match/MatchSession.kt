package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.chess.PieceKind
import com.artesoft.brasspawn.chess.Position
import com.artesoft.brasspawn.chess.Square
import kotlin.random.Random
import kotlin.reflect.KProperty

/**
 * Where a match's packets go. The connection to the server provides one of
 * these; the tests provide another that hands packets straight to a second
 * session, which is what lets a whole game be played — moves, clock,
 * resignation, rating — without two devices and two accounts.
 *
 * The data is a packet as JSON text: see `MatchPacket.toJson`.
 */
fun interface MatchTransport {
    fun send(data: String)
}

/**
 * One online game.
 *
 * Both devices run this, and both run the rules. Nothing arriving over the
 * wire is taken on trust: a move is played only if it is legal in the position
 * this device already has, so a peer that lies produces a dropped packet
 * rather than an illegal board.
 *
 * Not safe to share between threads — the Swift class is confined to the main
 * actor, and this one expects the same: make every call, [receive] and [tick]
 * included, from one thread.
 *
 * The session holds its transport strongly. The Swift one holds it weakly, to
 * break a reference cycle that the JVM's collector does not mind — and a weak
 * reference to a transport written as a lambda would be a transport that
 * vanishes at the next collection.
 */
class MatchSession(
    private val transport: MatchTransport,
    me: MatchPacket.Hello,
    val isHost: Boolean,
    val timeControl: TimeControl,
    /**
     * Whether the two were paired by the open search, among everybody on the
     * clock. A match from an invitation is not: two people who chose each
     * other could be one person with two accounts.
     */
    val openPool: Boolean = true,
) {
    sealed interface Phase {
        /** Connected, waiting for the host to deal colours. */
        data object Waiting : Phase

        data object Playing : Phase

        data class Finished(val result: MatchResult) : Phase
    }

    /** The square a move left and the one it arrived on, for marking on the board. */
    data class LastMove(val from: Square, val to: Square)

    /** What [settle] hands back: the result with its change in rating, and the record after it. */
    data class Settled(val result: MatchResult, val record: OnlineRecord)

    // MARK: - Observation

    /**
     * Called after every change to anything this session shows: once per call
     * into the session, when that call has finished and left something
     * different — not once per property, and not in the middle of a move. It
     * stands where `@Observable` stands in the Swift class; the app wraps it
     * in whatever its screens observe.
     */
    var onChange: (() -> Unit)? = null

    private var changed = false
    private var depth = 0

    /** A property the screen reads. Writing a different value to it is a change to report. */
    private inner class Observed<T>(private var value: T) {
        operator fun getValue(thisRef: Any?, property: KProperty<*>): T = value

        operator fun setValue(thisRef: Any?, property: KProperty<*>, value: T) {
            if (this.value != value) {
                this.value = value
                changed = true
            }
        }
    }

    /**
     * Runs one call into the session, and reports afterwards if it changed
     * anything. Calls nest — a packet sent can be answered before `send`
     * returns — and only the outermost reports, so the listener never sees a
     * move half applied.
     */
    private inline fun <T> change(block: () -> T): T {
        depth += 1
        try {
            return block()
        } finally {
            depth -= 1
            if (depth == 0 && changed) {
                changed = false
                onChange?.invoke()
            }
        }
    }

    // MARK: - State

    var phase: Phase by Observed<Phase>(Phase.Waiting)
        private set
    var position: Position by Observed(Position.start)
        private set
    var legalDestinations: Map<Square, List<Square>> by Observed(emptyMap())
        private set
    var lastMove: LastMove? by Observed<LastMove?>(null)
        private set
    var myColor: PieceColor by Observed(PieceColor.WHITE)
        private set
    var clock: ChessClock by Observed(ChessClock(timeControl))
        private set

    /** SAN, for the move list. */
    var moves: List<String> by Observed(emptyList())
        private set

    /**
     * The same moves as UCI: how many were played is what says whether a
     * game was played at all.
     */
    var uciMoves: List<String> by Observed(emptyList())
        private set
    var opponent: MatchPacket.Hello? by Observed<MatchPacket.Hello?>(null)
        private set

    /** True while the opponent's draw offer is on the table. */
    var drawOffered: Boolean by Observed(false)
        private set
    var drawOfferSent: Boolean by Observed(false)
        private set

    /** After a game: the opponent asks for another. */
    var rematchOffered: Boolean by Observed(false)
        private set

    /** After a game: this side has asked for another, and waits for the answer. */
    var rematchOfferSent: Boolean by Observed(false)
        private set

    /** The opponent said no to another game. */
    var rematchDeclined: Boolean by Observed(false)
        private set

    /** The opponent has left the match: nothing more can be asked of them. */
    var opponentLeft: Boolean by Observed(false)
        private set

    /** Which game of the match this is — 1, and one more for every rematch. */
    var gameNumber: Int by Observed(1)
        private set

    /**
     * Why this game does not count for the rating, if it does not: the two
     * chose each other, or it is a rematch — the same two again, by choice.
     * A game against the same opponent twice in one day is the app's to
     * decide, because it is the app that remembers.
     */
    val unratedByMatch: UnratedReason?
        get() {
            if (!openPool) return UnratedReason.INVITATION
            if (gameNumber > 1) return UnratedReason.REMATCH
            return null
        }

    /**
     * Who this side is, as the opponent is told — with the rating the last
     * game left, once there has been one. See `offerRematch`.
     */
    var me: MatchPacket.Hello by Observed(me)
        private set

    private var ply = 0

    /**
     * Set once `begin` has been called, so a hello that arrives before this
     * device is ready does not start a game it has not been asked for yet.
     */
    private var hasBegun = false
    private var whiteIsHost: Boolean? = null
    private var lastHello: Double? = null

    /** When the opponent's clock first read zero here. See `tick`. */
    private var opponentFlaggedSince: Double? = null

    /** The game `settle` has already scored. */
    private var settledGame: Int? = null

    val isMyTurn: Boolean
        get() = phase == Phase.Playing && position.sideToMove == myColor

    val myClockKey: ChessClock.PieceColorKey get() = key(myColor)
    val opponentClockKey: ChessClock.PieceColorKey get() = key(myColor.opponent)

    /**
     * Say hello, and — if this device is the host — deal the colours.
     *
     * The host decides because two devices choosing at random would disagree
     * half the time. It decides *randomly* so that being the host, which comes
     * down to which player ID sorts first, is not worth a colour.
     */
    fun begin(whiteIsHost: Boolean? = null): Unit = change {
        this.whiteIsHost = whiteIsHost
        hasBegun = true
        send(me)
        dealColours()
    }

    /**
     * Deal the colours, once there is somebody to deal them to.
     *
     * The host used to do this in `begin`, the instant Game Center handed back
     * a match. That is too early. The two devices do not finish connecting at
     * the same moment, and a packet sent before the other end has a session to
     * hand it to is dropped — it is not queued and it is never asked for
     * again. The guest then sat on "Connecting…" waiting for a start that had
     * already been spent, which is a game that never begins and never fails
     * either.
     *
     * So the deal waits for the guest's own hello, which is the one piece of
     * evidence that there is a session at the other end listening. Called from
     * both ends of that — `begin` and the arrival of a hello — because either
     * may be the one that happens last.
     */
    private fun dealColours() {
        if (!isHost || !hasBegun || opponent == null || phase != Phase.Waiting) return
        val hostPlaysWhite = whiteIsHost ?: Random.nextBoolean()
        myColor = if (hostPlaysWhite) PieceColor.WHITE else PieceColor.BLACK
        // Ours again with it: if the hello this device sent was the one that
        // was dropped, this is the copy the guest shows in the player row.
        send(me)
        send(
            MatchPacket.Start(
                youPlay = if (hostPlaysWhite) PieceColor.BLACK else PieceColor.WHITE,
                timeControl = timeControl,
            )
        )
        startPlaying()
    }

    /** A packet from the other side, as the JSON text it arrived as. One that cannot be read is dropped. */
    fun receive(data: String): Unit = change {
        val packet = MatchPacket.fromJson(data) ?: return@change
        when (packet) {
            is MatchPacket.Hello -> {
                opponent = packet
                dealColours()
            }

            is MatchPacket.Start -> {
                // Only the guest is told what to play, and only once.
                if (isHost || phase != Phase.Waiting) return@change
                myColor = packet.receiverColor
                startPlaying()
            }

            is MatchPacket.MovePacket -> applyRemote(packet)

            MatchPacket.Resign ->
                finish(MatchResult(MatchResult.Outcome.WIN, MatchResult.Reason.RESIGNATION))

            MatchPacket.DrawOffer -> {
                if (phase != Phase.Playing) return@change
                drawOffered = true
            }

            is MatchPacket.DrawResponse -> {
                drawOfferSent = false
                if (packet.accepted) finish(MatchResult(MatchResult.Outcome.DRAW, MatchResult.Reason.AGREEMENT))
            }

            is MatchPacket.GameOver ->
                // The other device saw the end first. Believe it only about things
                // it is entitled to declare: its own flag, or a result this device
                // can confirm from its own board.
                accept(packet)

            MatchPacket.RematchOffer -> {
                if (phase !is Phase.Finished || opponentLeft) return@change
                if (rematchOfferSent) {
                    // Both asked at once, each before hearing the other: that is
                    // a yes from both, and both start the next game.
                    rematchOfferSent = false
                    send(MatchPacket.RematchResponse(accepted = true))
                    restart()
                } else {
                    rematchOffered = true
                    rematchDeclined = false
                }
            }

            is MatchPacket.RematchResponse -> {
                if (!rematchOfferSent || phase !is Phase.Finished) return@change
                rematchOfferSent = false
                if (packet.accepted) restart() else rematchDeclined = true
            }

            MatchPacket.Goodbye -> opponentDisconnected()
        }
    }

    // MARK: - Playing

    fun play(from: Square, to: Square, promotion: PieceKind?): Boolean = change {
        if (!isMyTurn) return@change false
        val notation = Move(from, to, promotion)
        val move = position.legalMove(notation) ?: return@change false

        apply(move)
        send(
            MatchPacket.MovePacket(
                uci = move.uci, ply = ply,
                remaining = clock.remaining(myClockKey),
                yours = clock.remaining(opponentClockKey),
            )
        )
        checkGameOverAfterMove(justMovedBy = myColor)
        true
    }

    fun resign(): Unit = change {
        if (phase != Phase.Playing) return@change
        send(MatchPacket.Resign)
        finish(MatchResult(MatchResult.Outcome.LOSS, MatchResult.Reason.RESIGNATION))
    }

    fun offerDraw(): Unit = change {
        if (phase != Phase.Playing || drawOfferSent) return@change
        drawOfferSent = true
        send(MatchPacket.DrawOffer)
    }

    fun respondToDraw(accept: Boolean): Unit = change {
        if (!drawOffered) return@change
        drawOffered = false
        send(MatchPacket.DrawResponse(accepted = accept))
        if (accept) finish(MatchResult(MatchResult.Outcome.DRAW, MatchResult.Reason.AGREEMENT))
    }

    // MARK: - Another game

    /**
     * Ask for another game: same clock, colours swapped. `updated` is this
     * side as it now stands — its rating after the game just played — so the
     * opponent's player row, and the rating the next game is scored against,
     * are this game's and not the last one's.
     */
    fun offerRematch(updated: MatchPacket.Hello? = null): Unit = change {
        if (phase !is Phase.Finished || opponentLeft || rematchOfferSent) return@change
        if (updated != null) me = updated
        // Asked already: asking back is saying yes.
        if (rematchOffered) {
            respondToRematch(accept = true)
            return@change
        }
        rematchOfferSent = true
        rematchDeclined = false
        send(MatchPacket.RematchOffer)
    }

    fun respondToRematch(accept: Boolean, updated: MatchPacket.Hello? = null): Unit = change {
        if (!rematchOffered || phase !is Phase.Finished) return@change
        if (updated != null) me = updated
        rematchOffered = false
        send(MatchPacket.RematchResponse(accepted = accept))
        if (accept) restart()
    }

    /** Leaving: say so, so the other side is not left waiting on an answer. */
    fun leave() {
        send(MatchPacket.Goodbye)
    }

    /**
     * Called on a display timer: the clocks are read here, and a game that
     * has run out of time is ended here.
     *
     * Both flags, not just this device's own. Claiming only your own reads
     * well — the device whose clock ran out is the one that knows it — but it
     * assumes that device is awake to say so, and a phone whose screen has
     * locked or an app in the background is not. The game then carried on
     * past zero with the clock showing nothing left, and was decided by
     * whatever happened next instead.
     *
     * The opponent's flag waits out `flagGrace` first. This device's reading
     * of their clock is the lower of the two by design, and their move may be
     * on the wire as it runs out; a few seconds of doubt costs nothing and
     * turns a slow network into a lost second rather than a lost game.
     */
    fun tick(now: Double = nowSeconds()): Unit = change {
        // Still waiting: say hello again. The first one can be spent before
        // the other device has a session to receive it, and one lost packet
        // would otherwise cost the whole game — both ends sitting on
        // "Connecting…", each waiting for the other to speak first. A few
        // bytes a second until somebody answers is the cheap way out.
        if (phase == Phase.Waiting) {
            val last = lastHello
            if (last != null && now - last < 1) return@change
            lastHello = now
            send(me)
            return@change
        }
        if (phase != Phase.Playing || !clock.isRunning) return@change

        if (clock.hasFlagged(myClockKey, now)) {
            send(MatchPacket.GameOver(winner = myColor.opponent, reason = MatchResult.Reason.TIMEOUT))
            finish(MatchResult(MatchResult.Outcome.LOSS, MatchResult.Reason.TIMEOUT))
            return@change
        }

        if (!clock.hasFlagged(opponentClockKey, now)) {
            opponentFlaggedSince = null
            return@change
        }
        val since = opponentFlaggedSince ?: now
        opponentFlaggedSince = since
        if (now - since < flagGrace) return@change
        send(MatchPacket.GameOver(winner = myColor, reason = MatchResult.Reason.TIMEOUT))
        finish(MatchResult(MatchResult.Outcome.WIN, MatchResult.Reason.TIMEOUT))
    }

    /** The opponent left and did not come back — or said goodbye. */
    fun opponentDisconnected(): Unit = change {
        opponentLeft = true
        rematchOffered = false
        rematchOfferSent = false
        if (phase != Phase.Playing) return@change
        finish(MatchResult(MatchResult.Outcome.WIN, MatchResult.Reason.DISCONNECTED))
    }

    /**
     * Score the finished game — once — from the two players' records as they
     * stood when it began, and hand back the result, with the change in
     * rating, and this player's record after it.
     */
    fun settle(mine: OnlineRecord, against: OnlineRecord, at: Double = nowSeconds()): Settled? = change {
        val finished = phase as? Phase.Finished ?: return@change null
        if (settledGame == gameNumber) return@change null
        settledGame = gameNumber
        val record = mine.after(finished.result.score, against, at)
        val result = finished.result.copy(
            ratingDelta = record.rating - mine.rating,
            deviation = record.deviation,
        )
        phase = Phase.Finished(result)
        Settled(result, record)
    }

    /**
     * Take the server's word for what the finished game did to the rating.
     *
     * Not in the Swift class, where each device scores its own game: here the
     * server referees, and reports the change. This puts the change and the
     * new deviation on the finished result — what `settle` does to `phase`,
     * without working anything out — and hands the result back, or null when
     * there is no finished game to put them on.
     *
     * The game then counts as scored, so a `settle` that comes after it does
     * nothing; and the server's word replaces a `settle` that came before it,
     * and an earlier word of its own.
     */
    fun applyServerResult(ratingDelta: Int, deviation: Double?): MatchResult? = change {
        val finished = phase as? Phase.Finished ?: return@change null
        settledGame = gameNumber
        val result = finished.result.copy(ratingDelta = ratingDelta, deviation = deviation)
        phase = Phase.Finished(result)
        result
    }

    /**
     * The opponent as they said hello: what to score against when the record
     * that counts cannot be asked for.
     */
    val opponentAsTheySaid: OnlineRecord
        get() {
            val opponent = opponent ?: return OnlineRecord.new
            return OnlineRecord(
                rating = opponent.rating, deviation = opponent.ratingDeviation,
                games = opponent.games, lastPlayed = null,
            )
        }

    // MARK: - Internals

    /**
     * The next game of the match: the colours swap, everything else starts
     * again. Both sides swap their own colour, so they cannot disagree.
     */
    private fun restart() {
        myColor = myColor.opponent
        gameNumber += 1
        rematchOffered = false
        rematchOfferSent = false
        rematchDeclined = false
        opponentFlaggedSince = null
        // Who this side is now, rating and all, before the first move.
        send(me)
        startPlaying()
    }

    private fun startPlaying() {
        position = Position.start
        ply = 0
        moves = emptyList()
        uciMoves = emptyList()
        lastMove = null
        clock = ChessClock(timeControl).start()
        phase = Phase.Playing
        refreshDestinations()
    }

    private fun apply(move: Move) {
        val san = position.san(move)
        position = position.make(move)
        moves = moves + san
        uciMoves = uciMoves + move.uci
        lastMove = LastMove(from = move.from, to = move.to)
        ply += 1
        clock = clock.press()
        drawOffered = false
        refreshDestinations()
    }

    private fun applyRemote(packet: MatchPacket.MovePacket) {
        if (phase != Phase.Playing || position.sideToMove == myColor) return
        // A move for a ply that has already been played is a duplicate from a
        // retry, not a second move.
        if (packet.ply != ply + 1) return
        val parsed = Move.fromUci(packet.uci) ?: return
        val move = position.legalMove(parsed) ?: return

        apply(move)
        clock = clock.adopt(packet.remaining, opponentClockKey)
        // And their reading of mine. Downwards only, like theirs — see
        // `MovePacket.yours` for why both directions are needed.
        if (packet.yours != null) clock = clock.adopt(packet.yours, myClockKey)
        checkGameOverAfterMove(justMovedBy = myColor.opponent)
    }

    private fun checkGameOverAfterMove(justMovedBy: PieceColor) {
        val mover = justMovedBy
        if (phase != Phase.Playing) return
        if (position.isCheckmate) {
            val over = MatchPacket.GameOver(winner = mover, reason = MatchResult.Reason.CHECKMATE)
            if (mover == myColor) send(over)
            finish(
                MatchResult(
                    outcome = if (mover == myColor) MatchResult.Outcome.WIN else MatchResult.Outcome.LOSS,
                    reason = MatchResult.Reason.CHECKMATE,
                )
            )
            return
        }
        if (!position.isDraw) return
        val reason = if (position.isStalemate) {
            MatchResult.Reason.STALEMATE
        } else if (position.isInsufficientMaterial) {
            MatchResult.Reason.INSUFFICIENT_MATERIAL
        } else if (position.isThreefoldRepetition) {
            MatchResult.Reason.REPETITION
        } else {
            MatchResult.Reason.FIFTY_MOVE_RULE
        }
        if (mover == myColor) send(MatchPacket.GameOver(winner = null, reason = reason))
        finish(MatchResult(MatchResult.Outcome.DRAW, reason))
    }

    private fun accept(over: MatchPacket.GameOver) {
        if (phase != Phase.Playing) return
        val winner = over.winnerColor
        val outcome = when (winner) {
            null -> MatchResult.Outcome.DRAW
            myColor -> MatchResult.Outcome.WIN
            else -> MatchResult.Outcome.LOSS
        }
        finish(MatchResult(outcome, over.resultReason))
    }

    private fun finish(result: MatchResult) {
        if (phase != Phase.Playing) return
        clock = clock.stop()
        legalDestinations = emptyMap()
        drawOffered = false
        drawOfferSent = false
        phase = Phase.Finished(result)
    }

    private fun refreshDestinations() {
        if (!isMyTurn) {
            legalDestinations = emptyMap()
            return
        }
        val map = LinkedHashMap<Square, MutableList<Square>>()
        for (move in position.legalMoves()) {
            map.getOrPut(move.from) { ArrayList() }.add(move.to)
        }
        legalDestinations = map
    }

    private fun send(packet: MatchPacket) {
        val data = try {
            packet.toJson()
        } catch (unwritable: IllegalArgumentException) {
            // A clock reading that is not a number: there is nothing to send.
            return
        }
        transport.send(data)
    }

    private companion object {
        /** How long the opponent's flag has to stand before it is claimed. */
        const val flagGrace = 3.0

        fun key(color: PieceColor): ChessClock.PieceColorKey =
            if (color == PieceColor.WHITE) ChessClock.PieceColorKey.WHITE else ChessClock.PieceColorKey.BLACK
    }
}
