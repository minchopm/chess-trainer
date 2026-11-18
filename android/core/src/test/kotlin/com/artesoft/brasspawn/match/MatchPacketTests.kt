package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.PieceColor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * The wire format, pinned.
 *
 * The server relays packets between an iPhone and an Android phone, so what
 * this build writes has to be what Swift's synthesised `Codable` writes for
 * the enum these are ported from, and what it reads has to include everything
 * that writes. These are the exact strings; a change that moves one of them
 * is a change that breaks a game between the two.
 */
class MatchPacketTests {
    /** Each packet with the text it is on the wire. */
    private val pinned: List<kotlin.Pair<MatchPacket, String>> = listOf(
        MatchPacket.Hello(playerID = "G:1873", name = "Ann", rating = 1200, games = 0, deviation = 350.0) to
            """{"hello":{"_0":{"version":1,"playerID":"G:1873","name":"Ann","rating":1200,"games":0,"deviation":350}}}""",
        MatchPacket.Hello(playerID = "G:1873", name = "Ann", rating = 1834, games = 131, deviation = 72.4) to
            """{"hello":{"_0":{"version":1,"playerID":"G:1873","name":"Ann","rating":1834,"games":131,"deviation":72.4}}}""",
        MatchPacket.Hello(playerID = "G:1873", name = "Ann", rating = 1200, games = 0) to
            """{"hello":{"_0":{"version":1,"playerID":"G:1873","name":"Ann","rating":1200,"games":0}}}""",
        MatchPacket.Start(youPlay = PieceColor.BLACK, timeControl = TimeControl.FIVE) to
            """{"start":{"_0":{"version":1,"youPlay":"black","minutes":5}}}""",
        MatchPacket.Start(youPlay = PieceColor.WHITE, timeControl = TimeControl.THIRTY) to
            """{"start":{"_0":{"version":1,"youPlay":"white","minutes":30}}}""",
        MatchPacket.MovePacket(uci = "e2e4", ply = 1, remaining = 299.2, yours = 300.0) to
            """{"move":{"_0":{"uci":"e2e4","ply":1,"remaining":299.2,"yours":300}}}""",
        MatchPacket.MovePacket(uci = "e7e8q", ply = 62, remaining = 0.125) to
            """{"move":{"_0":{"uci":"e7e8q","ply":62,"remaining":0.125}}}""",
        MatchPacket.Resign to """{"resign":{}}""",
        MatchPacket.DrawOffer to """{"drawOffer":{}}""",
        MatchPacket.DrawResponse(accepted = true) to """{"drawResponse":{"accepted":true}}""",
        MatchPacket.DrawResponse(accepted = false) to """{"drawResponse":{"accepted":false}}""",
        MatchPacket.GameOver(winner = PieceColor.WHITE, reason = MatchResult.Reason.CHECKMATE) to
            """{"gameOver":{"_0":{"winner":"white","reason":"checkmate"}}}""",
        MatchPacket.GameOver(winner = PieceColor.BLACK, reason = MatchResult.Reason.TIMEOUT) to
            """{"gameOver":{"_0":{"winner":"black","reason":"timeout"}}}""",
        MatchPacket.GameOver(winner = null, reason = MatchResult.Reason.INSUFFICIENT_MATERIAL) to
            """{"gameOver":{"_0":{"reason":"insufficientMaterial"}}}""",
        MatchPacket.RematchOffer to """{"rematchOffer":{}}""",
        MatchPacket.RematchResponse(accepted = true) to """{"rematchResponse":{"accepted":true}}""",
        MatchPacket.Goodbye to """{"goodbye":{}}""",
    )

    @Test
    fun `Every packet is written as Swift writes it`() {
        for ((packet, json) in pinned) {
            assertEquals(json, packet.toJson())
        }
    }

    @Test
    fun `Every packet is read back from what Swift writes`() {
        for ((packet, json) in pinned) {
            assertEquals(packet, MatchPacket.fromJson(json), json)
        }
    }

    /** Swift's encoder does not promise an order for the keys, and a server may reformat. */
    @Test
    fun `The order of the keys and the space between them do not matter`() {
        assertEquals(
            MatchPacket.Hello(playerID = "A", name = "Ann", rating = 1200, games = 3, deviation = 350.0),
            MatchPacket.fromJson(
                """
                {
                  "hello" : {
                    "_0" : { "games" : 3, "deviation" : 350, "name" : "Ann", "rating" : 1200, "playerID" : "A", "version" : 1 }
                  }
                }
                """
            ),
        )
        assertEquals(
            MatchPacket.MovePacket(uci = "e2e4", ply = 1, remaining = 299.2, yours = 300.0),
            MatchPacket.fromJson("""{"move":{"_0":{"yours":300.0,"remaining":2.992e2,"ply":1,"uci":"e2e4"}}}"""),
        )
    }

