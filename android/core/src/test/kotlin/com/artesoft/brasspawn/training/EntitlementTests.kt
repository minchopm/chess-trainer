package com.artesoft.brasspawn.training

import java.time.ZoneId
import java.time.ZoneOffset
import java.time.ZonedDateTime
import kotlin.test.Test
import kotlin.test.assertEquals

class EntitlementTests {
    private val zone: ZoneId = ZoneOffset.UTC
    private val noon = 1_700_000_000.0

    /**
     * Five of each, and the same five everywhere: enough of a mode to watch a
     * rating move, which is the thing a subscription is being sold against.
     */
    @Test
    fun `A fresh account has five of everything`() {
        val progress = TrainingProgress()
        for (activity in TrainingActivity.entries) {
            assertEquals(
                5,
                progress.freeRemaining(activity, at = noon, zone = zone),
                "$activity does not start at five",
            )
            assertEquals(activity, TrainingActivity.fromRawValue(activity.rawValue))
        }
        assertEquals(2, progress.freeTacticsSkipsRemaining(at = noon, zone = zone))
    }

    /**
     * The count is spent by attempting, and nothing else. Opening a screen,
     * reading a position and going back must cost nothing — that is the
     * difference between a free tier and a locked door.
     */
    @Test
    fun `Five attempts, then the door`() {
        var progress = TrainingProgress()
        for (spent in 0 until 5) {
            assertEquals(5 - spent, progress.freeRemaining(TrainingActivity.TACTICS, at = noon, zone = zone))
            progress = progress.recordFreeUse(of = TrainingActivity.TACTICS, at = noon, zone = zone)
        }
        assertEquals(0, progress.freeRemaining(TrainingActivity.TACTICS, at = noon, zone = zone))
    }

    @Test
    fun `Tactics completion and Rush attempt have separate allowances`() {
        var progress = TrainingProgress()
        progress = progress.recordFreeUse(of = TrainingActivity.TACTICS, at = noon, zone = zone)

        assertEquals(4, progress.freeRemaining(TrainingActivity.TACTICS, at = noon, zone = zone))
        assertEquals(5, progress.freeRemaining(TrainingActivity.RUSH, at = noon, zone = zone))
        assertEquals(5, progress.freeRemaining(TrainingActivity.ENDGAME, at = noon, zone = zone))

        progress = progress.recordFreeUse(of = TrainingActivity.RUSH, at = noon, zone = zone)
        assertEquals(4, progress.freeRemaining(TrainingActivity.RUSH, at = noon, zone = zone))

        // Skips have their own count and spend neither of the above.
        progress = progress.recordFreeTacticsSkip(at = noon, zone = zone)
        progress = progress.recordFreeTacticsSkip(at = noon, zone = zone)
        assertEquals(0, progress.freeTacticsSkipsRemaining(at = noon, zone = zone))
        assertEquals(4, progress.freeRemaining(TrainingActivity.TACTICS, at = noon, zone = zone))
    }

    @Test
    fun `The allowance runs out and stays out for the rest of the day`() {
        var progress = TrainingProgress()
        repeat(10) { progress = progress.recordFreeUse(of = TrainingActivity.RUSH, at = noon, zone = zone) }

        assertEquals(0, progress.freeRemaining(TrainingActivity.RUSH, at = noon, zone = zone))
        val laterSameDay = noon + 6 * 3600
        assertEquals(0, progress.freeRemaining(TrainingActivity.RUSH, at = laterSameDay, zone = zone))
    }

    @Test
    fun `Tomorrow starts over`() {
        var progress = TrainingProgress()
        progress = progress.recordFreeUse(of = TrainingActivity.TACTICS, at = noon, zone = zone)
        val tomorrow = noon + 26 * 3600

        assertEquals(5, progress.freeRemaining(TrainingActivity.TACTICS, at = tomorrow, zone = zone))

        // And spending tomorrow does not resurrect yesterday's count.
        progress = progress.recordFreeUse(of = TrainingActivity.TACTICS, at = tomorrow, zone = zone)
        assertEquals(4, progress.freeRemaining(TrainingActivity.TACTICS, at = tomorrow, zone = zone))
    }

    @Test
    fun `The local allowance resets at nine in the morning`() {
        val local = ZoneOffset.ofHours(2)
        val before = ZonedDateTime.of(2026, 8, 21, 8, 59, 59, 0, local).toEpochSecond().toDouble()
        val nine = ZonedDateTime.of(2026, 8, 21, 9, 0, 0, 0, local).toEpochSecond().toDouble()
        val nextDayNine = ZonedDateTime.of(2026, 8, 22, 9, 0, 0, 0, local).toEpochSecond().toDouble()

        var progress = TrainingProgress()
        progress = progress.recordFreeUse(of = TrainingActivity.TACTICS, at = before, zone = local)
        progress = progress.recordFreeTacticsSkip(at = before, zone = local)
        assertEquals(4, progress.freeRemaining(TrainingActivity.TACTICS, at = before, zone = local))
        assertEquals(1, progress.freeTacticsSkipsRemaining(at = before, zone = local))

        // Nine o'clock is a new day: the count is whole again.
        assertEquals(5, progress.freeRemaining(TrainingActivity.TACTICS, at = nine, zone = local))
        assertEquals(2, progress.freeTacticsSkipsRemaining(at = nine, zone = local))
        assertEquals(nine, DailyUsage.nextReset(after = before, zone = local))

        progress = progress.recordFreeUse(of = TrainingActivity.TACTICS, at = nine, zone = local)
        assertEquals(4, progress.freeRemaining(TrainingActivity.TACTICS, at = nine, zone = local))
        assertEquals(nextDayNine, DailyUsage.nextReset(after = nine, zone = local))
    }

    @Test
    fun `Progress written before the free tier existed still loads`() {
        val json = """
            {"cards":{},"themes":{},"history":[],"games":[],"rushRecords":[],
             "currentStreak":2,"bestStreak":5,
             "ratings":["tactics",1500,"positional",1400,"endgame",1300]}
        """.trimIndent()
        val progress = TrainingProgress.decode(json)

        assertEquals(1500, progress.rating(TrainingMode.TACTICS))
        assertEquals(5, progress.freeRemaining(TrainingActivity.TACTICS, at = noon, zone = zone))
        assertEquals(2, progress.freeTacticsSkipsRemaining(at = noon, zone = zone))
    }

    @Test
    fun `Usage written before skip limits existed still decodes`() {
        val usage = swiftJson.decodeFromString(DailyUsage.serializer(), """{"day":0}""")
        assertEquals(2, usage.remainingTacticsSkips(at = usage.day, zone = zone))

        val spent = usage
            .record(TrainingActivity.TACTICS, at = usage.day, zone = zone)
            .record(TrainingActivity.RUSH, at = usage.day, zone = zone)
        val roundTripped = swiftJson.decodeFromString(
            DailyUsage.serializer(),
            swiftJson.encodeToString(DailyUsage.serializer(), spent),
        )
        assertEquals(spent, roundTripped)
    }
}
