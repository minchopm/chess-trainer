import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// The ring round a piece that can move, on the round board.
///
/// The flat board has had a circle in its vocabulary from the beginning and the
/// round board never drew one — the case was named in `GameBoard` and passed
/// over. That was not only a gap waiting to be filled: tactics has used a
/// circle as the first rung of its hint since it was written, so on the round
/// board that hint has been showing nothing at all.
@Suite("coach rings")
@MainActor
struct CoachRings {
    @Test("a ring arrives with a body, and lies flat")
    func ringHasABody() throws {
        let pool = RingPool()
        pool.show([BoardRing(square: Square("e1")!, tint: .suggestion)])

        let ring = try #require(pool.node.childNodes.first?.childNodes.first)
        let box = ring.boundingBox
        #expect(box.max.x > box.min.x, "no width")
        #expect(box.max.z > box.min.z, "no depth")
        // Flat: it spreads across the board and stands barely at all off it.
        // Scene vectors are Float on the phone and CGFloat on the Mac, so
        // everything is taken to Float before it is compared.
        let across = Float(box.max.x - box.min.x) * Float(ring.scale.x)
        let standing = Float(box.max.y - box.min.y) * Float(ring.scale.y)
        #expect(standing < across / 10, "\(standing) standing against \(across) across")
    }

    /// One node per ring, and the geometry shared between them: sixteen pieces
    /// can have a move at once and they are all the same ring.
    @Test("sixteen rings share one geometry")
    func geometryIsShared() throws {
        let pool = RingPool()
        let squares = ["a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2", "b1", "g1"]
        pool.show(squares.map { BoardRing(square: Square($0)!, tint: .suggestion) })

        #expect(pool.node.childNodes.count == squares.count)
        let geometries = pool.node.childNodes.compactMap { $0.childNodes.first?.geometry }
        #expect(geometries.count == squares.count)
        #expect(Set(geometries.map { ObjectIdentifier($0) }).count == 1,
                "one tint should mean one geometry")
    }

    /// Each ring stands over the square it belongs to.
    @Test("a ring sits on its own square")
    func ringSitsOnItsSquare() throws {
        let pool = RingPool()
        let squares = ["a1", "d4", "h8"].map { Square($0)! }
        pool.show(squares.map { BoardRing(square: $0, tint: .good) })

        for (node, square) in zip(pool.node.childNodes, squares) {
            let place = PlayingBoard.position(of: square)
            #expect(abs(Float(node.position.x) - place.x) < 0.001, "\(square) across")
            #expect(abs(Float(node.position.z) - place.z) < 0.001, "\(square) along")
            #expect(Float(node.position.y) > 0, "\(square) is not above the board")
        }
    }

    /// Renders the rings from the angles the board is looked at. Whether a ring
    /// reads as inlaid rather than drawn on, and whether it leaves the piece
    /// inside it readable, are not numbers a test can assert.
    @Test("render", .enabled(if: ProcessInfo.processInfo.environment["RENDER_RINGS"] != nil,
                             "set RENDER_RINGS=1 to look at the rings"))
    func render() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let directory = ProcessInfo.processInfo.environment["RENDER_DIR"] ?? NSTemporaryDirectory()

        // The opening position's movable pieces: eight pawns and two knights,
        // which is the busiest this mark ever gets.
        let rings = ["a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2", "b1", "g1"]
            .map { BoardRing(square: Square($0)!, tint: .suggestion) }

        for (index, elevation) in [0.30, 0.95, Float.pi / 2].enumerated() {
            let stage = Stage(quality: .high, style: .banded, playable: true)
            stage.board.reset()
            stage.setCoordinates(true)

            let pool = RingPool()
            stage.scene.rootNode.addChildNode(pool.node)
            pool.show(rings)

            let camera = OrbitCamera(azimuth: 0, elevation: elevation,
                                     distance: 11.4, target: SIMD3<Float>(0, 0.2, 0))
            let eye = camera.eye(clock: 0)
            let up = camera.up()
            stage.cameraNode.position = SCNVector3(eye.x, eye.y, eye.z)
            stage.cameraNode.look(
                at: SCNVector3(camera.target.x, camera.target.y, camera.target.z),
                up: SCNVector3(up.x, up.y, up.z), localFront: SCNVector3(0, 0, -1)
            )

            let renderer = SCNRenderer(device: device, options: nil)
            renderer.scene = stage.scene
            renderer.pointOfView = stage.cameraNode
            let image = renderer.snapshot(atTime: 0, with: NSSize(width: 760, height: 760),
                                          antialiasingMode: .multisampling4X)
            guard let data = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: data),
                  let png = rep.representation(using: .png, properties: [:]) else { return }
            let name = String(format: "ring-%d-elev-%.2f.png", index, elevation)
            try png.write(to: URL(fileURLWithPath: directory).appending(path: name))
        }
    }
}
