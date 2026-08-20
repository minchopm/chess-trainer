import ChessCore
import SceneKit
import simd
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

@Suite("The solids the pieces are made of")
struct SolidTests {
    /// Every triangle has to face out of the piece it belongs to.
    ///
    /// Wound the other way, SceneKit culls the faces you are meant to see and
    /// draws the inside of the piece instead — and since the inside faces away
    /// from every light, an ivory rook comes out looking like a glass one. It
    /// is a whole-app visual bug that no amount of grading the lights can fix,
    /// so it is checked here rather than looked at.
    @Test("Every face of a lathed solid points away from its axis")
    func lathe() {
        // A plain cone: every side face must point outward and upward.
        let solid = Solid.revolved([(0.0, 0.0), (0.5, 0.0), (0.0, 1.0)], segments: 24)
        #expect(!solid.positions.isEmpty)
        expectOutward(solid, from: SIMD3(0, 0.33, 0))
    }

    @Test("So does a sphere, a cylinder and a ring")
    func others() {
        expectOutward(Solid.sphere(radius: 0.4, at: .zero, segments: 24, rings: 12), from: .zero)
        expectOutward(Solid.cylinder(radius: 0.3, height: 1, at: .zero, segments: 16), from: .zero)
        // A ring is not star-shaped about its centre, so it is judged against
        // the middle of its own tube rather than the middle of the hole.
        let ring = Solid.ring(radius: 1, tube: 0.15, at: .zero, segments: 24, tubeSegments: 10)
        expectRingOutward(ring, major: 1)
    }

    /// SCNVector3 is Float on iOS and CGFloat on macOS, and the tests run on
    /// the Mac.
    private func vector(_ value: SCNVector3) -> SIMD3<Float> {
        SIMD3(Float(value.x), Float(value.y), Float(value.z))
    }

    private func expectOutward(_ solid: Solid, from centre: SIMD3<Float>, file: StaticString = #filePath) {
        var wrong = 0
        for triangle in stride(from: 0, to: solid.positions.count, by: 3) {
            let point = vector(solid.positions[triangle])
            let normal = vector(solid.normals[triangle])
            if simd_dot(normal, point - centre) < 0 { wrong += 1 }
        }
        #expect(wrong == 0, "\(wrong) of \(solid.positions.count / 3) faces point inward")
    }

    private func expectRingOutward(_ solid: Solid, major: Float) {
        var wrong = 0
        for triangle in stride(from: 0, to: solid.positions.count, by: 3) {
            let p = vector(solid.positions[triangle])
            let n = vector(solid.normals[triangle])
            // The nearest point on the ring's centre line.
            let flat = SIMD3<Float>(p.x, 0, p.z)
            let spine = simd_length(flat) > 1e-6 ? simd_normalize(flat) * major : SIMD3<Float>(major, 0, 0)
            if simd_dot(n, p - spine) < 0 { wrong += 1 }
        }
        #expect(wrong == 0, "\(wrong) of \(solid.positions.count / 3) ring faces point inward")
    }
}

@Suite("The knight")
@MainActor
struct KnightTests {
    /// The one piece a lathe cannot turn, and so the one piece whose geometry
    /// comes from somewhere else.
    ///
    /// Measured by its bounding box, because an SCNShape does not expose
    /// vertices the way a geometry built by hand does — asking it for its
    /// vertex sources returns nothing even for a plain square, which is a very
    /// convincing way to be told a shape is missing when it is not.
    @Test("stands as tall as the silhouette it is cut from")
    func head() throws {
        let node = TurnedPieces.node(for: .knight)
        #expect(node.childNodes.count == 2, "the knight should be a base and a head")

        let head = try #require(node.childNodes.last)
        let (low, high) = head.boundingBox
        let height = Float(high.y) - Float(low.y)
        // The silhouette runs from the base of the neck to the ear tips: 0.658
        // of the piece's own scale, which for a knight is 0.72.
        #expect(height > 0.4, "the head came out \(height) tall, so it did not tessellate")
        #expect(Float(low.y) < 0.4, "the head starts at \(low.y), above the neck it should meet")
    }
}

@Suite("Framing the board")
struct FramingTests {
    /// Turning the board must not lose it.
    ///
    /// A board is nine units square on and thirteen across the diagonal, so a
    /// camera parked at one distance either wastes the screen at one angle or
    /// drops its corners at the other — and the corners are where the rooks
    /// stand. Every angle is checked against the frustum it is actually being
    /// drawn into.
    @Test("Every angle keeps the board in the frame", arguments: [0.46, 0.62, 1.0, 1.72])
    func turning(aspect: Float) {
        for step in 0..<24 {
            var camera = OrbitCamera()
            camera.fit(aspect: aspect)
            camera.turn(by: Float(step) * .pi / 12 - camera.azimuth, and: 0)

            let worst = widestCorner(camera, aspect: aspect)
            // The framing deliberately allows a tall screen to crop the far
            // corners a little; past a fifth it is losing pieces.
            #expect(worst < 1.15, "at \(camera.azimuth) rad the board reaches \(worst) of the frame")
        }
    }

    @Test("The camera draws back into the diagonal and comes in square on")
    func breathes() {
        var square = OrbitCamera()
        square.fit(aspect: 0.46)
        square.turn(by: -square.azimuth, and: 0)          // straight on

        var diagonal = OrbitCamera()
        diagonal.fit(aspect: 0.46)
        diagonal.turn(by: .pi / 4 - diagonal.azimuth, and: 0)

        #expect(diagonal.distance > square.distance)
    }

    /// How far the outermost corner of the plinth reaches across the frame,
    /// where 1 is the edge.
    private func widestCorner(_ camera: OrbitCamera, aspect: Float) -> Float {
        let eye = camera.eye(clock: 0)
        let forward = simd_normalize(camera.target - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3<Float>(0, 1, 0)))
        let up = simd_cross(right, forward)

        let half = tanf(OrbitCamera.fieldOfView * .pi / 360)
        let horizontal = half * aspect
        var worst: Float = 0
        for x in [Float(-4.55), 4.55] {
            for z in [Float(-4.55), 4.55] {
                let corner = SIMD3<Float>(x, 0, z)
                let v = corner - eye
                let depth = simd_dot(v, forward)
                guard depth > 0.01 else { continue }
                worst = max(worst, abs(simd_dot(v, right)) / (depth * horizontal))
                worst = max(worst, abs(simd_dot(v, up)) / (depth * half))
            }
        }
        return worst
    }
}

@Suite("The banded set")
@MainActor
struct BandedSetTests {
    /// The brass has to be outside the wood it is wrapped around.
    ///
    /// The gilded foot is turned to nearly the same profile as the base it
    /// sheathes, so a change to one and not the other buries it — and a buried
    /// band does not look like a bug, it looks like a band that was never
    /// added. Which is exactly how it went unnoticed while the piece profile
    /// was being slimmed.
    @Test("The gilding stands outside the piece it is wrapped around")
    func giltIsVisible() throws {
        for kind in PieceKind.allCases {
            let node = TurnedPieces.node(for: kind, style: .banded)
            let body = try #require(node.childNodes.first { $0.name == TurnedPieces.bodyName })
            let trim = try #require(node.childNodes.first { $0.name == TurnedPieces.trimName })

            let bodyWidth = Float(body.boundingBox.max.x)
            let trimWidth = Float(trim.boundingBox.max.x)
            #expect(trimWidth > bodyWidth,
                    "\(kind): the brass reaches \(trimWidth) and the wood \(bodyWidth), so it is inside it")
        }
    }
}
