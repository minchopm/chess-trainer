package com.artesoft.brasspawn.online

import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put

/** The service said no. `code` is its short word for why: `alias-rejected`, `session`, … */
class OnlineException(val status: Int, val code: String) : Exception("$status $code")

/** A rating on one clock, as the service keeps it. */
data class Record(val rating: Int, val deviation: Double, val games: Int, val lastPlayed: Long) {
    companion object {
        val new = Record(1200, 350.0, 0, 0)
        fun from(json: JsonObject?): Record = if (json == null) new else Record(
            rating = json.int("rating") ?: 1200,
            deviation = json.double("deviation") ?: 350.0,
            games = json.int("games") ?: 0,
            lastPlayed = json.long("lastPlayed") ?: 0,
        )
    }
}

data class Player(val id: String, val alias: String, val record: Record = Record.new, val rank: Int? = null)

data class Login(
    val session: String, val expires: Long, val account: String, val alias: String,
    val aliasNeeded: Boolean, val records: Map<Int, Record>,
)

data class MatchInfo(
    val id: String, val host: Boolean, val minutes: Int, val open: Boolean,
    val opponent: Player, val me: Record,
)

data class GameResult(
    val match: String, val game: Int, val winner: String?, val reason: String,
    val rated: Boolean, val unrated: String?, val minutes: Int, val delta: Int, val record: Record,
)

data class FriendInvite(val id: String, val alias: String, val minutes: Int)

data class Friends(
    val friends: List<Player>, val incoming: List<Player>, val outgoing: List<Player>, val invites: List<FriendInvite>,
)

data class Leaderboard(val entries: List<Player>, val me: Player?, val total: Int)

data class InviteCode(val code: String, val minutes: Int, val link: String, val expires: Long)

sealed interface OnlineEvent {
    data class Matched(val match: MatchInfo) : OnlineEvent
    data class Packet(val match: String, val packet: String) : OnlineEvent
    data class Result(val result: GameResult) : OnlineEvent
    data class Peer(val match: String, val connected: Boolean) : OnlineEvent
    data class MatchEnded(val match: String) : OnlineEvent
    data class SeekEnded(val reason: String) : OnlineEvent
    data object FriendsChanged : OnlineEvent
    data class Invited(val invite: FriendInvite) : OnlineEvent
}

class EventBatch(val events: List<OnlineEvent>, val next: Long)

/**
 * The online service, call by call — see PROTOCOL.md in the Cloud Rush
 * repository (SharedExtensions/go/transport/chessplay), which this follows.
 */
class OnlineApi(private val transport: HttpTransport, baseUrl: String, private val device: String) {
    private val root = baseUrl.trimEnd('/') + "/brasspawn/v1"
    @Volatile var session: String? = null

    suspend fun login(alias: String?, proof: DeviceIdentity.Proof): Login {
        val reply = post("/login", buildJsonObject {
            put("device", device)
            if (!alias.isNullOrBlank()) put("alias", alias)
            put("key", buildJsonObject {
                put("publicKey", proof.publicKey)
                put("timestampMs", proof.timestampMs)
                put("signature", proof.signature)
            })
        }, authorized = false)
        val records = reply.obj("records")?.mapNotNull { (minutes, value) ->
            minutes.toIntOrNull()?.let { it to Record.from(value as? JsonObject) }
        }?.toMap().orEmpty()
        return Login(
            session = reply.string("session") ?: throw OnlineException(200, "malformed"),
            expires = reply.long("expires") ?: 0,
            account = reply.string("account").orEmpty(),
            alias = reply.string("alias").orEmpty(),
            aliasNeeded = reply.bool("aliasNeeded") ?: false,
            records = records,
        ).also { session = it.session }
    }

    suspend fun setAlias(alias: String): String =
        post("/profile", buildJsonObject { put("alias", alias) }).string("alias") ?: alias

    suspend fun deleteAccount() { post("/account/delete") }

    suspend fun events(after: Long, waitSeconds: Int = 25): EventBatch {
        val reply = call("GET", "/events?after=$after&wait=$waitSeconds", null, timeoutMs = (waitSeconds + 10) * 1000)
        val events = reply["events"]?.let { it as? JsonArray }.orEmpty().mapNotNull { (it as? JsonObject)?.let(::event) }
        return EventBatch(events, reply.long("next") ?: after)
    }

    suspend fun seek(minutes: Int) { post("/seek", buildJsonObject { put("minutes", minutes) }) }
    suspend fun cancelSeek() { post("/seek/cancel") }

    suspend fun createInvite(minutes: Int): InviteCode {
        val reply = post("/invite/create", buildJsonObject { put("minutes", minutes) })
        return InviteCode(reply.string("code").orEmpty(), reply.int("minutes") ?: minutes, reply.string("link").orEmpty(), reply.long("expires") ?: 0)
    }

    suspend fun joinInvite(code: String) { post("/invite/join", buildJsonObject { put("code", code) }) }
    suspend fun cancelInvite() { post("/invite/cancel") }

    suspend fun send(match: String, packet: String) {
        post("/match/send", buildJsonObject {
            put("match", match)
            put("packet", Json.parseToJsonElement(packet))
        })
    }

    suspend fun leave(match: String) { post("/match/leave", buildJsonObject { put("match", match) }) }

    suspend fun leaderboard(minutes: Int, scope: String, limit: Int = 50): Leaderboard {
        val reply = post("/leaderboard", buildJsonObject {
            put("minutes", minutes)
            put("scope", scope)
            put("limit", limit)
        })
        return Leaderboard(
            entries = reply.list("entries").map(::player),
            me = reply.obj("me")?.let(::player),
            total = reply.int("total") ?: 0,
        )
    }

