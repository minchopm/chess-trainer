import ChessCore
import SceneKit

#if canImport(UIKit)
import UIKit
typealias BezierPath = UIBezierPath
#else
import AppKit
typealias BezierPath = NSBezierPath
#endif

extension BezierPath {
    func start(_ x: CGFloat, _ y: CGFloat) { move(to: CGPoint(x: x, y: y)) }

    func straight(_ x: CGFloat, _ y: CGFloat) {
        #if canImport(UIKit)
        addLine(to: CGPoint(x: x, y: y))
        #else
        line(to: CGPoint(x: x, y: y))
        #endif
    }

    func curve(_ c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        let end = CGPoint(x: x, y: y)
        let one = CGPoint(x: c1x, y: c1y)
        let two = CGPoint(x: c2x, y: c2y)
        #if canImport(UIKit)
        addCurve(to: end, controlPoint1: one, controlPoint2: two)
        #else
        curve(to: end, controlPoint1: one, controlPoint2: two)
        #endif
    }
}

/// Which set is standing on the board.
public enum PieceStyle: String, Sendable, CaseIterable, Codable {
    /// The site's set: boxwood and ebony, nothing on them but the turning.
    case plain
    /// The same turning, banded and finialled in brass — the set the flat
    /// board has been using, which is a photographed Staunton with gilt collars
    /// and gilt finials. Not the photographs turned into meshes, which cannot
    /// honestly be done: the same lathe, given the same jewellery.
    case banded

    public var isBanded: Bool { self == .banded }
}

/// Chess pieces, turned rather than modelled.
///
/// Ported from the site profile for profile. A downloaded model set would look
/// better and cost two megabytes and a licence to check; every piece here is a
/// lathe plus, for the three a lathe cannot make, a small amount of honest
/// cheating — the knight is an extruded silhouette, the rook's battlements are
/// cut with cylinders, the king wears a cross made of two.
///
/// One square is one unit. The heights follow a real Staunton set's
/// proportions, because a set where the bishop outranks the queen reads as
/// wrong long before anybody works out why.
public enum TurnedPieces {
    static let segments = 48

    /// The foot every piece stands on: a wide disc that tucks in, then flares
    /// out again into the stem. Shared, so a set looks like a set.
    private static func foot(_ s: Float) -> [Turn] {
        [
            (0.0, 0.0), (0.34 * s, 0.0), (0.34 * s, 0.035 * s), (0.325 * s, 0.075 * s),
            (0.27 * s, 0.1 * s), (0.23 * s, 0.13 * s), (0.2 * s, 0.19 * s), (0.165 * s, 0.28 * s),
        ]
    }

    private static func collar(_ s: Float, _ y: Float, _ radius: Float) -> [Turn] {
        [
            (radius * s, y * s),
            ((radius + 0.055) * s, (y + 0.03) * s),
            ((radius + 0.045) * s, (y + 0.07) * s),
            (radius * s * 0.92, (y + 0.09) * s),
        ]
    }

    private static func pawn(_ s: Float) -> Solid {
        var solid = Solid.revolved(foot(s) + [
            (0.135 * s, 0.36 * s), (0.12 * s, 0.44 * s),
        ] + collar(s, 0.46, 0.12) + [
            (0.1 * s, 0.58 * s), (0.13 * s, 0.63 * s), (0.155 * s, 0.7 * s),
            (0.15 * s, 0.78 * s), (0.1 * s, 0.83 * s), (0.0, 0.85 * s),
        ], segments: segments)
        solid.append(.sphere(radius: 0.155 * s, at: SIMD3(0, 0.83 * s, 0), segments: segments, rings: 24))
        return solid
    }

    private static func rook(_ s: Float) -> Solid {
        var solid = Solid.revolved(foot(s) + [
            (0.185 * s, 0.4 * s), (0.18 * s, 0.58 * s),
        ] + collar(s, 0.6, 0.185) + [
            (0.2 * s, 0.72 * s), (0.235 * s, 0.78 * s), (0.245 * s, 0.86 * s),
            (0.245 * s, 1.02 * s), (0.19 * s, 1.02 * s), (0.19 * s, 0.9 * s), (0.0, 0.9 * s),
        ], segments: segments)

        // Battlements: six little towers left standing, which read as the gaps
        // between them because the crown ring sits proud of the wall.
        let merlons = 6
        for i in 0..<merlons {
            let angle = Float(i) / Float(merlons) * 2 * .pi
            solid.append(.cylinder(
                radius: 0.075 * s, height: 0.2 * s,
                at: SIMD3(cosf(angle) * 0.245 * s, 0.99 * s, sinf(angle) * 0.245 * s),
                segments: 10
            ))
        }
        solid.append(.ring(radius: 0.235 * s, tube: 0.03 * s, at: SIMD3(0, 0.86 * s, 0)))
        return solid
    }

