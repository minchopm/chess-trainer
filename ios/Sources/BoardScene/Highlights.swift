import ChessCore
import SceneKit

/// What the board says back: the square you have picked up, where it may go,
/// and where the last move came from.
///
/// Discs laid on the wood rather than squares tinted in the texture, because
/// the texture is one image shared by all sixty-four squares — and because a
/// disc catches the key light the same way a piece does, so the marks belong to
/// the same room as everything else.
@MainActor
final class Highlights {
    let node = SCNNode()

    private var destinations: [SCNNode] = []
    private var selection = SCNNode()
    private var trail: [SCNNode] = []

    private static let lift: Float = 0.006

    init() {
        selection = Self.square(colour: Colour.make(0xD6A95F), opacity: 0.3)
        selection.isHidden = true
        node.addChildNode(selection)

        for _ in 0..<2 {
            let mark = Self.square(colour: Colour.make(0xD6A95F), opacity: 0.16)
            mark.isHidden = true
            trail.append(mark)
            node.addChildNode(mark)
        }

        // Twenty-eight is the most squares a single piece can reach — a queen
        // on an open board — so the pool never has to grow mid-move.
        for _ in 0..<28 {
            let dot = Self.dot()
            dot.isHidden = true
            destinations.append(dot)
            node.addChildNode(dot)
        }
    }

    func show(selected: Square?, destinations squares: [Square], lastMove: (from: Square, to: Square)?) {
        if let selected {
            selection.isHidden = false
            place(selection, on: selected)
        } else {
            selection.isHidden = true
        }

        for (index, dot) in destinations.enumerated() {
            if index < squares.count {
                dot.isHidden = false
                place(dot, on: squares[index])
            } else {
                dot.isHidden = true
            }
        }

        let squares = lastMove.map { [$0.from, $0.to] } ?? []
        for (index, mark) in trail.enumerated() {
            if index < squares.count {
                mark.isHidden = false
                place(mark, on: squares[index])
            } else {
                mark.isHidden = true
            }
        }
    }

    private func place(_ node: SCNNode, on square: Square) {
        let point = PlayingBoard.position(of: square)
        node.position = SCNVector3(point.x, Self.lift, point.z)
    }

    private static func square(colour: Colour.Native, opacity: CGFloat) -> SCNNode {
        let plane = SCNPlane(width: 0.98, height: 0.98)
        let material = plane.firstMaterial!
        material.lightingModel = .constant
        material.diffuse.contents = colour
        material.blendMode = .add
        material.writesToDepthBuffer = false
        material.isDoubleSided = true
        let node = SCNNode(geometry: plane)
        node.opacity = opacity
        node.eulerAngles.x = -.pi / 2
        node.renderingOrder = 10
        return node
    }

    private static func dot() -> SCNNode {
        let disc = SCNCylinder(radius: 0.15, height: 0.004)
        let material = disc.firstMaterial!
        material.lightingModel = .constant
        material.diffuse.contents = Colour.make(0xF0CD8E)
        material.blendMode = .add
        material.writesToDepthBuffer = false
        let node = SCNNode(geometry: disc)
        node.opacity = 0.5
        node.renderingOrder = 10
        return node
    }
}
