package com.artesoft.brasspawn.ui

import android.content.Intent
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.chess.PieceColor
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.match.ChessClock
import com.artesoft.brasspawn.match.L
import com.artesoft.brasspawn.match.MatchResult
import com.artesoft.brasspawn.match.MatchSession
import com.artesoft.brasspawn.match.TimeControl
import com.artesoft.brasspawn.online.FriendInvite
import com.artesoft.brasspawn.online.OnlineModel
import com.artesoft.brasspawn.online.OnlineModel.State

/**
 * Playing a person, on the clock.
 *
 * The one mode with no engine in it. Nothing here suggests a move, grades one,
 * or puts a number on a square: an opponent is on the other end, and help that
 * only one side gets is not a game.
 */
@Composable
fun OnlineScreen(navigator: Navigator) {
    val context = LocalContext.current
    val model = remember { OnlineModel.shared(context) }
    var clock by rememberSaveable { mutableStateOf(TimeControl.FIVE) }
    var people by rememberSaveable { mutableStateOf<PeopleKind?>(null) }
    var leaving by remember { mutableStateOf(false) }

    DisposableEffect(model) {
        model.appear()
        onDispose { model.disappear() }
    }

    val game = model.game
    if (game != null) {
        val playing = game.session.phase == MatchSession.Phase.Playing
        BackHandler { if (playing) leaving = true else model.leaveGame() }
        GameView(model, game, onBack = { if (playing) leaving = true else model.leaveGame() })
        if (leaving) {
            val rated = game.info.open && game.session.gameNumber == 1
            ConfirmDialog(
                title = t("online.leaveTheGame", "Leave the game?"),
                message = if (rated) t("online.leavingAnOnlineGameLoses", "Leaving an online game loses it and costs you rating.")
                else t("online.leavingAFriendlyGame", "Leaving loses the game, but this one is not rated."),
                confirm = t("progress.leave", "Leave"), dismiss = t("progress.stay", "Stay"),
                onConfirm = { leaving = false; model.leaveGame() }, onDismiss = { leaving = false },
            )
        }
        return
    }

    val open = people
    if (open != null) {
        BackHandler { people = null }
        PeopleScreen(model, open, clock, onBack = { people = null })
        return
    }

    Screen(title = t("online.playOnline", "Play online"), onBack = navigator::back) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            when (val state = model.state) {
                State.Idle, State.Connecting -> Panel(Modifier.fillMaxWidth()) {
                    Body(t("online.android.connecting", "Connecting…"), color = Theatre.ivoryDim)
                }
                is State.Offline -> Panel(Modifier.fillMaxWidth()) {
                    Body(t("online.android.offline", "The server cannot be reached. Check the connection and try again."), color = Theatre.ivoryDim)
                    Spacer(Modifier.height(12.dp))
                    ChipButton(t("online.android.retry", "Try again"), primary = true) { model.connect() }
                }
                is State.NeedsNickname -> NicknameCard(model, state.rejected)
                else -> Lobby(model, clock, onClock = { clock = it }, onPeople = { people = it })
            }
        }
    }

    model.notice?.let { code ->
        val message = when (code) {
            "unknown", "invite-unknown" -> t("online.android.codeUnknown", "Nobody is waiting on that code. Ask for a new one.")
            "busy", "in-match" -> t("online.android.busy", "Finish the game under way first.")
            "alias-rejected" -> t("online.android.nicknameRejected", "That nickname cannot be used. Try another.")
            else -> t("online.android.offline", "The server cannot be reached. Check the connection and try again.")
        }
        ConfirmDialog(
            title = t("online.playOnline", "Play online"), message = message,
            confirm = t("common.ok", "OK"), dismiss = t("common.cancel", "Cancel"),
            onConfirm = { model.notice = null }, onDismiss = { model.notice = null },
        )
    }
}

