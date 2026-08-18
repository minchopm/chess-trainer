import Foundation
import Testing
@testable import ChessTraining

struct RushTests {
    static func puzzle(_ id: String, rating: Int) -> Puzzle {
        Puzzle(id: id, fen: "8/8/8/4k3/8/8/8/R3K3 w - - 0 1", solution: ["a1a8"],
               themes: ["mate"], rating: rating, mate: true, source: nil)
    }

    @Test("A fresh run has its full time")
    func clockStartsFull() {
        let run = RushRun(settings: RushSettings(duration: 300, target: 100))
        #expect(run.remaining() > 299)
        #expect(run.hasTimeLeft())
        #expect(run.isOver == false)
    }

    @Test("The clock runs down from the start time")
    func clockCountsDown() {
        let started = Date().addingTimeInterval(-120)
        let run = RushRun(settings: RushSettings(duration: 300), startedAt: started)
        #expect(run.remaining() < 181)
        #expect(run.remaining() > 179)
        #expect(run.hasTimeLeft())
    }

    @Test("Three misses ends the run, two do not")
    func missesEndTheRun() {
        var run = RushRun(settings: RushSettings())
        run.record(solved: false)
        run.record(solved: false)
        #expect(run.isOver == false)
        run.record(solved: false)
        #expect(run.isOver)
        #expect(run.endedByMisses)
    }

    @Test("Streaks reset on a miss and remember their best")
    func streaks() {
        var run = RushRun(settings: RushSettings())
        for _ in 0..<4 { run.record(solved: true) }
        #expect(run.streak == 4)
        run.record(solved: false)
        #expect(run.streak == 0)
        #expect(run.bestStreak == 4)
    }

    @Test("Difficulty climbs across a run")
    func difficultyRamps() {
        var run = RushRun(settings: RushSettings())
        let opening = run.targetRating(practiceRating: 1500)
        for _ in 0..<40 { run.record(solved: true) }
        let later = run.targetRating(practiceRating: 1500)
        #expect(opening < 1100, "a run should open well below your level, got \(opening)")
        #expect(later > opening)
    }

    @Test("A puzzle is always found for a real library")
    func alwaysFindsAPuzzle() throws {
        // Ratings spread the way the bundled set is.
        let library = (0..<200).map { Self.puzzle("p\($0)", rating: 760 + $0 * 10) }
        var used: Set<String> = []
        var run = RushRun(settings: RushSettings())

        for _ in 0..<50 {
            let target = run.targetRating(practiceRating: 1200)
            let next = try #require(
                ItemSelector.nextRushPuzzle(from: library, targetRating: target, excluding: used),
                "no puzzle for target rating \(target)"
            )
            #expect(used.contains(next.id) == false, "a run must not repeat a puzzle")
            used.insert(next.id)
            run.record(solved: true)
        }
    }
}
