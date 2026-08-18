import ChessCore

/// Positional features of a position.
///
/// The engine says which move is best; these say why, in the vocabulary a coach
/// would use — open files, rook placement, outposts, pawn structure, king
/// safety. Those are the handles a human can carry to the next game, which a
/// centipawn number is not.
public struct PositionFeatures: Sendable {
    public struct FileInfo: Sendable {
        public let index: Int
        public let whitePawns: Int
        public let blackPawns: Int

        public var name: String { String(Character(UnicodeScalar(UInt8(97 + index)))) }
        public var isOpen: Bool { whitePawns == 0 && blackPawns == 0 }

        /// Half-open for the side that has no pawn on it.
        public var halfOpenFor: PieceColor? {
            if whitePawns == 0 && blackPawns > 0 { return .white }
            if blackPawns == 0 && whitePawns > 0 { return .black }
            return nil
        }
    }

    public struct HeavyPiece: Sendable {
        public let square: Square
        public let color: PieceColor
        public let kind: PieceKind
        public let onOpenFile: Bool
        public let onHalfOpenFile: Bool
        public let onSeventhRank: Bool
    }

    public struct Knight: Sendable {
        public let square: Square
        public let color: PieceColor
        public let isOutpost: Bool
    }

    public struct PawnStructure: Sendable {
        public let isolated: [Square]
        public let doubled: [Square]
        public let passed: [Square]
        public let backward: [Square]
        public let count: Int
    }

    public struct KingSafety: Sendable {
        public let square: Square?
        /// Pawns shielding the king, counting those directly in front double.
        public let shield: Double
        public let openFilesNearby: Int
        public let hasCastled: Bool
    }

    public enum Phase: String, Sendable { case opening, middlegame, endgame }

    public let files: [FileInfo]
    public let heavyPieces: [HeavyPiece]
    public let knights: [Knight]
    public let structure: [PieceColor: PawnStructure]
    public let hasBishopPair: [PieceColor: Bool]
    public let material: [PieceColor: Int]
    public let kingSafety: [PieceColor: KingSafety]
    public let mobility: [PieceColor: Int]
    public let phase: Phase

    /// Material in centipawns, positive when White is ahead.
    public var materialBalance: Int { (material[.white] ?? 0) - (material[.black] ?? 0) }

    public init(_ position: Position) {
        var pawnsByFile: [PieceColor: [[Square]]] = [
            .white: Array(repeating: [], count: 8),
            .black: Array(repeating: [], count: 8),
        ]
        var pieces: [(Square, Piece)] = []

        for index in 0..<64 {
            let square = Square(index)
            guard let piece = position[square] else { continue }
            pieces.append((square, piece))
            if piece.kind == .pawn { pawnsByFile[piece.color]![square.file].append(square) }
        }

        files = (0..<8).map { file in
            FileInfo(
                index: file,
                whitePawns: pawnsByFile[.white]![file].count,
                blackPawns: pawnsByFile[.black]![file].count
            )
        }

        let fileTable = files
        heavyPieces = pieces.compactMap { square, piece in
            guard piece.kind == .rook || piece.kind == .queen else { return nil }
            let file = fileTable[square.file]
            return HeavyPiece(
                square: square,
                color: piece.color,
                kind: piece.kind,
                onOpenFile: file.isOpen,
                onHalfOpenFile: file.halfOpenFor == piece.color,
                onSeventhRank: piece.kind == .rook && square.relativeRank(for: piece.color) == 7
            )
        }

        knights = pieces.compactMap { square, piece in
            guard piece.kind == .knight else { return nil }
            return Knight(
                square: square,
                color: piece.color,
                isOutpost: PositionFeatures.isOutpost(square, piece.color, pieces)
            )
        }

        structure = [
            .white: PositionFeatures.pawnStructure(.white, pawnsByFile, pieces),
            .black: PositionFeatures.pawnStructure(.black, pawnsByFile, pieces),
        ]

        var bishops: [PieceColor: Int] = [.white: 0, .black: 0]
        var materialCount: [PieceColor: Int] = [.white: 0, .black: 0]
        for (_, piece) in pieces {
            if piece.kind == .bishop { bishops[piece.color]! += 1 }
            materialCount[piece.color]! += piece.kind.value
        }
        hasBishopPair = [.white: bishops[.white]! >= 2, .black: bishops[.black]! >= 2]
        material = materialCount

        kingSafety = [
            .white: PositionFeatures.kingSafety(.white, pieces, fileTable),
            .black: PositionFeatures.kingSafety(.black, pieces, fileTable),
        ]

        mobility = [
            .white: PositionFeatures.mobility(of: .white, in: position),
            .black: PositionFeatures.mobility(of: .black, in: position),
        ]

        let heavy = pieces.filter { "qrbn".contains($0.1.kind.letter) }.count
        phase = heavy >= 12 ? .opening : (heavy >= 6 ? .middlegame : .endgame)
    }

    // MARK: - Component analysis

    /// Squares a pawn of this colour attacks.
    static func pawnAttacks(from square: Square, _ color: PieceColor) -> [Square] {
        let rank = square.rank + (color == .white ? 1 : -1)
        guard rank >= 0, rank < 8 else { return [] }
        return [square.file - 1, square.file + 1]
            .filter { $0 >= 0 && $0 < 8 }
            .map { Square(file: $0, rank: rank) }
    }

