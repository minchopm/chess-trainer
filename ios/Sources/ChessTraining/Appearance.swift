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

    public init(pieces: PieceSet = .carved, board: BoardStyle = .wood, soundsOn: Bool = true) {
        self.pieces = pieces
        self.board = board
        self.soundsOn = soundsOn
    }
}

public enum PieceSet: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Photographs of a carved set.
    case carved
    /// The Unicode chess glyphs this app started with: flat, light, and legible
    /// at any size, which is a real advantage on a small phone.
    case glyph

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .carved: L.t("appearance.pieces.carved", "Carved")
        case .glyph: L.t("appearance.pieces.glyph", "Classic")
        }
    }
}

public enum BoardStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Photographed maple and walnut.
    case wood
    /// The painted brown board this app used before.
    case classic
    /// The green most online boards use — the easiest on the eyes for long
    /// sessions, which is why it became the default everywhere else.
    case forest
    case ocean
    case slate

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .wood: L.t("appearance.board.wood", "Walnut")
        case .classic: L.t("appearance.board.classic", "Amber")
        case .forest: L.t("appearance.board.forest", "Forest")
        case .ocean: L.t("appearance.board.ocean", "Ocean")
        case .slate: L.t("appearance.board.slate", "Slate")
        }
    }

    /// Squares as red, green, blue in 0...1, light first. The wood style paints
    /// these underneath its photographs, so a tile that fails to load still
    /// leaves a board rather than a hole.
    public var squares: (light: (Double, Double, Double), dark: (Double, Double, Double)) {
        switch self {
        case .wood: ((0.784, 0.580, 0.365), (0.314, 0.184, 0.114))
        case .classic: ((0.922, 0.894, 0.827), (0.604, 0.498, 0.373))
        case .forest: ((0.922, 0.925, 0.816), (0.467, 0.584, 0.337))
        case .ocean: ((0.871, 0.890, 0.902), (0.549, 0.635, 0.678))
        case .slate: ((0.804, 0.804, 0.816), (0.353, 0.376, 0.420))
        }
    }

    /// Image names for the textured styles; nil where the colour is the board.
    public var textures: (light: String, dark: String)? {
        self == .wood ? ("wood-light", "wood-dark") : nil
    }
}