    @Test
    fun `A draw is read with the winner left out or sent as null`() {
        val draw = MatchPacket.GameOver(winner = null, reason = MatchResult.Reason.STALEMATE)
        assertEquals(draw, MatchPacket.fromJson("""{"gameOver":{"_0":{"reason":"stalemate"}}}"""))
        assertEquals(draw, MatchPacket.fromJson("""{"gameOver":{"_0":{"winner":null,"reason":"stalemate"}}}"""))
        assertNull(draw.winnerColor)
        assertEquals(MatchResult.Reason.STALEMATE, draw.resultReason)
        assertEquals("""{"gameOver":{"_0":{"reason":"stalemate"}}}""", draw.toJson())
    }

    @Test
    fun `Optional fields are read when they are null, and left out when written`() {
        assertEquals(
            MatchPacket.Hello(playerID = "A", name = "Ann", rating = 1200, games = 0),
            MatchPacket.fromJson("""{"hello":{"_0":{"version":1,"playerID":"A","name":"Ann","rating":1200,"games":0,"deviation":null}}}"""),
        )
        assertEquals(
            MatchPacket.MovePacket(uci = "e2e4", ply = 1, remaining = 299.0),
            MatchPacket.fromJson("""{"move":{"_0":{"uci":"e2e4","ply":1,"remaining":299,"yours":null}}}"""),
        )
    }

    /** A newer build may say more; what this one does not know it passes over. */
    @Test
    fun `Fields this build does not know are ignored`() {
        assertEquals(
            MatchPacket.MovePacket(uci = "e2e4", ply = 1, remaining = 299.2, yours = 300.0),
            MatchPacket.fromJson(
                """{"move":{"_0":{"uci":"e2e4","ply":1,"remaining":299.2,"yours":300,"increment":2,"meta":{"a":[1,2]}}},"seq":17}"""
            ),
        )
        assertEquals(MatchPacket.Resign, MatchPacket.fromJson("""{"resign":{"at":12.5}}"""))
        assertEquals(
            MatchPacket.DrawResponse(accepted = true),
            MatchPacket.fromJson("""{"drawResponse":{"accepted":true,"note":"gg"}}"""),
        )
        assertEquals(
            MatchPacket.Start(youPlay = "black", minutes = 5, version = 2),
            MatchPacket.fromJson("""{"start":{"_0":{"version":2,"youPlay":"black","minutes":5,"increment":0}}}"""),
        )
    }

    @Test
    fun `A case this build does not know is no packet, and does not throw`() {
        assertNull(MatchPacket.fromJson("""{"emote":{"_0":{"kind":"wave"}}}"""))
        assertNull(MatchPacket.fromJson("""{"takebackOffer":{}}"""))
        assertNull(MatchPacket.fromJson("""{}"""))
        // Two cases at once is not one packet.
        assertNull(MatchPacket.fromJson("""{"resign":{},"goodbye":{}}"""))
    }

    @Test
    fun `Text that is not a packet is no packet, and does not throw`() {
        val noise = listOf(
            "", " ", "hello", "null", "true", "17", "\"resign\"", "[]", "[{\"resign\":{}}]",
            "{", "{\"resign\":", "{\"resign\":{}", "{\"move\":{\"_0\":{\"uci\":\"e2e4\",\"ply\":1,\"remaining\":",
        )
        for (text in noise) {
            assertNull(MatchPacket.fromJson(text), text)
        }
    }

