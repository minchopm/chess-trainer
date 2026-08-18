// Basic types. Squares are 0...63 with a1 = 0 and h8 = 63, so file and rank
// arithmetic is plain integer maths and the board is one flat array.

public enum PieceColor: Int, Sendable, CaseIterable {
    case white = 0, black = 1

    @inlinable public var opponent: PieceColor { self == .white ? .black : .white }

    /// Direction a pawn of this colour advances, in squares.
    @inlinable public var pawnStep: Int { self == .white ? 8 : -8 }

    /// Rank a pawn of this colour starts on.
    @inlinable public var pawnRank: Int { self == .white ? 1 : 6 }

    /// Rank a pawn of this colour promotes on.
    @inlinable public var promotionRank: Int { self == .white ? 7 : 0 }
}

public enum PieceKind: Int, Sendable, CaseIterable {
    case pawn = 0, knight, bishop, rook, queen, king

    public var letter: Character {
        switch self {
        case .pawn: "p"
        case .knight: "n"
        case .bishop: "b"
        case .rook: "r"
        case .queen: "q"
        case .king: "k"
        }
    }

    public init?(letter: Character) {
        switch Character(letter.lowercased()) {
        case "p": self = .pawn
        case "n": self = .knight
        case "b": self = .bishop
        case "r": self = .rook
        case "q": self = .queen
        case "k": self = .king
        default: return nil
        }
    }

    /// Rough material value in centipawns, used for explanations rather than search.
    public var value: Int {
        switch self {
        case .pawn: 100
        case .knight: 300
        case .bishop: 325
        case .rook: 500
        case .queen: 900
        case .king: 0
        }
    }
}

public struct Piece: Equatable, Hashable, Sendable {
    public let color: PieceColor
    public let kind: PieceKind

    public init(_ color: PieceColor, _ kind: PieceKind) {
        self.color = color
        self.kind = kind
    }

    public var character: Character {
        color == .white ? Character(String(kind.letter).uppercased()) : kind.letter
    }

    public init?(character: Character) {
        guard let kind = PieceKind(letter: character) else { return nil }
        self.init(character.isUppercase ? .white : .black, kind)
    }
}

/// A board square, 0...63, a1 = 0.
public struct Square: Equatable, Hashable, Sendable, CustomStringConvertible {
    public let index: Int

    @inlinable public init(_ index: Int) { self.index = index }

    @inlinable public init(file: Int, rank: Int) { self.index = rank * 8 + file }

    @inlinable public var file: Int { index & 7 }
    @inlinable public var rank: Int { index >> 3 }

    public init?(_ name: some StringProtocol) {
        guard name.count == 2 else { return nil }
        let characters = Array(name)
        guard let fileScalar = characters[0].asciiValue, let rankScalar = characters[1].asciiValue,
              fileScalar >= 97, fileScalar <= 104, rankScalar >= 49, rankScalar <= 56
        else { return nil }
        self.index = Int(rankScalar - 49) * 8 + Int(fileScalar - 97)
    }

    public var description: String {
        let file = Character(UnicodeScalar(UInt8(97 + self.file)))
        let rank = Character(UnicodeScalar(UInt8(49 + self.rank)))
        return "\(file)\(rank)"
    }

    /// Rank counted from a side's own back rank: a1 is rank 1 for White, a8 for Black.
    @inlinable public func relativeRank(for color: PieceColor) -> Int {
        color == .white ? rank + 1 : 8 - rank
    }
}

public struct CastlingRights: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let whiteKingside = CastlingRights(rawValue: 1 << 0)
    public static let whiteQueenside = CastlingRights(rawValue: 1 << 1)
    public static let blackKingside = CastlingRights(rawValue: 1 << 2)
    public static let blackQueenside = CastlingRights(rawValue: 1 << 3)
    public static let all: CastlingRights = [.whiteKingside, .whiteQueenside, .blackKingside, .blackQueenside]

    public var fenString: String {
        if isEmpty { return "-" }
        var text = ""
        if contains(.whiteKingside) { text += "K" }
        if contains(.whiteQueenside) { text += "Q" }
        if contains(.blackKingside) { text += "k" }
        if contains(.blackQueenside) { text += "q" }
        return text
    }
}
