import SceneKit
import simd

/// The knight — the one piece a lathe cannot turn, and so the one piece with a
/// front, a back and a shape of its own.
///
/// It was an extruded silhouette for a long time: the outline cut out and given
/// an even depth, the way a set is stamped when it is not carved. From the side
/// that reads; from anywhere else it does not. A real knight narrows as it
/// rises — the neck is thick where it meets the collar and the head is barely
/// half that — and a slab of even depth has none of it. Turn one a few degrees
/// and it goes flat.
///
/// So the outline carries a **depth at every anchor**, not one depth for the
/// piece: full at the base of the neck, at its thinnest through the crest,
/// thinner still at the muzzle and thinnest at the ear. The mesh is built from
/// that here rather than by `SCNShape`, which can only extrude evenly.
extension TurnedPieces {

    typealias KnightAnchor = (x: Float, y: Float, corner: Bool)

    /// The head, as measured anchors: where the outline goes, where it turns a
    /// corner the curve may not round off, and how deep the piece is there.
    ///
    /// Three readings of a knight's head look obvious and are wrong. The
    /// **ears** are not two tall triangles: what stands above the forehead is
    /// mostly the mane, cut off square, with one small ear showing behind it
    /// and the other hidden. The **muzzle** does not taper — its front runs all
    /// but straight down before it turns under, and a taper there makes a fox.
    /// The **neck** is broad, arching back at half height and flaring to the
    /// collar, rather than rising as a stalk.
    ///
    /// `ios/Tools/knight` draws the same outline and renders it from any angle,
    /// which is where all of this was fitted.
    ///
    /// Traced anticlockwise from the base of the neck.
    static let knightAnchors: [KnightAnchor] = [
        // Up the crest of the neck, from the collar. Thick where it meets the
        // turning, thinning as it rises.
        (-0.168, 0.500, true), (-0.192, 0.566, false),
        (-0.189, 0.632, false), (-0.189, 0.665, false),
        (-0.193, 0.698, false), (-0.201, 0.731, false),
        (-0.207, 0.764, false), (-0.214, 0.797, false),
        (-0.220, 0.830, false), (-0.224, 0.863, false),
        (-0.225, 0.896, false), (-0.224, 0.929, false),
        (-0.218, 0.962, false), (-0.214, 0.978, false),
        (-0.205, 1.004, false), (-0.191, 1.030, false),
        (-0.179, 1.047, false), (-0.164, 1.065, false),
        (-0.149, 1.082, false), (-0.129, 1.099, false),
        (-0.106, 1.116, false),
        // Over the poll: one small ear, then the mane cut off square.
        (-0.090, 1.134, false), (-0.077, 1.143, true),
        (-0.068, 1.150, true), (-0.059, 1.145, true),
        (-0.046, 1.143, true), (-0.010, 1.151, true),
        (0.056, 1.160, true),
        // Down the face. The cheek is the fullest part of the head.
        (0.058, 1.151, false), (0.059, 1.134, false),
        (0.059, 1.125, false), (0.061, 1.116, false),
        (0.065, 1.099, false), (0.074, 1.091, false),
        (0.092, 1.074, false), (0.114, 1.056, false),
        (0.135, 1.039, false), (0.156, 1.021, false),
        (0.178, 1.004, false), (0.202, 0.987, false),
        (0.215, 0.978, false), (0.266, 0.943, false),
        // The muzzle: front all but straight down, and the narrowest of the
        // head. At the same height as the neck and half its thickness, which
        // is the whole reason the depth follows the outline and not the height.
        (0.277, 0.926, false), (0.281, 0.909, false),
        (0.281, 0.900, false), (0.276, 0.883, false),
        (0.261, 0.866, false), (0.253, 0.856, true),
        // Back under the jaw to the throat.
        (0.180, 0.852, false), (0.100, 0.850, false),
        (0.042, 0.848, true),
        // And down the throat into the chest, thickening into the collar.
        (0.051, 0.839, false), (0.058, 0.831, false),
        (0.088, 0.797, false), (0.117, 0.764, false),
        (0.143, 0.731, false), (0.166, 0.698, false),
        (0.186, 0.665, false), (0.199, 0.632, false),
        (0.207, 0.599, false), (0.209, 0.566, false),
        (0.195, 0.500, true),
    ]

