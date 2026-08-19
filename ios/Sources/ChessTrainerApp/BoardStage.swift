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
    /// Draws "?" in place of the rating. Guess the Elo hides both ratings until
    /// the guess is in, and an empty space there reads as a bug rather than as
    /// something deliberately withheld.
    var mysteryRating = false
    let color: PieceColor
    let material: MaterialBalance
    /// Set in online play. Nil everywhere else, where there is no clock and the
    /// space belongs to the captures.
    var clock: String?
    var clockIsRunning = false

    var body: some View {
        HStack(spacing: 8) {
            identity
            Spacer(minLength: 6)
            captures
            if let clock { clockPill(clock) }
        }
        .frame(maxWidth: .infinity)
    }

    private func clockPill(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(clockIsRunning ? Color.primary : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                clockIsRunning ? Color.primary.opacity(0.16) : Color.primary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .layoutPriority(1)
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
            } else if mysteryRating {
                Text(verbatim: "?")
                    .font(.footnote.weight(.semibold))
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

        // Grouped by kind, with a wider gap between groups than inside one.
        // Evenly spaced, the row reads as a single smear of pieces; grouped,
        // "rook, two pawns" is countable at a glance without reading it.
        return HStack(spacing: 6) {
            HStack(spacing: 5) {
                ForEach(Array(Self.grouped(glyphs).enumerated()), id: \.offset) { _, group in
                    HStack(spacing: 1.5) {
                        ForEach(0..<group.count, id: \.self) { _ in
                            // The same art as the board, small: a captured
                            // knight should look like the knight that was on
                            // the square a moment ago.
                            Image(PieceArt.name(for: color.opponent, group.kind))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 17)
                        }
                    }
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

    /// Runs of the same kind. `capturedBy` already returns them heaviest first,
    /// so equal pieces are always adjacent.
    private static func grouped(_ kinds: [PieceKind]) -> [(kind: PieceKind, count: Int)] {
        var groups: [(kind: PieceKind, count: Int)] = []
        for kind in kinds {
            if groups.last?.kind == kind { groups[groups.count - 1].count += 1 }
            else { groups.append((kind, 1)) }
        }
        return groups
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
