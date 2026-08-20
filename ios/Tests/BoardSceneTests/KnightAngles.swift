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

        for (index, angle) in [0.0, 30.0, 60.0, 90.0].enumerated() {
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
            camera.camera?.fieldOfView = 22
            camera.position = SCNVector3(0, 0.62, 2.6)
            camera.look(at: SCNVector3(0, 0.56, 0))
            scene.rootNode.addChildNode(camera)

            let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
            renderer.scene = scene
            renderer.pointOfView = camera
            let size = NSSize(width: 420, height: 560)
            let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
            guard let data = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: data),
                  let png = rep.representation(using: .png, properties: [:]) else { return }
            let path = "/private/tmp/claude-501/-Users-minchomilev-chess/63baeda4-a148-4429-ae3d-4e75303c0c1c/scratchpad/knight-angle-\(index).png"
            try png.write(to: URL(fileURLWithPath: path))
        }
    }
}
