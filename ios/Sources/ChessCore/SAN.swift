import Foundation

extension Position {
    /// Standard algebraic notation for a legal move in this position: "Nxe5+".
    ///
    /// The fiddly part is disambiguation. When two identical pieces can reach
    /// the same square the notation must say which one moved, using the file if
    /// that distinguishes them, otherwise the rank, otherwise both.
    public func san(for move: Move) -> String {
        if move.kind == .kingsideCastle { return withSuffix("O-O", after: move) }
        if move.kind == .queensideCastle { return withSuffix("O-O-O", after: move) }

        guard let piece = self[move.from] else { return move.uci }

        var text = ""

        if piece.kind == .pawn {
            if move.isCapture {
                text += String(Character(UnicodeScalar(UInt8(97 + move.from.file))))
                text += "x"
            }
            text += move.to.description
            if let promotion = move.promotion {
                text += "=" + String(promotion.letter).uppercased()
            }
        } else {
            text += String(piece.kind.letter).uppercased()
            text += disambiguation(for: move, piece: piece)
            if move.isCapture { text += "x" }
            text += move.to.description
        }

        return withSuffix(text, after: move)
    }

    private func disambiguation(for move: Move, piece: Piece) -> String {
        let rivals = legalMoves().filter { candidate in
            candidate.to == move.to
                && candidate.from != move.from
                && self[candidate.from] == piece
        }
        guard !rivals.isEmpty else { return "" }

        let fileIsUnique = rivals.allSatisfy { $0.from.file != move.from.file }
        if fileIsUnique {
            return String(Character(UnicodeScalar(UInt8(97 + move.from.file))))
        }

        let rankIsUnique = rivals.allSatisfy { $0.from.rank != move.from.rank }
        if rankIsUnique {
            return String(move.from.rank + 1)
        }

        return move.from.description
    }

    /// Appends "+" or "#" by looking at the position the move produces.
    private func withSuffix(_ text: String, after move: Move) -> String {
        var next = self
        next.makeUnchecked(move)
        if next.isCheckmate { return text + "#" }
        if next.isCheck { return text + "+" }
        return text
    }

    /// Parse SAN against this position. Lenient about decorations like "!?" and
    /// the "e.p." suffix, strict about the move itself being legal.
    public func move(san notation: String) -> Move? {
        var text = notation.trimmingCharacters(in: .whitespaces)
        for noise in ["!", "?", "+", "#", "e.p.", " "] {
            text = text.replacingOccurrences(of: noise, with: "")
        }
        guard !text.isEmpty else { return nil }

        let moves = legalMoves()

        if text == "O-O" || text == "0-0" {
            return moves.first { $0.kind == .kingsideCastle }
        }
        if text == "O-O-O" || text == "0-0-0" {
            return moves.first { $0.kind == .queensideCastle }
        }

        // Matching by regenerating notation is slower than parsing the string,
        // but it cannot disagree with `san(for:)` — and a parser that disagrees
        // with its own printer is a bug that surfaces only in stored games.
        return moves.first { candidate in
            var printed = self.san(for: candidate)
            for noise in ["!", "?", "+", "#"] {
                printed = printed.replacingOccurrences(of: noise, with: "")
            }
            return printed == text
        }
    }
}
