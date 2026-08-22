import ChessCore
import Testing
@testable import BrassPawnApp

/// The editor's whole job is to refuse to hand over a board that is not a
/// position, and to say why in a sentence somebody can act on.
@MainActor
@Suite("Setting a position up by hand")
struct PositionEditorTests {
    private func sq(_ name: String) -> Square { Square(name)! }

    private func empty() -> PositionEditorModel {
        let model = PositionEditorModel()
        model.clear()
        return model
    }

    /// Both kings and nothing else — the smallest legal board.
    private func kings() -> PositionEditorModel {
        let model = empty()
        model.brush = .place(Piece(.white, .king))
        model.tap(sq("e1"))
        model.brush = .place(Piece(.black, .king))
        model.tap(sq("e8"))
        return model
    }

    @Test("The opening position is legal and reads back exactly")
    func openingRoundTrips() {
        let model = PositionEditorModel()
        #expect(model.problem == nil)
        #expect(model.fen == Position().fen)
    }

    @Test("Two kings alone are a position")
    func bareKingsAreLegal() {
        #expect(kings().problem == nil)
    }

    @Test("An empty board has no king and says so")
    func emptyBoardIsRefused() {
        let model = empty()
        #expect(model.problem != nil)
        #expect(model.position == nil)
    }

    @Test("A second king of the same colour is refused")
    func twoKingsOfAColourAreRefused() {
        let model = kings()
        model.brush = .place(Piece(.white, .king))
        model.tap(sq("a1"))
        #expect(model.problem != nil)
        #expect(model.position == nil)
    }

    @Test("Kings standing next to each other are refused")
    func touchingKingsAreRefused() {
        let model = empty()
        model.brush = .place(Piece(.white, .king))
        model.tap(sq("e1"))
        model.brush = .place(Piece(.black, .king))
        model.tap(sq("e2"))
        #expect(model.problem != nil)
        #expect(model.position == nil)
    }

    @Test("A pawn on the first or the last rank is refused")
    func pawnOnTheEdgeIsRefused() {
        let model = kings()
        model.brush = .place(Piece(.white, .pawn))
        model.tap(sq("a1"))
        #expect(model.problem != nil)

        model.tap(sq("a1"))          // the same tap takes it off again
        #expect(model.problem == nil)

        model.tap(sq("a8"))
        #expect(model.problem != nil)
    }

    @Test("Nine pawns are refused")
    func tooManyPawnsAreRefused() {
        let model = kings()
        model.brush = .place(Piece(.white, .pawn))
        for file in 0..<8 { model.tap(Square(file: file, rank: 1)) }
        #expect(model.problem == nil)
        model.tap(Square(file: 0, rank: 2))
        #expect(model.problem != nil)
    }

    /// A position where the side not on move is already in check could only be
    /// reached by a move nobody is allowed to make.
    @Test("The side not to move being in check is refused")
    func wrongSideInCheckIsRefused() {
        let model = kings()
        model.brush = .place(Piece(.white, .rook))
        model.tap(sq("e4"))          // white rook attacks the black king on e8

        model.sideToMove = .white
        #expect(model.problem != nil, "black is in check but it is white's move")

        model.sideToMove = .black
        #expect(model.problem == nil, "black to move out of check is an ordinary position")
    }

    @Test("Tapping the armed piece onto its own square takes it off")
    func tappingTwiceErases() {
        let model = empty()
        model.brush = .place(Piece(.white, .queen))
        model.tap(sq("d4"))
        #expect(model.pieces[sq("d4")] == Piece(.white, .queen))
        model.tap(sq("d4"))
        #expect(model.pieces[sq("d4")] == nil)
    }

    @Test("The eraser takes off whatever is there")
    func eraserClearsAnything() {
        let model = PositionEditorModel()
        model.brush = .erase
        model.tap(sq("e2"))
        #expect(model.pieces[sq("e2")] == nil)
    }

    // MARK: - Castling

    /// A right left ticked after the rook has been moved away writes a FEN that
    /// says something untrue, and the engines believe it.
    @Test("Moving a rook away drops the castling right with it")
    func castlingFollowsTheRook() {
        let model = PositionEditorModel()
        #expect(model.fen.contains("KQkq"))

        model.brush = .erase
        model.tap(sq("h1"))
        #expect(!model.canCastle(.whiteKingside))
        #expect(!model.fen.contains("KQkq"))
        #expect(model.fen.contains(" Qkq "))
    }

    @Test("A right cannot be set for a king that has moved")
    func castlingNeedsTheKingHome() {
        let model = kings()          // kings on e1 and e8, no rooks
        model.setCastling(.whiteKingside, on: true)
        #expect(!model.canCastle(.whiteKingside))
        #expect(model.fen.contains(" - - "))
    }

    @Test("Clearing the board clears the castling rights with it")
    func clearingDropsRights() {
        let model = PositionEditorModel()
        model.clear()
        #expect(model.fen.hasSuffix(" w - - 0 1"))
    }

    // MARK: - Handing over

    @Test("A finished board hands over the position it shows")
    func handsOverWhatItShows() {
        let model = kings()
        model.brush = .place(Piece(.black, .queen))
        model.tap(sq("d5"))
        model.sideToMove = .white

        let position = model.position
        #expect(position != nil)
        #expect(position?.fen == model.fen)
        #expect(position?[sq("d5")] == Piece(.black, .queen))
    }
}
