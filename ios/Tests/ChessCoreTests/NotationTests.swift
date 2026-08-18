import Testing
@testable import ChessCore

struct NotationTests {
    @Test("FEN round-trips through parsing and printing")
    func fenRoundTrip() throws {
        let samples = [
            Position.startFEN,
            "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
            "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
            "4k3/8/8/8/8/8/4P3/4K3 b - - 5 39",
        ]
        for fen in samples {
            let position = try #require(Position(fen: fen))
            #expect(position.fen == fen)
        }
    }

    @Test("Illegal positions are rejected")
    func rejectsIllegalPositions() {
        // Side not to move is in check — unreachable in a real game. The web
        // version shipped three hand-written drills with exactly this fault.
        #expect(Position(fen: "8/8/8/4k3/8/8/4Q3/4K3 w - - 0 1") == nil)
        #expect(Position(fen: "8/8/8/8/8/5k2/5p2/5K1Q w - - 0 1") == nil)
        // Missing a king.
        #expect(Position(fen: "8/8/8/4k3/8/8/8/8 w - - 0 1") == nil)
    }

    @Test("SAN is produced and parsed consistently")
    func sanRoundTrip() throws {
        var position = Position()
        let game = ["e4", "e5", "Nf3", "Nc6", "Bb5", "a6", "Ba4", "Nf6", "O-O", "Be7", "Re1", "b5", "Bb3", "d6", "c3", "O-O"]
        for text in game {
            let move = try #require(position.move(san: text), "should parse \(text)")
            #expect(position.san(for: move) == text)
            position.make(move)
        }
        #expect(position.fullmoveNumber == 9)
    }

    @Test("Disambiguation names the right piece")
    func disambiguation() throws {
        // Two knights on d2 and f2 can both reach e4; the file separates them.
        var position = try #require(Position(fen: "4k3/8/8/8/8/8/3N1N2/4K3 w - - 0 1"))
        let move = try #require(position.move(san: "Nde4"))
        #expect(position.san(for: move) == "Nde4")

        // Rooks on the same file need the rank instead.
        position = try #require(Position(fen: "4k3/8/8/R7/8/8/R7/4K3 w - - 0 1"))
        let rookMove = try #require(position.move(san: "R5a4"))
        #expect(position.san(for: rookMove) == "R5a4")
    }

    @Test("Checkmate is marked with #, plain check with +")
    func checkSuffixes() throws {
        // Fool's mate: after 1.f3 e5 2.g4, Qh4 is mate.
        var position = try #require(Position(fen: "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2"))
        let mate = try #require(position.move(san: "Qh4"))
        #expect(position.san(for: mate) == "Qh4#")
        position.make(mate)
        #expect(position.isCheckmate)
        #expect(position.legalMoves().isEmpty)

        // A check that is not mate gets "+".
        var check = try #require(Position(fen: "4k3/8/8/8/8/8/8/R6K w - - 0 1"))
        let rookCheck = try #require(check.move(san: "Re1+"))
        #expect(check.san(for: rookCheck) == "Re1+")
        check.make(rookCheck)
        #expect(check.isCheck)
        #expect(check.isCheckmate == false)
    }

    @Test("Threefold repetition is detected")
    func repetition() throws {
        var position = try #require(Position(fen: "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1"))
        // The first cycle changes castling rights, so it is not a repetition of
        // the start. Occurrences two and three come from the cycles after it.
        for _ in 0..<3 {
            for text in ["Rh2", "Ke7", "Rh1", "Ke8"] {
                let move = try #require(position.move(san: text), "should parse \(text)")
                position.make(move)
            }
        }
        #expect(position.isThreefoldRepetition)
    }

    @Test("Insufficient material covers the usual cases")
    func insufficientMaterial() throws {
        #expect(try #require(Position(fen: "4k3/8/8/8/8/8/8/4K3 w - - 0 1")).isInsufficientMaterial)
        #expect(try #require(Position(fen: "4k3/8/8/8/8/8/8/4KN2 w - - 0 1")).isInsufficientMaterial)
        #expect(try #require(Position(fen: "4k3/8/8/8/8/8/8/4KB2 w - - 0 1")).isInsufficientMaterial)
        #expect(try #require(Position(fen: "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1")).isInsufficientMaterial == false)
        #expect(try #require(Position(fen: "4k3/8/8/8/8/8/8/2B1KB2 w - - 0 1")).isInsufficientMaterial == false)
    }
}
