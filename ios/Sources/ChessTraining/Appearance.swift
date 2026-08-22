import Foundation

/// The type family used by the application's interface text.
///
/// Sizes and weights still communicate hierarchy, but mixing an editorial
/// heading with a monospaced button made individual screens feel assembled
/// from different systems. The player now chooses one family for the whole
/// application, with the platform face as the intentionally quiet default.
/// The three branded text groups on the main menu deliberately keep their
/// original families and are not controlled by this preference.
public enum AppTypeface: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case cormorantGaramond
    case jetBrainsMono

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .system:
            L.t("settings.font.system", "System")
        case .cormorantGaramond:
            "Cormorant Garamond"
        case .jetBrainsMono:
            "JetBrains Mono"
        }
    }

}

/// Which engine plays and grades.
///
/// Two engines ship, and they are not interchangeable in one respect the player
/// can see: Stockfish has `UCI_Elo` and can be asked to play like a 1400,
/// Reckless has no strength limiter at all and plays its best or not at all. So
/// choosing Reckless narrows the opponent ladder to a single rung, and the
/// settings say so rather than offering ratings it cannot hit.
///
/// This lives here rather than in ChessEngine because ChessTraining does not
/// depend on the engine module — and should not, since the whole point of that
/// separation is that the trainer can be tested without an engine.
public enum EngineChoice: String, Codable, CaseIterable, Identifiable, Sendable {
    case stockfish
    case reckless

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .stockfish: "Stockfish"
        case .reckless: "Reckless"
        }
    }

    /// Whether this engine can play at a requested rating. Mirrors
    /// `EngineCapabilities.limitsStrength`, which is the authority — this copy
    /// exists only so the settings can describe the choice before an engine has
    /// been built.
    public var limitsStrength: Bool { self == .stockfish }

    public var summary: String {
        switch self {
        case .stockfish:
            L.t("settings.engine.stockfishSummary",
                "The strongest engine there is, and the only one here that can play down to a rating.")
        case .reckless:
            L.t("settings.engine.recklessSummary",
                "A different opponent with its own taste in positions. It has no strength limiter, so it plays at full strength only.")
        }
    }
}

/// Which pieces and which board.
///
/// Taste, not settings: nobody needs to be taught what a walnut board looks
/// like, and the only way to find out which one somebody likes is to let them
/// look. Kept with the rest of the player's data so it survives an update and
/// travels with a device backup.
public struct Appearance: Codable, Equatable, Sendable {
    public var typeface: AppTypeface
    public var pieces: PieceSet
    public var board: BoardStyle
    public var soundsOn: Bool
    /// 0...1. The settings mute control moves this to zero and restores the
    /// previous non-zero value when sound is turned back on.
    public var volume: Double
    /// Flat or in the round. The flat board is the one to play a five-minute
    /// game on and the round one is the one to look at, so this is a choice
    /// rather than a migration: neither replaces the other.
    public var dimension: BoardDimension
    /// Which set stands on the round board.
    public var carving: Carving
    /// How the light side is shaded — the white pieces and the pale squares.
    public var lightTone: LightTone
    /// Files and ranks written round the edge of the board.
    ///
    /// On by default: this is a trainer, and every puzzle, every coach note and
    /// every game in the library names its squares. Somebody who has to count
    /// along the rank to find e4 is spending their attention on arithmetic.
    public var showsCoordinates: Bool
    /// Which engine plays, grades and labels. See `EngineChoice`.
    public var engine: EngineChoice

    public init(
        typeface: AppTypeface = .system,
        pieces: PieceSet = .ebony,
        board: BoardStyle = .wood,
        soundsOn: Bool = true,
        volume: Double = 0.7,
        dimension: BoardDimension = .flat,
        carving: Carving = .banded,
        lightTone: LightTone = .boxwood,
        showsCoordinates: Bool = true,
        engine: EngineChoice = .stockfish
    ) {
        self.typeface = typeface
        self.pieces = pieces
        self.board = board
        self.soundsOn = soundsOn
        self.volume = volume
        self.dimension = dimension
        self.carving = carving
        self.lightTone = lightTone
        self.showsCoordinates = showsCoordinates
        self.engine = engine
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        typeface = try container.decodeIfPresent(AppTypeface.self, forKey: .typeface) ?? .system
        pieces = try container.decodeIfPresent(PieceSet.self, forKey: .pieces) ?? .ebony
        board = try container.decodeIfPresent(BoardStyle.self, forKey: .board) ?? .wood
        soundsOn = try container.decodeIfPresent(Bool.self, forKey: .soundsOn) ?? true
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0.7
        dimension = try container.decodeIfPresent(BoardDimension.self, forKey: .dimension) ?? .flat
        carving = try container.decodeIfPresent(Carving.self, forKey: .carving) ?? .banded
        lightTone = try container.decodeIfPresent(LightTone.self, forKey: .lightTone) ?? .boxwood
        showsCoordinates = try container.decodeIfPresent(Bool.self, forKey: .showsCoordinates) ?? true
        // Stockfish for anybody who already had the app: the ladder they were
        // playing against is Stockfish's, and a silent change of opponent on
        // update is not a thing to do to somebody mid-way through a game.
        engine = try container.decodeIfPresent(EngineChoice.self, forKey: .engine) ?? .stockfish
    }
}