    /// How deep the piece is at a given height: a straight taper from the
    /// collar to the top of the head.
    ///
    /// Two things force this, and both were found the hard way.
    ///
    /// Depth follows the **height** and not the outline. Carried around the
    /// outline it gives two different answers where the outline passes the same
    /// height twice — once up the muzzle and once down the crest — and the face
    /// between them has no surface to lie on.
    ///
    /// And the taper is **straight**. A face is closed by cutting the outline
    /// into triangles, and a concave outline like this one cuts into long thin
    /// ones that span most of the piece. Over a curved profile each of those
    /// cuts its own chord, and the cheek comes out creased like folded paper —
    /// which is exactly what it looked like. A straight taper makes the face a
    /// plane, and every triangle of a plane lies on it however it is cut up.
    ///
    /// The cost is the reference's profile, which is not straight: its neck
    /// holds one thickness through the middle and thickens again into the
    /// collar. Against a creased cheek, the straight line wins.
    static func depth(atHeight y: Float) -> Float {
        let (base, top) = (Float(0.500), Float(1.160))
        let (thick, thin) = (Float(0.125), Float(0.058))
        let t = min(1, max(0, (y - base) / (top - base)))
        return thick + (thin - thick) * t
    }

    /// A closed curve through every anchor, breaking at the corners, carrying
    /// the depth along with the position.
    ///
    /// Fitted to the anchors rather than steered by handles, because the
    /// anchors are measurements: with beziers, moving one point of the outline
    /// meant moving four numbers.
    static func through(_ anchors: [KnightAnchor], steps: Int = 5) -> [(x: Float, y: Float, depth: Float)] {
        var points: [(x: Float, y: Float, depth: Float)] = []
        for i in anchors.indices {
            let a = anchors[(i - 1 + anchors.count) % anchors.count]
            let b = anchors[i]
            let c = anchors[(i + 1) % anchors.count]
            let d = anchors[(i + 2) % anchors.count]
            points.append((b.x, b.y, depth(atHeight: b.y)))
            if b.corner && c.corner { continue }   // a straight run between corners
            for step in 1..<steps {
                let t = Float(step) / Float(steps)
                func spline(_ p0: Float, _ p1: Float, _ p2: Float, _ p3: Float) -> Float {
                    let t2 = t * t, t3 = t2 * t
                    return 0.5 * (2 * p1 + (p2 - p0) * t
                                  + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                                  + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
                }
                let y = spline(a.y, b.y, c.y, d.y)
                points.append((spline(a.x, b.x, c.x, d.x), y, depth(atHeight: y)))
            }
        }
        return counterclockwise(points)
    }

    /// The outline in a known direction, so a normal turned off it points out
    /// of the piece rather than into it.
    static func counterclockwise(
        _ points: [(x: Float, y: Float, depth: Float)]
    ) -> [(x: Float, y: Float, depth: Float)] {
        var area: Float = 0
        for i in points.indices {
            let a = points[i], b = points[(i + 1) % points.count]
            area += a.x * b.y - b.x * a.y
        }
        return area < 0 ? points.reversed() : points
    }
}

// MARK: - Cutting the shape out of the block

extension TurnedPieces {

    /// Triangulates a closed outline by clipping ears off it.
    ///
    /// Needed because the outline is *concave* — the throat is notched in
    /// behind the jaw, and there is a nick between the ear and the mane. Handed
    /// to anything that assumes convexity, both get filled straight across, and
    /// the head comes out with a web of ivory hanging under its jaw.
    static func earClip(_ points: [(x: Float, y: Float)]) -> [(Int, Int, Int)] {
        guard points.count > 3 else { return points.count == 3 ? [(0, 1, 2)] : [] }

        var area: Float = 0
        for i in points.indices {
            let a = points[i], b = points[(i + 1) % points.count]
            area += a.x * b.y - b.x * a.y
        }
        var remaining = area < 0 ? Array(points.indices).reversed() as [Int] : Array(points.indices)

        func cross(_ a: (x: Float, y: Float), _ b: (x: Float, y: Float), _ c: (x: Float, y: Float)) -> Float {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }

        var triangles: [(Int, Int, Int)] = []
        var stalled = 0
        while remaining.count > 3 && stalled <= remaining.count {
            var clipped = false
            for k in remaining.indices {
                let i0 = remaining[(k - 1 + remaining.count) % remaining.count]
                let i1 = remaining[k]
                let i2 = remaining[(k + 1) % remaining.count]
                let a = points[i0], b = points[i1], c = points[i2]
                guard cross(a, b, c) > 0 else { continue }        // a reflex corner is no ear

                // An ear may not have any other corner of the outline inside it.
                var swallows = false
                for j in remaining where j != i0 && j != i1 && j != i2 {
                    let p = points[j]
                    if cross(a, b, p) >= 0 && cross(b, c, p) >= 0 && cross(c, a, p) >= 0 {
                        swallows = true
                        break
                    }
                }
                guard !swallows else { continue }

                triangles.append((i0, i1, i2))
                remaining.remove(at: k)
                clipped = true
                break
            }
            // A run that finds no ear at all is a degenerate outline. Stop with
            // what it has rather than spinning: a head short a few triangles is
            // a great deal better than a board that never appears.
            stalled = clipped ? 0 : stalled + 1
            if !clipped { break }
        }
        if remaining.count == 3 { triangles.append((remaining[0], remaining[1], remaining[2])) }
        return triangles
    }

