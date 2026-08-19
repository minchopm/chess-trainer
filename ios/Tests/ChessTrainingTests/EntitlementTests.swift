import Foundation
import Testing
@testable import ChessTraining

@Suite("Free tier")
struct EntitlementTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let noon = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("A fresh account has its whole daily allowance")
    func startsFull() {
        let progress = TrainingProgress()
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 5)
        #expect(progress.freeRemaining(.rush, at: noon, calendar: calendar) == 1)
        #expect(progress.freeRemaining(.positional, at: noon, calendar: calendar) == 3)
    }

    @Test("Each use spends one, and only from its own allowance")
    func spending() {
        var progress = TrainingProgress()
        progress.recordFreeUse(of: .tactics, at: noon, calendar: calendar)
        progress.recordFreeUse(of: .tactics, at: noon, calendar: calendar)

        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 3)
        #expect(progress.freeRemaining(.endgame, at: noon, calendar: calendar) == 3)
    }

    @Test("The allowance runs out and stays out for the rest of the day")
    func runsOut() {
        var progress = TrainingProgress()
        for _ in 0..<10 { progress.recordFreeUse(of: .rush, at: noon, calendar: calendar) }

        #expect(progress.freeRemaining(.rush, at: noon, calendar: calendar) == 0)
        let laterSameDay = noon.addingTimeInterval(6 * 3600)
        #expect(progress.freeRemaining(.rush, at: laterSameDay, calendar: calendar) == 0)
    }

    @Test("Tomorrow starts over")
    func resetsNextDay() {
        var progress = TrainingProgress()
        for _ in 0..<5 { progress.recordFreeUse(of: .tactics, at: noon, calendar: calendar) }
        let tomorrow = noon.addingTimeInterval(26 * 3600)

        #expect(progress.freeRemaining(.tactics, at: tomorrow, calendar: calendar) == 5)

        // And spending tomorrow does not resurrect yesterday's count.
        progress.recordFreeUse(of: .tactics, at: tomorrow, calendar: calendar)
        #expect(progress.freeRemaining(.tactics, at: tomorrow, calendar: calendar) == 4)
    }

    @Test("Progress written before the free tier existed still loads")
    func decodesOlderFiles() throws {
        let json = """
        {"cards":{},"themes":{},"history":[],"games":[],"rushRecords":[],
         "currentStreak":2,"bestStreak":5,
         "ratings":["tactics",1500,"positional",1400,"endgame":1300]}
        """.replacingOccurrences(of: "\"endgame\":1300", with: "\"endgame\",1300")
        let progress = try JSONDecoder().decode(TrainingProgress.self, from: Data(json.utf8))

        #expect(progress.rating(.tactics) == 1500)
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 5)
    }
}
