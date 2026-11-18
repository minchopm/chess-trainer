package com.artesoft.brasspawn.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.match.TimeControl
import com.artesoft.brasspawn.online.Leaderboard
import com.artesoft.brasspawn.online.OnlineModel
import com.artesoft.brasspawn.online.Player
import kotlinx.coroutines.delay

enum class PeopleKind { RANKS, FRIENDS, PLAYERS }

/** The rank list on a clock, this player's friends, and everybody who can be found by nickname. */
@Composable
fun PeopleScreen(model: OnlineModel, initial: PeopleKind, initialClock: TimeControl, onBack: () -> Unit) {
    var kind by rememberSaveable { mutableStateOf(initial) }
    var clock by rememberSaveable { mutableStateOf(initialClock) }
    val titles = listOf(t("online.rankList", "Rank list"), t("online.friends", "Friends"), t("online.players", "Players"))

    Screen(title = titles[kind.ordinal], onBack = onBack) {
        Segmented(titles, kind.ordinal, Modifier.fillMaxWidth()) { kind = PeopleKind.entries[it] }
        Spacer(Modifier.height(10.dp))
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            when (kind) {
                PeopleKind.RANKS -> Ranks(model, clock) { clock = it }
                PeopleKind.FRIENDS -> FriendsList(model, clock)
                PeopleKind.PLAYERS -> Players(model, clock)
            }
            Body(t("online.android.playersNote", "Nicknames and ratings are kept by Brass Pawn's own game service, the same for iPhone, iPad, Mac and Android. Online now means the app is on their screen."), size = 12, color = Theatre.ivoryFaint)
        }
    }
}

@Composable
private fun Ranks(model: OnlineModel, clock: TimeControl, onClock: (TimeControl) -> Unit) {
    var board by remember { mutableStateOf<Leaderboard?>(null) }
    var loaded by remember { mutableStateOf(false) }
    LaunchedEffect(clock) {
        loaded = false
        board = model.leaderboard(clock, "top")
        loaded = true
    }
    Segmented(TimeControl.entries.map { it.label }, TimeControl.entries.indexOf(clock), Modifier.fillMaxWidth()) { onClock(TimeControl.entries[it]) }
    val list = board
    when {
        !loaded -> Body(t("online.android.loadingPlayers", "Reading the lists…"), color = Theatre.ivoryDim)
        list == null -> Body(t("online.android.offline", "The server cannot be reached. Check the connection and try again."), color = Theatre.ivoryDim)
        else -> {
            Panel(Modifier.fillMaxWidth()) {
                Label(t("online.yourPlace", "Your place"))
                Spacer(Modifier.height(4.dp))
                val me = list.me
                if (me?.rank != null) {
                    Body(t("online.placeOf", "%1\$lld of %2\$lld", me.rank, list.total), style = LocalFaces.current.figures(18, Theatre.brassHot))
                } else {
                    Body(t("online.android.rankEmptyMe", "Play a rated game on this clock to get a place."), size = 13, color = Theatre.ivoryDim)
                }
            }
            if (list.entries.isEmpty()) {
                Body(t("online.nobodyRanked", "Nobody has a rating on this clock yet. The first game played on it starts the list."), size = 13, color = Theatre.ivoryDim)
            } else {
                Panel(Modifier.fillMaxWidth(), padding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)) {
                    list.entries.forEach { player -> PlayerRow(model, player, clock, showRank = true) }
                }
            }
        }
    }
}

