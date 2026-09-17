import ChessCore
import SceneKit

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The coach's answer, drawn from one square to another.
///
/// The flat board has drawn this since there was a coach; the round board never
/// did, and the argument simply went missing on the way through — a hint given
/// on the turned board pointed at nothing at all.
///
/// Laid into the wood rather than standing over it. A value is a label and
/// belongs face-on to the reader, which is why `ValueTag` turns to follow the
/// camera; an arrow is a direction, and a direction has to stay on the board it
/// is pointing across. So this lies flat, like the destination dots, and is
/// raised a little above them — they are what it is drawn over.
public struct BoardArrow: Sendable, Equatable {
    public let from: Square
    public let to: Square
    public let tint: ArrowTint

    public init(from: Square, to: Square, tint: ArrowTint) {
        self.from = from
        self.to = to
        self.tint = tint
    }
}

/// What the arrow is saying. The three the coach uses, in the flat board's own
/// colours — a hint that is blue on one board and green on the other is two
/// different answers to the same question.
public enum ArrowTint: Sendable, Equatable {
    /// The move the engine would play.
    case good
    /// A hint, offered rather than insisted on.
    case suggestion
    /// Something to look at before it costs you.
    case warning

    var hex: UInt32 {
        switch self {
        case .good: 0x6CBF73
        case .suggestion: 0x5B9BD5
        case .warning: 0xD9705F
        }
    }
}

/// A ring round a square, in the same language as the arrow.
///
/// The flat board has had a circle in its vocabulary since the beginning and
/// nothing ever drew one; this is the first thing that does — the mark on every
/// piece that has a legal move. It is a ring rather than a filled disc because
/// the piece has to stay readable underneath it: the mark is about the piece,
/// not instead of it.
public struct BoardRing: Sendable, Equatable {
    public let square: Square
    public let tint: ArrowTint

    public init(square: Square, tint: ArrowTint) {
        self.square = square
        self.tint = tint
    }
}

/// The pool of rings laid on the board.
///
/// Unlike an arrow, a ring is the same shape wherever it goes, so the geometry
/// is made once and every ring is a node sharing it. There can be sixteen of
/// them at the start of a game and they are all identical.
@MainActor
final class RingPool {
    let node = SCNNode()
    private var shown: [BoardRing] = []
    /// One geometry per tint, built the first time that tint is asked for.
    private var geometries: [UInt32: SCNGeometry] = [:]

    /// Under the arrow and over the dots. A ring says which pieces may move; an
    /// arrow says which move to make, and when both are on the board the answer
    /// belongs on top of the question.
    private static let lift: Float = 0.010
    /// The flat board's circle, in squares — radius 0.42, stroked 0.07 wide, so
    /// the pipe is half of that. Both boards draw the same ring.
    private static let ringRadius: CGFloat = 0.42
    private static let pipeRadius: CGFloat = 0.035
    /// Squashed flat, so the ring is an inlay with a top and a side rather than
    /// a length of rope lying on the board — the same thickness the arrow has.
    private static let thickness: CGFloat = 0.014

    func show(_ rings: [BoardRing]) {
        guard rings != shown else { return }
        shown = rings
        node.childNodes.forEach { $0.removeFromParentNode() }
        for ring in rings {
            node.addChildNode(inlay(ring))
        }
    }

    private func inlay(_ ring: BoardRing) -> SCNNode {
        let geometry = geometries[ring.tint.hex] ?? Self.make(tint: ring.tint)
        geometries[ring.tint.hex] = geometry

        let flat = SCNNode(geometry: geometry)
        // A torus already lies in the board's plane — its axis is up — so it
        // needs no turn, only flattening.
        flat.scale = SCNVector3(1, .init(Self.thickness / (2 * Self.pipeRadius)), 1)
        flat.opacity = 0.9
        // Above the dots, below the arrow and the value plates.
        flat.renderingOrder = 11

        let place = PlayingBoard.position(of: ring.square)
        let node = SCNNode()
        node.addChildNode(flat)
        node.position = SCNVector3(place.x, Self.lift + Float(Self.thickness) / 2, place.z)
        return node
    }

    private static func make(tint: ArrowTint) -> SCNGeometry {
        let torus = SCNTorus(ringRadius: ringRadius, pipeRadius: pipeRadius)
        // Enough segments that the ring is round at the size a square is drawn
        // on a phone, and few enough that sixteen of them cost nothing.
        torus.ringSegmentCount = 48
        torus.pipeSegmentCount = 8
        let material = torus.firstMaterial!
        let colour = Colour.make(tint.hex)
        // The arrow's materials, for the same reason: lit so the inlay has a
        // side, emissive so it survives a square the lamp has not reached.
        material.lightingModel = .lambert
        material.diffuse.contents = colour
        material.emission.contents = Colour.make(tint.hex, alpha: 0.45)
        material.writesToDepthBuffer = false
        return torus
    }
}

/// The pool of arrows laid on the board.
///
/// A pool of one, because the coach has never asked for two at once, and the
/// geometry has to be rebuilt for each anyway: an arrow's shape depends on
/// which two squares it joins, so unlike a dot it cannot be made once and moved.
@MainActor
final class ArrowPool {
    let node = SCNNode()
    private var shown: [BoardArrow] = []