    @Test
    fun `A known case without what it needs is no packet`() {
        val broken = listOf(
            // No payload, or the payload in the wrong place.
            """{"hello":{}}""",
            """{"hello":null}""",
            """{"hello":"Ann"}""",
            """{"move":{"uci":"e2e4","ply":1,"remaining":299.2}}""",
            """{"drawResponse":{}}""",
            """{"drawResponse":{"_0":{"accepted":true}}}""",
            """{"resign":true}""",
            """{"resign":null}""",
            """{"resign":[]}""",
            """{"goodbye":7}""",
            // A field missing.
            """{"hello":{"_0":{"playerID":"A","name":"Ann","rating":1200,"games":0}}}""",
            """{"hello":{"_0":{"version":1,"name":"Ann","rating":1200,"games":0}}}""",
            """{"start":{"_0":{"version":1,"youPlay":"black"}}}""",
            """{"move":{"_0":{"uci":"e2e4","remaining":299.2}}}""",
            """{"move":{"_0":{"uci":"e2e4","ply":1}}}""",
            """{"gameOver":{"_0":{"winner":"white"}}}""",
            // A field of the wrong kind.
            """{"hello":{"_0":{"version":1,"playerID":"A","name":"Ann","rating":"1200","games":0}}}""",
            """{"hello":{"_0":{"version":1,"playerID":"A","name":"Ann","rating":1200.5,"games":0}}}""",
            """{"hello":{"_0":{"version":1,"playerID":17,"name":"Ann","rating":1200,"games":0}}}""",
            """{"hello":{"_0":{"version":1,"playerID":"A","name":"Ann","rating":1200,"games":0,"deviation":"wide"}}}""",
            """{"move":{"_0":{"uci":"e2e4","ply":1,"remaining":null}}}""",
            """{"move":{"_0":{"uci":"e2e4","ply":1,"remaining":299.2,"yours":"300"}}}""",
            """{"move":{"_0":{"uci":"e2e4","ply":true,"remaining":299.2}}}""",
            """{"drawResponse":{"accepted":"true"}}""",
            """{"drawResponse":{"accepted":1}}""",
            """{"gameOver":{"_0":{"winner":1,"reason":"checkmate"}}}""",
            """{"gameOver":{"_0":{"winner":"white","reason":null}}}""",
        )
        for (text in broken) {
            assertNull(MatchPacket.fromJson(text), text)
        }
    }

    /** As Swift's decoder does: 1200.0 is a whole number, whoever wrote it that way. */
    @Test
    fun `A whole number written with a fraction is still whole`() {
        assertEquals(
            MatchPacket.Start(youPlay = "white", minutes = 10),
            MatchPacket.fromJson("""{"start":{"_0":{"version":1.0,"youPlay":"white","minutes":1e1}}}"""),
        )
    }

    @Test
    fun `Text is escaped, and comes back as it went`() {
        val awkward = MatchPacket.Hello(playerID = "G:\"1\"", name = "Ann \\ \"the rook\"\n— Ünïcödé ♜", rating = 1500, games = 12)
        assertEquals(awkward, MatchPacket.fromJson(awkward.toJson()))
        // Swift writes a slash as "\/", which is the same slash.
        assertEquals(
            MatchPacket.Hello(playerID = "a/b", name = "A/B", rating = 1500, games = 12),
            MatchPacket.fromJson("""{"hello":{"_0":{"version":1,"playerID":"a\/b","name":"A\/B","rating":1500,"games":12}}}"""),
        )
    }

    @Test
    fun `What a packet says is read leniently, as the Swift types read it`() {
        // A colour that is not "white" is black; a clock nobody offers is five minutes.
        val start = MatchPacket.Start(youPlay = "purple", minutes = 7)
        assertEquals(PieceColor.BLACK, start.receiverColor)
        assertEquals(TimeControl.FIVE, start.timeControl)
        assertEquals(PieceColor.WHITE, MatchPacket.Start(youPlay = PieceColor.WHITE, timeControl = TimeControl.TEN).receiverColor)
        assertEquals(TimeControl.TEN, MatchPacket.Start(youPlay = PieceColor.WHITE, timeControl = TimeControl.TEN).timeControl)

        // A reason from a newer build is an agreement; a winner that is no colour is nobody.
        val over = MatchPacket.GameOver(winner = "green", reason = "adjudication")
        assertNull(over.winnerColor)
        assertEquals(MatchResult.Reason.AGREEMENT, over.resultReason)
        assertEquals(PieceColor.BLACK, MatchPacket.GameOver(winner = PieceColor.BLACK, reason = MatchResult.Reason.TIMEOUT).winnerColor)
    }

    @Test
    fun `Every reason goes over the wire under its Swift name`() {
        assertEquals(
            listOf(
                "checkmate", "resignation", "timeout", "stalemate", "insufficientMaterial",
                "repetition", "fiftyMoveRule", "agreement", "disconnected",
            ),
            MatchResult.Reason.entries.map { it.rawValue },
        )
        for (reason in MatchResult.Reason.entries) {
            assertEquals(reason, MatchResult.Reason.fromRawValue(reason.rawValue))
            val packet = MatchPacket.GameOver(winner = null, reason = reason)
            assertEquals(reason, (MatchPacket.fromJson(packet.toJson()) as MatchPacket.GameOver).resultReason)
        }
        assertEquals(1, MatchProtocolVersion.current)
    }
}
