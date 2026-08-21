import ChessCore
import Foundation
import Testing
@testable import ChessTraining

struct FeatureTests {
    @Test("Open and half-open files are identified")
    func files() throws {
        // White has no d-pawn, Black has no e-pawn; the c-file is empty of both.
        let position = try #require(Position(fen: "r3k2r/pp1p1ppp/8/8/8/8/PP2PPPP/R3K2R w KQkq - 0 1"))
        let features = PositionFeatures(position)

        let byName = Dictionary(uniqueKeysWithValues: features.files.map { ($0.name, $0) })
        #expect(byName["c"]?.isOpen == true)
        #expect(byName["d"]?.halfOpenFor == .white)
        #expect(byName["a"]?.isOpen == false)
    }

    @Test("A rook on an open file is recognised")
    func rookOnOpenFile() throws {
        let position = try #require(Position(fen: "4k3/pp4pp/8/8/8/8/PP4PP/3RK3 w - - 0 1"))
        let features = PositionFeatures(position)
        let rook = try #require(features.heavyPieces.first { $0.square == Square("d1")! })
        #expect(rook.onOpenFile)
        #expect(rook.onSeventhRank == false)
    }

    @Test("An outpost needs a defender and no pawn that can chase it")
    func outposts() throws {
        // Knight on e5, defended by the d4 pawn. Black has no d- or f-pawn left
        // to drive it away, so it is a genuine outpost.
        let secure = try #require(Position(fen: "4k3/pp4pp/8/4N3/3P4/8/PP4PP/4K3 w - - 0 1"))
        #expect(PositionFeatures(secure).knights.first?.isOutpost == true)

        // Same knight, but now a black f-pawn can play f6 and evict it.
        let contested = try #require(Position(fen: "4k3/pp3ppp/8/4N3/3P4/8/PP4PP/4K3 w - - 0 1"))
        #expect(PositionFeatures(contested).knights.first?.isOutpost == false)

        // Undefended knight is not an outpost however deep it sits.
        let loose = try #require(Position(fen: "4k3/pp4pp/8/4N3/8/8/PP4PP/4K3 w - - 0 1"))
        #expect(PositionFeatures(loose).knights.first?.isOutpost == false)
    }

    @Test("Pawn structure faults are found")
    func pawnStructure() throws {
        // White a-pawn is isolated; the White d-pawn on d5 is passed.
        let position = try #require(Position(fen: "4k3/1p4pp/8/3P4/8/8/P5PP/4K3 w - - 0 1"))
        let structure = try #require(PositionFeatures(position).structure[.white])
        #expect(structure.isolated.contains(Square("a2")!))
        #expect(structure.passed.contains(Square("d5")!))
    }

    @Test("Mobility is measured for both sides")
    func mobility() throws {
        let position = try #require(Position(fen: Position.startFEN))
        let features = PositionFeatures(position)
        #expect(features.mobility[.white] == 20)
        #expect(features.mobility[.black] == 20)
    }
}

struct MoveDescriptionTests {
    func describe(_ fen: String, _ san: String) throws -> [String] {
        let position = try #require(Position(fen: fen))
        let move = try #require(position.move(san: san), "should parse \(san)")
        var resulting = position
        resulting.make(move)
        return MoveDescription.clauses(
            before: PositionFeatures(position),
            after: PositionFeatures(resulting),
            move: move,
            position: position,
            resulting: resulting
        )
    }

    @Test("Checkmate is described on its own")
    func mateSaysOnlyMate() throws {
        let clauses = try describe("6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1", "Ra8#")
        #expect(clauses == ["delivers checkmate"])
    }

    @Test("Taking the open file is named")
    func takesOpenFile() throws {
        let clauses = try describe("4k3/pp4pp/8/8/8/8/PP4PP/R3K3 w - - 0 1", "Rd1")
        #expect(clauses.contains { $0.contains("open d-file") })
    }

    @Test("Winning material is distinguished from an even trade")
    func materialWins() throws {
        let clauses = try describe("4k3/8/8/8/3q4/8/8/3RK3 w - - 0 1", "Rxd4")
        #expect(clauses.contains { $0.contains("wins material") })
    }

    @Test("Compact notation is expanded into a readable move")
    func detailedNotation() throws {
        let position = try #require(Position(fen: "3kq3/pQ6/8/3p4/3P2p1/2P5/PP4PP/4rNK1 b - - 2 37"))
        let move = try #require(position.move(san: "Rxf1+"))
        var resulting = position
        resulting.make(move)
        let sentence = try #require(MoveDescription.detailedSentence(
            san: "Rxf1+", move: move, position: position, resulting: resulting
        ))

        #expect(sentence.contains("rook from e1 to f1"))
        #expect(sentence.contains("capturing the knight"))
        #expect(sentence.contains("giving check"))
    }

    @Test("A summary reads the position")
    func summary() throws {
        let position = try #require(Position(fen: "4k3/pp4pp/8/4N3/3P4/8/PP4PP/3RK3 w - - 0 1"))
        let points = MoveDescription.summary(PositionFeatures(position))
        #expect(points.contains { $0.contains("secure knight on e5") })
        #expect(points.contains { $0.contains("Material") })
    }
}

struct ProgressTests {
    @Test("Rating rises on a win and falls on a loss")
    func rating() {
        var progress = TrainingProgress()
        let start = progress.rating(.tactics)

        progress.record(mode: .tactics, itemID: "a", itemRating: 1500, correct: true)
        #expect(progress.rating(.tactics) > start)

        var losing = TrainingProgress()
        losing.record(mode: .tactics, itemID: "a", itemRating: 900, correct: false)
        #expect(losing.rating(.tactics) < start)
    }

