import ChessCore
import Testing
@testable import ChessTraining

@Suite("Material balance")
struct MaterialTests {
    @Test("Nothing is captured in the starting position")
    func startingPosition() {
        let material = MaterialBalance(Position())
        #expect(material.capturedBy(.white).isEmpty)
        #expect(material.capturedBy(.black).isEmpty)
        #expect(material.lead(of: .white) == 0)
        #expect(material.lead(of: .black) == 0)
    }

    @Test("A missing piece is credited to the side that took it")
    func capturesAreCredited() throws {
        // White is a knight and a pawn down, Black a rook down.
        let fen = "1nbqkbnr/pppppppp/8/8/8/8/PPPPPPP1/R1BQKBNR w KQk - 0 1"
        let position = try #require(Position(fen: fen))
        let material = MaterialBalance(position)

        #expect(material.capturedBy(.black) == [.knight, .pawn])
        #expect(material.capturedBy(.white) == [.rook])
        // Rook 5 against knight 3 plus pawn 1.
        #expect(material.lead(of: .white) == 1)
        #expect(material.lead(of: .black) == 0)
    }

    @Test("A promoted pawn does not read as a captured queen")
    func promotionDoesNotUnderflow() throws {
        // Two white queens, seven white pawns: one pawn promoted, nothing taken.
        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPP1/RNBQKBNQ w kq - 0 1"
        let position = try #require(Position(fen: fen))
        let material = MaterialBalance(position)

        #expect(material.capturedBy(.black) == [.rook, .pawn])
        #expect(material.capturedBy(.white).isEmpty)
    }
}
