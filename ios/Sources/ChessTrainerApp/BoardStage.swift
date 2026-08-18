import ChessCore
import ChessEngine
import ChessTraining
import SwiftUI

/// One side's row beside the board: who they are, how strong, and what they
/// have captured.
///
/// The row belongs to a colour and shows the pieces that colour has taken — so
/// the black row fills with white pieces and the white row with black ones, the
/// way a scoresheet reads.
struct PlayerBar: View {
    let name: String
    /// Nil where there is no number to show. Stockfish at full strength has no
    /// meaningful Elo, and inventing one would be worse than leaving it out.
    var rating: Int?
    let color: PieceColor
    let material: MaterialBalance

    var body: some View {
        HStack(spacing: 8) {
            identity
            Spacer(minLength: 6)
            captures
        }
        .frame(maxWidth: .infinity)
    }

    private var identity: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color == .white ? Color(white: 0.94) : Color(white: 0.12))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
                .frame(width: 9, height: 9)
            Text(name)
                .font(.footnote.weight(.medium))
                .lineLimit(1)
            if let rating {
                // Verbatim: a rating is an identifier, not a quantity, and the
                // locale's thousands separator turns 1387 into "1,387".
                Text(verbatim: String(rating))
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .layoutPriority(1)
    }

    /// Past this many, a row is a smear of glyphs that says nothing. It also
    /// stops meaning what it claims: an endgame drill is a constructed
    /// position, not a game that lost thirteen pieces, and drawing them as
    /// captures invents a history the position never had. The lead is the whole
    /// content by then, so only the lead is shown.
    private static let glyphLimit = 8

    private var captures: some View {
        let taken = material.capturedBy(color)
        let lead = material.lead(of: color)
        let glyphs = taken.count <= Self.glyphLimit ? taken : []
        // Eight glyphs at full width crowd a phone; a tighter overlap still
        // reads, because the pieces are grouped by kind.
        let overlap: CGFloat = glyphs.count > 5 ? -5 : -3

        return HStack(spacing: 4) {
            HStack(spacing: overlap) {
                ForEach(Array(glyphs.enumerated()), id: \.offset) { _, kind in
                    Text(PieceGlyph.text(for: kind))
                        .font(.system(size: 15))
                        .foregroundStyle(glyphColor)
                }
            }
            if lead > 0 {
                Text(verbatim: "+\(lead)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
    }

    /// Captured pieces are the opponent's colour. Black glyphs are lifted well
    /// off pure black: on this background a true black piece is a silhouette of
    /// nothing.
    private var glyphColor: Color {
        color == .white ? Color(white: 0.45) : Color(white: 0.92)
    }
}

/// The board with a player row above and below it, and optionally the
/// evaluation bar down its side.
///
/// Sized from a width handed down by `TrainingLayout` rather than from whatever
/// the surrounding stack proposes. A square that negotiates with a VStack ends
/// up as tall as its share of the column instead of as wide as the screen, and
/// the board loses a fifth of its size for no reason a reader could see.
struct BoardStage<Board: View>: View {
    /// Width available to the whole stage, bar and all.
    let width: CGFloat
    let top: PlayerBar
    let bottom: PlayerBar
    var evaluation: EngineScore?
    var showsEvaluation = false
    var orientation: PieceColor = .white
    @ViewBuilder var board: Board

    /// Height the two rows add above and below the board.
    static var chromeHeight: CGFloat { 2 * (barHeight + spacing) }

    private static var barHeight: CGFloat { 22 }
    private static var spacing: CGFloat { 5 }
    private static var evaluationWidth: CGFloat { 14 }
    private static var evaluationGap: CGFloat { 8 }

    private var side: CGFloat {
        max(0, width - (showsEvaluation ? Self.evaluationWidth + Self.evaluationGap : 0))
    }

    var body: some View {
        HStack(spacing: Self.evaluationGap) {
            if showsEvaluation {
                EvaluationBar(score: evaluation, orientation: orientation)
                    .frame(height: side)
            }
            VStack(spacing: Self.spacing) {
                top.frame(width: side, height: Self.barHeight)
                board.frame(width: side, height: side)
                bottom.frame(width: side, height: Self.barHeight)
            }
        }
        .frame(width: width)
    }
}
