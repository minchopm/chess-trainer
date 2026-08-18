import ChessCore

/// The material story of a position: what has been taken, and who is ahead.
///
/// Counted against the standard starting set rather than against the position
/// the exercise began in. A puzzle FEN is a snapshot of a real game, and what
/// the two rows beside the board are for is reading that game — "Black is a
/// rook up but White has three pawns for it" — not the handful of plies since
/// the puzzle loaded.
public struct MaterialBalance: Equatable, Sendable {
    /// Classic teaching values. `PieceKind.value` separates bishop from knight,
    /// which is right for an engine explanation and wrong for a scoreboard:
    /// nobody reads a material lead as "+0.25".
    private static let points: [PieceKind: Int] = [
        .pawn: 1, .knight: 3, .bishop: 3, .rook: 5, .queen: 9, .king: 0,
    ]

    /// Heaviest first, so the piece that decides the balance leads the row.
    private static let fullSet: [(kind: PieceKind, count: Int)] = [
        (.queen, 1), (.rook, 2), (.bishop, 2), (.knight, 2), (.pawn, 8),
    ]

    private let counts: [PieceColor: [PieceKind: Int]]

    public init(_ position: Position) {
        var counts: [PieceColor: [PieceKind: Int]] = [.white: [:], .black: [:]]
        for index in 0..<64 {
            guard let piece = position[Square(index)] else { continue }
            counts[piece.color]?[piece.kind, default: 0] += 1
        }
        self.counts = counts
    }

    /// The pieces `color` has captured from the opponent, heaviest first.
    ///
    /// Under-promotion and a second queen make a colour hold more of a kind
    /// than it started with; the surplus is clamped away rather than reported
    /// as a negative capture.
    public func capturedBy(_ color: PieceColor) -> [PieceKind] {
        let remaining = counts[color.opponent] ?? [:]
        return Self.fullSet.flatMap { entry in
            Array(repeating: entry.kind, count: max(0, entry.count - (remaining[entry.kind] ?? 0)))
        }
    }

    /// How many points `color` is ahead by, counting what is on the board.
    /// Zero when level or behind, so a row can show a lead without showing a
    /// deficit the other row already states.
    public func lead(of color: PieceColor) -> Int {
        max(0, total(color) - total(color.opponent))
    }

    private func total(_ color: PieceColor) -> Int {
        (counts[color] ?? [:]).reduce(0) { sum, entry in
            sum + entry.value * (Self.points[entry.key] ?? 0)
        }
    }
}
