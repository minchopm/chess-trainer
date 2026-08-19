import Foundation

/// How good a move was.
public enum MoveGrade: String, Sendable, CaseIterable {
    case best, excellent, good, inaccuracy, mistake, blunder

    public var label: String {
        switch self {
        case .best: L.t("grade.best", "Best move")
        case .excellent: L.t("grade.excellent", "Excellent")
        case .good: L.t("grade.good", "Good")
        case .inaccuracy: L.t("grade.inaccuracy", "Inaccuracy")
        case .mistake: L.t("grade.mistake", "Mistake")
        case .blunder: L.t("grade.blunder", "Blunder")
        }
    }

    public var isMistake: Bool {
        self == .inaccuracy || self == .mistake || self == .blunder
    }

    /// Ceilings on win probability given up, best-first.
    static let thresholds: [(MoveGrade, Double)] = [
        (.best, 0.005), (.excellent, 0.02), (.good, 0.05),
        (.inaccuracy, 0.10), (.mistake, 0.20), (.blunder, .infinity),
    ]
}

public struct MoveAssessment: Sendable {
    public let grade: MoveGrade
    /// Win probability given up, 0...1.
    public let winProbabilityLost: Double
    /// Centipawns given up, for readers who think in pawns.
    public let centipawnsLost: Int
}

public enum Coach {
    /// Grade a move by how much winning chance it threw away, not by raw
    /// centipawns.
    ///
    /// Losing 100 centipawns when already a queen up barely matters; losing the
    /// same 100 in a level position decides the game. Centipawns cannot tell
    /// those apart, and a coach that shouts "blunder" when nothing happened
    /// stops being worth listening to.
    ///
    /// Both scores must be from the *mover's* point of view.
    public static func assess(
        before: Int,
        after: Int,
        wasEngineChoice: Bool
    ) -> MoveAssessment {
        let lost = max(0, winProbability(before) - winProbability(after))
        let grade = wasEngineChoice
            ? MoveGrade.best
            : MoveGrade.thresholds.first { lost <= $0.1 }!.0
        return MoveAssessment(
            grade: grade,
            winProbabilityLost: lost,
            centipawnsLost: max(0, before - after)
        )
    }

    /// Lichess' logistic fit from centipawns to expected score.
    public static func winProbability(_ centipawns: Int) -> Double {
        let clamped = Double(max(-1000, min(1000, centipawns)))
        return 1 / (1 + exp(-0.00368208 * clamped))
    }

    /// Accuracy for a whole game, in the usual sense: how close the moves were
    /// to engine play. Capped per move so one catastrophe does not swamp an
    /// otherwise sound game.
    public static func accuracy(centipawnLosses: [Int]) -> Int {
        guard !centipawnLosses.isEmpty else { return 100 }
        let average = centipawnLosses.map { min(300, $0) }.reduce(0, +) / centipawnLosses.count
        return max(0, 100 - average / 3)
    }
}
