import ChessCore
import Foundation
import Testing
@testable import BoardScene

@Suite("The games the board plays")
struct GameTests {
    /// The expansion stops at the first move the generator will not accept, so
    /// a short game is the symptom of a typo. These counts are the games as
    /// they were actually played.
    @Test("Every game expands to its full length", arguments: [
        ("opera", 33), ("evergreen", 47), ("immortal", 45),
    ])
    func length(id: String, plies: Int) throws {
        let game = try #require(ShowGames.all.first { $0.id == id })
        #expect(game.plies.count == plies)
    }

    @Test("Every game ends in mate")
    func mate() throws {
        for game in ShowGames.all {
            var position = Position()
            for ply in game.plies {
                let move = try #require(
                    position.legalMoves().first {
                        $0.from == ply.from && $0.to == ply.to && $0.promotion == ply.promotion
                    },
                    "\(game.id): \(ply.san) is not legal"
                )
                _ = position.make(move)
            }
            #expect(position.isCheckmate, "\(game.id) does not end in mate")
        }
    }

    @Test("Castling carries its rook, and en passant takes off the right square")
    func specialMoves() throws {
        // The Opera Game castles long on move fifteen.
        let opera = try #require(ShowGames.all.first { $0.id == "opera" })
        let castle = try #require(opera.plies.first { $0.san == "O-O-O" })
        let rook = try #require(castle.rook)
        #expect(rook.from == Square("a1"))
        #expect(rook.to == Square("d1"))

        // Nothing in these three games is an en passant capture, so the rule
        // that catches the board out — the taken piece is not on the square the
        // taker lands on — is checked against a position built for it.
        let passing = ShowGames.expandFrom(
            position: try #require(Position(fen: "4k3/8/8/8/3pP3/8/8/4K3 b - e3 0 1")),
            notation: "dxe3"
        )
        #expect(passing.count == 1)
        #expect(passing.first?.to == Square("e3"))
        #expect(passing.first?.capture == Square("e4"), "the pawn taken en passant stands on e4")
    }

    @Test("Every piece kind builds geometry with triangles in it")
    @MainActor
    func geometry() {
        for kind in PieceKind.allCases {
            let node = TurnedPieces.node(for: kind)
            let sources = node.childNodes.compactMap(\.geometry).flatMap { $0.sources(for: .vertex) }
            let vertices = sources.reduce(0) { $0 + $1.vectorCount }
            #expect(vertices > 200, "\(kind) came out with \(vertices) vertices")
        }
    }
}

@Suite("The board in the round")
@MainActor
struct BoardTests {
    @Test("A tap anywhere on a square lands on that square")
    func squareUnderPoint() throws {
        // The corners and the middle of one square, plus the two far corners of
        // the board, because an off-by-one in the rounding only shows at the
        // edges.
        #expect(LiveBoard.square(at: SIMD3(-3.5, 0, 3.5)) == Square("a1"))
        #expect(LiveBoard.square(at: SIMD3(-3.99, 0, 3.99)) == Square("a1"))
        #expect(LiveBoard.square(at: SIMD3(-3.01, 0, 3.01)) == Square("a1"))
        #expect(LiveBoard.square(at: SIMD3(3.5, 0, -3.5)) == Square("h8"))
        #expect(LiveBoard.square(at: SIMD3(0.5, 0, -0.5)) == Square("e5"))
        // And off the board is nothing, not the nearest square.
        #expect(LiveBoard.square(at: SIMD3(4.4, 0, 0)) == nil)
        #expect(LiveBoard.square(at: SIMD3(0, 0, -4.4)) == nil)
    }

    @Test("The board takes a position it was not built from")
    func arbitraryPosition() throws {
        let board = PlayingBoard()
        // Three queens a side: more of one piece than a set contains, which is
        // what the pool has to survive.
        let position = try #require(Position(fen: "qqq1k3/8/8/8/8/8/8/QQQ1K3 w - - 0 1"))
        board.set(position)

        #expect(board.occupied.count == 8)
        #expect(board.occupied[Square("a8")!] != nil)
        #expect(board.occupied[Square("d1")!] == nil)

        // And back to the standard array without leaving anything behind.
        board.set(Position())
        #expect(board.occupied.count == 32)
    }

    @Test("The banded set is gilded and the plain one is not")
    func sets() {
        for kind in PieceKind.allCases {
            let plain = TurnedPieces.node(for: kind, style: .plain)
            #expect(!plain.childNodes.contains { $0.name == TurnedPieces.trimName })

            let banded = TurnedPieces.node(for: kind, style: .banded)
            #expect(
                banded.childNodes.contains { $0.name == TurnedPieces.trimName },
                "\(kind) came out of the banded set with no brass on it"
            )
        }
    }

    @Test("Two pieces of one kind can wear different colours")
    func materialsAreNotShared() throws {
        // The clones share their prototype's vertex data, and a material lives
        // on the geometry rather than on the node — so without a copy, painting
        // one knight ebony paints White's knight too.
        let board = PlayingBoard()
        let white = try #require(board.occupied[Square("b1")!])
        let black = try #require(board.occupied[Square("b8")!])
        #expect(white.node.childNodes.first?.geometry !== black.node.childNodes.first?.geometry)
    }
}

@Suite("The library of recorded games")
struct LibraryTests {
    /// Every game in the shipped file, played through the app's own move
    /// generator.
    ///
    /// This is the check that makes the library trustworthy. The scores come
    /// out of published collections and are parsed by a script that knows
    /// nothing about chess; if the parser dropped a move, mangled a
    /// disambiguation or lost a promotion, the expansion stops early and the
    /// count here does not match. A game that cannot be played is not a game.
    @Test("Every recorded game plays from beginning to end")
    func everyGameExpands() throws {
        let file = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // BoardSceneTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // ios
            .deletingLastPathComponent()   // the repository
            .appendingPathComponent("data/classics.json")

        struct File: Decodable {
            struct Game: Decodable {
                let id: String
                let white: String
                let black: String
                let year: Int
                let moves: String
            }
            let games: [Game]
        }

        let data = try Data(contentsOf: file)
        let library = try JSONDecoder().decode(File.self, from: data)
        #expect(library.games.count > 500, "the library is suspiciously small")

        var broken: [String] = []
        for game in library.games {
            let expected = game.moves.split(separator: " ").count
            let plies = ShowGames.expand(game.moves)
            if plies.count != expected {
                broken.append("\(game.white)—\(game.black) \(game.year): \(plies.count)/\(expected)")
            }
        }

        #expect(broken.isEmpty, "\(broken.count) games stop early: \(broken.prefix(5).joined(separator: "; "))")
    }
}
