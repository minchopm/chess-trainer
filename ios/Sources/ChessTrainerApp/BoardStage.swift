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
    @Environment(\.pieceSet) private var pieceSet
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
                            Image(PieceArt.name(for: color.opponent, group.kind, set: pieceSet))
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


/// A chess clock, drawn the way one stands on the table: two faces turned away
/// from each other, the side to move lit.
///
/// It goes in the strip along the top of the window rather than in the player
/// rows. Two numbers that have to be compared belong on one line — "he has
/// forty seconds and I have two minutes" is a single glance here and two
/// glances when they sit at opposite ends of the board — and the row it takes
/// is one the game had already emptied.
struct ClockStrip: View {
    let session: MatchSession
    let now: Date

    var body: some View {
        HStack(spacing: 8) {
            face(
                remaining: session.clock.remaining(session.opponentClockKey, at: now),
                color: session.myColor.opponent,
                live: session.clock.isRunning && !session.isMyTurn
            )
            Spacer(minLength: 8)
            face(
                remaining: session.clock.remaining(session.myClockKey, at: now),
                color: session.myColor,
                live: session.clock.isRunning && session.isMyTurn
            )
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.2), value: session.isMyTurn)
    }

    private func face(remaining: TimeInterval, color: PieceColor, live: Bool) -> some View {
        HStack(spacing: 7) {
            // The black dot needs a rim to exist at all against a capsule
            // this dark; the white one is already the brightest thing in it.
            Circle()
                .fill(color == .white ? Theatre.ivory : Color(hex: 0x14161C))
                .overlay(Circle().strokeBorder(
                    color == .white ? Theatre.rule : Theatre.ivory.opacity(0.45),
                    lineWidth: 0.75
                ))
                .frame(width: 9, height: 9)
            Text(verbatim: ChessClock.text(remaining))
                .font(Face.mono(15, weight: live ? .semibold : .regular))
                .foregroundStyle(tint(remaining))
        }
        // Idle is dimmed rather than recoloured, so the one number that is
        // actually counting is the one the eye lands on.
        .opacity(live ? 1 : 0.5)
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(live ? Theatre.brassGlow : Theatre.ink3, in: Capsule())
        .overlay(
            Capsule().strokeBorder(live ? Theatre.brass.opacity(0.55) : Theatre.rule, lineWidth: 0.5)
        )
        .shadow(color: live ? Theatre.brassGlow : .clear, radius: 8)
    }

    /// The last half-minute is the part of a blitz game people lose without
    /// noticing, so the number changes colour before it runs out rather than
    /// after.
    private func tint(_ remaining: TimeInterval) -> Color {
        if remaining <= 10 { return Theatre.bad }
        if remaining <= 30 { return Theatre.warn }
        return Theatre.ivory
    }
}
