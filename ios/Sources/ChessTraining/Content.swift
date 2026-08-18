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

// MARK: - Loading

public struct ContentLibrary: Sendable {
    public let puzzles: [Puzzle]
    public let exercises: [PositionalExercise]
    public let drills: [EndgameDrill]

    public init(puzzles: [Puzzle] = [], exercises: [PositionalExercise] = [], drills: [EndgameDrill] = []) {
        self.puzzles = puzzles
        self.exercises = exercises
        self.drills = drills
    }

    private struct PuzzleFile: Codable { let puzzles: [Puzzle] }
    private struct ExerciseFile: Codable { let exercises: [PositionalExercise] }
    private struct DrillFile: Codable { let drills: [EndgameDrill] }

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
            drills: decode(DrillFile.self, "endgames.json")?.drills ?? []
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

    /// "mateIn2" -> "Mate in 2", "knightFork" -> "Knight fork".
    public static func readable(_ theme: String) -> String {
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
