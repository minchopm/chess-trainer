package com.artesoft.brasspawn.online

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.artesoft.brasspawn.BuildConfig
import com.artesoft.brasspawn.match.MatchPacket
import com.artesoft.brasspawn.match.MatchSession
import com.artesoft.brasspawn.match.MatchTransport
import com.artesoft.brasspawn.match.TimeControl
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Online play, as the screens see it: who this player is, the lobby, and the
 * game under way.
 *
 * The service pairs players, relays their packets and referees the game; the
 * game itself is `MatchSession`, the same state machine the iOS app runs, fed
 * from the event stream instead of a peer connection. The rating is the
 * service's: it is told here, never computed here.
 */
class OnlineModel(context: Context) {
    sealed interface State {
        /** Nothing asked of the service yet. */
        data object Idle : State
        data object Connecting : State
        /** A device-key account needs a nickname before anybody can see it. */
        data class NeedsNickname(val rejected: Boolean = false) : State
        data object Lobby : State
        data class Searching(val clock: TimeControl) : State
        /** An invitation code is out, waiting for somebody to join. */
        data class Inviting(val invite: InviteCode) : State
        /** A friend has been offered a game and has not answered. */
        data class Offering(val friend: Player, val clock: TimeControl) : State
        data object Playing : State
        data class Offline(val reason: String) : State
    }

    /** The game under way: the session, and what the service has said about it. */
    class Game(val info: MatchInfo, val session: MatchSession) {
        var result by mutableStateOf<GameResult?>(null)
        var opponentConnected by mutableStateOf(true)
        var closed by mutableStateOf(false)
        /** Bumped whenever the session changes, so the screen redraws. */
        var revision by mutableIntStateOf(0)
    }

