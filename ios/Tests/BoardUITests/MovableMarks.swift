import ChessCore
import Testing
@testable import BoardUI

/// The mark that answers "what can I even do here?".
///
/// Its reason for existing is check. A player who has just learned what check
/// is knows the king is attacked and reaches for the king; that it is legal to
/// block the attack, or to take the piece giving it, is the next thing to learn
/// and nothing on the board says it. Ringing every piece that can move says it
/// without saying which move to play.
@Suite("Movable pieces")
struct MovableMarks {
    /// Every legal move, grouped the way a board hands them to a view.
    static func destinations(_ fen: String) throws -> [Square: [Square]] {
        let position = try #require(Position(fen: fen))
        return Dictionary(grouping: position.legalMoves(), by: \.from)
            .mapValues { $0.map(\.to) }
    }

    static func squares(_ marks: [BoardShape]) -> [Square] {
        marks.compactMap {
            if case .circle(let square) = $0.kind { return square }
            return nil
        }
    }

    /// A rook checking down the e-file, a bishop that can step into it, and a
    /// king with squares of its own. The king is one answer of two, which is
    /// the thing this mark exists to say.
    ///
    /// The bishop is on a6 rather than the long diagonal, where it would have
    /// been giving check to the black king at the same time — a position with
    /// the side not to move in check cannot arise in a game, and `Position`
    /// refuses to parse one. The first draft of this test was that position.
    @Test("In check, the king is not the only piece marked")
    func inCheckThereIsMoreThanTheKing() throws {
        let marks = BoardShape.movable(try Self.destinations("4r2k/8/B7/8/8/8/8/4K3 w - - 0 1"))
        let squares = Self.squares(marks)
        #expect(squares.contains(Square("a6")!), "the bishop, which can block on e2")
        #expect(squares.contains(Square("e1")!), "and the king, which can step off the file")
        #expect(squares.count == 2, "and nothing else: \(squares.map(String.init(describing:)))")
    }

    /// Where only the king can move, it is the only one marked — the mark has
    /// to be able to say that too, or it says nothing.
    @Test("Where only the king can move, only the king is marked")
    func onlyTheKing() throws {
        // A bare king, with a rook holding the seventh rank. Not check — g8 is
        // free — so the king moves because it is the only piece there is.
        let marks = BoardShape.movable(try Self.destinations("7k/R7/8/8/8/8/8/K7 b - - 0 1"))
        #expect(Self.squares(marks) == [Square("h8")!])
    }

    /// Checkmate has nothing to mark, and neither has stalemate.
    @Test("A finished position is marked with nothing", arguments: [
        "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3",  // fool's mate
        "7k/5Q2/6K1/8/8/8/8/8 b - - 0 1",                                  // stalemate
    ])
    func finishedPositions(fen: String) throws {
        let marks = BoardShape.movable(try Self.destinations(fen))
        let position = try #require(Position(fen: fen))
        #expect(marks.isEmpty == position.legalMoves().isEmpty)
    }

    /// The same position always gives the same list, so nothing downstream
    /// mistakes a dictionary's order for a change on the board.
    @Test("The order is settled")
    func orderIsSettled() throws {
        let destinations = try Self.destinations(Position().fen)
        let once = Self.squares(BoardShape.movable(destinations))
        for _ in 0..<20 {
            #expect(Self.squares(BoardShape.movable(destinations)) == once)
        }
        #expect(once == once.sorted { $0.index < $1.index })
    }
}
