import ChessCore
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

    public static let standard = BoardTheme(
        lightSquare: Color(red: 0.922, green: 0.894, blue: 0.827),
        darkSquare: Color(red: 0.604, green: 0.498, blue: 0.373),
        lastMove: Color(red: 1.0, green: 0.839, blue: 0.361).opacity(0.45),
        selection: Color(red: 0.357, green: 0.608, blue: 0.835).opacity(0.5),
        check: Color(red: 0.851, green: 0.439, blue: 0.373),
        hint: Color.black.opacity(0.28),
        coachArrow: Color(red: 0.424, green: 0.749, blue: 0.451)
    )
}

/// Where a piece glyph comes from.
///
/// Only the *solid* glyphs are used, for both colours. Unicode ships two sets —
/// outlined (♙♘♗) meant for white and filled (♟♞♝) meant for black — but they
/// are different characters with different metrics, so a white pawn comes out
/// visibly smaller than a black one and reads as a faint outline rather than a
/// piece. Using one set and colouring it gives both sides identical shapes and
/// weight; a rim behind each glyph keeps them legible on either square.
enum PieceGlyph {
    static func text(for kind: PieceKind) -> String {
        switch kind {
        case .king: "♚"
        case .queen: "♛"
        case .rook: "♜"
        case .bishop: "♝"
        case .knight: "♞"
        case .pawn: "♟"
        }
    }

    static func text(for piece: Piece) -> String { text(for: piece.kind) }
}