@Composable
private fun FriendsList(model: OnlineModel, clock: TimeControl) {
    LaunchedEffect(Unit) { model.refreshFriends() }
    val friends = model.friends
    if (friends.incoming.isNotEmpty()) {
        Panel(Modifier.fillMaxWidth()) {
            Label(t("online.friendRequests", "Requests"))
            friends.incoming.forEach { player ->
                Row(Modifier.fillMaxWidth().padding(top = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Body(player.alias, Modifier.weight(1f), maxLines = 1)
                    ChipButton(t("online.accept", "Accept"), primary = true) { model.acceptFriend(player) }
                    Spacer(Modifier.width(8.dp))
                    ChipButton(t("online.decline", "Decline")) { model.removeFriend(player) }
                }
            }
        }
    }
    if (friends.friends.isEmpty()) {
        Panel(Modifier.fillMaxWidth()) {
            Body(t("online.noFriendsYet", "No friends yet."))
            Spacer(Modifier.height(4.dp))
            Body(t("online.friendsHow", "The button on each row of the rank list and the players sends a friend request. Once it is accepted, the name is here."), size = 13, color = Theatre.ivoryDim)
        }
    } else {
        Panel(Modifier.fillMaxWidth(), padding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)) {
            friends.friends.forEach { player -> PlayerRow(model, player, clock, showRank = false) }
        }
    }
    if (friends.outgoing.isNotEmpty()) {
        Panel(Modifier.fillMaxWidth()) {
            Label(t("online.friendsSent", "Sent"))
            friends.outgoing.forEach { player ->
                Row(Modifier.fillMaxWidth().padding(top = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Body(player.alias, Modifier.weight(1f), maxLines = 1)
                    ChipButton(t("online.cancelRequest", "Take the request back")) { model.removeFriend(player) }
                }
            }
        }
    }
}

@Composable
private fun Players(model: OnlineModel, clock: TimeControl) {
    var query by rememberSaveable { mutableStateOf("") }
    var found by remember { mutableStateOf<List<Player>?>(null) }
    LaunchedEffect(query) {
        if (query.trim().length < 2) {
            found = null
            return@LaunchedEffect
        }
        delay(350)
        found = model.search(query.trim())
    }
    TextInput(query, { query = it.take(20) }, t("online.searchPlayers", "Search by nickname"), Modifier.fillMaxWidth())
    val list = found
    when {
        list == null -> Unit
        list.isEmpty() -> Body(t("online.noMatch", "Nobody by that nickname among the players read so far."), size = 13, color = Theatre.ivoryDim)
        else -> Panel(Modifier.fillMaxWidth(), padding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)) {
            list.forEach { player -> PlayerRow(model, player, clock, showRank = false, showRating = false) }
        }
    }
}

/** One player on a list: who they are, what they are doing now, and what can be asked of them. */
@Composable
private fun PlayerRow(model: OnlineModel, player: Player, clock: TimeControl, showRank: Boolean, showRating: Boolean = true) {
    val mine = player.id == model.account
    val isFriend = model.friends.friends.any { it.id == player.id }
    val asked = model.friends.outgoing.any { it.id == player.id }
    val presence = model.onlineNow[player.id]
    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        if (showRank && player.rank != null) {
            BasicText(player.rank.toString(), Modifier.width(34.dp), style = LocalFaces.current.figures(13, Theatre.brass))
        }
        Column(Modifier.weight(1f)) {
            Body(
                player.alias, size = 15, maxLines = 1,
                style = LocalFaces.current.body(15, if (mine) Theatre.brassHot else Theatre.ivory, FontWeight.SemiBold),
            )
            if (presence != null && !mine) {
                val control = presence.second?.let(TimeControl::fromMinutes)
                Body(
                    when {
                        presence.first == "looking" && control != null -> t("online.presence.looking", "Looking for a %@ game", control.label)
                        presence.first == "playing" -> t("online.presence.playing", "In a game")
                        else -> t("online.presence.online", "Online now")
                    },
                    size = 12, color = Theatre.good,
                )
            }
        }
        if (showRating) {
            BasicText(player.record.rating.toString(), style = LocalFaces.current.figures(15, Theatre.ivory))
            Spacer(Modifier.width(10.dp))
        }
        when {
            mine -> Unit
            isFriend -> ChipButton(t("online.invite", "Invite"), enabled = model.state == OnlineModel.State.Lobby) { model.offer(player, clock) }
            asked -> Label(t("online.requestSent", "Request sent"), color = Theatre.ivoryFaint)
            else -> ChipButton(t("online.addAsFriend", "Add as friend")) { model.requestFriend(player) }
        }
    }
}