@Composable
private fun NicknameCard(model: OnlineModel, rejected: Boolean) {
    var name by rememberSaveable { mutableStateOf(model.alias) }
    Panel(Modifier.fillMaxWidth()) {
        BasicText(t("online.android.nicknameTitle", "Choose a nickname"), style = LocalFaces.current.display(24))
        Spacer(Modifier.height(6.dp))
        Body(t("online.android.nicknameHint", "3 to 20 characters. It is what other players see on the lists and over the board."), size = 13, color = Theatre.ivoryDim)
        Spacer(Modifier.height(12.dp))
        TextInput(name, { name = it.take(20) }, t("online.android.nicknameField", "Nickname"), Modifier.fillMaxWidth()) {
            if (name.trim().length >= 3) model.chooseNickname(name)
        }
        if (rejected) {
            Spacer(Modifier.height(8.dp))
            Body(t("online.android.nicknameRejected", "That nickname cannot be used. Try another."), size = 13, color = Theatre.bad)
        }
        Spacer(Modifier.height(12.dp))
        ChipButton(t("online.android.continue", "Continue"), primary = true, enabled = name.trim().length >= 3) {
            model.chooseNickname(name)
        }
    }
}

@Composable
private fun ColumnScope.Lobby(model: OnlineModel, clock: TimeControl, onClock: (TimeControl) -> Unit, onPeople: (PeopleKind) -> Unit) {
    val context = LocalContext.current
    val state = model.state
    val idle = state == State.Lobby

    Panel(Modifier.fillMaxWidth()) {
        Body(t("online.android.intro", "A real opponent, on the clock. No hints, no engine, no take-backs."), size = 13, color = Theatre.ivoryDim)
    }

    // Games friends have offered: answered here, wherever in the lobby the player is.
    for (invite in model.friends.invites) InviteBanner(model, invite)

    Panel(Modifier.fillMaxWidth()) {
        Label(t("online.clock", "Clock"))
        Spacer(Modifier.height(8.dp))
        Segmented(TimeControl.entries.map { it.minutes.toString() }, TimeControl.entries.indexOf(clock), Modifier.fillMaxWidth()) {
            if (idle) onClock(TimeControl.entries[it])
        }
        Spacer(Modifier.height(8.dp))
        Body(
            t("online.clockExplanation", "%@ each — %@. You are only paired with players who chose the same clock.", clock.label, clock.displayName.lowercase()),
            size = 13, color = Theatre.ivoryDim,
        )
        val looking = model.onlineNow.values.count { it.first == "looking" && it.second == clock.minutes }
        if (looking > 0) {
            Spacer(Modifier.height(6.dp))
            Body(t("online.lookingNow", "Looking for a %1\$@ game right now: %2\$lld", clock.label, looking), size = 13, color = Theatre.brass)
        }
    }

    Panel(Modifier.fillMaxWidth()) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Body(model.alias, size = 15, style = LocalFaces.current.body(15, weight = FontWeight.SemiBold), maxLines = 1)
                BasicText(model.record(clock).rating.toString(), style = LocalFaces.current.figures(24, Theatre.ivory))
            }
            when (state) {
                is State.Searching -> ChipButton(t("online.searchingTapToCancel", "Searching — tap to cancel"), primary = true) { model.cancelSearch() }
                else -> ChipButton(t("online.findOpponent", "Find opponent"), primary = true, enabled = idle, icon = "play.fill") { model.search(clock) }
            }
        }
        if (state is State.Offering) {
            Spacer(Modifier.height(10.dp))
            ChipButton(t("online.waitingForTapToCancel", "Waiting for %@ — tap to cancel", state.friend.alias), Modifier.fillMaxWidth()) { model.withdrawOffer() }
        }
    }

    Panel(Modifier.fillMaxWidth()) {
        Label(t("online.inviteSomebody", "Invite somebody"))
        Spacer(Modifier.height(6.dp))
        Body(t("online.android.inviteExplanation", "Send the link, or read the code out. Whoever opens it is put straight through to you, on iPhone, iPad, Mac or Android."), size = 13, color = Theatre.ivoryDim)
        Spacer(Modifier.height(10.dp))
        if (state is State.Inviting) {
            BasicText(state.invite.code, style = LocalFaces.current.figures(30, Theatre.brassHot).copy(letterSpacing = androidx.compose.ui.unit.TextUnit(6f, androidx.compose.ui.unit.TextUnitType.Sp)))
            Spacer(Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ChipButton(t("online.sendTheLink", "Send the link"), Modifier.weight(1f), primary = true) {
                    val text = t("online.inviteMessage", "A game of chess, %@ each: %@", clock.label, state.invite.link)
                    val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
                    context.startActivity(Intent.createChooser(send, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
                ChipButton(t("common.cancel", "Cancel"), Modifier.weight(1f)) { model.cancelInvite() }
            }
        } else {
            ChipButton(t("online.invite", "Invite"), enabled = idle, icon = "plus.circle") { model.invite(clock) }
            Spacer(Modifier.height(14.dp))
            Label(t("online.android.joinWithCode", "Have a code?"))
            Spacer(Modifier.height(8.dp))
            var code by rememberSaveable { mutableStateOf("") }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                TextInput(code, { code = it.uppercase().filter(Char::isLetterOrDigit).take(6) }, t("online.android.inviteCode", "Invitation code"), Modifier.weight(1f), capitalize = true) {
                    if (code.length == 6) model.join(code)
                }
                ChipButton(t("online.android.join", "Join"), enabled = idle && code.length == 6) { model.join(code) }
            }
        }
    }

    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        ChipButton(t("online.rankList", "Rank list"), Modifier.weight(1f), icon = "trophy.fill") { onPeople(PeopleKind.RANKS) }
        ChipButton(t("online.friends", "Friends"), Modifier.weight(1f)) { onPeople(PeopleKind.FRIENDS) }
        ChipButton(t("online.players", "Players"), Modifier.weight(1f)) { onPeople(PeopleKind.PLAYERS) }
    }
    Body(
        t("online.friendlyNote", "Invitations and rematches are friendly games, and only one game a day against the same opponent is rated."),
        size = 12, color = Theatre.ivoryFaint,
    )

    // An invitation link opened the app: join as soon as there is a lobby to join from.
    val pending = PendingInvitation.code
    LaunchedEffect(pending, idle) {
        if (pending != null && idle) {
            PendingInvitation.code = null
            model.join(pending)
        }
    }
}