    private static func bishop(_ s: Float) -> Solid {
        var solid = Solid.revolved(foot(s) + [
            (0.145 * s, 0.4 * s), (0.125 * s, 0.5 * s),
        ] + collar(s, 0.52, 0.125) + [
            (0.115 * s, 0.64 * s), (0.175 * s, 0.72 * s), (0.2 * s, 0.84 * s),
            (0.185 * s, 0.98 * s), (0.13 * s, 1.08 * s), (0.075 * s, 1.13 * s),
            (0.09 * s, 1.16 * s), (0.055 * s, 1.2 * s), (0.0, 1.22 * s),
        ], segments: segments)
        solid.append(.sphere(radius: 0.06 * s, at: SIMD3(0, 1.26 * s, 0), segments: segments, rings: 20))
        return solid
    }

    private static func queen(_ s: Float) -> Solid {
        var solid = Solid.revolved(foot(s) + [
            (0.17 * s, 0.42 * s), (0.145 * s, 0.56 * s),
        ] + collar(s, 0.58, 0.145) + [
            (0.13 * s, 0.72 * s), (0.185 * s, 0.86 * s), (0.225 * s, 1.02 * s),
            (0.235 * s, 1.14 * s), (0.2 * s, 1.2 * s), (0.235 * s, 1.24 * s),
            (0.235 * s, 1.3 * s), (0.12 * s, 1.3 * s), (0.0, 1.28 * s),
        ], segments: segments)

        let points = 9
        for i in 0..<points {
            let angle = Float(i) / Float(points) * 2 * .pi
            solid.append(.sphere(
                radius: 0.048 * s,
                at: SIMD3(cosf(angle) * 0.215 * s, 1.34 * s, sinf(angle) * 0.215 * s),
                segments: 20, rings: 12
            ))
        }
        solid.append(.sphere(radius: 0.075 * s, at: SIMD3(0, 1.36 * s, 0), segments: 32, rings: 16))
        return solid
    }

    private static func king(_ s: Float) -> Solid {
        var solid = Solid.revolved(foot(s) + [
            (0.175 * s, 0.44 * s), (0.15 * s, 0.6 * s),
        ] + collar(s, 0.62, 0.15) + [
            (0.135 * s, 0.76 * s), (0.19 * s, 0.9 * s), (0.23 * s, 1.08 * s),
            (0.24 * s, 1.22 * s), (0.205 * s, 1.28 * s), (0.24 * s, 1.32 * s),
            (0.235 * s, 1.4 * s), (0.13 * s, 1.42 * s), (0.0, 1.4 * s),
        ], segments: segments)

        solid.append(.cylinder(radius: 0.046 * s, height: 0.28 * s, at: SIMD3(0, 1.54 * s, 0)))
        solid.append(.cylinder(radius: 0.036 * s, height: 0.19 * s, at: SIMD3(0, 1.58 * s, 0), axis: .x))
        solid.append(.sphere(radius: 0.05 * s, at: SIMD3(0, 1.68 * s, 0), segments: 32, rings: 16))
        return solid
    }

    /// The base a knight's head sits on. The head itself is not a lathe.
    private static func knightBase(_ s: Float) -> Solid {
        Solid.revolved(foot(s) + [
            (0.175 * s, 0.36 * s), (0.165 * s, 0.44 * s),
        ] + collar(s, 0.44, 0.165) + [
            (0.16 * s, 0.56 * s), (0.0, 0.56 * s),
        ], segments: segments)
    }

