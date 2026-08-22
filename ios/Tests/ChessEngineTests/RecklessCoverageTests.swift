import ChessCore
import Foundation
import Testing
@testable import ChessEngine

/// The same two questions `ValueCoverageTests` asks of Stockfish, asked of
/// Reckless.
///
/// This is not a formality. The board labels every legal move with a number, and
/// it gets those numbers from one wide MultiPV search. An engine that reports
/// only the lines it thought were worth reporting leaves the board drawing a
/// plain dot where a number was promised — so whether Reckless can hold the
/// labels is a measured fact, not a hope.
@Suite(.serialized)
struct RecklessCoverageTests {
    /// A quiet middlegame: nothing forces the search to stop early.
    private let quiet = "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQK2R w KQkq - 0 1"
    /// A forced mate. The search proves it and stops — which is the case that
    /// matters here, because a mate is exactly when a player asks what the
    /// other moves were worth.
    private let mating = "6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1"

    @Test("A quiet position values every legal move")
    func quietIsComplete() async throws {
        let engine = await RecklessTests.makeEngine()
        let legal = Position(fen: quiet)!.legalMoves().count
        let values = try await engine.valueEveryMove(fen: quiet)
        #expect(values.byMove.count == legal,
                "valued \(values.byMove.count) of \(legal) legal moves")
    }

    @Test("A position with a forced mate values every legal move too")
    func mateIsComplete() async throws {
        let engine = await RecklessTests.makeEngine()
        let legal = Position(fen: mating)!.legalMoves().count
        let values = try await engine.valueEveryMove(fen: mating)
        #expect(values.byMove.count == legal,
                "valued \(values.byMove.count) of \(legal) legal moves")
    }
}
