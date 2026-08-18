import ChessCore

/// Turns a move into the reasons a coach would give for it.
public enum MoveDescription {
    /// Compare the positions either side of a move and name what it achieved.
    /// Returns short clauses meant to be joined into one sentence.
    public static func clauses(
        before: PositionFeatures,
        after: PositionFeatures,
        move: Move,
        position: Position,
        resulting: Position
    ) -> [String] {
        guard let piece = position[move.from] else { return [] }
        let mover = piece.color
        let them = mover.opponent
        let captured = capturedPiece(move: move, position: position)

        // Checkmate ends the game, so nothing else about the move matters.
        // Listing pawn structure beside "delivers checkmate" reads as noise.
        if resulting.isCheckmate {
            return captured.map { ["delivers checkmate, capturing the \(name(of: $0.kind))"] }
                ?? ["delivers checkmate"]
        }

        var clauses: [String] = []

        switch move.kind {
        case .kingsideCastle: clauses.append("castles kingside, tucking the king away")
        case .queensideCastle: clauses.append("castles queenside")
        default: break
        }

        if resulting.isCheck { clauses.append("gives check") }

        if let captured {
            let gained = captured.kind.value
            let risked = piece.kind.value
            clauses.append(gained > risked + 50
                ? "wins material — takes the \(name(of: captured.kind))"
                : "captures the \(name(of: captured.kind))")
        }

        if let promotion = move.promotion {
            clauses.append("promotes to a \(name(of: promotion))")
        }

        if piece.kind == .rook {
            let landed = after.heavyPieces.first { $0.square == move.to }
            let departed = before.heavyPieces.first { $0.square == move.from }
            if landed?.onOpenFile == true, departed?.onOpenFile != true {
                clauses.append("takes the open \(fileName(move.to.file))-file")
            } else if landed?.onHalfOpenFile == true, departed?.onHalfOpenFile != true {
                clauses.append("puts the rook on the half-open \(fileName(move.to.file))-file")
            }
            if landed?.onSeventhRank == true, departed?.onSeventhRank != true {
                clauses.append("lands the rook on the seventh rank")
            }
            let stacked = after.heavyPieces.filter {
                $0.color == mover && $0.kind == .rook && $0.square.file == move.to.file
            }
            if stacked.count > 1 { clauses.append("doubles the rooks") }
        }

        if piece.kind == .knight, after.knights.first(where: { $0.square == move.to })?.isOutpost == true {
            clauses.append("plants the knight on the \(move.to) outpost, where no pawn can dislodge it")
        }

        if let ours = after.structure[mover], let wasOurs = before.structure[mover],
           ours.passed.count > wasOurs.passed.count {
            clauses.append("creates a passed pawn")
        }

        if let theirs = after.structure[them], let wasTheirs = before.structure[them],
           theirs.isolated.count > wasTheirs.isolated.count {
            clauses.append("leaves the opponent with an isolated pawn")
        }

        if before.hasBishopPair[them] == true, after.hasBishopPair[them] == false {
            clauses.append("breaks up the enemy bishop pair")
        }

        for (index, file) in after.files.enumerated() where file.isOpen && !before.files[index].isOpen {
            clauses.append("opens the \(file.name)-file")
        }

        if let now = after.mobility[mover], let was = before.mobility[mover], now - was >= 6 {
            clauses.append("sharply increases the activity of the pieces")
        }

        if let now = after.kingSafety[them]?.openFilesNearby,
           let was = before.kingSafety[them]?.openFilesNearby, now > was {
            clauses.append("pries open lines toward the enemy king")
        }

        return clauses
    }

    /// A full sentence, or nil when the move achieved nothing worth naming.
    public static func sentence(
        san: String,
        before: PositionFeatures,
        after: PositionFeatures,
        move: Move,
        position: Position,
        resulting: Position
    ) -> String? {
        let parts = clauses(
            before: before, after: after, move: move,
            position: position, resulting: resulting
        )
        guard !parts.isEmpty else { return nil }
        return "\(san) \(join(parts))."
    }

    /// A static read of a position, for the judgement exercises.
    public static func summary(_ features: PositionFeatures) -> [String] {
        var points: [String] = []

        let openFiles = features.files.filter(\.isOpen).map(\.name)
        if !openFiles.isEmpty {
            points.append("Open file\(openFiles.count > 1 ? "s" : ""): \(openFiles.joined(separator: ", ")).")
        }

        for color in [PieceColor.white, PieceColor.black] {
            let side = color == .white ? "White" : "Black"

            let activeRooks = features.heavyPieces.filter {
                $0.color == color && $0.kind == .rook && ($0.onOpenFile || $0.onHalfOpenFile)
            }
            if !activeRooks.isEmpty {
                let squares = activeRooks.map { "\($0.square)" }.joined(separator: " and ")
                points.append("\(side) rook\(activeRooks.count > 1 ? "s" : "") on \(squares) control open lines.")
            }

            let outposts = features.knights.filter { $0.color == color && $0.isOutpost }
            if !outposts.isEmpty {
                points.append("\(side) has a secure knight on \(outposts.map { "\($0.square)" }.joined(separator: ", ")).")
            }

            if let structure = features.structure[color] {
                if !structure.passed.isEmpty {
                    points.append("\(side) has a passed pawn on \(structure.passed.map { "\($0)" }.joined(separator: ", ")).")
                }
                if !structure.isolated.isEmpty {
                    let squares = structure.isolated.map { "\($0)" }.joined(separator: ", ")
                    let plural = structure.isolated.count > 1
                    points.append("\(side)'s pawn\(plural ? "s" : "") on \(squares) \(plural ? "are" : "is") isolated.")
                }
                if !structure.backward.isEmpty {
                    points.append("\(side) has a backward pawn on \(structure.backward.map { "\($0)" }.joined(separator: ", ")).")
                }
            }
        }

        if features.hasBishopPair[.white] != features.hasBishopPair[.black] {
            points.append("\(features.hasBishopPair[.white] == true ? "White" : "Black") holds the bishop pair.")
        }

        let balance = features.materialBalance
        if abs(balance) >= 75 {
            let pawns = Double(abs(balance)) / 100
            points.append("Material: \(balance > 0 ? "White" : "Black") is up roughly \(String(format: "%.2f", pawns)) points.")
        } else {
            points.append("Material is level.")
        }

        if let white = features.mobility[.white], let black = features.mobility[.black], abs(white - black) >= 6 {
            points.append("\(white > black ? "White" : "Black") has noticeably more active pieces (\(white) versus \(black) legal moves).")
        }

        return points
    }

    // MARK: - Helpers

    static func capturedPiece(move: Move, position: Position) -> Piece? {
        if move.kind == .enPassant {
            return position[Square(file: move.to.file, rank: move.from.rank)]
        }
        return position[move.to]
    }

    public static func name(of kind: PieceKind) -> String {
        switch kind {
        case .pawn: "pawn"
        case .knight: "knight"
        case .bishop: "bishop"
        case .rook: "rook"
        case .queen: "queen"
        case .king: "king"
        }
    }

    static func fileName(_ index: Int) -> String {
        String(Character(UnicodeScalar(UInt8(97 + index))))
    }

    public static func join(_ clauses: [String]) -> String {
        guard clauses.count > 1 else { return clauses.first ?? "" }
        return clauses.dropLast().joined(separator: ", ") + " and " + clauses.last!
    }
}