    /// The knight's silhouette, extruded and bevelled — the way a set is
    /// actually stamped when it is not carved.
    ///
    /// Three things separate a horse from a rabbit, and all three are easy to
    /// get wrong: the ears are **short** triangles set back over the poll
    /// rather than long blades; the muzzle is **long** and travels forward
    /// *and down*, so the nose finishes well below the top of the skull; and
    /// the neck arches backwards instead of rising straight. The serrated edge
    /// down the back is the mane, and it does more for the read than any
    /// amount of detail on the face.
    ///
    /// Traced anticlockwise from the base of the neck: up the crest, over the
    /// poll, out along the ears, down the forehead and the bridge of the nose,
    /// round the muzzle, back under the jaw, and down the throat.
    private static func knightHead(_ s: Float) -> SCNGeometry {
        let path = BezierPath()
        func p(_ x: Float, _ y: Float) -> (CGFloat, CGFloat) { (CGFloat(x * s), CGFloat(y * s)) }

        var v = p(-0.185, 0.5); path.start(v.0, v.1)

        // The crest of the neck, arching back before it rises.
        let c1 = p(-0.275, 0.63), c2 = p(-0.285, 0.8), e1 = p(-0.245, 0.925)
        path.curve(c1.0, c1.1, c2.0, c2.1, e1.0, e1.1)

        // The mane: seven shallow scallops up the back of the neck. Shallow is
        // the whole trick — deep ones read as spikes, and they must stop short
        // of the poll so they do not merge with the ears into a crown.
        for point in [(-0.208, 0.945), (-0.232, 0.966), (-0.196, 0.982), (-0.22, 1.003),
                      (-0.184, 1.019), (-0.208, 1.04), (-0.17, 1.056)] {
            v = p(Float(point.0), Float(point.1)); path.straight(v.0, v.1)
        }
        let c3 = p(-0.15, 1.075), c4 = p(-0.115, 1.092), e2 = p(-0.078, 1.098)
        path.curve(c3.0, c3.1, c4.0, c4.1, e2.0, e2.1)

        // Ears: two short nubs with one notch between them. Anything taller is
        // a rabbit, and anything without the notch is a horn.
        for point in [(-0.088, 1.158), (-0.03, 1.104), (0.014, 1.156), (0.046, 1.092)] {
            v = p(Float(point.0), Float(point.1)); path.straight(v.0, v.1)
        }

        // Forehead, then the face falling forward and down.
        let c5 = p(0.096, 1.07), c6 = p(0.138, 1.028), e3 = p(0.162, 0.972)
        path.curve(c5.0, c5.1, c6.0, c6.1, e3.0, e3.1)
        let c7 = p(0.198, 0.906), c8 = p(0.238, 0.858), e4 = p(0.272, 0.828)
        path.curve(c7.0, c7.1, c8.0, c8.1, e4.0, e4.1)

        // The muzzle, cut off square and short. A long tapering one makes a fox.
        for point in [(0.298, 0.812), (0.302, 0.772), (0.268, 0.76), (0.276, 0.734), (0.226, 0.722)] {
            v = p(Float(point.0), Float(point.1)); path.straight(v.0, v.1)
        }

        // The cheek: a heavy round mass hanging below and behind the mouth,
        // with the throat notch tucked in behind it. This is the piece of
        // anatomy that stops a horse's head looking like a greyhound's.
        let c9 = p(0.17, 0.688), c10 = p(0.09, 0.672), e5 = p(0.036, 0.712)
        path.curve(c9.0, c9.1, c10.0, c10.1, e5.0, e5.1)
        let c11 = p(-0.008, 0.746), c12 = p(-0.028, 0.79), e6 = p(-0.02, 0.822)
        path.curve(c11.0, c11.1, c12.0, c12.1, e6.0, e6.1)

        // And down the throat into the chest.
        let c13 = p(0.008, 0.76), c14 = p(0.04, 0.64), e7 = p(0.098, 0.52)
        path.curve(c13.0, c13.1, c14.0, c14.1, e7.0, e7.1)
        path.close()

        // The eye, cut clean through. It catches the key light and does more
        // for the read than another thousand triangles would.
        let centre = p(0.055, 0.985)
        let radius = CGFloat(0.024 * s)
        let eye = BezierPath(ovalIn: CGRect(
            x: centre.0 - radius, y: centre.1 - radius, width: radius * 2, height: radius * 2
        ))
        path.append(eye)
        #if canImport(UIKit)
        path.usesEvenOddFillRule = true
        #else
        path.windingRule = .evenOdd
        #endif
        // Not smaller. Flatness is the error a curve may be flattened with,
        // and asking for a thousandth of a unit on a path this small does not
        // produce a smoother knight — it produces no knight: SCNShape's
        // tessellation collapses and the head comes out as a sliver a
        // thirty-fifth of its proper height, which on the board reads as a
        // horse with no head.
        path.flatness = 0.05

        let shape = SCNShape(path: path, extrusionDepth: CGFloat(0.27 * s))
        shape.chamferRadius = CGFloat(0.03 * s)
        shape.chamferMode = .both
        return shape
    }

