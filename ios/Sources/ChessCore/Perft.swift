extension Position {
    /// Count leaf nodes at a fixed depth.
    ///
    /// This is the standard way to prove a move generator correct: the counts
    /// for well-known positions are published and unforgiving. A generator that
    /// mishandles en passant, castling rights or promotion under-promotion will
    /// match at depth 1 and diverge by depth 3.
    public func perft(_ depth: Int) -> Int {
        guard depth > 0 else { return 1 }
        let moves = legalMoves()
        if depth == 1 { return moves.count }

        var total = 0
        for move in moves {
            var next = self
            next.makeUnchecked(move)
            total += next.perft(depth - 1)
        }
        return total
    }

    /// Per-move breakdown, for locating exactly where a count diverges.
    public func perftDivide(_ depth: Int) -> [(move: String, nodes: Int)] {
        legalMoves().map { move in
            var next = self
            next.makeUnchecked(move)
            return (move.uci, next.perft(depth - 1))
        }
        .sorted { $0.move < $1.move }
    }
}
