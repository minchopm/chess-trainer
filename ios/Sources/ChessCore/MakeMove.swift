extension Position {
    /// Play a move given in notation, if it is legal here.
    @discardableResult
    public mutating func make(_ notation: Move) -> Move? {
        guard let move = legalMoves().first(where: { $0.matchesNotation(of: notation) }) else { return nil }
        makeUnchecked(move)
        return move
    }

    @discardableResult
    public mutating func make(uci: String) -> Move? {
        guard let parsed = Move(uci: uci) else { return nil }
        return make(parsed)
    }

    /// Apply a move that is already known to be generated from this position.
    ///
    /// Used by the legality filter on a copy, so it must not itself check
    /// legality — that is the caller's job and the reason this is not public.
    mutating func makeUnchecked(_ move: Move) {
        let moving = squares[move.from.index]!
        let previousCastling = castling
        let previousEnPassant = enPassant

        // Remove the captured piece first; en passant takes from a square the
        // moving pawn never lands on.
        var captured: Piece?
        if move.kind == .enPassant {
            let capturedSquare = Square(file: move.to.file, rank: move.from.rank)
            captured = squares[capturedSquare.index]
            squares[capturedSquare.index] = nil
            hash ^= Zobrist.pieces[Zobrist.index(captured!)][capturedSquare.index]
        } else if let occupant = squares[move.to.index] {
            captured = occupant
            hash ^= Zobrist.pieces[Zobrist.index(occupant)][move.to.index]
        }

        squares[move.from.index] = nil
        hash ^= Zobrist.pieces[Zobrist.index(moving)][move.from.index]

        let placed = move.promotion.map { Piece(moving.color, $0) } ?? moving
        squares[move.to.index] = placed
        hash ^= Zobrist.pieces[Zobrist.index(placed)][move.to.index]

        // The rook hops over the king; the king move above already happened.
        if move.isCastle {
            let backRank = moving.color == .white ? 0 : 7
            let (rookFrom, rookTo) = move.kind == .kingsideCastle
                ? (Square(file: 7, rank: backRank), Square(file: 5, rank: backRank))
                : (Square(file: 0, rank: backRank), Square(file: 3, rank: backRank))
            let rook = squares[rookFrom.index]!
            squares[rookFrom.index] = nil
            squares[rookTo.index] = rook
            hash ^= Zobrist.pieces[Zobrist.index(rook)][rookFrom.index]
            hash ^= Zobrist.pieces[Zobrist.index(rook)][rookTo.index]
        }

        updateCastlingRights(moving: moving, move: move, captured: captured)

        enPassant = move.kind == .doublePawnPush
            ? Square(file: move.from.file, rank: (move.from.rank + move.to.rank) / 2)
            : nil

        if let previousEnPassant { hash ^= Zobrist.enPassantFile[previousEnPassant.file] }
        if let enPassant { hash ^= Zobrist.enPassantFile[enPassant.file] }
        if previousCastling != castling {
            hash ^= Zobrist.castling[Int(previousCastling.rawValue)]
            hash ^= Zobrist.castling[Int(castling.rawValue)]
        }

        halfmoveClock = (moving.kind == .pawn || captured != nil) ? 0 : halfmoveClock + 1
        if sideToMove == .black { fullmoveNumber += 1 }
        sideToMove = sideToMove.opponent
        hash ^= Zobrist.sideToMove

        // A pawn move or capture makes every earlier position unreachable, so
        // the repetition window can be cleared with it.
        if halfmoveClock == 0 { history.removeAll(keepingCapacity: true) }
        history.append(hash)
    }

    /// Castling rights die when the king moves, when a rook leaves its corner,
    /// and — easy to forget — when a rook is captured on its corner.
    private mutating func updateCastlingRights(moving: Piece, move: Move, captured: Piece?) {
        if moving.kind == .king {
            castling.subtract(moving.color == .white ? [.whiteKingside, .whiteQueenside] : [.blackKingside, .blackQueenside])
        }

        for square in [move.from, move.to] {
            switch square.index {
            case 0: castling.subtract(.whiteQueenside)
            case 7: castling.subtract(.whiteKingside)
            case 56: castling.subtract(.blackQueenside)
            case 63: castling.subtract(.blackKingside)
            default: break
            }
        }
    }

    // MARK: - Game state

    public var isCheckmate: Bool { isCheck && legalMoves().isEmpty }
    public var isStalemate: Bool { !isCheck && legalMoves().isEmpty }

    public var isFiftyMoveRule: Bool { halfmoveClock >= 100 }

    public var isThreefoldRepetition: Bool {
        guard let current = history.last else { return false }
        return history.filter { $0 == current }.count >= 3
    }

    /// Positions from which no sequence of legal moves can produce checkmate.
    public var isInsufficientMaterial: Bool {
        var knights = 0
        var bishopsOnLight = 0
        var bishopsOnDark = 0

        for index in 0..<64 {
            guard let piece = squares[index] else { continue }
            switch piece.kind {
            case .king: continue
            case .knight: knights += 1
            case .bishop:
                let square = Square(index)
                if (square.file + square.rank) % 2 == 0 { bishopsOnDark += 1 } else { bishopsOnLight += 1 }
            default: return false // any pawn, rook or queen can still mate
            }
        }

        let bishops = bishopsOnLight + bishopsOnDark
        if knights == 0 && bishops == 0 { return true }                 // bare kings
        if knights == 1 && bishops == 0 { return true }                 // king and knight
        if knights == 0 && bishops >= 1 {
            // Any number of bishops, all on one colour, can never mate.
            return bishopsOnLight == 0 || bishopsOnDark == 0
        }
        return false
    }

    public var isDraw: Bool {
        isStalemate || isInsufficientMaterial || isFiftyMoveRule || isThreefoldRepetition
    }

    public var isGameOver: Bool { isCheckmate || isDraw }
}