    /// Sweeps an outline of varying depth into a solid, rolling the edge over.
    ///
    /// The rim runs from the back face round to the front in `steps`, each ring
    /// set in from the outline by the part of the roll it has turned through —
    /// which is what `SCNShape`'s chamfer did for the flat version, done here
    /// so the depth can vary along the way. The chamfer is held to a share of
    /// the local depth: a fixed one wider than the nick between the ear and the
    /// mane closes it up.
    static func shell(_ outline: [(x: Float, y: Float, depth: Float)],
                      cap: [(Int, Int, Int)], scale s: Float,
                      chamfer: Float, steps: Int = 3) -> Solid {
        let count = outline.count
        var normals: [(Float, Float)] = []
        for i in 0..<count {
            let a = outline[(i - 1 + count) % count], b = outline[(i + 1) % count]
            let tx = b.x - a.x, ty = b.y - a.y
            let length = max(1e-6, (tx * tx + ty * ty).squareRoot())
            normals.append((ty / length, -tx / length))
        }

        var rings: [[SIMD3<Float>]] = []
        for step in 0...steps {
            let angle = -Float.pi / 2 + Float.pi * Float(step) / Float(steps)
            rings.append((0..<count).map { i in
                let radius = min(chamfer, outline[i].depth * 0.62)
                let inset = radius * (1 - cos(angle))
                return SIMD3((outline[i].x - normals[i].0 * inset) * s,
                             (outline[i].y - normals[i].1 * inset) * s,
                             outline[i].depth * sin(angle) * s)
            })
        }

        var solid = Solid()
        for step in 0..<steps {
            for i in 0..<count {
                let j = (i + 1) % count
                solid.quad(rings[step][i], rings[step][j], rings[step + 1][j], rings[step + 1][i])
            }
        }
        for (a, b, c) in cap {
            solid.triangle(rings[steps][a], rings[steps][b], rings[steps][c])
            solid.triangle(rings[0][c], rings[0][b], rings[0][a])
        }
        return solid
    }

    /// The outline and its triangulation, worked out once.
    ///
    /// Neither depends on the scale a piece is drawn at, and clipping ears off
    /// a two-hundred-point outline is not something to do once per knight on a
    /// board that has four of them.
    static let knightOutline = through(knightAnchors)
    static let knightCap = earClip(knightOutline.map { ($0.x, $0.y) })

    static func knightHead(_ s: Float) -> SCNGeometry {
        shell(knightOutline, cap: knightCap, scale: s, chamfer: 0.045, steps: 5).geometry
    }
}

// MARK: - The mane

extension TurnedPieces {

    /// The knight's mane, cut as its own piece and standing proud of the head
    /// so the brass shows from either side.
    ///
    /// The photographed set has a gilded mane and the turned one had no gold on
    /// the head at all, which left the knight the one piece that did not look
    /// like it belonged to the set. It is the crest's own anchors offset
    /// inwards — the same numbers the head is cut from, so it cannot drift off
    /// the edge when the head is reshaped. It stops below the ears: carried
    /// further it breaks out through the back of the skull, because the outline
    /// turns in there and a strip offset sideways does not.
    static let maneOutline: [(x: Float, y: Float, depth: Float)] = {
        let inset: Float = 0.055
        let shift: Float = 0.048          // clear of the head's rolled edge
        let proud: Float = 0.007          // how far it stands off the face
        let run = Array(knightAnchors[4...17])
        var inner: [KnightAnchor] = []
        for i in run.indices {
            let before = run[max(0, i - 1)], after = run[min(run.count - 1, i + 1)]
            let tx = after.x - before.x, ty = after.y - before.y
            let length = max(1e-6, (tx * tx + ty * ty).squareRoot())
            // Inwards: the crest is traced upwards, so that is to its right.
            inner.append((run[i].x + ty / length * (inset + shift),
                          run[i].y - tx / length * (inset + shift), false))
        }
        // Set in off the crest, not laid on it. The head's edge is rolled over
        // most of its depth, so a strip flush with the outline is swallowed by
        // that roll — and one laid just inside it stands past the roll and
        // reads as a fin hanging off the side. It has to land on the flat.
        var outer: [KnightAnchor] = []
        for i in run.indices {
            let before = run[max(0, i - 1)], after = run[min(run.count - 1, i + 1)]
            let tx = after.x - before.x, ty = after.y - before.y
            let length = max(1e-6, (tx * tx + ty * ty).squareRoot())
            outer.append((run[i].x + ty / length * shift, run[i].y - tx / length * shift,
                          run[i].corner))
        }
        let strip = outer + inner.reversed()
        return counterclockwise(strip.map { ($0.x, $0.y, depth(atHeight: $0.y) + proud) })
    }()

    static let maneCap = earClip(maneOutline.map { ($0.x, $0.y) })

    static func mane(_ s: Float) -> SCNGeometry {
        shell(maneOutline, cap: maneCap, scale: s, chamfer: 0.01).geometry
    }
}
