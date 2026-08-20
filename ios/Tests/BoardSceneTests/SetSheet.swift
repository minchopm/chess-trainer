import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// Renders the whole set to one image, the way a shop photographs one.
///
/// Not an assertion — a way to look at six pieces in two colours without
/// building the app, moving a simulator and finding a position that shows them
/// all. Kept out of the normal run.
@Suite("set sheet", .enabled(if: ProcessInfo.processInfo.environment["RENDER_SET"] != nil,
                             "set RENDER_SET=1 to look at the pieces"))
@MainActor
struct SetSheet {
    @Test("render")
    func render() throws {
        let order: [PieceKind] = [.king, .queen, .bishop, .knight, .rook, .pawn]
        let materials = PieceMaterials(style: .banded)
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        for (row, colour) in [PieceColor.white, .black].enumerated() {
            for (column, kind) in order.enumerated() {
                let scene = SCNScene()
                // The room the pieces actually stand in. Photographed against
                // white, brass at full metalness reflects white and the gold
                // reads as cream — which is a judgement about the backdrop, not
                // about the piece.
                scene.background.contents = NSColor(red: 0.02, green: 0.024, blue: 0.04, alpha: 1)
                scene.lightingEnvironment.contents = BoardSurface.environment() as Any
                scene.lightingEnvironment.intensity = 0.7

                let piece = TurnedPieces.node(for: kind, style: .banded)
                for child in piece.childNodes {
                    let gilt = child.name == TurnedPieces.trimName
                    child.geometry = child.geometry?.copy() as? SCNGeometry
                    child.geometry?.materials = [materials.material(for: colour, lit: false, gilt: gilt)]
                }
                // Only the knight is turned: it is the one piece with a front,
                // and turning the king puts the arms of its cross end-on.
                if kind == .knight { piece.eulerAngles.y = .pi / 2 }
                scene.rootNode.addChildNode(piece)

                let key = SCNNode()
                key.light = SCNLight()
                key.light?.type = .directional
                key.light?.intensity = 850
                key.position = SCNVector3(2, 4, 4)
                key.look(at: SCNVector3(0, 0.4, 0))
                scene.rootNode.addChildNode(key)

                let fill = SCNNode()
                fill.light = SCNLight()
                fill.light?.type = .ambient
                fill.light?.intensity = 260
                scene.rootNode.addChildNode(fill)

                let camera = SCNNode()
                camera.camera = SCNCamera()
                camera.camera?.fieldOfView = 27
                camera.camera?.wantsHDR = true
                camera.position = SCNVector3(0, 1.0, 5.2)
                camera.look(at: SCNVector3(0, 0.62, 0))
                scene.rootNode.addChildNode(camera)

                let renderer = SCNRenderer(device: device, options: nil)
                renderer.scene = scene
                renderer.pointOfView = camera
                let image = renderer.snapshot(atTime: 0, with: CGSize(width: 300, height: 380),
                                              antialiasingMode: .multisampling4X)
                let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
                let png = rep.representation(using: .png, properties: [:])!
                let name = "/private/tmp/claude-501/-Users-minchomilev-chess/63baeda4-a148-4429-ae3d-4e75303c0c1c/scratchpad/set-\(row)-\(column).png"
                try png.write(to: URL(fileURLWithPath: name))
            }
        }
        print("WROTE twelve tiles")
    }
}
