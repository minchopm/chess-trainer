import ChessCore
import ChessEngine
import Testing
@testable import BrassPawnApp

/// An engine that always plays the first legal move, slowly enough that the
/// test can change the board underneath it.
///
/// `analyse` throws because the free board never calls it — a stub that
/// returned a plausible-looking analysis would be inventing a contract nobody
/// exercises.
private actor StubEngine: Engine {
    private let delayMs: Int
    private(set) var searches = 0
    private(set) var stops = 0
    private var stopped = false

    init(delayMs: Int) { self.delayMs = delayMs }

    nonisolated var capabilities: EngineCapabilities {
        EngineCapabilities(name: "Stub", limitsStrength: false)
    }

    func setOption(_ name: String, _ value: String) {}
    func newGame() {}
    func stop() {
        stops += 1
        stopped = true
    }

    func analyse(fen: String, depth: Int, movetimeMs: Int, multiPV: Int) async throws -> Analysis {
        throw EngineError.invalidPosition(fen)
    }

    /// Slept in slices so `stop` can actually cut it short, the way a real
    /// search does. A stub that ignored `stop` would let the test pass while
    /// the app still waited out every abandoned budget.
    func chooseMove(fen: String, elo: Int?, depth: Int, movetimeMs: Int) async throws -> String? {
        searches += 1
        stopped = false
        var slept = 0
        while slept < delayMs, !stopped {
            try? await Task.sleep(for: .milliseconds(10))
            slept += 10
        }
        guard let position = Position(fen: fen) else { return nil }
        return position.legalMoves().first?.uci
    }
}

/// What happens when the board changes while an engine is mid-search.
@MainActor
@Suite("The free board under an engine")
struct BoardEngineTests {
    private func makeModel() -> BoardModel {
        SoundBoard.shared.isEnabled = false
        return BoardModel()
    }

    @Test("An engine seat plays when it is put on move")
    func engineSeatPlays() async {
        let model = makeModel()
        let engine = StubEngine(delayMs: 5)
        model.setSeat(.engine(.stockfish), for: .white)

        await model.runEngines { _ in engine }
        #expect(model.line.count == 1)
        #expect(model.position.sideToMove == .black)
    }

    /// The bug this holds: a seat changing hands during a search invalidates the
    /// answer, and the caller that made the change finds `runEngines` already
    /// running and leaves it alone. If the loop gives up at that point, nobody
    /// restarts it and the board sits there with an engine on move and no move
    /// coming.
    @Test("A seat changing mid-search does not strand the board")
    func seatChangeMidSearchDoesNotStall() async {
        let model = makeModel()
        let engine = StubEngine(delayMs: 60)
        model.setSeat(.engine(.stockfish), for: .white)

        async let running: Void = model.runEngines { _ in engine }

        // While the first search is in flight, hand Black over and take it back.
        // Two changes, so the answer being computed is stale by the time it
        // lands — but White is still an engine and still owes a move.
        try? await Task.sleep(for: .milliseconds(20))
        model.setSeat(.engine(.stockfish), for: .black)
        model.setSeat(.you, for: .black)

        await running

        #expect(model.line.count == 1, "White never moved after the seat changed")
        #expect(await engine.searches >= 2, "the stale search should have been redone")
    }

    /// Without this the abandoned search ran its whole budget while `isThinking`
    /// held the next one off, and several quick changes queued behind each
    /// other. It looked exactly like the board had frozen.
    @Test("Handing a seat over cuts the running search short")
    func seatChangeStopsTheSearch() async {
        let model = makeModel()
        let engine = StubEngine(delayMs: 2000)
        model.setSeat(.engine(.stockfish), for: .white)

        async let running: Void = model.runEngines { _ in engine }
        try? await Task.sleep(for: .milliseconds(40))
        model.setSeat(.you, for: .white)
        await running

        #expect(await engine.stops >= 1, "the abandoned search was left to run its budget")
    }

    @Test("Stepping away cuts the running search short too")
    func stepStopsTheSearch() async {
        let model = makeModel()
        #expect(model.load("1. e4 e5 2. Nf3"))
        let engine = StubEngine(delayMs: 2000)
        model.setSeat(.engine(.stockfish), for: .black)

        async let running: Void = model.runEngines { _ in engine }
        try? await Task.sleep(for: .milliseconds(40))
        model.stepBack()
        await running

        #expect(await engine.stops >= 1)
    }

    /// Stepping away from the end while a search runs must not drop a move onto
    /// the position being looked at.
    @Test("A step during a search throws the answer away")
    func steppingMidSearchDropsTheMove() async {
        let model = makeModel()
        #expect(model.load("1. e4 e5 2. Nf3"))
        let engine = StubEngine(delayMs: 60)
        model.setSeat(.engine(.stockfish), for: .black)

        async let running: Void = model.runEngines { _ in engine }
        try? await Task.sleep(for: .milliseconds(20))
        model.stepBack()
        await running

        #expect(model.line.count == 3, "the line grew while nobody was at the end of it")
        #expect(model.ply == 2)
    }
}
