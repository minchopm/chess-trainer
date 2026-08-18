import Foundation

/// A chess position and the rules that govern it.
///
/// Move generation is pseudo-legal followed by a make/test/unmake legality
/// filter. That is slower than staying strictly legal during generation, but it
/// is far harder to get subtly wrong — and every awkward case (pinned pieces,
/// en passant exposing the king along a rank, castling through an attacked
/// square) falls out of it for free rather than needing its own special case.
/// Speed is not the constraint here: Stockfish does the searching.
public struct Position: Sendable {
    public internal(set) var squares: [Piece?]
    public internal(set) var sideToMove: PieceColor
    public internal(set) var castling: CastlingRights
    public internal(set) var enPassant: Square?
    public internal(set) var halfmoveClock: Int
    public internal(set) var fullmoveNumber: Int
    public internal(set) var hash: UInt64

    /// Hashes reached since the last irreversible move, for repetition detection.
    internal var history: [UInt64] = []

    public static let startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    public init() {
        self.init(fen: Position.startFEN)!
    }

    // MARK: - FEN

    public init?(fen: String) {
        let fields = fen.split(separator: " ", omittingEmptySubsequences: true)
        guard fields.count >= 4 else { return nil }

        var board = [Piece?](repeating: nil, count: 64)
        var rank = 7
        var file = 0
        for character in fields[0] {
            if character == "/" {
                guard file == 8 else { return nil }
                rank -= 1
                file = 0
                if rank < 0 { return nil }
            } else if let digit = character.wholeNumberValue, digit >= 1, digit <= 8 {
                file += digit
                if file > 8 { return nil }
            } else if let piece = Piece(character: character) {
                guard file < 8 else { return nil }
                board[rank * 8 + file] = piece
                file += 1
            } else {
                return nil
            }
        }
        guard rank == 0, file == 8 else { return nil }

        guard let side = fields[1].first, side == "w" || side == "b" else { return nil }

        var rights: CastlingRights = []
        if fields[2] != "-" {
            for character in fields[2] {
                switch character {
                case "K": rights.insert(.whiteKingside)
                case "Q": rights.insert(.whiteQueenside)
                case "k": rights.insert(.blackKingside)
                case "q": rights.insert(.blackQueenside)
                default: return nil
                }
            }
        }

        var ep: Square?
        if fields[3] != "-" {
            guard let square = Square(fields[3]) else { return nil }
            ep = square
        }

        self.squares = board
        self.sideToMove = side == "w" ? .white : .black
        self.castling = rights
        self.enPassant = ep
        self.halfmoveClock = fields.count > 4 ? Int(fields[4]) ?? 0 : 0
        self.fullmoveNumber = fields.count > 5 ? Int(fields[5]) ?? 1 : 1
        self.hash = 0
        self.hash = computeHash()
        // The position as given counts as the first occurrence for repetition.
        self.history = [self.hash]

        // A position where both kings are not present, or where the side not to
        // move is in check, cannot arise in a game. Rejecting it here stops such
        // positions reaching the engine, which answers them with "bestmove
        // (none)" and looks like a crash.
        guard king(of: .white) != nil, king(of: .black) != nil else { return nil }
        guard !isInCheck(sideToMove.opponent) else { return nil }
    }

    public var fen: String {
        var placement = ""
        for rank in stride(from: 7, through: 0, by: -1) {
            var empty = 0
            for file in 0..<8 {
                if let piece = squares[rank * 8 + file] {
                    if empty > 0 { placement += String(empty); empty = 0 }
                    placement.append(piece.character)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { placement += String(empty) }
            if rank > 0 { placement += "/" }
        }
        let ep = enPassant.map(String.init(describing:)) ?? "-"
        return "\(placement) \(sideToMove == .white ? "w" : "b") \(castling.fenString) \(ep) \(halfmoveClock) \(fullmoveNumber)"
    }

    private func computeHash() -> UInt64 {
        var value: UInt64 = 0
        for index in 0..<64 {
            if let piece = squares[index] {
                value ^= Zobrist.pieces[Zobrist.index(piece)][index]
            }
        }
        value ^= Zobrist.castling[Int(castling.rawValue)]
        if let enPassant { value ^= Zobrist.enPassantFile[enPassant.file] }
        if sideToMove == .black { value ^= Zobrist.sideToMove }
        return value
    }

    // MARK: - Queries

    public subscript(square: Square) -> Piece? { squares[square.index] }

    public func king(of color: PieceColor) -> Square? {
        for index in 0..<64 where squares[index] == Piece(color, .king) {
            return Square(index)
        }
        return nil
    }

    public func isInCheck(_ color: PieceColor) -> Bool {
        guard let square = king(of: color) else { return false }
        return isAttacked(square, by: color.opponent)
    }

    public var isCheck: Bool { isInCheck(sideToMove) }

    /// Is `square` attacked by any piece of `color`?
    ///
    /// Looks outward from the square for attackers rather than generating every
    /// enemy move, which keeps this cheap enough to call inside the legality
    /// filter for every candidate move.
    public func isAttacked(_ square: Square, by color: PieceColor) -> Bool {
        let file = square.file
        let rank = square.rank

        // Pawns: step back along the direction that colour's pawns capture.
        let pawnRankOffset = color == .white ? -1 : 1
        for fileOffset in [-1, 1] {
            let f = file + fileOffset
            let r = rank + pawnRankOffset
            if f >= 0, f < 8, r >= 0, r < 8, squares[r * 8 + f] == Piece(color, .pawn) {
                return true
            }
        }

        for (fileOffset, rankOffset) in Position.knightOffsets {
            let f = file + fileOffset
            let r = rank + rankOffset
            if f >= 0, f < 8, r >= 0, r < 8, squares[r * 8 + f] == Piece(color, .knight) {
                return true
            }
        }

        for (fileOffset, rankOffset) in Position.kingOffsets {
            let f = file + fileOffset
            let r = rank + rankOffset
            if f >= 0, f < 8, r >= 0, r < 8, squares[r * 8 + f] == Piece(color, .king) {
                return true
            }
        }

        for (fileOffset, rankOffset) in Position.rookDirections {
            if slidingAttacker(from: file, rank, fileOffset, rankOffset, color, .rook) { return true }
        }
        for (fileOffset, rankOffset) in Position.bishopDirections {
            if slidingAttacker(from: file, rank, fileOffset, rankOffset, color, .bishop) { return true }
        }
        return false
    }

    /// Walks one ray; a queen counts as both a rook and a bishop.
    private func slidingAttacker(
        from file: Int, _ rank: Int, _ fileOffset: Int, _ rankOffset: Int,
        _ color: PieceColor, _ kind: PieceKind
    ) -> Bool {
        var f = file + fileOffset
        var r = rank + rankOffset
        while f >= 0, f < 8, r >= 0, r < 8 {
            if let piece = squares[r * 8 + f] {
                return piece.color == color && (piece.kind == kind || piece.kind == .queen)
            }
            f += fileOffset
            r += rankOffset
        }
        return false
    }

    static let knightOffsets: [(Int, Int)] = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)]
    static let kingOffsets: [(Int, Int)] = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    static let rookDirections: [(Int, Int)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    static let bishopDirections: [(Int, Int)] = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
}
