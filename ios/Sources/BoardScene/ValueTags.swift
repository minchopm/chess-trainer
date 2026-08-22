import ChessCore
import CoreGraphics
import CoreText
import Foundation
import SceneKit

/// What a move is worth, said on the board itself.
///
/// The flat board writes these into the square. The turned board cannot: a
/// number laid flat on a square is legible from one chair and foreshortened
/// into a smear from every other, and the board turns. So on the round board
/// each value is a small standing plate that keeps its face to whoever is
/// looking — it lives in the scene, takes the room's light and the scene's
/// perspective, but never turns edge-on.
public struct ValueTag: Sendable, Equatable {
    public let square: Square
    /// Already formatted in the reader's own numerals.
    public let text: String
    /// Centipawns given up against the best move available.
    public let loss: Int
    /// Whether a piece stands on the square, which decides how high the plate
    /// floats: above the piece rather than through it.
    public let overPiece: Bool

    public init(square: Square, text: String, loss: Int, overPiece: Bool) {
        self.square = square
        self.text = text
        self.loss = loss
        self.overPiece = overPiece
    }
}

/// What one reachable square is worth, ready to be drawn.
public struct ValuePlate: Sendable, Equatable {
    /// Already formatted in the reader's own numerals.
    public let text: String
    /// Centipawns given up against the best move available.
    public let loss: Int

    public init(text: String, loss: Int) {
        self.text = text
        self.loss = loss
    }
}

/// Green for the best move, sliding through amber to red as it gets worse.
///
/// One ramp, used by both boards. Two would drift apart, and a move that is
/// amber in the round and orange in the flat is two different answers to the
/// same question.
public enum ValueTint {
    public static func components(loss: Int) -> (r: Double, g: Double, b: Double) {
        switch loss {
        case ..<15: (0.16, 0.55, 0.24)
        case ..<60: (0.35, 0.52, 0.22)
        case ..<150: (0.72, 0.55, 0.13)
        case ..<350: (0.75, 0.38, 0.14)
        default: (0.68, 0.22, 0.18)
        }
    }
}

/// The pool of standing plates, one per reachable square.
@MainActor
final class ValueTagPool {
    let node = SCNNode()
    private var plates: [SCNNode] = []

    /// The most squares a single piece can reach — a queen on an open board.
    private static let capacity = 28

    /// How high the plate floats, in squares. A piece is about one square tall
    /// at the tallest; clearing that keeps the number off the king's cross.
    private static let overEmpty: Float = 0.52
    private static let overOccupied: Float = 1.38

    init() {
        for _ in 0..<Self.capacity {
            let plate = Self.plate()
            plate.isHidden = true
            plates.append(plate)
            node.addChildNode(plate)
        }
    }

    func show(_ tags: [ValueTag]) {
        for (index, plate) in plates.enumerated() {
            guard index < tags.count else {
                plate.isHidden = true
                continue
            }
            let tag = tags[index]
            plate.isHidden = false
            let point = PlayingBoard.position(of: tag.square)
            plate.position = SCNVector3(
                point.x,
                tag.overPiece ? Self.overOccupied : Self.overEmpty,
                point.z
            )
            let tint = ValueTint.components(loss: tag.loss)
            plate.geometry?.firstMaterial?.diffuse.contents =
                Self.face(tag.text, tint: tint) as Any
        }
    }

    private static func plate() -> SCNNode {
        let plane = SCNPlane(width: 0.92, height: 0.46)
        let material = plane.firstMaterial!
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.writesToDepthBuffer = false
        material.transparencyMode = .aOne

        let node = SCNNode(geometry: plane)
        // Turned about the upright axis only. Free on all three and the plate
        // tips with the camera and reads as a sticker on the lens; free on
        // none and it goes edge-on the moment the board is turned.
        let facing = SCNBillboardConstraint()
        facing.freeAxes = .Y
        node.constraints = [facing]
        // Over the pieces, whatever the depth buffer thinks: a number hidden
        // behind the queen it is describing is worse than no number.
        node.renderingOrder = 20
        return node
    }

    /// The plate's face: a filled capsule with the number in it.
    private static func face(_ text: String, tint: (r: Double, g: Double, b: Double)) -> CGImage? {
        let width = 264, height = 136
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let inset: CGFloat = 8
        let box = CGRect(x: inset, y: inset,
                         width: CGFloat(width) - inset * 2, height: CGFloat(height) - inset * 2)
        let capsule = CGPath(roundedRect: box, cornerWidth: box.height / 2,
                             cornerHeight: box.height / 2, transform: nil)

        // A rim of the room's own dark, so the plate reads against ivory as
        // well as against wood.
        ctx.setShadow(offset: .zero, blur: 10,
                      color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.55))
        ctx.addPath(capsule)
        ctx.setFillColor(CGColor(red: tint.r, green: tint.g, blue: tint.b, alpha: 0.96))
        ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        ctx.addPath(capsule)
        ctx.setStrokeColor(CGColor(red: 1, green: 0.98, blue: 0.94, alpha: 0.30))
        ctx.setLineWidth(3)
        ctx.strokePath()

        let font = CTFontCreateWithName("Menlo-Bold" as CFString, 62, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        ]
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: text, attributes: attributes)
        )
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        ctx.textPosition = CGPoint(
            x: (CGFloat(width) - bounds.width) / 2 - bounds.origin.x,
            y: (CGFloat(height) - bounds.height) / 2 - bounds.origin.y
        )
        CTLineDraw(line, ctx)
        return ctx.makeImage()
    }
}