/// How the light side is shaded, from snow through the boxwood the set is
/// photographed in to a pale blue.
///
/// The dark side has had four stains to choose from since the set was
/// photographed, and the light side has had one — which is how a real set is
/// made, and is no help at all to somebody who finds ivory-on-cream hard to
/// read. This shifts the whole light side together, pieces and squares: shading
/// only one of them would trade one pair that sits too close for another.
///
/// It is a tint over the photographs rather than a second set of them. Boxwood
/// is very nearly white already, so there is room to lift it to snow and room
/// to cool it towards blue, and nowhere near enough to make it a dark side.
public enum LightTone: String, Codable, CaseIterable, Identifiable, Sendable {
    case snow, chalk, boxwood, frost, mist

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .snow: L.t("appearance.tone.snow", "Snow")
        case .chalk: L.t("appearance.tone.chalk", "Chalk")
        case .boxwood: L.t("appearance.tone.boxwood", "Boxwood")
        case .frost: L.t("appearance.tone.frost", "Frost")
        case .mist: L.t("appearance.tone.mist", "Mist")
        }
    }

    /// What to multiply the light side by, and how much to lift it afterwards.
    ///
    /// Multiplying alone can only darken, and half of what is wanted here is
    /// *whiter* than the photograph — so the lift is what gets there, and the
    /// multiplier is what turns it blue on the way back.
    public var shading: (multiply: (Double, Double, Double), lift: Double) {
        switch self {
        case .snow: ((1.00, 1.00, 1.00), 0.10)
        case .chalk: ((1.00, 0.995, 0.985), 0.05)
        case .boxwood: ((1.00, 1.00, 1.00), 0.00)
        // Boxwood is a warm photograph — its blue channel is its lowest — so
        // the cool end of the range is reached by taking red and green down,
        // not by adding blue there is no headroom for.
        case .frost: ((0.900, 0.960, 1.00), 0.05)
        case .mist: ((0.800, 0.900, 1.00), 0.10)
        }
    }
}

public enum BoardDimension: String, Codable, CaseIterable, Identifiable, Sendable {
    case flat, dimensional
    public var id: String { rawValue }
    public var isDimensional: Bool { self == .dimensional }
}

/// The two turned sets.
public enum Carving: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Boxwood and ebony, nothing on them but the turning.
    case plain
    /// The same turning with brass bands and brass finials — the set the flat
    /// board uses, which is a photographed Staunton with gilt collars.
    case banded
    public var id: String { rawValue }
}

public enum PieceSet: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Photographs of a carved set. Real sets are stained rather than painted,
    /// so the dark side comes in the colours a wood stain actually produces —
    /// ebony, and the green, blue and red that tournament sets have been dyed
    /// for a century — while the light side stays boxwood in all of them.
    case ebony, emerald, sapphire, claret
    /// The Unicode chess glyphs this app started with: flat, light, and legible
    /// at any size, which is a real advantage on a small phone.
    case glyph

    public var id: String { rawValue }

    /// The image prefix for the dark side. The light side is always boxwood.
    public var darkArtPrefix: String {
        switch self {
        case .ebony: "black"
        case .emerald: "emerald"
        case .sapphire: "sapphire"
        case .claret: "claret"
        case .glyph: "black"
        }
    }

    public var usesGlyphs: Bool { self == .glyph }

    public var name: String {
        switch self {
        case .ebony: L.t("appearance.pieces.ebony", "Ivory & ebony")
        case .emerald: L.t("appearance.pieces.emerald", "Ivory & emerald")
        case .sapphire: L.t("appearance.pieces.sapphire", "Ivory & sapphire")
        case .claret: L.t("appearance.pieces.claret", "Ivory & claret")
        case .glyph: L.t("appearance.pieces.glyph", "Classic")
        }
    }
}

public enum BoardStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Photographed maple and walnut.
    case wood
    case amber, forest, ocean, ivory, rose, sand, slate

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .wood: L.t("appearance.board.wood", "Walnut")
        case .amber: L.t("appearance.board.classic", "Amber")
        case .forest: L.t("appearance.board.forest", "Forest")
        case .ocean: L.t("appearance.board.ocean", "Ocean")
        case .ivory: L.t("appearance.board.ivory", "Porcelain")
        case .rose: L.t("appearance.board.rose", "Rosewater")
        case .sand: L.t("appearance.board.sand", "Sand")
        case .slate: L.t("appearance.board.slate", "Slate")
        }
    }

    /// Squares as red, green, blue in 0...1, light first.
    ///
    /// Every dark square here is lighter than a board usually is, and that is
    /// deliberate: a dark set on a dark square is two dark shapes in the same
    /// place, and no amount of shadow fixes it. The contrast that matters on a
    /// chessboard is between the pieces and the squares, not between the two
    /// colours of square.
    public var squares: (light: (Double, Double, Double), dark: (Double, Double, Double)) {
        switch self {
        case .wood: ((0.796, 0.608, 0.400), (0.424, 0.263, 0.173))
        case .amber: ((0.945, 0.918, 0.859), (0.706, 0.596, 0.455))
        case .forest: ((0.922, 0.925, 0.816), (0.545, 0.663, 0.435))
        case .ocean: ((0.871, 0.906, 0.925), (0.573, 0.694, 0.769))
        case .ivory: ((1.000, 1.000, 1.000), (0.788, 0.812, 0.847))
        case .rose: ((0.961, 0.902, 0.898), (0.796, 0.588, 0.596))
        case .sand: ((0.945, 0.894, 0.796), (0.804, 0.694, 0.514))
        case .slate: ((0.859, 0.875, 0.898), (0.545, 0.588, 0.643))
        }
    }

    /// Image names for the textured styles; nil where the colour is the board.
    public var textures: (light: String, dark: String)? {
        self == .wood ? ("wood-light", "wood-dark") : nil
    }
}