    private val app = context.applicationContext
    private val identity = DeviceIdentity(app)
    private val preferences = app.getSharedPreferences("online", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private var api: OnlineApi? = null
    private var events: Job? = null
    private var ticker: Job? = null
    private var presence: Job? = null
    private var outbox: Channel<String>? = null
    private var cursor = 0L
    private var visible = false

    var state by mutableStateOf<State>(State.Idle)
        private set
    var account by mutableStateOf("")
        private set
    var alias by mutableStateOf(preferences.getString("alias", "").orEmpty())
        private set
    var records by mutableStateOf<Map<Int, Record>>(emptyMap())
        private set
    var game by mutableStateOf<Game?>(null)
        private set
    var friends by mutableStateOf(Friends(emptyList(), emptyList(), emptyList(), emptyList()))
        private set
    var onlineNow by mutableStateOf<Map<String, Pair<String, Int?>>>(emptyMap())
        private set
    /** Something the service refused, said once and cleared by the screen. */
    var notice by mutableStateOf<String?>(null)

    val isSignedIn: Boolean get() = account.isNotEmpty() && state !is State.NeedsNickname
    fun record(clock: TimeControl): Record = records[clock.minutes] ?: Record.new

    // MARK: - Coming and going

    /** The online screen is up: sign in if that has not happened, and listen. */
    fun appear() {
        visible = true
        when (state) {
            State.Idle, is State.Offline -> connect()
            else -> startPresence()
        }
    }

    /** The online screen is gone. A game under way keeps its connection; a search does not. */
    fun disappear() {
        visible = false
        presence?.cancel()
        when (state) {
            is State.Searching -> cancelSearch()
            is State.Inviting -> cancelInvite()
            else -> Unit
        }
        if (game == null) scope.launch { runCatching { api?.gone() } }
    }

    fun connect(nickname: String? = null) {
        if (state == State.Connecting) return
        state = State.Connecting
        scope.launch {
            try {
                val service = api ?: OnlineApi(
                    Transports.forBaseUrl(app, BuildConfig.ONLINE_BASE_URL), BuildConfig.ONLINE_BASE_URL, identity.device,
                ).also { api = it }
                val login = service.login(nickname ?: alias.ifBlank { null }, identity.proof())
                account = login.account
                records = login.records
                if (login.aliasNeeded) {
                    state = State.NeedsNickname(rejected = false)
                    return@launch
                }
                remember(login.alias)
                state = State.Lobby
                listen()
                startPresence()
                refreshFriends()
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: OnlineException) {
                state = if (error.code == "alias-rejected") State.NeedsNickname(rejected = true) else State.Offline(error.code)
            } catch (error: Exception) {
                state = State.Offline(error.message ?: "network")
            }
        }
    }

    /** Take a nickname: at first sign-in, or changing it later. */
    fun chooseNickname(nickname: String) {
        val service = api
        if (service == null || account.isEmpty()) {
            connect(nickname)
            return
        }
        val wasAsking = state is State.NeedsNickname
        scope.launch {
            try {
                remember(service.setAlias(nickname.trim()))
                if (wasAsking) {
                    state = State.Lobby
                    listen()
                    startPresence()
                    refreshFriends()
                }
            } catch (error: OnlineException) {
                if (wasAsking) state = State.NeedsNickname(rejected = true)
                else notice = "alias-rejected"
            } catch (error: Exception) {
                if (wasAsking) state = State.Offline(error.message ?: "network")
            }
        }
    }

    fun deleteAccount() {
        val service = api ?: return
        scope.launch {
            runCatching { service.deleteAccount() }
            events?.cancel()
            presence?.cancel()
            identity.reset()
            preferences.edit().remove("alias").apply()
            api = null
            account = ""
            alias = ""
            records = emptyMap()
            friends = Friends(emptyList(), emptyList(), emptyList(), emptyList())
            state = State.Idle
        }
    }

    private fun remember(name: String) {
        alias = name
        preferences.edit().putString("alias", name).apply()
    }

    // MARK: - Finding a game

    fun search(clock: TimeControl) = ask(State.Searching(clock)) { it.seek(clock.minutes) }

    fun cancelSearch() {
        if (state is State.Searching) state = State.Lobby
        scope.launch { runCatching { api?.cancelSeek() } }
    }

    fun invite(clock: TimeControl) {
        val service = api ?: return
        scope.launch {
            try {
                state = State.Inviting(service.createInvite(clock.minutes))
            } catch (error: Exception) {
                refuse(error)
            }
        }
    }

    fun cancelInvite() {
        if (state is State.Inviting) state = State.Lobby
        scope.launch { runCatching { api?.cancelInvite() } }
    }

    fun join(code: String) {
        val service = api ?: return
        scope.launch {
            try {
                service.joinInvite(code.trim().uppercase())
            } catch (error: Exception) {
                refuse(error)
            }
        }
    }

    fun offer(friend: Player, clock: TimeControl) = ask(State.Offering(friend, clock)) { it.offerGame(friend.id, clock.minutes) }

    fun withdrawOffer() {
        val offering = state as? State.Offering ?: return
        state = State.Lobby
        scope.launch { runCatching { api?.cancelOffer(offering.friend.id) } }
    }

    fun answer(invite: FriendInvite, accept: Boolean) {
        friends = friends.copy(invites = friends.invites.filterNot { it.id == invite.id })
        scope.launch {
            try {
                api?.answerOffer(invite.id, accept)
            } catch (error: Exception) {
                refuse(error)
            }
        }
    }

    private fun ask(next: State, call: suspend (OnlineApi) -> Unit) {
        val service = api ?: return
        if (game != null && game?.closed != true && game?.result == null) {
            notice = "busy"
            return
        }
        val before = state
        state = next
        scope.launch {
            try {
                call(service)
            } catch (error: Exception) {
                if (state == next) state = before
                refuse(error)
            }
        }
    }

    private fun refuse(error: Exception) {
        if (error is CancellationException) throw error
        notice = (error as? OnlineException)?.code ?: "network"
    }

    // MARK: - Friends and lists

    fun refreshFriends() {
        val service = api ?: return
        scope.launch {
            runCatching { service.friends() }.onSuccess { friends = it }
            runCatching { service.online() }.onSuccess { onlineNow = it }
        }
    }

    fun requestFriend(player: Player) = friendCall { it.requestFriend(player.id) }
    fun acceptFriend(player: Player) = friendCall { it.acceptFriend(player.id) }
    fun removeFriend(player: Player) = friendCall { it.removeFriend(player.id) }

    private fun friendCall(call: suspend (OnlineApi) -> Unit) {
        val service = api ?: return
        scope.launch {
            try {
                call(service)
            } catch (error: Exception) {
                refuse(error)
            }
            refreshFriends()
        }
    }

    suspend fun leaderboard(clock: TimeControl, scope: String): Leaderboard? =
        runCatching { api?.leaderboard(clock.minutes, scope) }.getOrNull()

    suspend fun search(nickname: String): List<Player> =
        runCatching { api?.search(nickname) }.getOrNull().orEmpty()

    // MARK: - The game

    /** Leave the game: said to the opponent, and to the service. Loses a game still being played. */
    fun leaveGame() {
        val current = game ?: return
        current.session.leave()
        ticker?.cancel()
        outbox?.close()
        outbox = null
        game = null
        state = State.Lobby
        scope.launch { runCatching { api?.leave(current.info.id) } }
        startPresence()
    }

    private fun begin(info: MatchInfo) {
        val service = api ?: return
        // Packets go out one at a time, in the order the session produced them.
        val queue = Channel<String>(Channel.UNLIMITED)
        outbox?.close()
        outbox = queue
        scope.launch {
            for (packet in queue) {
                // A packet that cannot be sent is tried again: the referee drops a duplicate move.
                var attempt = 0
                while (isActive) {
                    val sent = try {
                        service.send(info.id, packet)
                        true
                    } catch (error: OnlineException) {
                        // Refused — an illegal or stale packet, or the match is over. Not worth repeating.
                        true
                    } catch (error: CancellationException) {
                        throw error
                    } catch (error: Exception) {
                        false
                    }
                    if (sent || ++attempt >= 5) break
                    delay(600L * attempt)
                }
            }
        }
        val clock = TimeControl.fromMinutes(info.minutes) ?: TimeControl.FIVE
        val session = MatchSession(
            transport = MatchTransport { data -> queue.trySend(data) },
            me = MatchPacket.Hello(
                playerID = account, name = alias, rating = info.me.rating, games = info.me.games, deviation = info.me.deviation,
            ),
            isHost = info.host,
            timeControl = clock,
            openPool = info.open,
        )
        val started = Game(info, session)
        session.onChange = { started.revision++ }
        game = started
        state = State.Playing
        session.begin()
        ticker?.cancel()
        ticker = scope.launch {
            while (isActive) {
                delay(200)
                session.tick()
                started.revision++
            }
        }
        startPresence()
    }

    private fun handle(event: OnlineEvent) {
        when (event) {
            is OnlineEvent.Matched -> begin(event.match)
            is OnlineEvent.Packet -> game?.takeIf { it.info.id == event.match }?.session?.receive(event.packet)
            is OnlineEvent.Result -> {
                records = records + (event.result.minutes to event.result.record)
                game?.takeIf { it.info.id == event.result.match }?.let { current ->
                    current.result = event.result
                    current.session.applyServerResult(event.result.delta, event.result.record.deviation)
                }
            }
            is OnlineEvent.Peer -> game?.takeIf { it.info.id == event.match }?.opponentConnected = event.connected
            is OnlineEvent.MatchEnded -> game?.takeIf { it.info.id == event.match }?.let { current ->
                current.closed = true
                current.session.opponentDisconnected()
            }
            is OnlineEvent.SeekEnded -> if (state is State.Searching) state = State.Lobby
            OnlineEvent.FriendsChanged -> refreshFriends()
            is OnlineEvent.Invited -> {
                if (friends.invites.none { it.id == event.invite.id }) friends = friends.copy(invites = friends.invites + event.invite)
            }
        }
    }

    private fun listen() {
        val service = api ?: return
        events?.cancel()
        events = scope.launch {
            var failures = 0
            while (isActive) {
                try {
                    val batch = service.events(cursor)
                    cursor = batch.next
                    failures = 0
                    batch.events.forEach(::handle)
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (error: OnlineException) {
                    if (error.status == 401) {
                        // The session ran out (a day): sign in again, quietly.
                        runCatching { service.login(alias.ifBlank { null }, identity.proof()) }
                            .onFailure { delay(5_000) }
                    } else delay(2_000)
                } catch (error: Exception) {
                    failures++
                    delay(minOf(1_000L * failures, 8_000L))
                }
            }
        }
    }

    /** Say what this player is doing, while the screen is up: each word lasts five minutes. */
    private fun startPresence() {
        presence?.cancel()
        val service = api ?: return
        if (!visible && game == null) return
        presence = scope.launch {
            while (isActive) {
                val (status, minutes) = when (val now = state) {
                    is State.Searching -> "looking" to now.clock.minutes
                    State.Playing -> "playing" to (game?.info?.minutes ?: 5)
                    else -> "online" to null
                }
                runCatching { service.here(status, minutes) }.onSuccess { invites ->
                    if (invites != friends.invites) friends = friends.copy(invites = invites)
                }
                runCatching { service.online() }.onSuccess { onlineNow = it }
                delay(60_000)
            }
        }
    }

    companion object {
        @Volatile private var instance: OnlineModel? = null

        fun shared(context: Context): OnlineModel =
            instance ?: synchronized(this) { instance ?: OnlineModel(context).also { instance = it } }
    }
}