@Composable
private fun InviteBanner(model: OnlineModel, invite: FriendInvite) {
    val clock = TimeControl.fromMinutes(invite.minutes) ?: TimeControl.FIVE
    Panel(Modifier.fillMaxWidth()) {
        Body(t("online.friendInvite", "%1\$@ invites you to a %2\$@ game.", invite.alias, clock.label))
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ChipButton(t("online.accept", "Accept"), Modifier.weight(1f), primary = true) { model.answer(invite, true) }
            ChipButton(t("online.decline", "Decline"), Modifier.weight(1f)) { model.answer(invite, false) }
        }
    }
}

/** An invitation code that arrived in a link, kept until the lobby can use it. */
object PendingInvitation {
    var code by mutableStateOf<String?>(null)
}

// MARK: - The game

@Composable
private fun GameView(model: OnlineModel, game: OnlineModel.Game, onBack: () -> Unit) {
    // Read so that every change to the session redraws this.
    @Suppress("UNUSED_VARIABLE") val revision = game.revision
    val session = game.session
    val opponentName = session.opponent?.name ?: game.info.opponent.alias
    val phase = session.phase
    var resigning by remember { mutableStateOf(false) }

    Screen(title = null, onBack = onBack, trailing = {
        Label(if (session.unratedByMatch == null) t("online.android.rated", "Rated game") else t("online.android.friendly", "Friendly game"), color = Theatre.brass)
    }) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = 14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(Modifier.widthIn(max = 560.dp)) {
                PlayerBar(
                    name = opponentName, rating = session.opponent?.rating ?: game.info.opponent.record.rating,
                    color = session.myColor.opponent, clock = session.clock.remaining(session.opponentClockKey),
                    running = phase == MatchSession.Phase.Playing && !session.isMyTurn,
                )
                Spacer(Modifier.height(8.dp))
                ChessBoard(
                    position = session.position,
                    orientation = session.myColor,
                    legalMoves = if (session.isMyTurn) session.position.legalMoves() else emptyList(),
                    lastMove = session.lastMove?.let { it.from to it.to },
                    modifier = Modifier.fillMaxWidth(),
                    onMove = { move -> session.play(move.from, move.to, move.promotion) },
                )
                Spacer(Modifier.height(8.dp))
                PlayerBar(
                    name = model.alias, rating = model.record(session.timeControl).rating,
                    color = session.myColor, clock = session.clock.remaining(session.myClockKey),
                    running = phase == MatchSession.Phase.Playing && session.isMyTurn,
                )
                Spacer(Modifier.height(12.dp))

                Panel(Modifier.fillMaxWidth()) {
                    when (phase) {
                        MatchSession.Phase.Waiting -> Body(t("online.joining", "Joining %@…", opponentName), color = Theatre.ivoryDim)
                        MatchSession.Phase.Playing -> {
                            BasicText(
                                if (session.isMyTurn) t("play.yourMove", "Your move.")
                                else t("board.toMove", "%@ to move.", L.color(session.position.sideToMove)),
                                style = LocalFaces.current.display(24),
                            )
                            Body(
                                t("online.gameSummary", "%@ · %@ · you are %@", session.timeControl.displayName, session.timeControl.label, L.color(session.myColor).lowercase()),
                                size = 13, color = Theatre.ivoryDim,
                            )
                            if (!game.opponentConnected) {
                                Spacer(Modifier.height(6.dp))
                                Body(t("online.android.opponentAway", "%@ has lost the connection — waiting for them to come back.", opponentName), size = 13, color = Theatre.warn)
                            }
                            if (session.drawOffered) {
                                Spacer(Modifier.height(10.dp))
                                Body(t("online.offersADraw", "%@ offers a draw.", opponentName))
                                Spacer(Modifier.height(8.dp))
                                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                    ChipButton(t("online.accept", "Accept"), Modifier.weight(1f), primary = true) { session.respondToDraw(true) }
                                    ChipButton(t("online.playOn", "Play on"), Modifier.weight(1f)) { session.respondToDraw(false) }
                                }
                            } else if (session.drawOfferSent) {
                                Spacer(Modifier.height(6.dp))
                                Body(t("online.drawOfferedWaitingForAn", "Draw offered — waiting for an answer."), size = 13, color = Theatre.ivoryDim)
                            }
                        }
                        is MatchSession.Phase.Finished -> FinishedCard(model, game, phase.result, opponentName)
                    }
                }

                if (session.moves.isNotEmpty()) {
                    Spacer(Modifier.height(12.dp))
                    Panel(Modifier.fillMaxWidth()) {
                        Label(t("online.moves", "Moves"))
                        Spacer(Modifier.height(6.dp))
                        Body(moveText(session.moves), size = 14, style = LocalFaces.current.figures(13, Theatre.ivoryDim))
                    }
                }
                Spacer(Modifier.height(12.dp))

                when (phase) {
                    MatchSession.Phase.Playing -> ActionBar {
                        ActionButton(t("online.resign", "Resign"), "flag.fill") { resigning = true }
                        ActionButton(t("online.offerDraw", "Offer draw"), "equal.circle", enabled = !session.drawOfferSent && !session.drawOffered) { session.offerDraw() }
                    }
                    is MatchSession.Phase.Finished -> ActionBar {
                        ActionButton(
                            t("online.playAgain", "Play again"), "arrow.clockwise", primary = true,
                            enabled = !session.opponentLeft && !game.closed && !session.rematchOfferSent,
                        ) { session.offerRematch() }
                        ActionButton(t("online.backToTheLobby", "Back to the lobby"), "chevron.left") { model.leaveGame() }
                    }
                    else -> Unit
                }
            }
        }
    }

    if (resigning) {
        ConfirmDialog(
            title = t("online.resign", "Resign"),
            message = if (session.unratedByMatch == null) t("online.leavingAnOnlineGameLoses", "Leaving an online game loses it and costs you rating.")
            else t("online.leavingAFriendlyGame", "Leaving loses the game, but this one is not rated."),
            confirm = t("online.resign", "Resign"), dismiss = t("online.playOn", "Play on"),
            onConfirm = { resigning = false; session.resign() }, onDismiss = { resigning = false },
        )
    }
}

