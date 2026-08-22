import Foundation
import Testing
@testable import ChessTraining

@Suite("Free tier")
struct EntitlementTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let noon = Date(timeIntervalSince1970: 1_700_000_000)

    /// Five of each, and the same five everywhere: enough of a mode to watch a
    /// rating move, which is the thing a subscription is being sold against.
    @Test("A fresh account has five of everything")
    func startsFull() {
        let progress = TrainingProgress()
        for activity in TrainingActivity.allCases {
            #expect(
                progress.freeRemaining(activity, at: noon, calendar: calendar) == 5,
                "\(activity) does not start at five"
            )
        }
        #expect(progress.freeTacticsSkipsRemaining(at: noon, calendar: calendar) == 2)
    }

    /// The count is spent by attempting, and nothing else. Opening a screen,
    /// reading a position and going back must cost nothing — that is the
    /// difference between a free tier and a locked door.
    @Test("Five attempts, then the door")
    func fiveThenTheDoor() {
        var progress = TrainingProgress()
        for spent in 0..<5 {
            #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 5 - spent)
            progress.recordFreeUse(of: .tactics, at: noon, calendar: calendar)
        }
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 0)
    }

    @Test("Tactics completion and Rush attempt have separate allowances")
    func spending() {
        var progress = TrainingProgress()
        progress.recordFreeUse(of: .tactics, at: noon, calendar: calendar)

        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 4)
        #expect(progress.freeRemaining(.rush, at: noon, calendar: calendar) == 5)
        #expect(progress.freeRemaining(.endgame, at: noon, calendar: calendar) == 5)

        progress.recordFreeUse(of: .rush, at: noon, calendar: calendar)
        #expect(progress.freeRemaining(.rush, at: noon, calendar: calendar) == 4)

        // Skips have their own count and spend neither of the above.
        progress.recordFreeTacticsSkip(at: noon, calendar: calendar)
        progress.recordFreeTacticsSkip(at: noon, calendar: calendar)
        #expect(progress.freeTacticsSkipsRemaining(at: noon, calendar: calendar) == 0)
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 4)
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

        #expect(progress.freeRemaining(.tactics, at: tomorrow, calendar: calendar) == 5)

        // And spending tomorrow does not resurrect yesterday's count.
        progress.recordFreeUse(of: .tactics, at: tomorrow, calendar: calendar)
        #expect(progress.freeRemaining(.tactics, at: tomorrow, calendar: calendar) == 4)
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
        #expect(progress.freeRemaining(.tactics, at: before, calendar: local) == 4)
        #expect(progress.freeTacticsSkipsRemaining(at: before, calendar: local) == 1)
        // Nine o'clock is a new day: the count is whole again.
        #expect(progress.freeRemaining(.tactics, at: nine, calendar: local) == 5)
        #expect(progress.freeTacticsSkipsRemaining(at: nine, calendar: local) == 2)
        #expect(DailyUsage.nextReset(after: before, calendar: local) == nine)

        progress.recordFreeUse(of: .tactics, at: nine, calendar: local)
        #expect(progress.freeRemaining(.tactics, at: nine, calendar: local) == 4)
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
        #expect(progress.freeRemaining(.tactics, at: noon, calendar: calendar) == 5)
        #expect(progress.freeTacticsSkipsRemaining(at: noon, calendar: calendar) == 2)
    }

    @Test("Usage written before skip limits existed still decodes")
    func decodesOlderDailyUsage() throws {
        let old = Data(#"{"day":0}"#.utf8)
        let usage = try JSONDecoder().decode(DailyUsage.self, from: old)

        #expect(usage.remainingTacticsSkips(at: usage.day, calendar: calendar) == 2)
    }
}
