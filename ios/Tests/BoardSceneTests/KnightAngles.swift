import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// Renders the knight from several angles at once.
///
/// Not an assertion — a way to catch what a single view cannot. The head was an
/// extruded silhouette for a long time and read perfectly from the side, which
/// is exactly the angle it was ever looked at: turned even thirty degrees it
/// went flat, because a slab of even depth has no shape to show. Anything that
/// changes the head wants looking at from all four.
@Suite("knight angles", .enabled(if: ProcessInfo.processInfo.environment["RENDER_KNIGHT"] != nil,
                                 "set RENDER_KNIGHT=1 to look at the knight"))
@MainActor
struct KnightAngles {
    @Test("render")
    func render() throws {
        guard MTLCreateSystemDefaultDevice() != nil else { return }
        let materials = PieceMaterials(style: .banded)

        // Four angles to look at, and three more shot the way
        // `ios/Tools/knight/reference.py` shoots a reference — orthographic,
        // square on — so `measure.py` can be run over both and the two read
        // against each other in numbers rather than by eye.
        let views: [(name: String, angle: Double, flat: Bool)] =
            [("angle-0", 0, false), ("angle-1", 30, false),
             ("angle-2", 60, false), ("angle-3", 90, false),
             ("mine-side", 90, true), ("mine-quarter", 45, true), ("mine-front", 0, true)]

        for (index, view) in views.enumerated() {
            let angle = view.angle
            let scene = SCNScene()
            scene.background.contents = NSColor(red: 0.02, green: 0.024, blue: 0.04, alpha: 1)
            scene.lightingEnvironment.contents = BoardSurface.environment() as Any
            scene.lightingEnvironment.intensity = 0.7

            let piece = TurnedPieces.node(for: .knight, style: .banded)
            for child in piece.childNodes {
                let gilt = child.name == TurnedPieces.trimName
                child.geometry = child.geometry?.copy() as? SCNGeometry
                child.geometry?.materials = [materials.material(for: .white, lit: false, gilt: gilt)]
            }
            piece.eulerAngles.y = .init(angle * .pi / 180)
            scene.rootNode.addChildNode(piece)

            let camera = SCNNode()
            camera.camera = SCNCamera()
            if view.flat {
                camera.camera?.usesOrthographicProjection = true
                camera.camera?.orthographicScale = 0.52
                camera.position = SCNVector3(0, 0.72, 3)
                camera.look(at: SCNVector3(0, 0.72, 0))
            } else {
                camera.camera?.fieldOfView = 22
                camera.position = SCNVector3(0, 0.62, 2.6)
                camera.look(at: SCNVector3(0, 0.56, 0))
            }
            scene.rootNode.addChildNode(camera)

            let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
            renderer.scene = scene
            renderer.pointOfView = camera
            let size = NSSize(width: view.flat ? 560 : 420, height: view.flat ? 760 : 560)
            let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
            guard let data = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: data),
                  let png = rep.representation(using: .png, properties: [:]) else { return }
            _ = index
            let path = "/private/tmp/claude-501/-Users-minchomilev-chess/63baeda4-a148-4429-ae3d-4e75303c0c1c/scratchpad/knight-\(view.name).png"
            try png.write(to: URL(fileURLWithPath: path))
        }
    }
}