@Composable
private fun FinishedCard(model: OnlineModel, game: OnlineModel.Game, result: MatchResult, opponentName: String) {
    val session = game.session
    BasicText(result.headline, style = LocalFaces.current.display(24))
    val scored = game.result?.takeIf { it.game == session.gameNumber }
    if (scored != null) {
        Spacer(Modifier.height(4.dp))
        if (scored.rated) {
            val before = scored.record.rating - scored.delta
            Body(
                t("online.ratingChange", "Rating %1\$@ → %2\$lld", before.toString(), scored.record.rating) +
                    "  (" + (if (scored.delta >= 0) "+" else "−") + kotlin.math.abs(scored.delta) + ")",
                color = if (scored.delta >= 0) Theatre.good else Theatre.bad,
            )
        } else {
            Body(
                when (scored.unrated) {
                    "invitation" -> t("online.unrated.invitation", "Not rated: games from an invitation are friendly.")
                    "rematch" -> t("online.unrated.rematch", "Not rated: a rematch is a friendly game.")
                    "sameOpponentToday" -> t("online.unrated.again", "Not rated: only one game a day against the same opponent counts.")
                    "aborted" -> t("online.unrated.aborted", "Not rated: the game ended before both sides had moved.")
                    else -> t("online.unrated.void", "Not rated: the two devices did not agree about the clock.")
                },
                size = 13, color = Theatre.ivoryDim,
            )
        }
    }
    val next = L.color(session.myColor.opponent).lowercase()
    when {
        session.opponentLeft || game.closed -> {
            Spacer(Modifier.height(8.dp))
            Body(t("online.opponentLeft", "%@ has left.", opponentName), size = 13, color = Theatre.ivoryDim)
        }
        session.rematchOffered -> {
            Spacer(Modifier.height(10.dp))
            Body(t("online.rematchOffered", "%1\$@ wants another game. You would play %2\$@.", opponentName, next))
            Spacer(Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ChipButton(t("online.accept", "Accept"), Modifier.weight(1f), primary = true) { session.respondToRematch(true) }
                ChipButton(t("online.notNow", "Not now"), Modifier.weight(1f)) { session.respondToRematch(false) }
            }
        }
        session.rematchOfferSent -> {
            Spacer(Modifier.height(8.dp))
            Body(t("online.rematchWaiting", "Asking %@ for another game…", opponentName), size = 13, color = Theatre.ivoryDim)
        }
        session.rematchDeclined -> {
            Spacer(Modifier.height(8.dp))
            Body(t("online.rematchDeclined", "%@ does not want another game.", opponentName), size = 13, color = Theatre.ivoryDim)
        }
        else -> {
            Spacer(Modifier.height(8.dp))
            Body(t("online.rematchDetail", "The same clock, colours swapped: you would play %@.", next), size = 13, color = Theatre.ivoryFaint)
        }
    }
}

