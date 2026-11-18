package com.artesoft.brasspawn.training

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AppearanceTests {
    @Test
    fun `System is the default typeface`() {
        assertEquals(AppTypeface.SYSTEM, Appearance().typeface)
    }

    @Test
    fun `The selected typeface persists`() {
        val appearance = Appearance(typeface = AppTypeface.JET_BRAINS_MONO)
        val decoded = Appearance.decode(appearance.encode())

        assertEquals(AppTypeface.JET_BRAINS_MONO, decoded.typeface)
    }

    @Test
    fun `Legacy appearance data defaults to the system typeface`() {
        val json = """{"pieces":"ebony","board":"wood","soundsOn":true,"volume":0.7,"dimension":"flat","carving":"banded"}"""
        val decoded = Appearance.decode(json)

        assertEquals(AppTypeface.SYSTEM, decoded.typeface)
        assertEquals(BoardStyle.WOOD, decoded.board)
        assertEquals(LightTone.BOXWOOD, decoded.lightTone)
        assertTrue(decoded.showsCoordinates)
        assertTrue(decoded.showsCompletionSummary)
    }

    @Test
    fun `Unknown enum values from a newer build fall back to defaults`() {
        val json = """{"typeface":"futura","board":"marble","pieces":"ivory","dimension":"holographic","carving":"gothic","lightTone":"amber","engine":"alphazero"}"""
        val decoded = Appearance.decode(json)

        assertEquals(Appearance(), decoded)
        assertNull(Appearance.decodeOrNull("not json at all"))
    }

    @Test
    fun `Palettes, sets and carvings report their visual properties`() {
        assertEquals(0xFFFFFFFF.toInt(), Rgb(1.0, 1.0, 1.0).argb)
        assertEquals(0xFF000000.toInt(), Rgb(0.0, 0.0, 0.0).argb)

        assertNotNull(BoardStyle.WOOD.textures)
        assertNull(BoardStyle.LAMPLIGHT.textures)
        assertTrue(PieceSet.GLYPH.usesGlyphs)
        assertFalse(PieceSet.EBONY.usesGlyphs)
        assertEquals("emerald", PieceSet.EMERALD.darkArtPrefix)
        assertEquals("black", PieceSet.EBONY.darkArtPrefix)
        assertTrue(BoardDimension.DIMENSIONAL.isDimensional)
        assertFalse(BoardDimension.FLAT.isDimensional)

        for (style in BoardStyle.entries) assertEquals(style, BoardStyle.fromRawValue(style.rawValue))
        for (tone in LightTone.entries) {
            assertEquals(tone, LightTone.fromRawValue(tone.rawValue))
            assertTrue(tone.shading.lift >= 0.0)
        }
        for (carving in Carving.entries) assertEquals(carving, Carving.fromRawValue(carving.rawValue))
        for (set in PieceSet.entries) assertEquals(set, PieceSet.fromRawValue(set.rawValue))
        for (face in AppTypeface.entries) assertEquals(face, AppTypeface.fromRawValue(face.rawValue))
    }
}

class EngineChoiceTests {
    @Test
    fun `Stockfish is the default engine`() {
        assertEquals(EngineChoice.STOCKFISH, Appearance().engine)
    }

    @Test
    fun `The selected engine persists`() {
        val appearance = Appearance(engine = EngineChoice.RECKLESS)
        val decoded = Appearance.decode(appearance.encode())

        assertEquals(EngineChoice.RECKLESS, decoded.engine)
    }

    /**
     * Somebody who already has the app has a saved file with no engine in it,
     * and they have been playing Stockfish's ladder. Loading that as anything
     * else would change their opponent on update without asking.
     */
    @Test
    fun `A save from before the choice existed still loads, as Stockfish`() {
        val json = """{"pieces":"ebony","board":"wood","soundsOn":true,"volume":0.7,"dimension":"flat","carving":"banded","showsCoordinates":true}"""
        val decoded = Appearance.decode(json)

        assertEquals(EngineChoice.STOCKFISH, decoded.engine)
        assertTrue(decoded.showsOnline, "shown online unless they say otherwise")
    }

    @Test
    fun `Hiding from the online list is remembered`() {
        val appearance = Appearance()
        assertTrue(appearance.showsOnline)
        val decoded = Appearance.decode(appearance.copy(showsOnline = false).encode())
        assertFalse(decoded.showsOnline)
    }

    /** The one difference between the two that the player can see. */
    @Test
    fun `Only Stockfish claims to limit its strength`() {
        assertTrue(EngineChoice.STOCKFISH.limitsStrength)
        assertFalse(EngineChoice.RECKLESS.limitsStrength)
        assertEquals("Stockfish", EngineChoice.STOCKFISH.displayName)
        assertEquals("Reckless", EngineChoice.RECKLESS.displayName)
        assertTrue(EngineChoice.STOCKFISH.summary.isNotEmpty())
        assertTrue(EngineChoice.RECKLESS.summary.isNotEmpty())
    }
}
