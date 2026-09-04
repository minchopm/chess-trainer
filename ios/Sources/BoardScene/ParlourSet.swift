import ChessCore
import SceneKit

/// A third set: the club Staunton photographed on a lamp table, in boxwood and
/// walnut, with no gilt on it anywhere.
///
/// The two sets that were here are the site's set — one silhouette, one
/// turning, offered plain or dressed in brass. This is a different turning, and
/// the reason is proportion rather than decoration. The site's set is drawn
/// small: its king stands 1.44 squares and its widest base is 0.55 of a square
/// across, so a full back rank has daylight between every piece. A real
/// tournament set is a 95mm king with a 40mm base on 57mm squares — 1.67 and
/// 0.70 — and the reference is wider still. That is most of what makes a
/// photographed board look like furniture and a rendered one look like a
/// diagram: the pieces sit *in* their squares rather than on them.
///
/// So the heights here are a real set's, and the bases are the reference's:
///
/// | | king | queen | bishop | knight | rook | pawn |
/// |---|---|---|---|---|---|---|
/// | site's set | 1.44 | 1.15 | 0.98 | 0.83 | 0.67 | 0.61 |
/// | this set   | 1.82 | 1.58 | 1.40 | 1.24 | 1.08 | 0.94 |
/// | real Staunton, to scale | 1.82 | 1.57 | 1.38 | 1.24 | 1.00 | 0.86 |
///
/// The rook and the pawn are the two that are deliberately off a real set's
/// ratio, and both upward. A 1.00 rook beside a 1.24 knight is correct and
/// reads as a stump from a low camera, where the piece is mostly base; the
/// reference's own rook is taller than a tournament rook for the same reason a
/// shop's display set is.
///
/// One thing here is not new, on purpose: the knight's head. It is the same
/// mesh, the same measured outline and the same relief, scaled — see
/// `Knight.swift` for what it cost to get right. A second horse would be a
/// second set of that work and a set that no longer looked like one set.
enum ParlourSet {
    static let segments = 48

    /// Total height, in squares, finial included.
    static let height: [PieceKind: Float] = [
        .pawn: 0.94, .rook: 1.08, .knight: 1.24, .bishop: 1.40, .queen: 1.58, .king: 1.82,
    ]

    /// Base radius, in squares. The king's foot is 0.79 of a square across,
    /// which is what leaves a back rank looking crowded rather than sparse —
    /// and is as wide as it can go before two neighbours touch and the shadow
    /// between them closes up.
    private static let foot: [PieceKind: Float] = [
        .pawn: 0.310, .rook: 0.352, .knight: 0.352, .bishop: 0.348, .queen: 0.376, .king: 0.396,
    ]

    /// Stem radius, where the turning is narrowest above the base.
    private static let stem: [PieceKind: Float] = [
        .pawn: 0.104, .rook: 0.150, .knight: 0.150, .bishop: 0.128, .queen: 0.146, .king: 0.152,
    ]

    /// The knight's head is drawn on its own scale, in which it stands 1.198
    /// tall and lands its neck at y 0.598. Everything the base has to meet is
    /// therefore a multiple of this.
    private static var knightScale: Float { (height[.knight] ?? 1.24) / 1.198 }

    // MARK: - the base

    /// The foot, which every piece in the set shares the shape of.
    ///
    /// Read off the reference in three parts, and it is the middle one that
    /// does the work. A vertical rim at the bottom, about a quarter of the
    /// base's height — that is the part a low camera sees, and a base that
    /// starts curving from the cloth immediately has no edge to catch the light
    /// on. Then a short convex roll over the top of it. Then a long concave
    /// cove sweeping in and up, which is the line that says "turned" — a
    /// straight taper in its place reads as a plastic tournament set, and the
    /// site's own base has a straighter one.
    ///
    /// It finishes on a bead: the small ring the stem stands out of. Without it
    /// the cove runs into the stem tangentially and the join is a smudge
    /// wherever the light is soft, which on this board is everywhere.
    ///
    /// Heights go with the base's own width rather than with the piece's
    /// height. A turner uses one pattern and grades the diameters; scaling the
    /// base with the piece instead gives the king a foot half again as tall as
    /// the pawn's, and the set stops looking related.
    private static func base(_ radius: Float, stem: Float) -> [Turn] {
        let top = radius * 0.62
        return [
            (0.0, 0.0), (radius, 0.0),
            (radius, top * 0.30), (radius * 0.986, top * 0.42),
            (radius * 0.930, top * 0.52), (radius * 0.822, top * 0.62),
            (radius * 0.688, top * 0.71), (radius * 0.560, top * 0.80),
            (radius * 0.470, top * 0.88), (max(stem * 1.16, radius * 0.425), top),
            // The bead.
            (stem * 1.34, top + radius * 0.085), (stem * 1.30, top + radius * 0.145),
            (stem * 1.08, top + radius * 0.185), (stem, top + radius * 0.20),
        ]
    }

