extension Position {
    /// Every legal move in this position.
    public func legalMoves() -> [Move] {
        var moves = pseudoLegalMoves()
        moves.removeAll { move in
            var copy = self
            copy.makeUnchecked(move)
            return copy.isInCheck(sideToMove)
        }
        return moves
    }

    /// Legal moves starting from a given square — what the board UI needs.
    public func legalMoves(from square: Square) -> [Move] {
        legalMoves().filter { $0.from == square }
    }

    /// Moves that respect piece movement rules but may leave the king in check.
    func pseudoLegalMoves() -> [Move] {
        var moves: [Move] = []
        moves.reserveCapacity(48)

        for index in 0..<64 {
            guard let piece = squares[index], piece.color == sideToMove else { continue }
            let square = Square(index)
            switch piece.kind {
            case .pawn: generatePawnMoves(from: square, into: &moves)
            case .knight: generateStepMoves(from: square, offsets: Position.knightOffsets, into: &moves)
            case .king: generateStepMoves(from: square, offsets: Position.kingOffsets, into: &moves)
            case .bishop: generateSlidingMoves(from: square, directions: Position.bishopDirections, into: &moves)
            case .rook: generateSlidingMoves(from: square, directions: Position.rookDirections, into: &moves)
            case .queen:
                generateSlidingMoves(from: square, directions: Position.rookDirections, into: &moves)
                generateSlidingMoves(from: square, directions: Position.bishopDirections, into: &moves)
            }
        }

        generateCastlingMoves(into: &moves)
        return moves
    }

    private func generateStepMoves(from square: Square, offsets: [(Int, Int)], into moves: inout [Move]) {
        for (fileOffset, rankOffset) in offsets {
            let file = square.file + fileOffset
            let rank = square.rank + rankOffset
            guard file >= 0, file < 8, rank >= 0, rank < 8 else { continue }
            let target = Square(file: file, rank: rank)
            if let occupant = squares[target.index] {
                if occupant.color != sideToMove {
                    moves.append(Move(from: square, to: target, kind: .capture))
                }
            } else {
                moves.append(Move(from: square, to: target, kind: .quiet))
            }
        }
    }

    private func generateSlidingMoves(from square: Square, directions: [(Int, Int)], into moves: inout [Move]) {
        for (fileOffset, rankOffset) in directions {
            var file = square.file + fileOffset
            var rank = square.rank + rankOffset
            while file >= 0, file < 8, rank >= 0, rank < 8 {
                let target = Square(file: file, rank: rank)
                if let occupant = squares[target.index] {
                    if occupant.color != sideToMove {
                        moves.append(Move(from: square, to: target, kind: .capture))
                    }
                    break
                }
                moves.append(Move(from: square, to: target, kind: .quiet))
                file += fileOffset
                rank += rankOffset
            }
        }
    }

    private func generatePawnMoves(from square: Square, into moves: inout [Move]) {
        let step = sideToMove.pawnStep
        let promotionRank = sideToMove.promotionRank
        let forward = square.index + step

        func append(_ move: Move, promoting: Bool) {
            if promoting {
                for kind in [PieceKind.queen, .rook, .bishop, .knight] {
                    moves.append(Move(from: move.from, to: move.to, promotion: kind, kind: move.kind))
                }
            } else {
                moves.append(move)
            }
        }

        // Single and double pushes.
        if forward >= 0, forward < 64, squares[forward] == nil {
            let target = Square(forward)
            append(Move(from: square, to: target, kind: .quiet), promoting: target.rank == promotionRank)

            if square.rank == sideToMove.pawnRank {
                let double = forward + step
                if double >= 0, double < 64, squares[double] == nil {
                    moves.append(Move(from: square, to: Square(double), kind: .doublePawnPush))
                }
            }
        }

        // Captures, including en passant.
        for fileOffset in [-1, 1] {
            let file = square.file + fileOffset
            let rank = square.rank + (sideToMove == .white ? 1 : -1)
            guard file >= 0, file < 8, rank >= 0, rank < 8 else { continue }
            let target = Square(file: file, rank: rank)

            if let occupant = squares[target.index] {
                guard occupant.color != sideToMove else { continue }
                append(Move(from: square, to: target, kind: .capture), promoting: target.rank == promotionRank)
            } else if target == enPassant {
                moves.append(Move(from: square, to: target, kind: .enPassant))
            }
        }
    }

    private func generateCastlingMoves(into moves: inout [Move]) {
        guard let kingSquare = king(of: sideToMove), !isInCheck(sideToMove) else { return }

        let backRank = sideToMove == .white ? 0 : 7
        guard kingSquare == Square(file: 4, rank: backRank) else { return }

        let kingsideRight: CastlingRights = sideToMove == .white ? .whiteKingside : .blackKingside
        let queensideRight: CastlingRights = sideToMove == .white ? .whiteQueenside : .blackQueenside
        let enemy = sideToMove.opponent

        // Kingside: f and g empty, and the king may not start, pass through, or
        // land on an attacked square.
        if castling.contains(kingsideRight),
           squares[backRank * 8 + 5] == nil, squares[backRank * 8 + 6] == nil,
           squares[backRank * 8 + 7] == Piece(sideToMove, .rook),
           !isAttacked(Square(file: 5, rank: backRank), by: enemy),
           !isAttacked(Square(file: 6, rank: backRank), by: enemy) {
            moves.append(Move(from: kingSquare, to: Square(file: 6, rank: backRank), kind: .kingsideCastle))
        }

        // Queenside: b, c and d empty. The king only travels through d and c, so
        // b may be attacked — only the rook passes over it.
        if castling.contains(queensideRight),
           squares[backRank * 8 + 1] == nil, squares[backRank * 8 + 2] == nil, squares[backRank * 8 + 3] == nil,
           squares[backRank * 8 + 0] == Piece(sideToMove, .rook),
           !isAttacked(Square(file: 3, rank: backRank), by: enemy),
           !isAttacked(Square(file: 2, rank: backRank), by: enemy) {
            moves.append(Move(from: kingSquare, to: Square(file: 2, rank: backRank), kind: .queensideCastle))
        }
    }
}
