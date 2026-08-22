import ChessCore
import Testing
@testable import BrassPawnApp

/// The free board's rules. Three of them are the whole feature: a paste lands
/// on the board at the position it reached, a move played from a position you
/// stepped back to replaces what came after it, and an engine stops thinking
/// the moment you step away from the end of the line.
@MainActor
@Suite("The free board")
struct BoardModelTests {
    /// The synthesiser is not wanted in a test run, and `play` returns early
    /// when it is off.
    private func sq(_ name: String) -> Square { Square(name)! }

    private func makeModel() -> BoardModel {
        SoundBoard.shared.isEnabled = false
        return BoardModel()
    }

    @Test("A fresh board offers moves straight away")
    func freshBoardIsPlayable() {
        let model = makeModel()
        #expect(model.position.fen == Position().fen)
        #expect(model.legalDestinations[sq("e2")]?.contains(sq("e4")) == true)
        #expect(model.line.isEmpty)
    }

    @Test("A pasted game lands at the position it reached")
    func pastedGameLandsAtTheEnd() {
        let model = makeModel()
        #expect(model.load("1. e4 e5 2. Nf3 Nc6"))
        #expect(model.line.map(\.san) == ["e4", "e5", "Nf3", "Nc6"])
        #expect(model.ply == 4)
        #expect(model.isAtLiveEnd)
        #expect(model.position.sideToMove == .white)
    }

    @Test("A bare position is a board with no line behind it")
    func pastedPositionHasNoMoves() {
        let model = makeModel()
        #expect(model.load("4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"))
        #expect(model.line.isEmpty)
        #expect(model.ply == 0)
        #expect(model.position.fen.hasPrefix("4k3/8/8/8/8/8/4P3/4K3 w"))
    }

    /// The moves before a bad token are a real game. Giving them back and
    /// naming what stopped it is the difference between a caveat and a failure.
    @Test("A line that breaks part way keeps what it read")
    func brokenLineKeepsWhatItRead() {
        let model = makeModel()
        #expect(model.load("1. e4 e5 2. Nf3 Qxz9"))
        #expect(model.line.map(\.san) == ["e4", "e5", "Nf3"])
        #expect(model.note?.contains("Qxz9") == true)
    }

    @Test("Rubbish is refused and said to be refused")
    func rubbishIsRefused() {
        let model = makeModel()
        #expect(!model.load("the quick brown fox"))
        #expect(model.note != nil)
        #expect(model.line.isEmpty)
    }

    @Test("Stepping back and forward walks the same line")
    func steppingWalksTheLine() {
        let model = makeModel()
        #expect(model.load("1. e4 e5 2. Nf3 Nc6"))
        let atEnd = model.position.fen

        model.stepToStart()
        #expect(model.ply == 0)
        #expect(model.position.fen == Position().fen)
        #expect(!model.canStepBack)

        model.stepToEnd()
        #expect(model.position.fen == atEnd)
        #expect(!model.canStepForward)
    }

    /// An analysis board branches. The moves after the point you played from
    /// were one line; now there is another, and keeping both would mean a tree,
    /// which is a different feature.
    @Test("A move played from the middle replaces what came after it")
    func playingFromTheMiddleTruncates() {
        let model = makeModel()
        #expect(model.load("1. e4 e5 2. Nf3 Nc6"))

        model.step(to: 2)                       // after 1. e4 e5
        model.play(from: sq("b1"), to: sq("c3"), promotion: nil)

        #expect(model.line.map(\.san) == ["e4", "e5", "Nc3"])
        #expect(model.ply == 3)
        #expect(model.isAtLiveEnd)
    }

    @Test("An illegal move is ignored rather than half-played")
    func illegalMovesAreIgnored() {
        let model = makeModel()
        model.play(from: sq("e2"), to: sq("e5"), promotion: nil)
        #expect(model.line.isEmpty)
        #expect(model.position.fen == Position().fen)
    }

    /// The squares you may drag from depend on who holds the side to move, so
    /// handing that side to an engine has to take them away — and giving it
    /// back has to bring them back.
    @Test("A side held by an engine offers no squares to drag")
    func engineSeatTakesTheHighlightsAway() {
        let model = makeModel()
        #expect(!model.legalDestinations.isEmpty)

        model.setSeat(.engine, for: .white)
        #expect(model.legalDestinations.isEmpty)

        model.setSeat(.you, for: .white)
        #expect(model.legalDestinations[sq("e2")]?.contains(sq("e4")) == true)
    }

    @Test("An engine owes a move only when it holds the side to move")
    func engineOwesOnlyItsOwnTurn() {
        let model = makeModel()
        #expect(!model.engineOwesMove)

        model.setSeat(.engine, for: .black)
        #expect(!model.engineOwesMove)          // white to move, and white is yours

        model.play(from: sq("e2"), to: sq("e4"), promotion: nil)
        #expect(model.engineOwesMove)           // now it is black's turn
    }

    /// Stepping back to look at something has to stop the engines, or the board
    /// you are reading moves out from under you.
    @Test("Stepping back off the end stops the engines")
    func steppingBackPausesTheEngines() {
        let model = makeModel()
        model.setSeat(.engine, for: .black)
        model.play(from: sq("e2"), to: sq("e4"), promotion: nil)
        #expect(model.engineOwesMove)

        model.stepBack()
        #expect(!model.engineOwesMove)

        model.stepToEnd()
        #expect(model.engineOwesMove)
    }

    @Test("A finished game owes nobody a move")
    func checkmateOwesNothing() {
        let model = makeModel()
        model.setSeat(.engine, for: .black)
        #expect(model.load("1. f3 e5 2. g4 Qh4#"))
        #expect(model.position.isCheckmate)
        #expect(!model.engineOwesMove)
    }

    @Test("Starting over clears the line and the note")
    func startingOverClears() {
        let model = makeModel()
        #expect(model.load("1. e4 e5"))
        #expect(model.note != nil)

        model.reset()
        #expect(model.line.isEmpty)
        #expect(model.ply == 0)
        #expect(model.note == nil)
        #expect(model.position.fen == Position().fen)
    }

    /// Flipping is a camera move, not a game move: it must not touch the line.
    @Test("Flipping the board leaves the game alone")
    func flippingIsOnlyACamera() {
        let model = makeModel()
        #expect(model.load("1. e4 e5"))
        let before = model.position.fen

        model.flip()
        #expect(model.orientation == .black)
        #expect(model.position.fen == before)
        #expect(model.line.count == 2)
    }
}