    /// A collar: the flared ring that carries whatever the piece holds up.
    ///
    /// Under the pawn's ball, under the rook's tower, under the bishop's mitre
    /// and under the crowns. It is the one ornament this set has, and the
    /// reference wears it on every piece, which is what makes six different
    /// shapes read as one set.
    private static func collar(_ y: Float, _ radius: Float, flare: Float = 1.30) -> [Turn] {
        [
            (radius * 1.03, y),
            (radius * flare, y + radius * 0.20),
            (radius * flare * 0.96, y + radius * 0.38),
            (radius * 1.02, y + radius * 0.56),
        ]
    }

    // MARK: - the six

    private static func pawn() -> Solid {
        let stem = stem[.pawn]!
        var solid = Solid.revolved(base(foot[.pawn]!, stem: stem) + [
            (0.104, 0.330), (0.098, 0.412),
        ] + collar(0.424, 0.104, flare: 1.52) + [
            // A plain stalk, and the widest collar in the set under it. The
            // pawn was drawn with a swelling body first, on the reasoning that
            // the reference's is a vase rather than a stick — and at this size
            // the swell and the ball above it merge into one lump, so the piece
            // came out a mushroom. What tells a pawn is the gap between the
            // collar and the ball, and a swell fills it in.
            (0.098, 0.540), (0.098, 0.640), (0.096, 0.686), (0.0, 0.700),
        ], segments: segments)
        // The ball emerges from the stalk a little above its foot rather than
        // sitting on top of it, which is what a turner gets and what stops the
        // join reading as a bead.
        solid.append(.sphere(radius: 0.162, at: SIMD3(0, 0.778, 0), segments: segments, rings: 26))
        return solid
    }

    private static func rook() -> Solid {
        let stem = stem[.rook]!
        var solid = Solid.revolved(base(foot[.rook]!, stem: stem) + [
            (0.150, 0.360), (0.154, 0.480), (0.160, 0.556),
        ] + collar(0.568, 0.160, flare: 1.26) + [
            // The tower rises very nearly straight, opening by a fifth over its
            // whole run. It was drawn flaring from 0.150 to 0.268 first, which
            // is a wine glass: a rook is a tower with a rampart oversailing it,
            // and the overhang has to come from the rampart rather than from
            // the tower opening out to meet it.
            (0.176, 0.680), (0.186, 0.750), (0.194, 0.800), (0.196, 0.822),
            // The rampart: a thin course oversailing the wall, and no more.
            //
            // Drawn as a deep drum with small teeth on it — which is what it
            // was — the battlements read as a chip out of the rim rather than
            // as towers, because from a player's eye level the drum and the
            // merlons above it are one continuous face.
            (0.240, 0.842), (0.240, 0.870),
            // In across the walkway and down inside it, so the tower is hollow.
            //
            // The floor is dead level, and that is not a detail. Sloped by even
            // a hundredth it is a cone of forty-eight facets meeting at a
            // point, each catching the light differently — which renders as a
            // bright star sitting inside the rook, and took a shot from
            // overhead to see at all.
            (0.186, 0.870), (0.186, 0.842), (0.0, 0.842),
        ], segments: segments)

        // Battlements, as six blocks of wall left standing out of the rim.
        //
        // Not a partial `revolved`, which is how the site's rook cuts its five
        // and is wrong in a way that only shows from directly overhead — where
        // this app's camera is allowed to go. A partial sweep is an open shell,
        // so `revolved` closes it with two radial faces, and it closes them
        // **to the axis**: every merlon drags a pair of blades right through the
        // middle of the tower. From above the rook is a pinwheel of white fins,
        // and the hollow it is supposed to have is full of them.
        //
        // Six, not the site's five. Five leaves two and a half facing the
        // camera and the half is a merlon seen edge-on, which reads as a chip
        // off the rim; six puts three across the front from wherever a player
        // sits.
        let merlons = 6
        for i in 0..<merlons {
            let centre = Float(i) / Float(merlons) * 2 * .pi
            // Half wall, half gap. Wider merlons close the gaps into slots and
            // the rim reads as notched rather than as crenellated.
            let width: Float = 2 * .pi / Float(merlons) * 0.52
            // A couple of thousandths proud of the rim on both faces, and its
            // underside buried in it. Flush, the two surfaces are coincident
            // over the height they share, and coincident surfaces fight for the
            // same pixels — which shows as the battlements flickering as the
            // board turns.
            solid.append(.sector(inner: 0.184, outer: 0.242,
                                 bottom: 0.860, top: 1.080,
                                 from: centre - width / 2, through: width))
        }
        return solid
    }