    /// A knight is on an outpost when it stands in enemy territory, a friendly
    /// pawn defends it, and no enemy pawn can ever come to chase it away.
    static func isOutpost(_ square: Square, _ color: PieceColor, _ pieces: [(Square, Piece)]) -> Bool {
        let rank = square.relativeRank(for: color)
        guard rank >= 4, rank <= 6 else { return false }

        let defended = pieces.contains { candidateSquare, piece in
            piece.kind == .pawn && piece.color == color
                && pawnAttacks(from: candidateSquare, color).contains(square)
        }
        guard defended else { return false }

        let enemy = color.opponent
        let canBeChased = pieces.contains { candidateSquare, piece in
            guard piece.kind == .pawn, piece.color == enemy else { return false }
            guard abs(candidateSquare.file - square.file) == 1 else { return false }
            // Only a pawn that has not yet passed the square can still attack it.
            return color == .white
                ? candidateSquare.rank > square.rank
                : candidateSquare.rank < square.rank
        }
        return !canBeChased
    }

    static func pawnStructure(
        _ color: PieceColor,
        _ pawnsByFile: [PieceColor: [[Square]]],
        _ pieces: [(Square, Piece)]
    ) -> PawnStructure {
        let own = pawnsByFile[color]!
        let enemy = pawnsByFile[color.opponent]!
        var isolated: [Square] = []
        var doubled: [Square] = []
        var passed: [Square] = []
        var backward: [Square] = []

        for file in 0..<8 where !own[file].isEmpty {
            let neighbours = (file > 0 ? own[file - 1].count : 0) + (file < 7 ? own[file + 1].count : 0)
            if neighbours == 0 { isolated.append(contentsOf: own[file]) }
            if own[file].count > 1 { doubled.append(contentsOf: own[file]) }

            for square in own[file] {
                let ahead: ([Square]) -> Bool = { list in
                    list.contains { color == .white ? $0.rank > square.rank : $0.rank < square.rank }
                }
                let blocked = ahead(enemy[file])
                    || (file > 0 && ahead(enemy[file - 1]))
                    || (file < 7 && ahead(enemy[file + 1]))
                if !blocked { passed.append(square) }

                // Backward: no friendly pawn on an adjacent file is level with
                // or behind it, and an enemy pawn covers the square in front.
                let supported = [file > 0 ? own[file - 1] : [], file < 7 ? own[file + 1] : []]
                    .contains { list in
                        list.contains { color == .white ? $0.rank <= square.rank : $0.rank >= square.rank }
                    }
                let frontRank = square.rank + (color == .white ? 1 : -1)
                if !supported, frontRank >= 0, frontRank < 8 {
                    let front = Square(file: file, rank: frontRank)
                    let contested = pieces.contains { candidateSquare, piece in
                        piece.kind == .pawn && piece.color != color
                            && pawnAttacks(from: candidateSquare, piece.color).contains(front)
                    }
                    if contested { backward.append(square) }
                }
            }
        }

        return PawnStructure(
            isolated: isolated, doubled: doubled, passed: passed, backward: backward,
            count: own.flatMap { $0 }.count
        )
    }

    static func kingSafety(
        _ color: PieceColor, _ pieces: [(Square, Piece)], _ files: [FileInfo]
    ) -> KingSafety {
        guard let king = pieces.first(where: { $0.1 == Piece(color, .king) })?.0 else {
            return KingSafety(square: nil, shield: 0, openFilesNearby: 0, hasCastled: false)
        }

        var shield = 0.0
        for fileOffset in -1...1 {
            let file = king.file + fileOffset
            guard file >= 0, file < 8 else { continue }
            for step in 1...2 {
                let rank = king.rank + (color == .white ? step : -step)
                guard rank >= 0, rank < 8 else { continue }
                let square = Square(file: file, rank: rank)
                if pieces.contains(where: { $0.0 == square && $0.1 == Piece(color, .pawn) }) {
                    shield += step == 1 ? 1 : 0.5
                    break
                }
            }
        }

        var openNearby = 0
        for fileOffset in -1...1 {
            let file = king.file + fileOffset
            guard file >= 0, file < 8 else { continue }
            if files[file].isOpen || files[file].halfOpenFor == color.opponent { openNearby += 1 }
        }

        return KingSafety(
            square: king,
            shield: shield,
            openFilesNearby: openNearby,
            hasCastled: king.relativeRank(for: color) == 1 && (king.file <= 2 || king.file >= 6)
        )
    }

    /// Legal moves for a colour, obtained by handing that side the move.
    /// Returns 0 when that would be an illegal position, which happens whenever
    /// the other side is currently giving check.
    static func mobility(of color: PieceColor, in position: Position) -> Int {
        if position.sideToMove == color { return position.legalMoves().count }

        var fields = position.fen.split(separator: " ").map(String.init)
        guard fields.count >= 4 else { return 0 }
        fields[1] = color == .white ? "w" : "b"
        fields[3] = "-"  // an en-passant square cannot be inherited by the other side
        guard let probe = Position(fen: fields.joined(separator: " ")) else { return 0 }
        return probe.legalMoves().count
    }
}
