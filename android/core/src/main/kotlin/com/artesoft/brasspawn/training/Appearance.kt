package com.artesoft.brasspawn.training

import com.artesoft.brasspawn.match.L
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException

/**
 * The type family used by the application's interface text.
 *
 * Sizes and weights still communicate hierarchy, but mixing an editorial
 * heading with a monospaced button made individual screens feel assembled
 * from different systems. The player now chooses one family for the whole
 * application, with the platform face as the intentionally quiet default.
 * The three branded text groups on the main menu deliberately keep their
 * original families and are not controlled by this preference.
 */
@Serializable
enum class AppTypeface(val rawValue: String) {
    @SerialName("system") SYSTEM("system"),
    @SerialName("cormorantGaramond") CORMORANT_GARAMOND("cormorantGaramond"),
    @SerialName("jetBrainsMono") JET_BRAINS_MONO("jetBrainsMono");

    val id: String get() = rawValue

    /** `name` in the Swift code; a Kotlin enum already has a `name`, and it is the constant's. */
    val displayName: String
        get() = when (this) {
            SYSTEM -> L.t("settings.font.system", "System")
            CORMORANT_GARAMOND -> "Cormorant Garamond"
            JET_BRAINS_MONO -> "JetBrains Mono"
        }

    companion object {
        fun fromRawValue(rawValue: String): AppTypeface? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

/**
 * Which engine plays and grades.
 *
 * Two engines ship, and they are not interchangeable in one respect the player
 * can see: Stockfish has `UCI_Elo` and can be asked to play like a 1400,
 * Reckless has no strength limiter at all and plays its best or not at all. So
 * choosing Reckless narrows the opponent ladder to a single rung, and the
 * settings say so rather than offering ratings it cannot hit.
 *
 * This lives here rather than with the engine because the training code does
 * not depend on the engine — and should not, since the whole point of that
 * separation is that the trainer can be tested without an engine.
 */
@Serializable
enum class EngineChoice(val rawValue: String) {
    @SerialName("stockfish") STOCKFISH("stockfish"),
    @SerialName("reckless") RECKLESS("reckless");

    val id: String get() = rawValue

    val displayName: String
        get() = when (this) {
            STOCKFISH -> "Stockfish"
            RECKLESS -> "Reckless"
        }

    /**
     * Whether this engine can play at a requested rating. Mirrors the engine's
     * own account of itself, which is the authority — this copy exists only so
     * the settings can describe the choice before an engine has been built.
     */
    val limitsStrength: Boolean get() = this == STOCKFISH

    val summary: String
        get() = when (this) {
            STOCKFISH ->
                L.t(
                    "settings.engine.stockfishSummary",
                    "The strongest engine there is, and the only one here that can play down to a rating.",
                )
            RECKLESS ->
                L.t(
                    "settings.engine.recklessSummary",
                    "A different opponent with its own taste in positions. It has no strength limiter, so it plays at full strength only.",
                )
        }

    companion object {
        fun fromRawValue(rawValue: String): EngineChoice? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

/**
 * Which pieces and which board.
 *
 * Taste, not settings: nobody needs to be taught what a walnut board looks
 * like, and the only way to find out which one somebody likes is to let them
 * look. Kept with the rest of the player's data so it survives an update and
 * travels with a device backup.
 *
 * Every field has a default, and a file that lacks one gets it: a save from
 * before a choice existed loads as the choice that was the only one then.
 */
@Serializable
data class Appearance(
    val typeface: AppTypeface = AppTypeface.SYSTEM,
    val pieces: PieceSet = PieceSet.EBONY,
    val board: BoardStyle = BoardStyle.LAMPLIGHT,
    val soundsOn: Boolean = true,
    /**
     * 0...1. The settings mute control moves this to zero and restores the
     * previous non-zero value when sound is turned back on.
     */
    @Serializable(with = SwiftDoubleSerializer::class) val volume: Double = 0.7,
    /**
     * Flat or in the round. The flat board is the one to play a five-minute
     * game on and the round one is the one to look at, so this is a choice
     * rather than a migration: neither replaces the other.
     */
    val dimension: BoardDimension = BoardDimension.FLAT,
    /** Which set stands on the round board. */
    val carving: Carving = Carving.BANDED,
    /** How the light side is shaded — the white pieces and the pale squares. */
    val lightTone: LightTone = LightTone.BOXWOOD,
    /**
     * Files and ranks written round the edge of the board.
     *
     * On by default: this is a trainer, and every puzzle, every coach note and
     * every game in the library names its squares. Somebody who has to count
     * along the rank to find e4 is spending their attention on arithmetic.
     */
    val showsCoordinates: Boolean = true,
    /**
     * Which engine plays, grades and labels. See `EngineChoice`.
     *
     * Stockfish for anybody who already had the app: the ladder they were
     * playing against is Stockfish's, and a silent change of opponent on
     * update is not a thing to do to somebody mid-way through a game.
     */
    val engine: EngineChoice = EngineChoice.STOCKFISH,
    /**
     * Whether a solved puzzle stops to be congratulated.
     *
     * On by default, and turned off from the congratulation itself. Somebody
     * working through puzzles at speed is interrupted by a panel telling them
     * what they already know from the board, and the interruption costs more
     * the faster they are going. A puzzle that went wrong still stops: there
     * the panel is the only place the reason is written down.
     */
    val showsCompletionSummary: Boolean = true,
    /**
     * Whether other players can see that this one is online — here, looking
     * for a game, or in one — while the app is on screen. On by default, as
     * on any chess site: it is what lets an invitation reach somebody who is
     * actually there to play.
     */
    val showsOnline: Boolean = true,
) {
    /** The appearance as JSON text, in the shape Swift's `JSONEncoder` gives it. */
    fun encode(): String = swiftJson.encodeToString(serializer(), this)

    companion object {
        /** Reads what [encode] wrote, or the iPhone app did. Throws `SerializationException` for text that is neither. */
        fun decode(text: String): Appearance = swiftJson.decodeFromString(serializer(), text)

        /** [decode], or null when the text cannot be read. */
        fun decodeOrNull(text: String): Appearance? =
            try {
                decode(text)
            } catch (_: SerializationException) {
                null
            } catch (_: IllegalArgumentException) {
                null
            }
    }
}

/**
 * A colour as the Swift source states it: red, green and blue, each 0...1.
 * Plain numbers, so the app can make its own colours out of them.
 */
data class Rgb(val red: Double, val green: Double, val blue: Double) {
    /** The same colour, opaque, as `0xAARRGGBB` — what `android.graphics.Color` and Compose's `Color(Int)` take. */
    val argb: Int
        get() {
            fun channel(value: Double): Int = swiftRounded(value.coerceIn(0.0, 1.0) * 255)
            return (0xFF shl 24) or (channel(red) shl 16) or (channel(green) shl 8) or channel(blue)
        }
}

/**
 * How the light side is shaded, from snow through the boxwood the set is
 * photographed in to a pale blue.
 *
 * The dark side has had four stains to choose from since the set was
 * photographed, and the light side has had one — which is how a real set is
 * made, and is no help at all to somebody who finds ivory-on-cream hard to
 * read. This shifts the whole light side together, pieces and squares: shading
 * only one of them would trade one pair that sits too close for another.
 *
 * It is a tint over the photographs rather than a second set of them. Boxwood
 * is very nearly white already, so there is room to lift it to snow and room
 * to cool it towards blue, and nowhere near enough to make it a dark side.
 */
@Serializable
enum class LightTone(val rawValue: String) {
    @SerialName("snow") SNOW("snow"),
    @SerialName("chalk") CHALK("chalk"),
    @SerialName("boxwood") BOXWOOD("boxwood"),
    @SerialName("frost") FROST("frost"),
    @SerialName("mist") MIST("mist");

    val id: String get() = rawValue

    val displayName: String
        get() = when (this) {
            SNOW -> L.t("appearance.tone.snow", "Snow")
            CHALK -> L.t("appearance.tone.chalk", "Chalk")
            BOXWOOD -> L.t("appearance.tone.boxwood", "Boxwood")
            FROST -> L.t("appearance.tone.frost", "Frost")
            MIST -> L.t("appearance.tone.mist", "Mist")
        }

    /** What to multiply each channel of the light side by, and how much to add to each afterwards. */
    data class Shading(val multiply: Rgb, val lift: Double)

    /**
     * What to multiply the light side by, and how much to lift it afterwards.
     *
     * Multiplying alone can only darken, and half of what is wanted here is
     * *whiter* than the photograph — so the lift is what gets there, and the
     * multiplier is what turns it blue on the way back.
     */
    val shading: Shading
        get() = when (this) {
            SNOW -> Shading(Rgb(1.00, 1.00, 1.00), 0.10)
            CHALK -> Shading(Rgb(1.00, 0.995, 0.985), 0.05)
            BOXWOOD -> Shading(Rgb(1.00, 1.00, 1.00), 0.00)
            // Boxwood is a warm photograph — its blue channel is its lowest — so
            // the cool end of the range is reached by taking red and green down,
            // not by adding blue there is no headroom for.
            FROST -> Shading(Rgb(0.900, 0.960, 1.00), 0.05)
            MIST -> Shading(Rgb(0.800, 0.900, 1.00), 0.10)
        }

    companion object {
        fun fromRawValue(rawValue: String): LightTone? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

@Serializable
enum class BoardDimension(val rawValue: String) {
    @SerialName("flat") FLAT("flat"),
    @SerialName("dimensional") DIMENSIONAL("dimensional");

    val id: String get() = rawValue
    val isDimensional: Boolean get() = this == DIMENSIONAL

    companion object {
        fun fromRawValue(rawValue: String): BoardDimension? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

/** The turned sets, and the board each is shown on. */
@Serializable
enum class Carving(val rawValue: String) {
    /** Boxwood and ebony, nothing on them but the turning. */
    @SerialName("plain") PLAIN("plain"),

    /**
     * The same turning with brass bands and brass finials — the set the flat
     * board uses, which is a photographed Staunton with gilt collars.
     */
    @SerialName("banded") BANDED("banded"),

    /**
     * A club Staunton in boxwood and walnut, cut to a real set's proportions,
     * on a framed maple board on a table under a lamp.
     *
     * This one brings its own board, which the other two do not: they share
     * the lit black room the app opens on. A set and a board are one object in
     * a photograph and these two are not interchangeable — the walnut set in
     * the black room reads as a different game, and the banded set's brass has
     * nothing to catch under a domestic lamp. So the choice is of a look
     * rather than of a set, and there is one control rather than two.
     */
    @SerialName("parlour") PARLOUR("parlour"),

    /** Tall Staunton pieces in brass and dark bronze, with circular bases. */
    @SerialName("bronze") BRONZE("bronze");

    val id: String get() = rawValue

    companion object {
        fun fromRawValue(rawValue: String): Carving? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

@Serializable
enum class PieceSet(val rawValue: String) {
    // Photographs of a carved set. Real sets are stained rather than painted,
    // so the dark side comes in the colours a wood stain actually produces —
    // ebony, and the green, blue and red that tournament sets have been dyed
    // for a century — while the light side stays boxwood in all of them.
    @SerialName("ebony") EBONY("ebony"),
    @SerialName("emerald") EMERALD("emerald"),
    @SerialName("sapphire") SAPPHIRE("sapphire"),
    @SerialName("claret") CLARET("claret"),

    /**
     * The Unicode chess glyphs this app started with: flat, light, and legible
     * at any size, which is a real advantage on a small phone.
     */
    @SerialName("glyph") GLYPH("glyph");

    val id: String get() = rawValue

    /** The image prefix for the dark side. The light side is always boxwood. */
    val darkArtPrefix: String
        get() = when (this) {
            EBONY -> "black"
            EMERALD -> "emerald"
            SAPPHIRE -> "sapphire"
            CLARET -> "claret"
            GLYPH -> "black"
        }

    val usesGlyphs: Boolean get() = this == GLYPH

    val displayName: String
        get() = when (this) {
            EBONY -> L.t("appearance.pieces.ebony", "Ivory & ebony")
            EMERALD -> L.t("appearance.pieces.emerald", "Ivory & emerald")
            SAPPHIRE -> L.t("appearance.pieces.sapphire", "Ivory & sapphire")
            CLARET -> L.t("appearance.pieces.claret", "Ivory & claret")
            GLYPH -> L.t("appearance.pieces.glyph", "Classic")
        }

    companion object {
        fun fromRawValue(rawValue: String): PieceSet? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

@Serializable
enum class BoardStyle(val rawValue: String) {
    /** Photographed maple and walnut. */
    @SerialName("wood") WOOD("wood"),

    /**
     * The walnut as the lamp sees it.
     *
     * The round board is lit, and light takes the colour out of wood: beside
     * it the flat walnut reads as orange. These are the numbers measured off
     * the lit board itself, so the two dimensions are the same board seen two
     * ways rather than two different boards.
     */
    @SerialName("lamplight") LAMPLIGHT("lamplight"),
    @SerialName("amber") AMBER("amber"),
    @SerialName("forest") FOREST("forest"),
    @SerialName("ocean") OCEAN("ocean"),
    @SerialName("ivory") IVORY("ivory"),
    @SerialName("rose") ROSE("rose"),
    @SerialName("sand") SAND("sand"),
    @SerialName("slate") SLATE("slate");

    val id: String get() = rawValue

    val displayName: String
        get() = when (this) {
            WOOD -> L.t("appearance.board.wood", "Walnut")
            LAMPLIGHT -> L.t("appearance.board.lamplight", "Lamplight")
            AMBER -> L.t("appearance.board.classic", "Amber")
            FOREST -> L.t("appearance.board.forest", "Forest")
            OCEAN -> L.t("appearance.board.ocean", "Ocean")
            IVORY -> L.t("appearance.board.ivory", "Porcelain")
            ROSE -> L.t("appearance.board.rose", "Rosewater")
            SAND -> L.t("appearance.board.sand", "Sand")
            SLATE -> L.t("appearance.board.slate", "Slate")
        }

    /** The two colours of square. */
    data class Squares(val light: Rgb, val dark: Rgb)

    /** Image names for a textured board. */
    data class Textures(val light: String, val dark: String)

    /**
     * Squares as red, green, blue in 0...1, light first.
     *
     * Every dark square here is lighter than a board usually is, and that is
     * deliberate: a dark set on a dark square is two dark shapes in the same
     * place, and no amount of shadow fixes it. The contrast that matters on a
     * chessboard is between the pieces and the squares, not between the two
     * colours of square.
     */
    val squares: Squares
        get() = when (this) {
            WOOD -> Squares(Rgb(0.796, 0.608, 0.400), Rgb(0.424, 0.263, 0.173))
            LAMPLIGHT -> Squares(Rgb(0.878, 0.733, 0.557), Rgb(0.502, 0.408, 0.302))
            AMBER -> Squares(Rgb(0.945, 0.918, 0.859), Rgb(0.706, 0.596, 0.455))
            FOREST -> Squares(Rgb(0.922, 0.925, 0.816), Rgb(0.545, 0.663, 0.435))
            OCEAN -> Squares(Rgb(0.871, 0.906, 0.925), Rgb(0.573, 0.694, 0.769))
            IVORY -> Squares(Rgb(1.000, 1.000, 1.000), Rgb(0.788, 0.812, 0.847))
            ROSE -> Squares(Rgb(0.961, 0.902, 0.898), Rgb(0.796, 0.588, 0.596))
            SAND -> Squares(Rgb(0.945, 0.894, 0.796), Rgb(0.804, 0.694, 0.514))
            SLATE -> Squares(Rgb(0.859, 0.875, 0.898), Rgb(0.545, 0.588, 0.643))
        }

    /** Image names for the textured styles; null where the colour is the board. */
    val textures: Textures?
        get() = if (this == WOOD) Textures("wood-light", "wood-dark") else null

    companion object {
        fun fromRawValue(rawValue: String): BoardStyle? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
