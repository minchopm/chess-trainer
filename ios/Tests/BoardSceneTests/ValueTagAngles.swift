import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// A value tag has to be readable from every angle the camera can reach.
///
/// The camera on the playing board orbits from six degrees above the table to
/// straight down — `OrbitCamera.elevationRange` — and a number that is legible
/// at one end of that and a smear at the other is a feature that works by luck.
/// The fault is angle-dependent, so no single shot shows it; this renders the
/// same three tags from the whole range, which is the only way to look at it.
@Suite("value tags", .enabled(if: ProcessInfo.processInfo.environment["RENDER_TAGS"] != nil,
                              "set RENDER_TAGS=1 to look at the tags"))
@MainActor
struct ValueTagAngles {
    @Test("render")
    func render() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let directory = ProcessInfo.processInfo.environment["RENDER_DIR"] ?? NSTemporaryDirectory()

        // Three squares a knight on g1 can reach. One of them has a piece
        // standing on it, which is the case a plate has to stay readable over,
        // and the three tints span the ramp from best move to plain mistake.
        let tags = [
            ValueTag(square: Square("f3")!, text: "+0.3", loss: 0),
            ValueTag(square: Square("h3")!, text: "+0.1", loss: 40),
            ValueTag(square: Square("e2")!, text: "−0.4", loss: 180),
        ]

        // The default the playing board opens at, then a shallower and two
        // steeper ones, ending at the top of the range — straight down, where a
        // tag that only turns about the upright axis is edge-on and gone.
        for (index, elevation) in [0.30, 0.95, 1.25, Float.pi / 2].enumerated() {
            let stage = Stage(quality: .high, style: .banded, playable: true)
            stage.board.reset()
            stage.setCoordinates(true)

            let pool = ValueTagPool()
            stage.scene.rootNode.addChildNode(pool.node)
            pool.show(tags)

            var camera = OrbitCamera(azimuth: 0, elevation: elevation,
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
            let name = String(format: "tags-%d-elev-%.2f.png", index, elevation)
            try png.write(to: URL(fileURLWithPath: directory).appending(path: name))
        }
    }
}
