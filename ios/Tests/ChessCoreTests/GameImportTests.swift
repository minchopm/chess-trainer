import Foundation
import Testing
@testable import ChessCore

@Suite("Reading a pasted game")
struct GameImportTests {
    @Test("Bare moves, the way a book prints them")
    func bareMoves() throws {
        let read = try #require(GameImport.read("1. e4 e5 2. Nf3 Nc6 3. Bb5"))
        #expect(read.moves.count == 5)
        #expect(read.stoppedAt == nil)
        #expect(read.final.sideToMove == .black)
    }

    @Test("Moves with no numbering at all")
    func unnumbered() throws {
        let read = try #require(GameImport.read("e4 e5 Nf3 Nc6"))
        #expect(read.moves.count == 4)
    }

    @Test("A number stuck to its move")
    func numberTouchingMove() throws {
        let read = try #require(GameImport.read("1.e4 e5 2.Nf3 Nc6"))
        #expect(read.moves.count == 4)
    }

    /// What actually comes off a website.
    @Test("A full PGN, headers, comments, variations and result")
    func wholePGN() throws {
        let pgn = """
        [Event "Paris"]
        [Site "Paris FRA"]
        [Result "1-0"]

        1. e4 e5 {the old way} 2. Nf3 (2. f4 exf4 is the gambit) 2... Nc6 $1
        3. Bb5 a6 1-0
        """
        let read = try #require(GameImport.read(pgn))
        #expect(read.moves.count == 6, "got \(read.moves.count)")
        #expect(read.stoppedAt == nil)
    }

    /// A variation is somebody else's idea about a move that was not played.
    @Test("The variation is not played")
    func variationIgnored() throws {
        let read = try #require(GameImport.read("1. e4 e5 (1... c5 2. Nf3) 2. Nf3"))
        #expect(read.moves.count == 3)
        #expect(read.final.fen.hasPrefix("rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2"))
    }

    @Test("A game that starts from a FEN header")
    func fromHeader() throws {
        // The h-pawn is on h6, not h7: with all three pawns home this is a
        // back-rank mate and the king has nowhere to go, which is what the
        // first draft of this test asked it to do.
        let pgn = """
        [FEN "6k1/5pp1/7p/8/8/8/5PPP/R5K1 w - - 0 1"]

        1. Ra8+ Kh7
        """
        let read = try #require(GameImport.read(pgn))
        #expect(read.start.fen.hasPrefix("6k1/5pp1"))
        #expect(read.moves.count == 2)
    }

    @Test("A FEN pasted on its own is a position with no moves")
    func bareFEN() throws {
        let read = try #require(GameImport.read("6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1"))
        #expect(read.moves.isEmpty)
        #expect(read.final.fen.hasPrefix("6k1/5ppp"))
    }

    @Test("UCI moves, the way a log writes them")
    func uci() throws {
        let read = try #require(GameImport.read("e2e4 e7e5 g1f3"))
        #expect(read.moves.count == 3)
    }

    /// Twenty-nine moves and a reason beats nothing and no reason.
    @Test("A typo stops the line and says where")
    func stopsAtTheTypo() throws {
        let read = try #require(GameImport.read("1. e4 e5 2. Nf3 Qxq9 3. Bb5"))
        #expect(read.moves.count == 3)
        #expect(read.stoppedAt?.token == "Qxq9")
        #expect(read.stoppedAt?.afterMoves == 3)
    }

    @Test("An illegal but well-formed move stops it too")
    func stopsAtTheIllegalMove() throws {
        let read = try #require(GameImport.read("1. e4 e5 2. Nf6"))
        #expect(read.moves.count == 2)
        #expect(read.stoppedAt?.token == "Nf6")
    }

    @Test("Nonsense is nothing at all")
    func nonsense() {
        #expect(GameImport.read("hello there") == nil)
        #expect(GameImport.read("") == nil)
    }
}