/** A player's row over or under the board: colour, name, rating, and the clock. */
@Composable
fun PlayerBar(name: String, rating: Int?, color: PieceColor, clock: Double? = null, running: Boolean = false) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 2.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(
            Modifier.size(10.dp).clip(CircleShape)
                .background(if (color == PieceColor.WHITE) Theatre.ivory else Theatre.ink4)
                .then(if (color == PieceColor.BLACK) Modifier.padding(1.dp) else Modifier)
        )
        Spacer(Modifier.width(8.dp))
        // The name gives way to the rating and the clock, which are never cut short.
        Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
            Body(name, Modifier.weight(1f, fill = false), size = 14, style = LocalFaces.current.body(14, weight = FontWeight.SemiBold), maxLines = 1)
            if (rating != null) {
                Spacer(Modifier.width(8.dp))
                BasicText(rating.toString(), style = LocalFaces.current.figures(13))
            }
        }
        Spacer(Modifier.width(8.dp))
        if (clock != null) {
            val low = clock < 20
            Box(
                Modifier.clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
                    .background(if (running) Theatre.brassGlow else Theatre.ink3)
                    .padding(horizontal = 10.dp, vertical = 4.dp)
            ) {
                BasicText(
                    ChessClock.text(clock),
                    style = LocalFaces.current.figures(18, if (running && low) Theatre.bad else if (running) Theatre.brassHot else Theatre.ivoryDim),
                )
            }
        }
    }
}

/** "1. e4 e5 2. Nf3 …" from a list of SAN moves. */
fun moveText(moves: List<String>): String = buildString {
    moves.forEachIndexed { index, san ->
        if (index % 2 == 0) append(index / 2 + 1).append(". ")
        append(san).append(' ')
    }
}.trimEnd()
