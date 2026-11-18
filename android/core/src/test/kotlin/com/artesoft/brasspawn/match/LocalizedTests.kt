package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.PieceColor
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The localisation shim. On the iPhone this is `Bundle.localizedString` and
 * `String(format:)`; here the lookup is plugged in and the formatting is this
 * module's own, so both are checked.
 */
class LocalizedTests {
    @AfterTest
    fun unplug() {
        L.resolver = null
    }

    @Test
    fun `With nothing plugged in, the English source is the text`() {
        assertEquals("Blitz", L.t("clock.blitz", "Blitz"))
        assertEquals("White", L.color(PieceColor.WHITE))
        assertEquals("Black", L.color(PieceColor.BLACK))
        assertEquals("You won by checkmate", MatchResult(MatchResult.Outcome.WIN, MatchResult.Reason.CHECKMATE).headline)
        assertEquals("You lost by time", MatchResult(MatchResult.Outcome.LOSS, MatchResult.Reason.TIMEOUT).headline)
        assertEquals("Drawn by the fifty-move rule", MatchResult(MatchResult.Outcome.DRAW, MatchResult.Reason.FIFTY_MOVE_RULE).headline)
        assertEquals("Not rated: a rematch is a friendly game.", UnratedReason.REMATCH.text)
    }

    @Test
    fun `The app's strings are used where it has them`() {
        val bulgarian = mapOf(
            "clock.minutes" to "%lld мин",
            "result.youWonBy" to "Победихте с %@",
            "result.checkmate" to "мат",
        )
        L.resolver = { key -> bulgarian[key] }

        assertEquals("5 мин", TimeControl.FIVE.label)
        assertEquals("Победихте с мат", MatchResult(MatchResult.Outcome.WIN, MatchResult.Reason.CHECKMATE).headline)
        // And the English source where it does not.
        assertEquals("Rapid", TimeControl.TEN.displayName)
    }

    @Test
    fun `The specifiers of String(format) are filled in`() {
        assertEquals("Mate in 3", L.t("k", "Mate in %lld", 3))
        assertEquals("Mate in 3", L.t("k", "Mate in %d", 3))
        assertEquals("Mate in 3", L.t("k", "Mate in %ld", 3L))
        assertEquals("Black to play", L.t("k", "%@ to play", "Black"))
        assertEquals("Ann beat Bo by 12", L.t("k", "%@ beat %@ by %lld", "Ann", "Bo", 12))
        assertEquals("100% of 7", L.t("k", "%d%% of %d", 100, 7))
        assertEquals("1:05", L.t("k", "%d:%02d", 1, 5))
        assertEquals("12.3 s", L.t("k", "%.1f s", 12.34))
        assertEquals("(null)", L.t("k", "%@", null))
    }

    /** Word order is not a detail other languages agree with us about. */
    @Test
    fun `Positional specifiers put the arguments where the translation wants them`() {
        assertEquals("Bo lost to Ann", L.t("k", "%2\$@ lost to %1\$@", "Ann", "Bo"))
        assertEquals("3 of 10 for Ann", L.t("k", "%2\$lld of %3\$d for %1\$@", "Ann", 3, 10))
    }

    @Test
    fun `Text with no arguments is left exactly as it is`() {
        assertEquals("100% sure", L.t("k", "100% sure"))
        assertEquals("%@ and %d", L.t("k", "%@ and %d"))
    }

    @Test
    fun `A specifier with no argument to fill it is left standing`() {
        assertEquals("Ann beat %@", L.t("k", "%@ beat %@", "Ann"))
        assertEquals("Ann and %3\$@", L.t("k", "%1\$@ and %3\$@", "Ann", "Bo"))
    }
}
