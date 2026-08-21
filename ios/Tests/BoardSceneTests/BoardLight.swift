import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// Renders the board from several angles, to look at the lighting.
///
/// The complaint the rig has to answer is angle-dependent, so one shot cannot
/// show it: turned one way the varnish catches the key light and the squares go
/// white enough to lose an ivory piece standing on them; turned another the far
/// corners fall away far enough to lose a black one. Both at once is what makes
/// it hard — brightening the corners is easy if the middle is allowed to blow
/// out, and vice versa.
@Suite("board light", .enabled(if: ProcessInfo.processInfo.environment["RENDER_BOARD"] != nil,
                               "set RENDER_BOARD=1 to look at the lighting"))
@MainActor
struct BoardLight {
    @Test("render")
    func render() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        // Low and turned round: the angles the pieces are actually looked at
        // from, and where both faults show.
        let shots: [(name: String, azimuth: Float, elevation: Float, playable: Bool)] = [
            ("front-low", -0.72, 0.30, true), ("front-high", -0.72, 0.72, true),
            ("side", -1.45, 0.34, true), ("across", 0.62, 0.30, true),
            // The title sequence, which is lit for the shot rather than for
            // play — and still has to leave a dark square looking dark.
            ("title-near", -0.72, 0.46, false), ("title-turned", -1.20, 0.40, false),
        ]

        for (index, shot) in shots.enumerated() {
            let stage = Stage(quality: .high, style: .banded, playable: shot.playable)
            stage.board.reset()
            stage.setCoordinates(shot.playable)

            var camera = OrbitCamera()
            camera.azimuth = shot.azimuth
            camera.elevation = shot.elevation
            camera.fit(aspect: 0.62)
            let eye = camera.eye(clock: 0)
            stage.cameraNode.position = SCNVector3(eye.x, eye.y, eye.z)
            stage.cameraNode.look(
                at: SCNVector3(camera.target.x, camera.target.y, camera.target.z),
                up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1)
            )

            let renderer = SCNRenderer(device: device, options: nil)
            renderer.scene = stage.scene
            renderer.pointOfView = stage.cameraNode
            let image = renderer.snapshot(atTime: 0, with: NSSize(width: 620, height: 900),
                                          antialiasingMode: .multisampling4X)
            guard let data = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: data),
                  let png = rep.representation(using: .png, properties: [:]) else { return }
            let path = "/private/tmp/claude-501/-Users-minchomilev-chess/63baeda4-a148-4429-ae3d-4e75303c0c1c/scratchpad/board-\(index)-\(shot.name).png"
            try png.write(to: URL(fileURLWithPath: path))
        }
    }
}