    private static func bishop() -> Solid {
        let stem = stem[.bishop]!
        var solid = Solid.revolved(base(foot[.bishop]!, stem: stem) + [
            (0.128, 0.345), (0.120, 0.440),
        ] + collar(0.452, 0.124, flare: 1.36) + [
            (0.124, 0.556),
            // The mitre. Its widest point is a third of the way up, not
            // halfway, and it is narrower than it wants to be — 0.186 against
            // the queen's 0.256. Drawn to the queen's width with its widest
            // point in the middle it is an egg, which is what it was.
            (0.146, 0.616), (0.172, 0.694), (0.186, 0.772), (0.190, 0.836),
            // The one feature that says mitre rather than ogive: the line where
            // the two halves of a real bishop's hat meet. A *groove* — three
            // points cutting a V into the surface and coming back out. It was
            // a step first, the upper half set back from the lower, and a step
            // at this scale is a shelf: the piece read as a barrel with a cone
            // stood on it.
            (0.180, 0.874), (0.174, 0.888), (0.182, 0.902),
            // And a long, nearly straight run to the point.
            (0.174, 0.952), (0.152, 1.024), (0.126, 1.098), (0.096, 1.170),
            (0.066, 1.232), (0.040, 1.282), (0.020, 1.308), (0.0, 1.318),
        ], segments: segments)
        solid.append(.sphere(radius: 0.055, at: SIMD3(0, 1.345, 0), segments: segments, rings: 20))
        return solid
    }

    private static func queen() -> Solid {
        let stem = stem[.queen]!
        var solid = Solid.revolved(base(foot[.queen]!, stem: stem) + [
            (0.148, 0.380), (0.140, 0.512),
        ] + collar(0.524, 0.144, flare: 1.32) + [
            (0.148, 0.650),
            // The bowl, opening all the way to the crown. Fullest low down: the
            // curvature is spent in the first half so the run into the crown is
            // almost straight, which is what keeps it from reading as a cone.
            (0.184, 0.740), (0.216, 0.848), (0.238, 0.958), (0.250, 1.068),
            (0.256, 1.166),
            // A groove under the crown's rim, and then out to it. The reference
            // has this on both the queen and the king and it is what stops the
            // crown looking like the top of the bowl.
            (0.226, 1.222), (0.254, 1.268), (0.258, 1.318), (0.258, 1.356),
            // In across the rim, down inside it, and across the floor the
            // finial stands on — dead level, or the floor is a shallow cone of
            // forty-eight facets and renders as a star inside the crown.
            (0.204, 1.356), (0.204, 1.326), (0.060, 1.326),
            (0.052, 1.410), (0.0, 1.422),
        ], segments: segments)

        // The coronet. Points, not beads: the reference's are small pyramids
        // filed off the rim, and a ring of balls in their place is a jester's
        // hat — which is what the site's set is wearing, and gets away with
        // because at that scale the crown is six pixels across.
        let points = 9
        let spike: [Turn] = [
            (0.0, 0.0), (0.044, 0.0), (0.040, 0.024), (0.026, 0.060), (0.0, 0.082),
        ]
        for i in 0..<points {
            let angle = Float(i) / Float(points) * 2 * .pi
            solid.append(Solid.revolved(spike, segments: 14)
                .moved(by: SIMD3(cosf(angle) * 0.226, 1.350, sinf(angle) * 0.226)))
        }
        solid.append(.sphere(radius: 0.086, at: SIMD3(0, 1.494, 0), segments: 36, rings: 20))
        return solid
    }

