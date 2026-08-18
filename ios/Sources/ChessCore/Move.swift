/// A move, plus enough recorded state to undo it exactly.
public struct Move: Equatable, Hashable, Sendable, CustomStringConvertible {
    public let from: Square
    public let to: Square
    public let promotion: PieceKind?
    public let kind: Kind

    public enum Kind: UInt8, Sendable {
        case quiet, capture, doublePawnPush, enPassant, kingsideCastle, queensideCastle
    }

    public init(from: Square, to: Square, promotion: PieceKind? = nil, kind: Kind = .quiet) {
        self.from = from
        self.to = to
        self.promotion = promotion
        self.kind = kind
    }

    public var isCapture: Bool { kind == .capture || kind == .enPassant }
    public var isCastle: Bool { kind == .kingsideCastle || kind == .queensideCastle }

    /// Long algebraic notation, the form UCI speaks: "e2e4", "e7e8q".
    public var uci: String {
        var text = "\(from)\(to)"
        if let promotion { text.append(promotion.letter) }
        return text
    }

    public var description: String { uci }

    public init?(uci: some StringProtocol) {
        guard uci.count == 4 || uci.count == 5 else { return nil }
        let characters = Array(uci)
        guard let from = Square(String(characters[0...1])),
              let to = Square(String(characters[2...3]))
        else { return nil }
        var promotion: PieceKind?
        if characters.count == 5 {
            guard let kind = PieceKind(letter: characters[4]) else { return nil }
            promotion = kind
        }
        // The kind is unknown from notation alone; Position resolves it when the
        // move is matched against the legal list.
        self.init(from: from, to: to, promotion: promotion)
    }

    /// Compares only the parts notation carries, ignoring the internal kind.
    public func matchesNotation(of other: Move) -> Bool {
        from == other.from && to == other.to && promotion == other.promotion
    }
}

/// Everything needed to restore the position before a move.
public struct Undo: Sendable {
    let move: Move
    let captured: Piece?
    let castling: CastlingRights
    let enPassant: Square?
    let halfmoveClock: Int
    let hash: UInt64
}
