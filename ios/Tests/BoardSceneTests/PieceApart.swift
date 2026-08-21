import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// Renders the turning, the whole piece, and the head on its own.
///
/// Three pictures rather than one, because a fault in a piece made of parts
/// that stand inside one another cannot be placed from the assembled render.
/// The knight's head was torn open along the bottom for some time and it read
/// as a ring of shards round the collar, which looks exactly like a badly
/// seated band — so the band was moved, grooved and reseated three times over
/// while the hole stayed where it was. Rendering the head with nothing else in
/// the scene settled it in one shot.
@Suite("piece apart", .enabled(if: ProcessInfo.processInfo.environment["RENDER_BASE"] != nil))
@MainActor
struct PieceApart {
    @Test("render")
    func render() throws {
        guard MTLCreateSystemDefaultDevice() != nil else { return }
        let materials = PieceMaterials(style: .banded)
        for (index, keep) in ["base", "whole", "head"].enumerated() {
            let scene = SCNScene()
            scene.background.contents = NSColor(red: 0.02, green: 0.024, blue: 0.04, alpha: 1)
            scene.lightingEnvironment.contents = BoardSurface.environment() as Any
            scene.lightingEnvironment.intensity = 0.7
            let piece: SCNNode
            if keep == "head" {
                // The head's own geometry, with nothing else in the scene: no
                // base to intersect, no brass, no mane.
                piece = SCNNode(geometry: TurnedPieces.knightHead(0.72))
                piece.geometry?.materials = [materials.material(for: .white, lit: false, gilt: false)]
            } else {
                piece = TurnedPieces.node(for: .knight, style: .banded)
            }
            for child in piece.childNodes {
                let gilt = child.name == TurnedPieces.trimName
                child.geometry = child.geometry?.copy() as? SCNGeometry
                child.geometry?.materials = [materials.material(for: .white, lit: false, gilt: gilt)]
            }
            if keep == "base" {
                for child in piece.childNodes where (child.geometry?.elements.first?.primitiveCount ?? 0) > 2000 {
                    child.removeFromParentNode()
                }
            }
            piece.eulerAngles.y = .init(60 * Double.pi / 180)
            scene.rootNode.addChildNode(piece)
            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.fieldOfView = 16
            camera.position = SCNVector3(0, 0.58, 2.6)
            camera.look(at: SCNVector3(0, 0.54, 0))
            scene.rootNode.addChildNode(camera)
            let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
            renderer.scene = scene
            renderer.pointOfView = camera
            let image = renderer.snapshot(atTime: 0, with: NSSize(width: 500, height: 500),
                                          antialiasingMode: .multisampling4X)
            guard let data = image.tiffRepresentation, let rep = NSBitmapImageRep(data: data),
                  let png = rep.representation(using: .png, properties: [:]) else { return }
            try png.write(to: URL(fileURLWithPath: "/private/tmp/claude-501/-Users-minchomilev-chess/63baeda4-a148-4429-ae3d-4e75303c0c1c/scratchpad/base-\(index).png"))
        }
    }
}

