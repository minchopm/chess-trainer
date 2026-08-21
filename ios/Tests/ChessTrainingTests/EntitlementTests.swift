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
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 1)
        #expect(progress.freeRemaining(.rush, at: noon, calendar: calendar) == 1)
        #expect(progress.freeRemaining(.positional, at: noon, calendar: calendar) == 3)
        #expect(progress.freeTacticsSkipsRemaining(at: noon, calendar: calendar) == 2)
    }

    @Test("Tactics completion and Rush attempt have separate allowances")
    func spending() {
        var progress = TrainingProgress()
        progress.recordFreeUse(of: .tactics, at: noon, calendar: calendar)

        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 0)
        #expect(progress.freeRemaining(.rush, at: noon, calendar: calendar) == 1)
        #expect(progress.freeRemaining(.endgame, at: noon, calendar: calendar) == 3)

        progress.recordFreeUse(of: .rush, at: noon, calendar: calendar)
        #expect(progress.freeRemaining(.rush, at: noon, calendar: calendar) == 0)

        progress.recordFreeTacticsSkip(at: noon, calendar: calendar)
        progress.recordFreeTacticsSkip(at: noon, calendar: calendar)
        #expect(progress.freeTacticsSkipsRemaining(at: noon, calendar: calendar) == 0)
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 0)
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
        progress.recordFreeUse(of: .tactics, at: noon, calendar: calendar)
        let tomorrow = noon.addingTimeInterval(26 * 3600)

        #expect(progress.freeRemaining(.tactics, at: tomorrow, calendar: calendar) == 1)

        // And spending tomorrow does not resurrect yesterday's count.
        progress.recordFreeUse(of: .tactics, at: tomorrow, calendar: calendar)
        #expect(progress.freeRemaining(.tactics, at: tomorrow, calendar: calendar) == 0)
    }

    @Test("The local allowance resets at nine in the morning")
    func resetsAtNine() {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = TimeZone(secondsFromGMT: 2 * 3_600)!
        let before = local.date(from: DateComponents(
            year: 2026, month: 8, day: 21, hour: 8, minute: 59, second: 59
        ))!
        let nine = local.date(from: DateComponents(
            year: 2026, month: 8, day: 21, hour: 9
        ))!

        var progress = TrainingProgress()
        progress.recordFreeUse(of: .tactics, at: before, calendar: local)
        progress.recordFreeTacticsSkip(at: before, calendar: local)
        #expect(progress.freeRemaining(.tactics, at: before, calendar: local) == 0)
        #expect(progress.freeTacticsSkipsRemaining(at: before, calendar: local) == 1)
        #expect(progress.freeRemaining(.tactics, at: nine, calendar: local) == 1)
        #expect(progress.freeTacticsSkipsRemaining(at: nine, calendar: local) == 2)
        #expect(DailyUsage.nextReset(after: before, calendar: local) == nine)

        progress.recordFreeUse(of: .tactics, at: nine, calendar: local)
        #expect(progress.freeRemaining(.tactics, at: nine, calendar: local) == 0)
        #expect(DailyUsage.nextReset(after: nine, calendar: local)
                == local.date(byAdding: .day, value: 1, to: nine))
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
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 1)
        #expect(progress.freeTacticsSkipsRemaining(at: noon, calendar: calendar) == 2)
    }

    @Test("Usage written before skip limits existed still decodes")
    func decodesOlderDailyUsage() throws {
        let old = Data(#"{"day":0}"#.utf8)
        let usage = try JSONDecoder().decode(DailyUsage.self, from: old)

        #expect(usage.remainingTacticsSkips(at: usage.day, calendar: calendar) == 2)
    }
}
