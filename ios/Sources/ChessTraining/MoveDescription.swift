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
            return captured.map { [L.t("coach.mateCapturing", "delivers checkmate, capturing the %@", name(of: $0.kind))] }
                ?? [L.t("coach.mate", "delivers checkmate")]
        }

        var clauses: [String] = []

        switch move.kind {
        case .kingsideCastle: clauses.append(L.t("coach.castlesKingside", "castles kingside, tucking the king away"))
        case .queensideCastle: clauses.append(L.t("coach.castlesQueenside", "castles queenside"))
        default: break
        }

        if resulting.isCheck { clauses.append(L.t("coach.givesCheck", "gives check")) }

        if let captured {
            let gained = captured.kind.value
            let risked = piece.kind.value
            clauses.append(gained > risked + 50
                ? L.t("coach.winsMaterial", "wins material — takes the %@", name(of: captured.kind))
                : L.t("coach.captures", "captures the %@", name(of: captured.kind)))
        }

        if let promotion = move.promotion {
            clauses.append(L.t("coach.promotes", "promotes to a %@", name(of: promotion)))
        }

        if piece.kind == .rook {
            let landed = after.heavyPieces.first { $0.square == move.to }
            let departed = before.heavyPieces.first { $0.square == move.from }
            if landed?.onOpenFile == true, departed?.onOpenFile != true {
                clauses.append(L.t("coach.takesOpenFile", "takes the open %@-file", fileName(move.to.file)))
            } else if landed?.onHalfOpenFile == true, departed?.onHalfOpenFile != true {
                clauses.append(L.t("coach.halfOpenFile", "puts the rook on the half-open %@-file", fileName(move.to.file)))
            }
            if landed?.onSeventhRank == true, departed?.onSeventhRank != true {
                clauses.append(L.t("coach.seventhRank", "lands the rook on the seventh rank"))
            }
            let stacked = after.heavyPieces.filter {
                $0.color == mover && $0.kind == .rook && $0.square.file == move.to.file
            }
            if stacked.count > 1 { clauses.append(L.t("coach.doublesRooks", "doubles the rooks")) }
        }

        if piece.kind == .knight, after.knights.first(where: { $0.square == move.to })?.isOutpost == true {
            clauses.append(L.t("coach.outpost", "plants the knight on the %@ outpost, where no pawn can dislodge it", "\(move.to)"))
        }

        if let ours = after.structure[mover], let wasOurs = before.structure[mover],
           ours.passed.count > wasOurs.passed.count {
            clauses.append(L.t("coach.passedPawn", "creates a passed pawn"))
        }

        if let theirs = after.structure[them], let wasTheirs = before.structure[them],
           theirs.isolated.count > wasTheirs.isolated.count {
            clauses.append(L.t("coach.isolatesOpponent", "leaves the opponent with an isolated pawn"))
        }

        if before.hasBishopPair[them] == true, after.hasBishopPair[them] == false {
            clauses.append(L.t("coach.breaksBishopPair", "breaks up the enemy bishop pair"))
        }

        for (index, file) in after.files.enumerated() where file.isOpen && !before.files[index].isOpen {
            clauses.append(L.t("coach.opensFile", "opens the %@-file", file.name))
        }

        if let now = after.mobility[mover], let was = before.mobility[mover], now - was >= 6 {
            clauses.append(L.t("coach.moreActivity", "sharply increases the activity of the pieces"))
        }

        if let now = after.kingSafety[them]?.openFilesNearby,
           let was = before.kingSafety[them]?.openFilesNearby, now > was {
            clauses.append(L.t("coach.opensKingLines", "pries open lines toward the enemy king"))
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
            points.append(openFiles.count > 1
                ? L.t("summary.openFiles", "Open files: %@.", openFiles.joined(separator: ", "))
                : L.t("summary.openFile", "Open file: %@.", openFiles.joined(separator: ", ")))
        }

        for color in [PieceColor.white, PieceColor.black] {
            let side = L.color(color)

            let activeRooks = features.heavyPieces.filter {
                $0.color == color && $0.kind == .rook && ($0.onOpenFile || $0.onHalfOpenFile)
            }
            if !activeRooks.isEmpty {
                let squares = activeRooks.map { "\($0.square)" }.joined(separator: " and ")
                points.append(activeRooks.count > 1
                    ? L.t("summary.rooksOpenLines", "%@ rooks on %@ control open lines.", side, squares)
                    : L.t("summary.rookOpenLines", "%@ rook on %@ controls open lines.", side, squares))
            }

            let outposts = features.knights.filter { $0.color == color && $0.isOutpost }
            if !outposts.isEmpty {
                points.append(L.t("summary.secureKnight", "%@ has a secure knight on %@.",
                                  side, outposts.map { "\($0.square)" }.joined(separator: ", ")))
            }

            if let structure = features.structure[color] {
                if !structure.passed.isEmpty {
                    points.append(L.t("summary.passedPawn", "%@ has a passed pawn on %@.",
                                      side, structure.passed.map { "\($0)" }.joined(separator: ", ")))
                }
                if !structure.isolated.isEmpty {
                    let squares = structure.isolated.map { "\($0)" }.joined(separator: ", ")
                    let plural = structure.isolated.count > 1
                    points.append(plural
                        ? L.t("summary.isolatedPawns", "%@'s pawns on %@ are isolated.", side, squares)
                        : L.t("summary.isolatedPawn", "%@'s pawn on %@ is isolated.", side, squares))
                }
                if !structure.backward.isEmpty {
                    points.append(L.t("summary.backwardPawn", "%@ has a backward pawn on %@.",
                                      side, structure.backward.map { "\($0)" }.joined(separator: ", ")))
                }
            }
        }

        if features.hasBishopPair[.white] != features.hasBishopPair[.black] {
            points.append(L.t("summary.bishopPair", "%@ holds the bishop pair.",
                              L.color(features.hasBishopPair[.white] == true ? .white : .black)))
        }

        let balance = features.materialBalance
        if abs(balance) >= 75 {
            let pawns = Double(abs(balance)) / 100
            points.append(L.t("summary.material", "Material: %@ is up roughly %@ points.",
                              L.color(balance > 0 ? .white : .black), String(format: "%.2f", pawns)))
        } else {
            points.append(L.t("summary.materialLevel", "Material is level."))
        }

        if let white = features.mobility[.white], let black = features.mobility[.black], abs(white - black) >= 6 {
            points.append(L.t("summary.moreActive", "%@ has noticeably more active pieces (%lld versus %lld legal moves).",
                              L.color(white > black ? .white : .black), max(white, black), min(white, black)))
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
        case .pawn: L.t("piece.pawn", "pawn")
        case .knight: L.t("piece.knight", "knight")
        case .bishop: L.t("piece.bishop", "bishop")
        case .rook: L.t("piece.rook", "rook")
        case .queen: L.t("piece.queen", "queen")
        case .king: L.t("piece.king", "king")
        }
    }

    static func fileName(_ index: Int) -> String {
        String(Character(UnicodeScalar(UInt8(97 + index))))
    }

    public static func join(_ clauses: [String]) -> String {
        guard clauses.count > 1 else { return clauses.first ?? "" }
        return L.t("coach.joinClauses", "%@ and %@",
                   clauses.dropLast().joined(separator: ", "), clauses.last!)
    }
}