    /// Where the brass sits on each piece, as (height, radius, tube) on the
    /// turning's own scale.
    ///
    /// Chosen to land on the collar every piece already has rather than
    /// anywhere new: a band that does not sit in a groove reads as a sticker.
    private static func bands(_ kind: PieceKind, _ s: Float) -> [(y: Float, r: Float, tube: Float)] {
        switch kind {
        case .pawn: [(0.5 * s, 0.152 * s, 0.019 * s), (0.075 * s, 0.318 * s, 0.02 * s)]
        case .rook: [(0.645 * s, 0.218 * s, 0.022 * s), (0.075 * s, 0.318 * s, 0.02 * s)]
        case .bishop: [(0.565 * s, 0.158 * s, 0.02 * s), (0.075 * s, 0.318 * s, 0.02 * s)]
        case .knight: [(0.485 * s, 0.198 * s, 0.021 * s), (0.075 * s, 0.318 * s, 0.02 * s)]
        case .queen: [(0.625 * s, 0.178 * s, 0.022 * s), (0.075 * s, 0.318 * s, 0.02 * s)]
        case .king: [(0.665 * s, 0.183 * s, 0.022 * s), (0.075 * s, 0.318 * s, 0.02 * s)]
        }
    }

    /// The gilt on top: the finial the turning already ends in, in brass rather
    /// than in the body's own material.
    private static func finial(_ kind: PieceKind, _ s: Float) -> Solid? {
        switch kind {
        case .pawn, .knight:
            return nil

        case .bishop:
            return Solid.sphere(radius: 0.062 * s, at: SIMD3(0, 1.26 * s, 0), segments: 32, rings: 20)

        case .rook:
            return Solid.ring(radius: 0.237 * s, tube: 0.032 * s, at: SIMD3(0, 0.86 * s, 0))

        case .queen:
            var crown = Solid.sphere(radius: 0.077 * s, at: SIMD3(0, 1.36 * s, 0), segments: 32, rings: 16)
            for i in 0..<9 {
                let angle = Float(i) / 9 * 2 * .pi
                crown.append(.sphere(
                    radius: 0.05 * s,
                    at: SIMD3(cosf(angle) * 0.215 * s, 1.34 * s, sinf(angle) * 0.215 * s),
                    segments: 20, rings: 12
                ))
            }
            return crown

        case .king:
            var cross = Solid.cylinder(radius: 0.048 * s, height: 0.28 * s, at: SIMD3(0, 1.54 * s, 0))
            cross.append(.cylinder(radius: 0.038 * s, height: 0.19 * s, at: SIMD3(0, 1.58 * s, 0), axis: .x))
            cross.append(.sphere(radius: 0.052 * s, at: SIMD3(0, 1.68 * s, 0), segments: 32, rings: 16))
            return cross
        }
    }

    private static let height: [PieceKind: Float] = [
        .pawn: 0.62, .knight: 0.72, .bishop: 0.74, .rook: 0.66, .queen: 0.82, .king: 0.9,
    ]

    /// One piece, as a node with the geometry already positioned.
    ///
    /// A node rather than a geometry because the knight is two pieces of
    /// geometry that cannot be one: a lathe and an extrusion, meeting at the
    /// neck.
    public static func node(for kind: PieceKind, style: PieceStyle = .plain) -> SCNNode {
        let s = height[kind] ?? 0.7
        let node = SCNNode()

        let turned: Solid = switch kind {
        case .pawn: pawn(s)
        case .rook: rook(s)
        case .bishop: bishop(s)
        case .queen: queen(s)
        case .king: king(s)
        case .knight: knightBase(s)
        }
        let body = SCNNode(geometry: turned.geometry)
        body.name = Self.bodyName
        node.addChildNode(body)

        if kind == .knight {
            let head = SCNNode(geometry: knightHead(s))
            // The silhouette is drawn facing along +x and extruded through z;
            // a quarter turn stands it across the board, facing the opponent.
            head.eulerAngles.y = -.pi / 2
            head.name = Self.bodyName
            node.addChildNode(head)
        }

        if style.isBanded {
            var brass = Solid()
            for band in bands(kind, s) {
                brass.append(.ring(radius: band.r, tube: band.tube, at: SIMD3(0, band.y, 0)))
            }
            if let top = finial(kind, s) { brass.append(top) }
            let trim = SCNNode(geometry: brass.geometry)
            trim.name = Self.trimName
            node.addChildNode(trim)
        }

        return node
    }

    /// The two halves of a piece, so a set can be gilded without repainting it.
    public static let bodyName = "body"
    public static let trimName = "trim"
}
