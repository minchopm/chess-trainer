import Testing
@testable import ChessCore

/// The six standard perft positions. Between them they cover castling both
/// sides, castling rights lost to rook captures, en passant including the
/// discovered-check case, promotion and under-promotion, and stalemate.
struct PerftTests {
    struct Case {
        let name: String
        let fen: String
        let expected: [Int] // index 0 = depth 1
    }

    static let positions: [Case] = [
        Case(name: "starting position",
             fen: Position.startFEN,
             expected: [20, 400, 8902, 197_281, 4_865_609]),
        Case(name: "kiwipete",
             fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
             expected: [48, 2039, 97_862, 4_085_603]),
        Case(name: "endgame with en passant",
             fen: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
             expected: [14, 191, 2812, 43_238, 674_624]),
        Case(name: "promotion and pins",
             fen: "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
             expected: [6, 264, 9467]),
        Case(name: "under-promotion",
             fen: "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
             expected: [44, 1486, 62_379]),
        Case(name: "dense middlegame",
             fen: "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
             expected: [46, 2079, 89_890]),
    ]

    @Test("Perft counts match the published values", arguments: positions)
    func perftMatches(_ testCase: Case) throws {
        let position = try #require(Position(fen: testCase.fen), "FEN should parse: \(testCase.name)")
        for (index, expected) in testCase.expected.enumerated() {
            let depth = index + 1
            let actual = position.perft(depth)
            #expect(actual == expected, "\(testCase.name) depth \(depth): got \(actual), expected \(expected)")
        }
    }
}
