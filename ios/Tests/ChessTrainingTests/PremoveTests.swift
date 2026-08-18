import ChessCore
import Testing
@testable import ChessTraining

@Suite("Premoves")
struct PremoveTests {
    /// White has played e4, so Black is to move: White may plan but not play.
    private func afterE4() throws -> Position {
        var position = Position()
        let move = try #require(position.legalMoves().first { position.san(for: $0) == "e4" })
        position.make(move)
        return position
    }

    @Test("A move can be queued while it is the opponent's turn")
    func queueOnOpponentsTurn() throws {
        let position = try afterE4()
        var queue = PremoveQueue()
        let accepted = queue.queue(from: Square("g1")!, to: Square("f3")!, promotion: nil,
                                   in: position, for: .white)

        #expect(accepted)
        #expect(queue.count == 1)
        #expect(queue.squares == [Square("g1")!, Square("f3")!])
    }

    @Test("Nothing is queued on your own turn — that is a move, not a plan")
    func refusesOnYourOwnTurn() {
        var queue = PremoveQueue()
        let accepted = queue.queue(from: Square("e2")!, to: Square("e4")!, promotion: nil,
                                   in: Position(), for: .white)

        #expect(!accepted)
        #expect(queue.isEmpty)
    }

    @Test("A plan several moves deep builds on itself")
    func chains() throws {
        let position = try afterE4()
        var queue = PremoveQueue()
        let knight = queue.queue(from: Square("g1")!, to: Square("f3")!, promotion: nil,
                                 in: position, for: .white)
        // f1–c4 needs the e-pawn gone, which it is, and is judged against the
        // board the plan has built rather than the one on screen.
        let bishop = queue.queue(from: Square("f1")!, to: Square("c4")!, promotion: nil,
                                 in: position, for: .white)

        #expect(knight)
        #expect(bishop)
        #expect(queue.count == 2)

        let planned = queue.planned(from: position, for: .white)
        #expect(planned[Square("f3")!] == Piece(.white, .knight))
        #expect(planned[Square("c4")!] == Piece(.white, .bishop))
    }

    @Test("The queue plays out when the move is still legal")
    func playsOut() throws {
        var position = try afterE4()
        var queue = PremoveQueue()
        queue.queue(from: Square("g1")!, to: Square("f3")!, promotion: nil, in: position, for: .white)

        let reply = try #require(position.legalMoves().first { position.san(for: $0) == "e5" })
        position.make(reply)
        let played = queue.next(in: position)
        let next = try #require(played)

        #expect(next.from == Square("g1")!)
        #expect(next.to == Square("f3")!)
        #expect(queue.isEmpty)
        #expect(!queue.wasDropped)
    }

    @Test("A plan whose first step became impossible is dropped whole")
    func dropsTheWholePlan() throws {
        // Black to move, queen and rook facing each other down the d-file.
        // White plans Rxd8; Black takes the rook first.
        var position = try #require(Position(fen: "3q3k/8/8/8/8/8/6PP/3R2K1 b - - 0 1"))
        var queue = PremoveQueue()
        let planned = queue.queue(from: Square("d1")!, to: Square("d8")!, promotion: nil,
                                  in: position, for: .white)
        #expect(planned)

        let takesTheRook = try #require(position.legalMoves().first {
            $0.from == Square("d8")! && $0.to == Square("d1")!
        })
        position.make(takesTheRook)
        let played = queue.next(in: position)

        #expect(played == nil)
        #expect(queue.isEmpty)
        #expect(queue.wasDropped)
    }

    @Test("No destinations are offered when it is your move")
    func noDestinationsOnYourTurn() {
        let queue = PremoveQueue()
        #expect(queue.destinations(in: Position(), for: .white).isEmpty)
        #expect(!queue.destinations(in: Position(), for: .black).isEmpty)
    }
}
