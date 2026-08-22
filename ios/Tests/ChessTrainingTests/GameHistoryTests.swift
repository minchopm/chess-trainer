import ChessCore
import Foundation
import SwiftData
import Testing
@testable import ChessTraining

/// The store for games that were actually played.
@MainActor
@Suite("Saved games")
struct GameHistoryTests {
    private func store() throws -> ModelContext {
        ModelContext(try GameHistory.container(inMemory: true))
    }

    private func game(
        notation: String = "e4 e5 Nf3 Nc6",
        result: String = "win",
        white: String = "",
        black: String = "Club (1800)",
        yourColor: String? = "white"
    ) -> SavedGame {
        SavedGame(
            notation: notation, result: result, white: white, black: black,
            yourColor: yourColor, source: "play"
        )
    }

    @Test("A game goes in and comes back out")
    func roundTrips() throws {
        let context = try store()
        context.insert(game())
        try context.save()

        let found = try context.fetch(FetchDescriptor<SavedGame>())
        #expect(found.count == 1)
        #expect(found[0].moves == ["e4", "e5", "Nf3", "Nc6"])
        #expect(found[0].moveCount == 4)
    }

    /// Storing the moves as notation is what lets a saved game go back through
    /// the same reader as a pasted one.
    @Test("The stored notation reads back through the game importer")
    func notationIsWhatTheImporterReads() {
        let saved = game()
        let imported = GameImport.read(saved.notation)
        #expect(imported != nil)
        #expect(imported?.moves.count == 4)
    }

    @Test("A game that began from a set-up position keeps that position")
    func keepsItsStartingPosition() {
        let fen = "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"
        let saved = SavedGame(
            startFEN: fen, notation: "e4", result: "*", white: "Stockfish",
            black: "Reckless", source: "board"
        )
        #expect(saved.startPosition.fen == fen)
        #expect(!saved.isYours)
    }

    /// Your own side is stored empty rather than as the word "You", so a
    /// history written while the app was in one language does not read wrong in
    /// another.
    @Test("Your side is named in the language being read, not the one it was played in")
    func yourNameIsNotFrozen() {
        let saved = game()
        #expect(saved.white.isEmpty)
        #expect(saved.name(for: .white) == "You")
        #expect(saved.name(for: .black) == "Club (1800)")
    }

    @Test("An empty game is still a game")
    func noMovesIsFine() {
        let saved = game(notation: "")
        #expect(saved.moves.isEmpty)
        #expect(saved.moveCount == 0)
    }

    @Test("Games come back newest first")
    func sortsByDate() throws {
        let context = try store()
        let old = game(notation: "e4")
        old.playedAt = Date(timeIntervalSince1970: 1_000)
        let recent = game(notation: "d4")
        recent.playedAt = Date(timeIntervalSince1970: 2_000)
        context.insert(old)
        context.insert(recent)
        try context.save()

        var descriptor = FetchDescriptor<SavedGame>()
        descriptor.sortBy = [SortDescriptor(\SavedGame.playedAt, order: .reverse)]
        let found = try context.fetch(descriptor)
        #expect(found.map(\.notation) == ["d4", "e4"])
    }
}
