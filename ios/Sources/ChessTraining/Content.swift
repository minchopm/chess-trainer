import ChessCore
import Foundation

/// A tactics puzzle: one position, one winning idea.
///
/// `solution` alternates solver move, opponent reply, solver move… and always
/// ends on a solver move.
public struct Puzzle: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let fen: String
    public let solution: [String]     // UCI
    public let themes: [String]
    public let rating: Int
    public let mate: Bool
    public let source: String?

    public var solverMoveCount: Int { (solution.count + 1) / 2 }

    public var sideToMove: PieceColor {
        fen.split(separator: " ").dropFirst().first == "w" ? .white : .black
    }
}

/// A quiet position where judgement, not calculation, decides.
public struct PositionalExercise: Codable, Identifiable, Hashable, Sendable {
    public struct Candidate: Codable, Hashable, Sendable {
        public let uci: String
        /// Centipawns from the mover's point of view.
        public let cp: Int
        public let pv: [String]?
    }

    public let id: String
    public let fen: String
    /// Evaluation from White's point of view, which is what the assessment
    /// question asks about.
    public let cp: Int
    public let best: Candidate
    public let alternatives: [Candidate]
    public let rating: Int
    public let themes: [String]

    public var sideToMove: PieceColor {
        fen.split(separator: " ").dropFirst().first == "w" ? .white : .black
    }
}

/// An endgame played out against the engine to a required result.
public struct EndgameDrill: Codable, Identifiable, Hashable, Sendable {
    public enum Goal: String, Codable, Sendable {
        case win, draw
    }

    public let id: String
    public let name: String
    public let fen: String
    public let goal: Goal
    public let rating: Int
    public let idea: String
    public let themes: [String]
}

/// A complete rated game between two humans, for Guess the Elo.
///
/// The two ratings are kept apart rather than averaged in the file: the guess
/// is scored against the average, but the reveal is more interesting when it
/// can show what each player was actually rated.
public struct AnnotatedGame: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let white: Int
    public let black: Int
    public let result: String
    public let speed: String?
    public let timeControl: String?
    public let termination: String?
    public let eco: String?
    public let opening: String?
    public let date: String?
    /// UCI moves, space separated — one string rather than an array because a
    /// few thousand games of quoted four-character strings is mostly quotes.
    public let moves: String

    public var uciMoves: [String] { moves.split(separator: " ").map(String.init) }

    public var averageRating: Int { (white + black) / 2 }

    /// "Blitz · 5+0 · Sicilian Defense" — everything about the game that is not
    /// a clue to the players' strength.
    public var subtitle: String {
        [speed, timeControl.map(Self.readableClock), opening]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// "300+3" is how the archive writes it; "5+3" is how players say it.
    static func readableClock(_ control: String) -> String {
        let parts = control.split(separator: "+")
        guard let seconds = Int(parts.first ?? "") else { return control }
        let increment = parts.count > 1 ? String(parts[1]) : "0"
        return seconds % 60 == 0 ? "\(seconds / 60)+\(increment)" : "\(seconds)s+\(increment)"
    }
}

// MARK: - Loading

public struct ContentLibrary: Sendable {
    public let puzzles: [Puzzle]
    public let exercises: [PositionalExercise]
    public let drills: [EndgameDrill]
    public let games: [AnnotatedGame]
    public let classics: [ClassicGame]

    public init(
        puzzles: [Puzzle] = [],
        exercises: [PositionalExercise] = [],
        drills: [EndgameDrill] = [],
        games: [AnnotatedGame] = [],
        classics: [ClassicGame] = []
    ) {
        self.puzzles = puzzles
        self.exercises = exercises
        self.drills = drills
        self.games = games
        self.classics = classics
    }

    private struct PuzzleFile: Codable { let puzzles: [Puzzle] }
    private struct ExerciseFile: Codable { let exercises: [PositionalExercise] }
    private struct DrillFile: Codable { let drills: [EndgameDrill] }
    private struct GameFile: Codable { let games: [AnnotatedGame] }
    private struct ClassicFile: Codable { let games: [ClassicGame] }

    /// Load the three data files from a directory, tolerating any of them being
    /// absent — a build without the generated tactics should still run the
    /// endgames rather than refuse to start.
    public static func load(from directory: URL) throws -> ContentLibrary {
        func decode<T: Decodable>(_ type: T.Type, _ name: String) -> T? {
            let url = directory.appendingPathComponent(name)
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(type, from: data)
        }

        return ContentLibrary(
            puzzles: decode(PuzzleFile.self, "tactics.json")?.puzzles ?? [],
            exercises: decode(ExerciseFile.self, "positions.json")?.exercises ?? [],
            drills: decode(DrillFile.self, "endgames.json")?.drills ?? [],
            games: decode(GameFile.self, "games.json")?.games ?? [],
            classics: decode(ClassicFile.self, "classics.json")?.games ?? []
        )
    }
}

// MARK: - Themes

public enum Themes {
    /// Themes that describe a puzzle rather than name a skill: which phase it is
    /// from, how long the line is, how big the resulting advantage is, who
    /// played the original game. Useful for filtering a set; useless as a
    /// measure of you, since every puzzle is "short" or "long".
    static let descriptive: Set<String> = [
        "opening", "middlegame", "endgame",
        "oneMove", "short", "long", "veryLong",
        "crushing", "advantage", "equality", "mate",
        "master", "masterVsMaster", "superGM",
    ]

    public static func isMotif(_ theme: String) -> Bool { !descriptive.contains(theme) }

    /// "mateIn2" -> "Mate in 2", "knightFork" -> "Knight fork" — or whatever a
    /// translator called it. Splitting the camel case is the fallback for a
    /// theme the catalogue has never seen, which is what a fresh Lichess import
    /// brings in.
    public static func readable(_ theme: String) -> String {
        L.t("theme.\(theme)", spaced(theme))
    }

    private static func spaced(_ theme: String) -> String {
        var spaced = ""
        for character in theme {
            if character.isUppercase || character.isNumber, !spaced.isEmpty, spaced.last != " " {
                spaced.append(" ")
            }
            spaced.append(Character(character.lowercased()))
        }
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }
}


/// A game somebody played, kept to be watched.
///
/// Every one is a real game from a published collection of its players' own
/// games, and the moves are the moves as recorded — in the notation a book
/// prints, not pre-chewed into coordinates, so the app's own move generator has
/// to agree with the record before anything can be shown.
public struct ClassicGame: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let white: String
    public let black: String
    public let event: String
    public let site: String?
    public let year: Int
    public let result: String
    public let eco: String?
    /// True for the games named in the importer's own list — the ones nobody
    /// needs a reason to watch.
    public let notable: Bool
    /// SAN, space separated.
    public let moves: String

    public var players: String { "\(white) — \(black)" }

    /// "Hastings, 1895 · 1–0"
    public var occasion: String {
        [event.isEmpty ? nil : event, String(year)]
            .compactMap { $0 }
            .joined(separator: ", ") + " · " + result
    }

    public var plyCount: Int { moves.split(separator: " ").count }
    public var moveCount: Int { (plyCount + 1) / 2 }

    /// Everything a search box should match: the two players, where and when.
    public var haystack: String {
        "\(white) \(black) \(event) \(year) \(eco ?? "")".lowercased()
    }
}
