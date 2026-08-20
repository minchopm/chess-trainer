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
            (0.0, 0.0), (0.305 * s, 0.0), (0.305 * s, 0.035 * s), (0.292 * s, 0.075 * s),
            (0.243 * s, 0.1 * s), (0.207 * s, 0.13 * s), (0.18 * s, 0.19 * s), (0.148 * s, 0.28 * s),
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
            (0.245 * s, 0.9 * s), (0.185 * s, 0.9 * s), (0.185 * s, 0.86 * s), (0.0, 0.86 * s),
        ], segments: segments)

        // Battlements cut rather than stacked.
        //
        // Five towers left standing out of a wall, each one a piece of the same
        // turning swept through part of a circle instead of all of it — so the
        // gaps between them are square-cut and go all the way down to the
        // rampart. Little cylinders stood on the rim, which is the cheap way,
        // read as pegs from every angle.
        let merlons = 5
        let wall: [Turn] = [
            (0.185 * s, 0.9 * s), (0.245 * s, 0.9 * s),
            (0.245 * s, 1.02 * s), (0.185 * s, 1.02 * s),
        ]
        for i in 0..<merlons {
            let centre = Float(i) / Float(merlons) * 2 * .pi
            let width: Float = 2 * .pi / Float(merlons) * 0.56
            solid.append(.revolved(wall, segments: 8, from: centre - width / 2, through: width))
        }

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

        // A Staunton cross is short and stands on the crown. Drawn tall it
        // reads as a mast, and the piece stops being a king.
        solid.append(.cylinder(radius: 0.05 * s, height: 0.2 * s, at: SIMD3(0, 1.5 * s, 0)))
        solid.append(.cylinder(radius: 0.042 * s, height: 0.17 * s, at: SIMD3(0, 1.52 * s, 0), axis: .x))
        return solid
    }

    /// The base a knight's head sits on. The head itself is not a lathe.
    ///
    /// Its top is wider than the other pieces' because it has to carry a neck
    /// rather than a stem: the head is at its broadest where it lands, and on a
    /// narrower collar the neck hangs over the edge and shows its flat
    /// underside from every angle but straight on.
    private static func knightBase(_ s: Float) -> Solid {
        Solid.revolved(foot(s) + [
            (0.175 * s, 0.36 * s), (0.165 * s, 0.44 * s),
        ] + collar(s, 0.44, 0.165) + [
            (0.203 * s, 0.545 * s), (0.0, 0.545 * s),
        ], segments: segments)
    }

    /// Where the brass sits on each piece, as (height, radius, tube) on the
    /// turning's own scale.
    ///
    /// Read off the photographed set the flat board uses: a wide band round the
    /// very foot, a second where the base flares into the stem, and a collar
    /// under whatever the piece carries on top. They land in grooves the
    /// turning already has — a band that does not sit in one reads as a
    /// sticker.
    private static func bands(_ kind: PieceKind, _ s: Float) -> [(y: Float, r: Float, tube: Float)] {
        let foot: [(y: Float, r: Float, tube: Float)] = [
            (0.132 * s, 0.208 * s, 0.019 * s),   // where the base gathers in
        ]

        let collar: [(y: Float, r: Float, tube: Float)] = switch kind {
        case .pawn: [(0.5 * s, 0.152 * s, 0.019 * s), (0.772 * s, 0.158 * s, 0.017 * s)]
        case .rook: [(0.645 * s, 0.218 * s, 0.022 * s), (0.79 * s, 0.238 * s, 0.02 * s)]
        case .bishop: [(0.565 * s, 0.158 * s, 0.02 * s), (0.715 * s, 0.181 * s, 0.019 * s)]
        case .knight: [(0.485 * s, 0.198 * s, 0.021 * s)]
        case .queen: [(0.625 * s, 0.178 * s, 0.022 * s), (1.285 * s, 0.238 * s, 0.021 * s)]
        case .king: [(0.665 * s, 0.183 * s, 0.022 * s), (1.31 * s, 0.243 * s, 0.022 * s),
                     (1.395 * s, 0.222 * s, 0.019 * s)]
        }

        return foot + collar
    }

    /// The gilded step the piece stands on.
    ///
    /// On the photographed set this is not a ring laid against the base — it is
    /// the bottom of the base itself, turned in gold, and it is the widest
    /// piece of brass on the piece. A torus in its place either hides inside
    /// the wood or stands off it like a bracelet.
    private static func gildedFoot(_ s: Float) -> Solid {
        // A hair proud of the wood it sheathes. Turned to exactly the same
        // profile the two surfaces are coincident, and coincident surfaces
        // fight for the same pixels — the gold flickers, or loses.
        let out: Float = 1.03
        return Solid.revolved([
            (0.0, -0.002 * s), (0.305 * s * out, -0.002 * s), (0.305 * s * out, 0.035 * s),
            (0.292 * s * out, 0.078 * s), (0.276 * s, 0.092 * s), (0.276 * s, 0.086 * s),
        ], segments: segments)
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
            var cross = Solid.cylinder(radius: 0.052 * s, height: 0.2 * s, at: SIMD3(0, 1.5 * s, 0))
            cross.append(.cylinder(radius: 0.044 * s, height: 0.17 * s, at: SIMD3(0, 1.52 * s, 0), axis: .x))
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
            var brass = gildedFoot(s)
            for band in bands(kind, s) {
                brass.append(.ring(radius: band.r, tube: band.tube, at: SIMD3(0, band.y, 0)))
            }
            if let top = finial(kind, s) { brass.append(top) }
            let trim = SCNNode(geometry: brass.geometry)
            trim.name = Self.trimName
            node.addChildNode(trim)

            if kind == .knight {
                let crest = SCNNode(geometry: mane(s))
                crest.eulerAngles.y = -.pi / 2
                crest.name = Self.trimName
                node.addChildNode(crest)
            }
        }

        return node
    }

    /// The two halves of a piece, so a set can be gilded without repainting it.
    public static let bodyName = "body"
    public static let trimName = "trim"
}