    /// Clear of the dots, which sit at 0.006 and are 0.004 thick. Above them by
    /// about the thickness of the arrow itself, so where the two cross — and
    /// they cross on the square the arrow points at — it is the arrow on top.
    private static let lift: Float = 0.015
    /// How far the inlay stands proud of the board.
    ///
    /// Small enough to read as laid into the wood rather than lying on it, and
    /// large enough that its edge takes the key light and the arrow has a side
    /// as well as a face. At a tenth of this it is a decal; at ten times it is
    /// a wall across the board.
    private static let thickness: CGFloat = 0.014

    // The flat board's proportions, in squares — see `BoardView.drawArrow`, so
    // the two boards draw the same arrow.
    private static let shaftHalfWidth: CGFloat = 0.065
    private static let headHalfWidth: CGFloat = 0.132
    /// Where the head's back edge falls, measured back from the centre of the
    /// square being pointed at, so the whole head sits inside that square.
    private static let headInset: CGFloat = 0.34
    /// And its point, which stops short of the centre for the same reason.
    private static let tipInset: CGFloat = 0.08
    /// The tail starts outside the middle of its own square, so a piece
    /// standing there is not skewered by it.
    private static let tailInset: CGFloat = 0.20

    func show(_ arrows: [BoardArrow]) {
        guard arrows != shown else { return }
        shown = arrows
        node.childNodes.forEach { $0.removeFromParentNode() }
        for arrow in arrows where arrow.from != arrow.to {
            node.addChildNode(Self.inlay(arrow))
        }
    }

    private static func inlay(_ arrow: BoardArrow) -> SCNNode {
        let start = PlayingBoard.position(of: arrow.from)
        let end = PlayingBoard.position(of: arrow.to)
        let run = SIMD2<Float>(end.x - start.x, end.z - start.z)
        let length = max(0.001, (run * run).sum().squareRoot())

        let shape = SCNShape(path: profile(length: CGFloat(length)), extrusionDepth: thickness)
        let material = shape.firstMaterial!
        let colour = Colour.make(arrow.tint.hex)
        // Lit rather than constant, unlike the dots: a dot is a flat disc with
        // nothing to shade, and this has a wall around it that is worth seeing.
        // The emission is what keeps it in the dots' family — it glows in its
        // own right, so it stays legible on a square the lamp has not reached,
        // while the diffuse gives the top and the side different brightnesses
        // and the inlay a thickness you can see.
        material.lightingModel = .lambert
        material.diffuse.contents = colour
        material.emission.contents = Colour.make(arrow.tint.hex, alpha: 0.45)
        material.writesToDepthBuffer = false

        // The profile is drawn in the plane the path was written in and the
        // extrusion runs along its normal, so a quarter turn lays the arrow on
        // the board with its thickness standing up off it. SCNShape extrudes
        // about the profile rather than from it, hence the half.
        let flat = SCNNode(geometry: shape)
        flat.eulerAngles.x = -.pi / 2
        flat.opacity = 0.92
        // After the dots and before the value plates, which are the only things
        // on the board with more right to be seen than this.
        flat.renderingOrder = 12

        // The turn and the place it is turned about are the parent's, so the
        // geometry never has to know which way it points. See `profile`.
        let node = SCNNode()
        node.addChildNode(flat)
        node.position = SCNVector3(start.x, lift + Float(thickness) / 2, start.z)
        // `.init` rather than the bare angle: a scene vector is Float on the
        // phone and CGFloat on the Mac, and this file is built for both.
        node.eulerAngles.y = .init(atan2(-run.x, -run.y))
        return node
    }

    /// The arrow lying along the profile plane's own axis, as one closed
    /// outline, with only its length to say which arrow it is.
    ///
    /// Written straight and then turned, rather than written between the two
    /// squares, and that is not tidiness. Given the outline in board
    /// coordinates, `SCNShape` builds nothing at all for an arrow lying at an
    /// odd angle — a knight's move comes back with an empty bounding box and
    /// draws nothing, while the same arrow along a file or a diagonal is fine.
    /// It fails silently, which is how it survived being written. Built along
    /// one axis, every arrow is the same handful of corners in the same places
    /// and only the shaft gets longer, so there is one case and it is the case
    /// that works. `CoachArrowAngles` holds every direction to it.
    ///
    /// A single polygon rather than a shaft and a head laid over each other:
    /// two overlapping subpaths are a question about fill rules that the two
    /// platforms' bezier paths answer differently.
    private static func profile(length: CGFloat) -> BezierPath {
        let tail = tailInset
        // A one-square arrow still has to have a shaft; nothing shorter exists,
        // but nothing here should depend on that.
        let neck = max(tail + 0.001, length - headInset)
        let tip = length - tipInset

        let outline = [
            CGPoint(x: shaftHalfWidth, y: tail),
            CGPoint(x: shaftHalfWidth, y: neck),
            CGPoint(x: headHalfWidth, y: neck),
            CGPoint(x: 0, y: tip),
            CGPoint(x: -headHalfWidth, y: neck),
            CGPoint(x: -shaftHalfWidth, y: neck),
            CGPoint(x: -shaftHalfWidth, y: tail),
        ]

        let path = BezierPath()
        path.start(outline[0].x, outline[0].y)
        for corner in outline.dropFirst() { path.straight(corner.x, corner.y) }
        path.close()
        return path
    }
}
