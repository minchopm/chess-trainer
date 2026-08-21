import Foundation
import Testing
@testable import ChessTraining

@Suite("Guess the Elo")
struct EloGuessTests {
    @Test("A guess is scored against the average of the two players")
    func scoring() {
        let guess = EloGuess(guess: 1600, actual: 1550)
        #expect(guess.error == 50)
        #expect(guess.isHigh)
        #expect(guess.verdict == .spot)
        #expect(guess.points == 90)
    }

    @Test("White and black guesses are scored independently")
    func pairScoring() {
        let guess = EloPairGuess(
            whiteGuess: 1700,
            blackGuess: 1400,
            whiteActual: 1600,
            blackActual: 1600
        )

        #expect(guess.white.error == 100)
        #expect(guess.black.error == 200)
        #expect(guess.averageError == 150)
        #expect(guess.verdict == .fair)
        #expect(guess.points == 70)

        let record = EloGuessRecord(
            gameID: "pair",
            whiteGuess: 1700,
            whiteActual: 1600,
            blackGuess: 1400,
            blackActual: 1600
        )
        #expect(record.error == 150)
        #expect(record.bias == -50)
    }

    @Test("Verdicts widen in bands, not by a hair")
    func verdicts() {
        #expect(EloGuess(guess: 1500, actual: 1500).verdict == .spot)
        #expect(EloGuess(guess: 1600, actual: 1500).verdict == .close)
        #expect(EloGuess(guess: 1750, actual: 1500).verdict == .fair)
        #expect(EloGuess(guess: 2000, actual: 1500).verdict == .off)
        // Five hundred out is worth nothing, and nothing is the floor.
        #expect(EloGuess(guess: 2200, actual: 1500).points == 0)
    }

    @Test("Statistics report the miss and the direction of it")
    func statistics() {
        let stats = EloGuessStats([
            EloGuessRecord(gameID: "a", guess: 1700, actual: 1500),
            EloGuessRecord(gameID: "b", guess: 1600, actual: 1500),
            EloGuessRecord(gameID: "c", guess: 1500, actual: 1500),
        ])
        #expect(stats.judged == 3)
        #expect(stats.averageError == 100)
        #expect(stats.bestError == 0)
        // Consistently high, which is the useful half of the report.
        #expect(stats.bias == 100)
    }

    @Test("A judged game is remembered")
    func recording() {
        var progress = TrainingProgress()
        let verdict = progress.record(guess: 1450, on: "gabc", actual: 1500)
        #expect(verdict.error == 50)
        #expect(progress.eloGuesses.count == 1)
        #expect(progress.eloGuessStats.averageError == 50)
    }

    @Test("Progress written by an older build still loads")
    func decodesOlderFiles() throws {
        // Everything Guess the Elo added is missing here, as it would be in a
        // file written before the mode existed. The ratings must survive.
        let json = """
        {"cards":{},"themes":{},"history":[],"games":[],"rushRecords":[],
         "currentStreak":4,"bestStreak":9,
         "ratings":["tactics",1683,"positional",1420,"endgame",1310]}
        """
        let progress = try JSONDecoder().decode(TrainingProgress.self, from: Data(json.utf8))

        #expect(progress.rating(.tactics) == 1683)
        #expect(progress.currentStreak == 4)
        #expect(progress.bestStreak == 9)
        #expect(progress.eloGuesses.isEmpty)
    }
}
