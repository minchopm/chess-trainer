import ChessCore

/// One half-move, with everything the board needs to animate it.
///
/// Nothing here is transcribed. The games are stored as the moves they were
/// actually played in — the notation a book prints — and expanded by the same
/// move generator the rest of the app plays with. That settles en passant,
/// castling and promotion by the rules rather than by hand, and a wrong move
/// in a game list fails to expand instead of quietly animating a piece through
/// a wall.
public struct Ply: Sendable, Equatable {
    public let from: Square
    public let to: Square
    public let kind: PieceKind
    public let color: PieceColor
    /// Where the taken piece was standing — which for en passant is not `to`.
    public let capture: Square?
    public let promotion: PieceKind?
    /// Castling moves a rook as well.
    public let rook: RookMove?
    public let san: String

    public struct RookMove: Sendable, Equatable {
        public let from: Square
        public let to: Square
    }
}

/// A game the board plays out on its own.
public struct ShowGame: Sendable, Identifiable, Equatable {
    public let id: String
    public let white: String
    public let black: String
    public let event: String
    public let year: Int
    public let result: String
    public let note: String
    public let plies: [Ply]

    public var caption: String { "\(white) — \(black)" }
    public var occasion: String { "\(event), \(year) · \(result)" }
}

public enum ShowGames {
    /// Three of the most famous attacking games ever recorded, the same three
    /// the site plays. Each ends in mate and none of them is a grind: a title
    /// sequence has about a minute of anyone's attention and needs every move
    /// to be doing something.
    public static let all: [ShowGame] = [
        make(
            id: "opera", white: "Paul Morphy", black: "Duke of Brunswick & Count Isouard",
            event: "Paris Opera", year: 1858, result: "1–0",
            note: "Seventeen moves, every one of them developing something, and a mate delivered by the last piece to arrive.",
            moves: """
            e4 e5 Nf3 d6 d4 Bg4 dxe5 Bxf3 Qxf3 dxe5 Bc4 Nf6 Qb3 Qe7 Nc3 c6 Bg5 b5 Nxb5 cxb5
            Bxb5+ Nbd7 O-O-O Rd8 Rxd7 Rxd7 Rd1 Qe6 Bxd7+ Nxd7 Qb8+ Nxb8 Rd8#
            """
        ),
        make(
            id: "evergreen", white: "Adolf Anderssen", black: "Jean Dufresne",
            event: "Berlin", year: 1852, result: "1–0",
            note: "A queen given away on move twenty-two, and mate three moves later with the two bishops nobody was watching.",
            moves: """
            e4 e5 Nf3 Nc6 Bc4 Bc5 b4 Bxb4 c3 Ba5 d4 exd4 O-O d3 Qb3 Qf6 e5 Qg6 Re1 Nge7
            Ba3 b5 Qxb5 Rb8 Qa4 Bb6 Nbd2 Bb7 Ne4 Qf5 Bxd3 Qh5 Nf6+ gxf6 exf6 Rg8 Rad1 Qxf3
            Rxe7+ Nxe7 Qxd7+ Kxd7 Bf5+ Ke8 Bd7+ Kf8 Bxe7#
            """
        ),
        make(
            id: "immortal", white: "Adolf Anderssen", black: "Lionel Kieseritzky",
            event: "London", year: 1851, result: "1–0",
            note: "Both rooks and the queen sacrificed, and mate delivered by three minor pieces against a full board.",
            moves: """
            e4 e5 f4 exf4 Bc4 Qh4+ Kf1 b5 Bxb5 Nf6 Nf3 Qh6 d3 Nh5 Nh4 Qg5 Nf5 c6 g4 Nf6
            Rg1 cxb5 h4 Qg6 h5 Qg5 Qf3 Ng8 Bxf4 Qf6 Nc3 Bc5 Nd5 Qxb2 Bd6 Bxg1 e5 Qxa1+
            Ke2 Na6 Nxg7+ Kd8 Qf6+ Nxf6 Be7#
            """
        ),
    ]

    private static func make(
        id: String, white: String, black: String, event: String, year: Int,
        result: String, note: String, moves: String
    ) -> ShowGame {
        ShowGame(
            id: id, white: white, black: black, event: event, year: year,
            result: result, note: note, plies: expand(moves)
        )
    }

    /// Turns a game's notation into plies by playing it.
    ///
    /// A move the generator will not accept stops the expansion there rather
    /// than throwing: a board that plays a famous game two moves short is a
    /// smaller failure than a first screen that crashes, and the tests catch
    /// the short game long before anybody sees it.
    static func expand(_ notation: String) -> [Ply] {
        expandFrom(position: Position(), notation: notation)
    }

    /// The same, from a position that is not the starting one. Used by the
    /// tests to reach the rules these three games never exercise.
    static func expandFrom(position start: Position, notation: String) -> [Ply] {
        var position = start
        var plies: [Ply] = []

        for token in notation.split(whereSeparator: \.isWhitespace) {
            let san = String(token)
            guard let move = position.move(san: san),
                  let piece = position[move.from]
            else { break }

            let capture: Square? = switch move.kind {
            case .enPassant: Square(file: move.to.file, rank: move.from.rank)
            case .capture: move.to
            default: nil
            }

            // The rook's half of a castle, which the notation leaves implicit.
            let rank = move.from.rank
            let rook: Ply.RookMove? = switch move.kind {
            case .kingsideCastle:
                .init(from: Square(file: 7, rank: rank), to: Square(file: 5, rank: rank))
            case .queensideCastle:
                .init(from: Square(file: 0, rank: rank), to: Square(file: 3, rank: rank))
            default: nil
            }

            plies.append(Ply(
                from: move.from, to: move.to, kind: piece.kind, color: piece.color,
                capture: capture, promotion: move.promotion, rook: rook, san: san
            ))

            _ = position.make(move)
        }

        return plies
    }
}
