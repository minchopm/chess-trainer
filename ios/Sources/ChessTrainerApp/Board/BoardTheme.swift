import ChessCore
import ChessTraining
import SwiftUI

/// Colours and metrics for the board. Kept in one place so the whole app can be
/// re-skinned without hunting through view code.
public struct BoardTheme: Sendable {
    public var lightSquare: Color
    public var darkSquare: Color
    public var lastMove: Color
    public var selection: Color
    public var check: Color
    public var hint: Color
    public var coachArrow: Color
    /// Moves you have queued while it is not your turn.
    public var premove: Color
    /// Square images, for the boards that are photographs rather than paint.
    public var textures: Textures?

    public struct Textures: Sendable, Equatable {
        public let light: String
        public let dark: String
    }

    public static var standard: BoardTheme { BoardTheme(style: .wood) }

    /// Highlights are chosen per board, not once: the yellow that reads as
    /// "last move" on maple disappears on the green board, and the blue that
    /// reads as "selected" on slate is invisible on ocean.
    public init(style: BoardStyle) {
        let light = style.squares.light
        let dark = style.squares.dark
        lightSquare = Color(red: light.0, green: light.1, blue: light.2)
        darkSquare = Color(red: dark.0, green: dark.1, blue: dark.2)
        textures = style.textures.map { Textures(light: $0.light, dark: $0.dark) }

        // Highlights are chosen per board, not once: the yellow that reads as
        // "last move" on maple disappears on the green board, and the blue
        // that reads as "selected" on slate is invisible on ocean.
        switch style {
        case .wood, .amber, .sand:
            lastMove = Color(red: 1.0, green: 0.839, blue: 0.361).opacity(0.5)
            selection = Color(red: 0.20, green: 0.48, blue: 0.85).opacity(0.42)
        case .forest:
            lastMove = Color(red: 0.99, green: 0.93, blue: 0.35).opacity(0.55)
            selection = Color(red: 0.16, green: 0.42, blue: 0.82).opacity(0.42)
        case .ocean, .slate, .ivory:
            lastMove = Color(red: 0.99, green: 0.72, blue: 0.20).opacity(0.5)
            selection = Color(red: 0.10, green: 0.40, blue: 0.78).opacity(0.42)
        case .rose:
            lastMove = Color(red: 0.98, green: 0.80, blue: 0.30).opacity(0.55)
            selection = Color(red: 0.40, green: 0.30, blue: 0.75).opacity(0.40)
        }
        check = Color(red: 0.851, green: 0.439, blue: 0.373)
        hint = Color.black.opacity(0.28)
        coachArrow = Color(red: 0.424, green: 0.749, blue: 0.451)
        premove = Color(red: 0.357, green: 0.608, blue: 0.835).opacity(0.42)
    }
}

/// Where a piece image comes from.
///
/// The pieces are photographs of a carved set rather than the Unicode glyphs
/// this app used to draw. A glyph is a letter: one flat colour, at the mercy of
/// whichever font the system feels like using, and — as this project found out
/// the hard way — liable to be rendered as a colour emoji that ignores the
/// colour asked for. An image is the piece somebody actually sculpted.
enum PieceArt {
    /// Every piece is drawn on the same square canvas with the same baseline,
    /// so a king comes out taller than a pawn without anything here scaling
    /// them relative to each other. The light side is boxwood whichever set is
    /// chosen; only the dark side is stained.
    static func name(for piece: Piece, set: PieceSet) -> String {
        name(for: piece.color, piece.kind, set: set)
    }

    static func name(for color: PieceColor, _ kind: PieceKind, set: PieceSet) -> String {
        let side = color == .white ? "white" : set.darkArtPrefix
        return "\(side)-\(kindName(kind))"
    }

    private static func kindName(_ kind: PieceKind) -> String {
        switch kind {
        case .king: "king"
        case .queen: "queen"
        case .bishop: "bishop"
        case .knight: "knight"
        case .rook: "rook"
        case .pawn: "pawn"
        }
    }
}

/// The flat Unicode set, kept as an alternative to the photographs.
///
/// Only the *solid* glyphs are used, for both colours. Unicode ships two sets —
/// outlined (♙♘♗) meant for white and filled (♟♞♝) meant for black — but they
/// are different characters with different metrics, so a white pawn comes out
/// visibly smaller than a black one. Using one set and colouring it gives both
/// sides identical shapes and weight.
enum PieceGlyph {
    /// Text presentation selector, U+FE0E.
    ///
    /// Without it the pawn is drawn by the colour emoji font, which ignores
    /// foregroundStyle entirely — every white pawn came out solid black, and
    /// the board looked like it held sixteen black pawns.
    private static let textPresentation = "\u{FE0E}"

    static func text(for kind: PieceKind) -> String {
        let glyph: String = switch kind {
        case .king: "♚"
        case .queen: "♛"
        case .rook: "♜"
        case .bishop: "♝"
        case .knight: "♞"
        case .pawn: "♟"
        }
        return glyph + textPresentation
    }

    static func fill(for color: PieceColor) -> Color {
        color == .white ? Color(white: 0.98) : Color(white: 0.10)
    }

    static func rim(for color: PieceColor) -> Color {
        color == .white ? Color(white: 0.10) : Color(white: 0.95)
    }

    /// Eight directions, so the outline is even rather than cross-shaped. A
    /// scaled copy behind the glyph sounds equivalent and is not: it thickens
    /// by a percentage, so a slender bishop is swallowed while a dense queen
    /// gets a hairline.
    static let rimOffsets: [(x: CGFloat, y: CGFloat)] = [
        (1, 0), (-1, 0), (0, 1), (0, -1),
        (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7), (-0.7, -0.7),
    ]
}
