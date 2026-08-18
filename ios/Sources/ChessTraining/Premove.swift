import ChessCore

/// Moves given before it is your turn.
///
/// A queue rather than a single move, because what a player has in mind while
/// the opponent thinks is usually a short plan — take, recapture, castle — not
/// one isolated reply. Each move is checked against the board that actually
/// arrives, and the first one that cannot be played takes the rest with it: the
/// moves behind it were planned on a position that never happened, so carrying
/// them out would be following a plan whose first step already failed.
public struct PremoveQueue: Equatable, Sendable {
    public private(set) var moves: [Move] = []
    /// True when the queue was thrown away because reality diverged, so the
    /// screen can say why the plan vanished instead of leaving it a mystery.
    public private(set) var wasDropped = false

    public init() {}

    public var isEmpty: Bool { moves.isEmpty }
    public var count: Int { moves.count }

    /// Every square taking part in the plan, for marking on the board.
    public var squares: [Square] { moves.flatMap { [$0.from, $0.to] } }

    /// The position the next premove is planned against: yours to move, with
    /// everything already queued played out and the opponent's pieces left
    /// exactly where they stand.
    public func planned(from position: Position, for side: PieceColor) -> Position {
        var probe = position.speculating(with: side)
        for move in moves {
            guard probe.make(move) != nil else { break }
            probe = probe.speculating(with: side)
        }
        return probe
    }

    public func destinations(in position: Position, for side: PieceColor) -> [Square: [Square]] {
        guard position.sideToMove != side, !position.isGameOver else { return [:] }
        var map: [Square: [Square]] = [:]
        for move in planned(from: position, for: side).legalMoves() {
            map[move.from, default: []].append(move.to)
        }
        return map
    }

    /// Add a move to the plan. Returns false when the piece could not make that
    /// move even on the board the plan assumes.
    @discardableResult
    public mutating func queue(
        from: Square, to: Square, promotion: PieceKind?,
        in position: Position, for side: PieceColor
    ) -> Bool {
        guard position.sideToMove != side, !position.isGameOver else { return false }
        let notation = Move(from: from, to: to, promotion: promotion)
        guard let move = planned(from: position, for: side).legalMoves()
            .first(where: { $0.matchesNotation(of: notation) })
        else { return false }
        moves.append(move)
        wasDropped = false
        return true
    }

    public mutating func clear() {
        moves = []
        wasDropped = false
    }

    /// The next move to play, or nil — either because nothing is queued, or
    /// because what was queued is no longer possible, in which case the whole
    /// plan is dropped.
    public mutating func next(in position: Position) -> Move? {
        guard let first = moves.first else { return nil }
        guard let legal = position.legalMoves().first(where: { $0.matchesNotation(of: first) }) else {
            moves = []
            wasDropped = true
            return nil
        }
        moves.removeFirst()
        wasDropped = false
        return legal
    }
}
