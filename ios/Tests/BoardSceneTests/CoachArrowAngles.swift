import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// The coach's arrow on the round board.
@Suite("coach arrows")
@MainActor
struct CoachArrowAngles {
    /// Every direction an arrow can point has to arrive with a body in it.
    ///
    /// The test that had to exist, because the fault it catches is invisible
    /// twice over. Handed its outline in board coordinates, `SCNShape` built
    /// nothing at all for an arrow lying at an odd angle: a knight's move came
    /// back with an empty bounding box and drew nothing, while the same arrow
    /// along a file or a diagonal was perfect. No error and no warning — just a
    /// hint the coach gave that the player never saw, and only for some moves.
    ///
    /// So: a queen's eight directions, a knight's eight, and the length of the
    /// board, all from the middle of it, and each has to have three dimensions.
    @Test("every direction has a body")
    func directions() throws {
        let from = Square("d4")!
        let squares = [
            // The queen's eight, one square out.
            "d5", "e5", "e4", "e3", "d3", "c3", "c4", "c5",
            // The knight's eight, which are the ones that were missing.
            "e6", "f5", "f3", "e2", "c2", "b3", "b5", "c6",
            // And the length of the board, which is the other extreme.
            "d8", "h8", "a1",
        ].map { Square($0)! }

        for to in squares {
            let pool = ArrowPool()
            pool.show([BoardArrow(from: from, to: to, tint: .good)])

            let arrow = try #require(pool.node.childNodes.first?.childNodes.first,
                                     "no arrow node for d4\(to)")
            let box = arrow.boundingBox
            #expect(box.max.x > box.min.x, "d4\(to) came back flat across")
            #expect(box.max.y > box.min.y, "d4\(to) came back flat along")
            #expect(box.max.z > box.min.z, "d4\(to) has no thickness")
        }
    }

    /// Renders the arrow from the angles it is looked at.
    ///
    /// Two things to look at, and neither is a number a test could assert.
    /// Whether it reads as laid into the wood rather than lying on it — which
    /// is the whole of the difference between an inlay and a decal, and lives
    /// in how the light catches a hundredth of a square of standing edge. And
    /// whether it sits over the destination dots where the two cross, which is
    /// on the square it points at, every time.
    @Test("render", .enabled(if: ProcessInfo.processInfo.environment["RENDER_ARROWS"] != nil,
                             "set RENDER_ARROWS=1 to look at the arrows"))
    func render() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let directory = ProcessInfo.processInfo.environment["RENDER_DIR"] ?? NSTemporaryDirectory()

        // A knight's move and a long diagonal: the short one was the broken
        // case, and an arrow that is right at one length is not always right at
        // the other.
        let arrows = [
            BoardArrow(from: Square("g1")!, to: Square("f3")!, tint: .suggestion),
            BoardArrow(from: Square("f1")!, to: Square("c4")!, tint: .good),
        ]
        // The squares a knight on g1 can reach, so the arrow has dots to cross.
        let dots = [Square("f3")!, Square("h3")!, Square("e2")!]

        for (index, elevation) in [0.30, 0.95, 1.25, Float.pi / 2].enumerated() {
            let stage = Stage(quality: .high, style: .banded, playable: true)
            stage.board.reset()
            stage.setCoordinates(true)

            let highlights = Highlights()
            stage.scene.rootNode.addChildNode(highlights.node)
            highlights.show(selected: Square("g1")!, destinations: dots, lastMove: nil)

            let pool = ArrowPool()
            stage.scene.rootNode.addChildNode(pool.node)
            pool.show(arrows)

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
            let name = String(format: "arrow-%d-elev-%.2f.png", index, elevation)
            try png.write(to: URL(fileURLWithPath: directory).appending(path: name))
        }
    }
}