    private static func king() -> Solid {
        let stem = stem[.king]!
        var solid = Solid.revolved(base(foot[.king]!, stem: stem) + [
            (0.154, 0.400), (0.146, 0.545),
        ] + collar(0.558, 0.150, flare: 1.30) + [
            (0.154, 0.700),
            (0.186, 0.800), (0.220, 0.916), (0.244, 1.040), (0.258, 1.162),
            (0.264, 1.262),
            // The crown, no wider than the bowl under it. Drawn wider it
            // oversails the body all the way round and reads as the brim of a
            // hat, which is a rook's business and not a king's.
            (0.232, 1.318), (0.256, 1.362), (0.258, 1.408), (0.258, 1.444),
            (0.204, 1.444), (0.204, 1.412), (0.070, 1.412),
            (0.060, 1.468), (0.0, 1.480),
        ], segments: segments)

        // A Staunton cross is short and stands on the crown. Drawn tall it
        // reads as a mast and the piece stops being a king — which is the one
        // note from the site's set worth keeping verbatim.
        solid.append(.cylinder(radius: 0.052, height: 0.360, at: SIMD3(0, 1.640, 0),
                               segments: 20))
        solid.append(.cylinder(radius: 0.044, height: 0.196, at: SIMD3(0, 1.694, 0),
                               segments: 20, axis: .x))
        return solid
    }

    /// The knight's base, which is not the others'.
    ///
    /// Everything above the collar is dictated by the head rather than chosen:
    /// the shoulder has to be straight-sided where the neck lands and wide
    /// enough to swallow the corners of the neck's *section*, which stands
    /// further out than its silhouette does. Those numbers are the site's,
    /// because the head is the site's, and they are written here on the head's
    /// own scale so the two stay registered when the scale changes.
    private static func knightBase() -> Solid {
        let s = knightScale
        let stem = stem[.knight]!
        return Solid.revolved(base(foot[.knight]!, stem: stem) + [
            (0.158, 0.360), (0.166, 0.442),
        ] + collar(0.452, 0.164, flare: 1.26) + [
            // Straight-sided where the neck comes down into it. A neck landing
            // on a cone meets it at a shallow angle and the two surfaces
            // interpenetrate along it, which shows as a ring of torn triangles;
            // across a cylinder they cross in one clean circle.
            (0.200, 0.556), (0.200, 0.578),
            // The shoulder, on the head's scale.
            (0.244 * s, 0.586 * s), (0.248 * s, 0.602 * s),
            (0.238 * s, 0.622 * s), (0.208 * s, 0.646 * s),
            (0.152 * s, 0.668 * s), (0.086 * s, 0.680 * s), (0.0, 0.684 * s),
        ], segments: segments)
    }

    /// One piece, as a node with its geometry already positioned.
    static func node(for kind: PieceKind) -> SCNNode {
        let node = SCNNode()

        let turned: Solid = switch kind {
        case .pawn: pawn()
        case .rook: rook()
        case .bishop: bishop()
        case .queen: queen()
        case .king: king()
        case .knight: knightBase()
        }
        let body = SCNNode(geometry: turned.geometry)
        body.name = TurnedPieces.bodyName
        node.addChildNode(body)

        if kind == .knight {
            let headNode = SCNNode(geometry: TurnedPieces.knightHead(knightScale))
            // The silhouette is drawn facing along +x and extruded through z; a
            // quarter turn stands it across the board, facing the opponent.
            headNode.eulerAngles.y = -.pi / 2
            headNode.name = TurnedPieces.bodyName
            node.addChildNode(headNode)

            // The mane, in wood rather than in brass. On the banded set it is
            // the gilt ridge that stops the knight being the one piece with no
            // gold on it; here it is simply carving, and the reference's knight
            // has it cut into the crest the same way.
            let crest = SCNNode(geometry: TurnedPieces.mane(knightScale))
            crest.eulerAngles.y = -.pi / 2
            crest.name = TurnedPieces.bodyName
            node.addChildNode(crest)
        }

        return node
    }
}

extension Solid {
    /// The same triangles, somewhere else.
    ///
    /// `revolved` turns about the y axis through the origin, which is the only
    /// axis a lathe has — so anything turned and then stood off-centre, like
    /// one point of a coronet, has to be moved after the fact. The normals are
    /// recomputed from the moved triangles, which for a facet is the same
    /// normal.
    func moved(by offset: SIMD3<Float>) -> Solid {
        var out = Solid()
        func corner(_ i: Int) -> SIMD3<Float> {
            SIMD3(Float(positions[i].x), Float(positions[i].y), Float(positions[i].z)) + offset
        }
        for triangle in stride(from: 0, to: positions.count, by: 3) {
            out.triangle(corner(triangle), corner(triangle + 1), corner(triangle + 2))
        }
        return out
    }
}
