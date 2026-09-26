import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// A dark square in the left-hand corner — "light on the right".
///
/// Both of the round board's fields are drawn into a CGContext, whose origin is
/// the bottom-left corner, and SceneKit lays the image on the board with rank
/// one nearest White. So the parity that reads as a1-dark in a top-down loop is
/// a1-light here, and both boards shipped that way: every square the wrong
/// colour, which nobody who plays notices for a moment and then cannot stop
/// seeing. This looks at the rendered board rather than at the loop, because
/// the loop was right on paper.
@Suite("square colours")
@MainActor
struct SquareColours {
    @Test("a dark square in White's left-hand corner", arguments: [PieceStyle.banded, .parlour])
    func darkCorner(style: PieceStyle) throws {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let stage = Stage(quality: .low, style: style, playable: true)
        stage.board.reset()
        stage.setCoordinates(false)

        // Straight down, square on, White at the bottom of the picture, and
        // orthographic so a square's pixels are where its coordinates say.
        let camera = stage.cameraNode.camera ?? SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 4.0
        stage.cameraNode.camera = camera
        stage.cameraNode.position = SCNVector3(0, 20, 0)
        stage.cameraNode.look(at: SCNVector3(0, 0, 0), up: SCNVector3(0, 0, -1),
                              localFront: SCNVector3(0, 0, -1))

        let size = 256
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = stage.scene
        renderer.pointOfView = stage.cameraNode
        let image = renderer.snapshot(atTime: 0, with: NSSize(width: size, height: size),
                                      antialiasingMode: .none)
        let rep = try #require(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))

        // The third rank, which the starting position leaves empty.
        func brightness(file: Int, rank: Int) -> CGFloat {
            let x = Float(file) - 3.5, z = 3.5 - Float(rank - 1)
            let px = Int((x + 4) / 8 * Float(rep.pixelsWide))
            let py = Int((z + 4) / 8 * Float(rep.pixelsHigh))
            var total: CGFloat = 0
            for dx in -3...3 {
                for dy in -3...3 {
                    let colour = rep.colorAt(x: px + dx, y: py + dy)?.usingColorSpace(.deviceRGB)
                    total += (colour?.redComponent ?? 0) + (colour?.greenComponent ?? 0) + (colour?.blueComponent ?? 0)
                }
            }
            return total / 49
        }

        let a3 = brightness(file: 0, rank: 3)
        let b3 = brightness(file: 1, rank: 3)
        let h3 = brightness(file: 7, rank: 3)
        #expect(a3 < b3, "a3 should be dark and b3 light")
        #expect(a3 < h3, "a3 and h3 are different colours, a3 the dark one")
    }
}
