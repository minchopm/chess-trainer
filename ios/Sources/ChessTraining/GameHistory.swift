import ChessCore
import Foundation
import SwiftData

/// A game that was actually played, kept whole.
///
/// `TrainingProgress.games` already records that a game happened — result,
/// accuracy, how strong the opponent was — because those are the numbers a
/// rating is made of. It says nothing about what was played. This is the moves,
/// so a game can be watched back afterwards and picked up again from any point
/// in it.
///
/// Its own store rather than another field on the progress file: that file is
/// read and rewritten whole on every change, and a couple of hundred games of
/// notation is not something to re-encode because somebody solved a puzzle.
@Model
public final class SavedGame {
    /// A string, so it keys the same watch marks and favourites the classics
    /// use. `TrainingProgress` stores both against a `String` id already, and a
    /// game you played is a game like any other in that respect.
    @Attribute(.unique) public var id: String
    public var playedAt: Date

    /// Where the line begins. The opening position for an ordinary game, and
    /// something else entirely for one that began from a board you set up.
    public var startFEN: String

    /// The moves in SAN, separated by spaces — the form `GameImport` reads.
    ///
    /// Stored as notation rather than as a move list so that a saved game comes
    /// back through the same parser as a pasted one. One reader, one set of
    /// bugs, and a database that can be read by eye if anybody ever looks.
    public var notation: String

    /// "win", "draw" or "loss" from your side; "*" when neither side was yours.
    public var result: String
    public var white: String
    public var black: String

    /// "white", "black", or nil when you held neither side — two engines
    /// playing each other is still a game worth keeping.
    ///
    /// Your own side's name is stored empty rather than as "You": the word is
    /// translated, and a history written in the language the app happened to be
    /// in on the day would read wrong ever after. The empty string means "the
    /// player", and `name(for:)` puts the right word in at the time of asking.
    public var yourColor: String?
    public var opponentElo: Int?
    public var accuracy: Int?

    /// Which screen it came from: "play", "board", "online".
    public var source: String

    public init(
        id: String = UUID().uuidString,
        playedAt: Date = Date(),
        startFEN: String = Position().fen,
        notation: String,
        result: String,
        white: String,
        black: String,
        yourColor: String? = nil,
        opponentElo: Int? = nil,
        accuracy: Int? = nil,
        source: String
    ) {
        self.id = id
        self.playedAt = playedAt
        self.startFEN = startFEN
        self.notation = notation
        self.result = result
        self.white = white
        self.black = black
        self.yourColor = yourColor
        self.opponentElo = opponentElo
        self.accuracy = accuracy
        self.source = source
    }
}

public extension SavedGame {
    /// Who held a side, in the language being read now.
    func name(for color: PieceColor) -> String {
        let stored = color == .white ? white : black
        return stored.isEmpty ? L.t("history.you", "You") : stored
    }

    var players: String { "\(name(for: .white)) — \(name(for: .black))" }

    var moves: [String] {
        notation.split(separator: " ").map(String.init)
    }

    var moveCount: Int { moves.count }

    /// Where the line begins, or the opening position if the stored FEN has
    /// somehow stopped being one.
    var startPosition: Position { Position(fen: startFEN) ?? Position() }

    /// True when the game is one you took part in, rather than one you set two
    /// engines going and watched.
    var isYours: Bool { yourColor != nil }
}

/// The store the saved games live in.
public enum GameHistory {
    public static let schema = Schema([SavedGame.self])

    /// Nothing is trimmed. A game is a few hundred bytes of notation, so ten
    /// thousand of them is a couple of megabytes — cheaper than deciding on
    /// somebody's behalf which of their own games they are done with.
    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        )
    }
}