    suspend fun search(alias: String): List<Player> =
        post("/players/search", buildJsonObject { put("alias", alias) }).list("players").map(::player)

    suspend fun here(status: String, minutes: Int?): List<FriendInvite> =
        post("/here", buildJsonObject {
            put("status", status)
            if (minutes != null) put("minutes", minutes)
        }).list("invites").map(::invite)

    suspend fun gone() { post("/gone") }

    /** Everybody on screen now: account → (status, minutes). */
    suspend fun online(): Map<String, Pair<String, Int?>> =
        post("/online").list("players").associate { it.string("id").orEmpty() to (it.string("status").orEmpty() to it.int("minutes")) }

    suspend fun friends(): Friends {
        val reply = post("/friends")
        return Friends(
            friends = reply.list("friends").map(::player),
            incoming = reply.list("incoming").map(::player),
            outgoing = reply.list("outgoing").map(::player),
            invites = reply.list("invites").map(::invite),
        )
    }

    suspend fun requestFriend(id: String) { post("/friends/request", buildJsonObject { put("to", id) }) }
    suspend fun acceptFriend(id: String) { post("/friends/accept", buildJsonObject { put("from", id) }) }
    suspend fun removeFriend(id: String) { post("/friends/remove", buildJsonObject { put("other", id) }) }
    suspend fun offerGame(id: String, minutes: Int) {
        post("/friends/invite", buildJsonObject { put("to", id); put("minutes", minutes) })
    }
    suspend fun answerOffer(id: String, accept: Boolean) {
        post("/friends/answer", buildJsonObject { put("from", id); put("accept", accept) })
    }
    suspend fun cancelOffer(id: String) { post("/friends/cancel", buildJsonObject { put("to", id) }) }

    // MARK: -

    private suspend fun post(path: String, body: JsonObject = JsonObject(emptyMap()), authorized: Boolean = true): JsonObject =
        call("POST", path, body, authorized = authorized)

    private suspend fun call(
        method: String, path: String, body: JsonObject?, authorized: Boolean = true, timeoutMs: Int = 15_000,
    ): JsonObject {
        val headers = buildMap {
            put("Accept", "application/json")
            put("X-Device-ID", device)
            if (authorized) put("Authorization", "Bearer ${session ?: throw OnlineException(401, "session")}")
        }
        val reply = withTimeout(timeoutMs + 2_000L) { transport.send(method, root + path, headers, body?.toString(), timeoutMs) }
        val json = runCatching { Json.parseToJsonElement(reply.body) as? JsonObject }.getOrNull()
        if (reply.status != 200) throw OnlineException(reply.status, json?.string("error") ?: "http")
        return json ?: throw OnlineException(200, "malformed")
    }

    private fun event(json: JsonObject): OnlineEvent? = when (json.string("type")) {
        "match" -> OnlineEvent.Matched(
            MatchInfo(
                id = json.string("match").orEmpty(),
                host = json.bool("host") ?: false,
                minutes = json.int("minutes") ?: 5,
                open = json.bool("open") ?: true,
                opponent = json.obj("opponent")?.let(::player) ?: Player("", ""),
                me = Record.from(json.obj("me")),
            )
        )
        "packet" -> json["packet"]?.let { OnlineEvent.Packet(json.string("match").orEmpty(), it.toString()) }
        "result" -> OnlineEvent.Result(
            GameResult(
                match = json.string("match").orEmpty(),
                game = json.int("game") ?: 1,
                winner = json.string("winner"),
                reason = json.string("reason").orEmpty(),
                rated = json.bool("rated") ?: false,
                unrated = json.string("unrated"),
                minutes = json.int("minutes") ?: 5,
                delta = json.int("delta") ?: 0,
                record = Record.from(json.obj("record")),
            )
        )
        "peer" -> OnlineEvent.Peer(json.string("match").orEmpty(), json.bool("connected") ?: true)
        "matchEnded" -> OnlineEvent.MatchEnded(json.string("match").orEmpty())
        "seekEnded" -> OnlineEvent.SeekEnded(json.string("reason").orEmpty())
        "friends" -> OnlineEvent.FriendsChanged
        "invite" -> OnlineEvent.Invited(FriendInvite(json.string("from").orEmpty(), json.string("alias").orEmpty(), json.int("minutes") ?: 5))
        else -> null
    }

    private fun player(json: JsonObject) = Player(
        id = json.string("id").orEmpty(),
        alias = json.string("alias").orEmpty(),
        record = Record.from(json),
        rank = json.int("rank"),
    )

    private fun invite(json: JsonObject) = FriendInvite(json.string("id").orEmpty(), json.string("alias").orEmpty(), json.int("minutes") ?: 5)
}

internal fun JsonObject.string(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it !is JsonNull && it.isString }?.content
internal fun JsonObject.int(key: String): Int? = (this[key] as? JsonPrimitive)?.let { it.intOrNull ?: it.doubleOrNull?.toInt() }
internal fun JsonObject.long(key: String): Long? = (this[key] as? JsonPrimitive)?.let { it.longOrNull ?: it.doubleOrNull?.toLong() }
internal fun JsonObject.double(key: String): Double? = (this[key] as? JsonPrimitive)?.doubleOrNull
internal fun JsonObject.bool(key: String): Boolean? = (this[key] as? JsonPrimitive)?.booleanOrNull
internal fun JsonObject.obj(key: String): JsonObject? = this[key] as? JsonObject
internal fun JsonObject.list(key: String): List<JsonObject> = (this[key] as? JsonArray)?.mapNotNull { it as? JsonObject }.orEmpty()