    @Test("A hint means the attempt does not count towards rating")
    func hintsDoNotCount() {
        var progress = TrainingProgress()
        progress.record(mode: .tactics, itemID: "a", itemRating: 1500, correct: true, usedHint: true)
        #expect(progress.rating(.tactics) < 1200)  // scored as a miss for rating purposes
    }

    @Test("A missed puzzle returns tomorrow, a solved one later")
    func scheduling() {
        let now = Date()
        var progress = TrainingProgress()

        progress.record(mode: .tactics, itemID: "missed", itemRating: 1200, correct: false, now: now)
        let missed = progress.cards["missed"]!
        #expect(missed.intervalDays == 1)

        progress.record(mode: .tactics, itemID: "solved", itemRating: 1200, correct: true, now: now)
        progress.record(mode: .tactics, itemID: "solved", itemRating: 1200, correct: true,
                        now: now.addingTimeInterval(86_400 * 2))
        #expect(progress.cards["solved"]!.intervalDays >= 4)
    }

    @Test("Descriptive themes are not counted as skills")
    func descriptiveThemesIgnored() {
        var progress = TrainingProgress()
        progress.record(mode: .tactics, itemID: "a", itemRating: 1200, correct: true,
                        themes: ["pin", "short", "middlegame", "crushing"])
        #expect(progress.themes["pin"] != nil)
        #expect(progress.themes["short"] == nil)
        #expect(progress.themes["middlegame"] == nil)
    }

    @Test("Confidence, not raw accuracy, ranks weaknesses")
    func wilsonRanking() {
        var oneMiss = ThemeRecord(); oneMiss.seen = 1; oneMiss.solved = 0
        var manyMisses = ThemeRecord(); manyMisses.seen = 20; manyMisses.solved = 5

        // Both are 0% and 25%, but only the second is evidence of a weakness.
        #expect(manyMisses.ceiling < oneMiss.ceiling)
    }

    @Test("Targets are motifs below your own baseline")
    func targets() {
        var progress = TrainingProgress()
        progress.themes = [
            "pin": ThemeRecord(seen: 12, solved: 3),
            "deflection": ThemeRecord(seen: 9, solved: 3),
            "fork": ThemeRecord(seen: 14, solved: 12),
            "discoveredAttack": ThemeRecord(seen: 10, solved: 9),
        ]
        let names = Set(progress.trainingTargets().map(\.name))
        #expect(names.contains("pin"))
        #expect(names.contains("deflection"))
        #expect(names.contains("fork") == false)
    }

    @Test("Streaks count consecutive days only")
    func streaks() {
        var progress = TrainingProgress()
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        progress.record(mode: .tactics, itemID: "a", itemRating: 1200, correct: true, now: day)
        progress.record(mode: .tactics, itemID: "b", itemRating: 1200, correct: true,
                        now: day.addingTimeInterval(86_400))
        #expect(progress.currentStreak == 2)

        // Skipping a day resets it.
        progress.record(mode: .tactics, itemID: "c", itemRating: 1200, correct: true,
                        now: day.addingTimeInterval(86_400 * 4))
        #expect(progress.currentStreak == 1)
        #expect(progress.bestStreak == 2)
    }
}

struct SelectionTests {
    static func puzzle(_ id: String, rating: Int, themes: [String]) -> Puzzle {
        Puzzle(id: id, fen: Position.startFEN, solution: ["e2e4"], themes: themes,
               rating: rating, mate: false, source: nil)
    }

    @Test("Due reviews come before anything else")
    func reviewFirst() {
        var progress = TrainingProgress()
        let now = Date()
        progress.record(mode: .tactics, itemID: "old", itemRating: 1200, correct: false,
                        now: now.addingTimeInterval(-86_400 * 3))

        let puzzles = [
            Self.puzzle("old", rating: 1200, themes: ["pin"]),
            Self.puzzle("new", rating: 1250, themes: ["fork"]),
        ]
        let selection = ItemSelector.nextPuzzle(from: puzzles, progress: progress, now: now)
        #expect(selection?.item.id == "old")
        #expect(selection?.reason == .review)
    }

    @Test("Weak motifs are targeted most of the time")
    func targetsWeakness() {
        var progress = TrainingProgress()
        progress.ratings[.tactics] = 1500
        progress.themes = [
            "pin": ThemeRecord(seen: 12, solved: 3),
            "fork": ThemeRecord(seen: 14, solved: 12),
            "discoveredAttack": ThemeRecord(seen: 10, solved: 9),
        ]

        let puzzles = (0..<40).map { index in
            Self.puzzle("p\(index)", rating: 1500, themes: index % 2 == 0 ? ["pin"] : ["fork"])
        }

        // Force the targeting branch; the share itself is a product decision,
        // not something a test should pin down.
        let selection = ItemSelector.nextPuzzle(
            from: puzzles, progress: progress,
            random: { _ in 0 }, chance: { 0.0 }
        )
        #expect(selection?.item.themes.contains("pin") == true)
        if case .weakness(let motif, _, _) = selection?.reason {
            #expect(motif == "pin")
        } else {
            Issue.record("expected a weakness selection, got \(String(describing: selection?.reason))")
        }
    }

    @Test("Without enough evidence it just tracks your level")
    func fallsBackToRating() {
        var progress = TrainingProgress()
        progress.ratings[.tactics] = 1500
        let puzzles = [
            Self.puzzle("near", rating: 1540, themes: ["pin"]),
            Self.puzzle("far", rating: 2400, themes: ["pin"]),
        ]
        let selection = ItemSelector.nextPuzzle(
            from: puzzles, progress: progress, random: { _ in 0 }, chance: { 0.0 }
        )
        #expect(selection?.item.id == "near")
        #expect(selection?.reason == .level)
    }
}
