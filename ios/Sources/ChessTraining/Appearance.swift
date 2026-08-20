import Foundation

/// Which pieces and which board.
///
/// Taste, not settings: nobody needs to be taught what a walnut board looks
/// like, and the only way to find out which one somebody likes is to let them
/// look. Kept with the rest of the player's data so it survives an update and
/// travels with a device backup.
public struct Appearance: Codable, Equatable, Sendable {
    public var pieces: PieceSet
    public var board: BoardStyle
    public var soundsOn: Bool
    /// 0...1. Kept apart from the on/off switch: turning the sound down to
    /// nothing and turning it off are different intentions, and a player who
    /// does the first should not lose their volume when they do the second.
    public var volume: Double
    /// Flat or in the round. The flat board is the one to play a five-minute
    /// game on and the round one is the one to look at, so this is a choice
    /// rather than a migration: neither replaces the other.
    public var dimension: BoardDimension
    /// Which set stands on the round board.
    public var carving: Carving

    public init(
        pieces: PieceSet = .ebony,
        board: BoardStyle = .wood,
        soundsOn: Bool = true,
        volume: Double = 0.7,
        dimension: BoardDimension = .flat,
        carving: Carving = .banded
    ) {
        self.pieces = pieces
        self.board = board
        self.soundsOn = soundsOn
        self.volume = volume
        self.dimension = dimension
        self.carving = carving
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pieces = try container.decodeIfPresent(PieceSet.self, forKey: .pieces) ?? .ebony
        board = try container.decodeIfPresent(BoardStyle.self, forKey: .board) ?? .wood
        soundsOn = try container.decodeIfPresent(Bool.self, forKey: .soundsOn) ?? true
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0.7
        dimension = try container.decodeIfPresent(BoardDimension.self, forKey: .dimension) ?? .flat
        carving = try container.decodeIfPresent(Carving.self, forKey: .carving) ?? .banded
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
