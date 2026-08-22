import Testing
@testable import BrassPawnApp

/// The opponent ladder is built on `UCI_Elo`, which only Stockfish has. These
/// hold the rule that follows from that: an engine which cannot limit its
/// strength is offered at full strength and nothing else, and a rung left
/// selected from the other engine's ladder does not survive the change.
@Suite("Opponent ladder")
struct OpponentLadderTests {
    @Test("An engine that limits strength offers the whole ladder")
    func stockfishOffersEverything() {
        let levels = OpponentLevel.available(limitsStrength: true)
        #expect(levels.count == 6)
        #expect(levels.map(\.elo) == [1400, 1800, 2100, 2400, 2700, nil])
    }

    @Test("An engine that cannot limit strength offers one rung, unrated")
    func recklessOffersFullStrengthOnly() {
        let levels = OpponentLevel.available(limitsStrength: false)
        #expect(levels == [OpponentLevel.fullStrength])
        #expect(levels[0].elo == nil)
    }

    /// A rating shown against an engine that cannot hit it would be the whole
    /// feature quietly lying, so nothing unrated may carry a number.
    @Test("No rung without a limiter claims a rating")
    func unlimitedLevelsCarryNoRating() {
        for level in OpponentLevel.available(limitsStrength: false) {
            #expect(level.elo == nil, "\(level.name) claims \(level.elo ?? 0)")
        }
    }

    @MainActor
    @Test("Switching to an engine with no ladder drops a rated selection")
    func clampingLeavesALegalLevel() {
        let model = PlayModel()
        model.level = OpponentLevel.all[0]        // Casual (1400)
        #expect(model.level.elo == 1400)

        model.clampLevel(limitsStrength: false)
        #expect(model.level == OpponentLevel.fullStrength)
    }

    @MainActor
    @Test("A legal selection is left alone")
    func clampingKeepsAValidLevel() {
        let model = PlayModel()
        model.level = OpponentLevel.all[3]        // Expert (2400)
        model.clampLevel(limitsStrength: true)
        #expect(model.level == OpponentLevel.all[3])
    }
}
