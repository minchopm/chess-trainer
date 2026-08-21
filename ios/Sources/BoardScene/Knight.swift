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

    typealias KnightAnchor = (x: Float, y: Float, corner: Bool, depth: Float)

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
        (-0.168, 0.500, true, 0.128), (-0.192, 0.566, false, 0.104),
        (-0.189, 0.632, false, 0.088), (-0.189, 0.665, false, 0.082),
        (-0.193, 0.698, false, 0.078), (-0.201, 0.731, false, 0.076),
        (-0.207, 0.764, false, 0.074), (-0.214, 0.797, false, 0.073),
        (-0.220, 0.830, false, 0.073), (-0.224, 0.863, false, 0.073),
        (-0.225, 0.896, false, 0.073), (-0.224, 0.929, false, 0.074),
        (-0.218, 0.962, false, 0.076), (-0.214, 0.978, false, 0.077),
        (-0.205, 1.004, false, 0.079), (-0.191, 1.030, false, 0.081),
        (-0.179, 1.047, false, 0.082), (-0.164, 1.065, false, 0.083),
        (-0.149, 1.082, false, 0.083), (-0.129, 1.099, false, 0.082),
        (-0.106, 1.116, false, 0.080),
        // Over the poll: one small ear, then the mane cut off square.
        (-0.090, 1.134, false, 0.072), (-0.077, 1.143, true, 0.048),
        (-0.068, 1.150, true, 0.042), (-0.059, 1.145, true, 0.048),
        (-0.046, 1.143, true, 0.060), (-0.010, 1.151, true, 0.058),
        (0.056, 1.160, true, 0.056),
        // Down the face. The cheek is the fullest part of the head.
        (0.058, 1.151, false, 0.066), (0.059, 1.134, false, 0.072),
        (0.059, 1.125, false, 0.075), (0.061, 1.116, false, 0.078),
        (0.065, 1.099, false, 0.082), (0.074, 1.091, false, 0.084),
        (0.092, 1.074, false, 0.086), (0.114, 1.056, false, 0.086),
        (0.135, 1.039, false, 0.084), (0.156, 1.021, false, 0.081),
        (0.178, 1.004, false, 0.077), (0.202, 0.987, false, 0.072),
        (0.215, 0.978, false, 0.070), (0.266, 0.943, false, 0.062),
        // The muzzle: front all but straight down, and the narrowest of the
        // head. At the same height as the neck and half its thickness, which
        // is the whole reason the depth follows the outline and not the height.
        (0.277, 0.926, false, 0.058), (0.281, 0.909, false, 0.056),
        (0.281, 0.900, false, 0.055), (0.276, 0.883, false, 0.056),
        (0.261, 0.866, false, 0.058), (0.253, 0.856, true, 0.060),
        // Back under the jaw to the throat.
        (0.180, 0.852, false, 0.068), (0.100, 0.850, false, 0.076),
        (0.042, 0.848, true, 0.078),
        // And down the throat into the chest, thickening into the collar.
        (0.051, 0.839, false, 0.078), (0.058, 0.831, false, 0.078),
        (0.088, 0.797, false, 0.078), (0.117, 0.764, false, 0.078),
        (0.143, 0.731, false, 0.079), (0.166, 0.698, false, 0.080),
        (0.186, 0.665, false, 0.084), (0.199, 0.632, false, 0.090),
        (0.207, 0.599, false, 0.100), (0.199, 0.566, false, 0.110),
        (0.182, 0.500, true, 0.128),
    ]

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
            points.append((b.x, b.y, b.depth))
            if b.corner && c.corner { continue }   // a straight run between corners
            for step in 1..<steps {
                let t = Float(step) / Float(steps)
                func spline(_ p0: Float, _ p1: Float, _ p2: Float, _ p3: Float) -> Float {
                    let t2 = t * t, t3 = t2 * t
                    return 0.5 * (2 * p1 + (p2 - p0) * t
                                  + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                                  + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
                }
                points.append((spline(a.x, b.x, c.x, d.x), spline(a.y, b.y, c.y, d.y),
                               max(0.02, spline(a.depth, b.depth, c.depth, d.depth))))
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

    /// A ring of the piece: where it runs in plan, and how deep it is there.
    typealias Ring = [(x: Float, y: Float, depth: Float)]

    /// Draws the outline in a little, the way a face closes over.
    ///
    /// Offsetting every point along its own normal is the obvious way and it
    /// tears: at a notch the two sides march through each other. Smoothing the
    /// ring after each step — each point pulled towards the average of its
    /// neighbours — lets the notches close over instead of crossing, which is
    /// what a face does as it domes.
    ///
    /// The depth is smoothed along with the position. The muzzle is cut thinner
    /// than the neck behind it, and without this those two depths would meet
    /// head-on where the rings converge and leave a crease down the middle of
    /// the cheek.
    private static func drawIn(_ ring: Ring, by step: Float) -> Ring {
        let count = ring.count
        var moved: Ring = []
        for i in 0..<count {
            let before = ring[(i - 1 + count) % count], after = ring[(i + 1) % count]
            let tx = after.x - before.x, ty = after.y - before.y
            let length = max(1e-6, (tx * tx + ty * ty).squareRoot())
            moved.append((ring[i].x + ty / length * -step, ring[i].y - tx / length * -step,
                          ring[i].depth))
        }
        var smoothed = moved
        for _ in 0..<2 {
            var pass = smoothed
            for i in 0..<count {
                let before = smoothed[(i - 1 + count) % count], after = smoothed[(i + 1) % count]
                pass[i] = (smoothed[i].x * 0.5 + (before.x + after.x) * 0.25,
                           smoothed[i].y * 0.5 + (before.y + after.y) * 0.25,
                           smoothed[i].depth * 0.5 + (before.depth + after.depth) * 0.25)
            }
            smoothed = pass
        }
        return smoothed
    }

    /// The area a ring encloses, **signed**.
    ///
    /// The sign is the point of it. A ring drawn in past the middle of a narrow
    /// part folds through itself, and a folded ring keeps most of its area if
    /// the sign is thrown away — so a guard written on the size alone lets the
    /// face carry on being drawn in long after it has turned inside out, which
    /// it then shows as a tangle poking through the cheek.
    private static func area(_ ring: Ring) -> Float {
        var total: Float = 0
        for i in ring.indices {
            let a = ring[i], b = ring[(i + 1) % ring.count]
            total += a.x * b.y - b.x * a.y
        }
        return total / 2
    }

    /// Sweeps an outline of varying depth into a solid.
    ///
    /// The piece is one surface, ring by ring: in from the middle of the back
    /// face, out to the edge, round the roll, and in again across the front.
    /// Every ring holds the same number of points, so the whole thing is a grid
    /// — quads between neighbours, and a normal at every corner taken from the
    /// surface either side of it.
    ///
    /// Closing each face in one go was the version before this, and both of its
    /// faults came from the same place. A concave outline cuts into long thin
    /// triangles spanning most of the piece, so the face could only be a plane
    /// — anything curved and each triangle cut its own chord across it, leaving
    /// the cheek creased like folded paper. And a plane is what it looked like:
    /// flat panels meeting at drawn lines, where the piece wants to be rounded.
    static func shell(_ outline: Ring, scale s: Float,
                      roll: Float, bulge: Float, rimSteps: Int = 6) -> Solid {
        let count = outline.count
        var normals: [(Float, Float)] = []
        for i in 0..<count {
            let a = outline[(i - 1 + count) % count], b = outline[(i + 1) % count]
            let tx = b.x - a.x, ty = b.y - a.y
            let length = max(1e-6, (tx * tx + ty * ty).squareRoot())
            normals.append((ty / length, -tx / length))
        }

        // The face, drawn in until there is nothing left of it to draw.
        let full = area(outline)
        var faces: [Ring] = [(0..<count).map { i in
            let reach = min(roll, outline[i].depth * 0.7)
            return (outline[i].x - normals[i].0 * reach,
                    outline[i].y - normals[i].1 * reach, outline[i].depth)
        }]
        while faces.count < 14 {
            let next = drawIn(faces[faces.count - 1], by: 0.015)
            guard area(next) > full * 0.12 else { break }
            faces.append(next)
        }

        // The face is closed with the **outline's** triangulation, not the
        // innermost ring's.
        //
        // Drawing a ring in folds the thin parts long before the wide ones —
        // the nick between the ear and the mane is thirteen thousandths wide,
        // so any worthwhile step closes it — and a ring that crosses itself
        // cannot be triangulated at all: ear clipping stalls on it and hands
        // back part of a face, which is a hole. The piece came out a hollow
        // pipe bent along the outline and lit from the inside.
        //
        // Every ring holds the same points in the same order, so the cut made
        // on the outline — which is simple, and cuts cleanly — fits all of
        // them. Where a ring has folded, that costs a few triangles overlapping
        // inside the piece, which is nothing; a hole in the cheek is not.
        let cap = earClip(outline.map { ($0.x, $0.y) })

        func lift(_ k: Int) -> Float {
            guard faces.count > 1 else { return 1 }
            let t = Float(k) / Float(faces.count - 1)
            return 1 + bulge * sin(t * .pi / 2)
        }

        var rings: [[SIMD3<Float>]] = []
        func place(_ ring: Ring, _ sign: Float, _ k: Int) -> [SIMD3<Float>] {
            ring.map { SIMD3($0.x * s, $0.y * s, sign * $0.depth * lift(k) * s) }
        }
        for k in stride(from: faces.count - 1, through: 1, by: -1) {
            rings.append(place(faces[k], -1, k))
        }
        for step in 0...rimSteps {
            let angle = -Float.pi / 2 + Float.pi * Float(step) / Float(rimSteps)
            rings.append((0..<count).map { i in
                let reach = min(roll, outline[i].depth * 0.7)
                let inset = reach * (1 - cos(angle))
                return SIMD3((outline[i].x - normals[i].0 * inset) * s,
                             (outline[i].y - normals[i].1 * inset) * s,
                             outline[i].depth * sin(angle) * s)
            })
        }
        for k in 1..<faces.count {
            rings.append(place(faces[k], 1, k))
        }

        return skin(rings, closingWith: cap)
    }

    /// Stitches a stack of rings into a surface, with a normal at every corner
    /// taken from its neighbours rather than from the triangle it sits in.
    static func skin(_ rings: [[SIMD3<Float>]], closingWith cap: [(Int, Int, Int)]) -> Solid {
        guard let count = rings.first?.count, rings.count > 1 else { return Solid() }

        var normals: [[SIMD3<Float>]] = []
        for k in rings.indices {
            normals.append((0..<count).map { i in
                // Along the ring first, then across to the next one: the other
                // way round gives the same plane with the sign flipped, and a
                // surface lit from inside itself looks hollow rather than wrong.
                let along = rings[k][(i + 1) % count] - rings[k][(i - 1 + count) % count]
                let across = rings[min(k + 1, rings.count - 1)][i] - rings[max(k - 1, 0)][i]
                let normal = simd_cross(along, across)
                let length = simd_length(normal)
                // Where a ring has drawn itself down to nothing its neighbours
                // sit on top of each other and there is no plane to take.
                return length > 1e-9 ? normal / length : SIMD3(0, 0, 1)
            })
        }

        var solid = Solid()
        for k in 0..<(rings.count - 1) {
            for i in 0..<count {
                let j = (i + 1) % count
                solid.triangle(rings[k][i], rings[k][j], rings[k + 1][j],
                               normals: normals[k][i], normals[k][j], normals[k + 1][j])
                solid.triangle(rings[k][i], rings[k + 1][j], rings[k + 1][i],
                               normals: normals[k][i], normals[k + 1][j], normals[k + 1][i])
            }
        }
        // The two ends, where the face has drawn in as far as it goes. Whatever
        // is left there is small and all but flat, so it can be closed in one
        // piece without showing.
        let first = 0, last = rings.count - 1
        for (a, b, c) in cap {
            solid.triangle(rings[last][a], rings[last][b], rings[last][c],
                           normals: normals[last][a], normals[last][b], normals[last][c])
            solid.triangle(rings[first][c], rings[first][b], rings[first][a],
                           normals: normals[first][c], normals[first][b], normals[first][a])
        }
        return solid
    }

    /// The outline and its triangulation, worked out once.
    ///
    /// Neither depends on the scale a piece is drawn at, and clipping ears off
    /// a two-hundred-point outline is not something to do once per knight on a
    /// board that has four of them.
    static let knightOutline = through(knightAnchors)

    static func knightHead(_ s: Float) -> SCNGeometry {
        shell(knightOutline, scale: s, roll: 0.04, bulge: 0.16).geometry
    }
}

// MARK: - The mane

extension TurnedPieces {

    /// The knight's mane: a gilded ridge run down the back of the neck.
    ///
    /// The photographed set has a gilded mane and the turned one had no gold on
    /// the head at all, which left the knight the one piece that did not look
    /// like it belonged to the set.
    ///
    /// It rides the **back edge**, not the sides. It was a flat strip laid on
    /// the face before this, and since a piece has two faces the set came out
    /// with two gold stripes down it, one on each cheek — a mane in two places,
    /// which is nowhere. The crest of a neck is one ridge along the back, so
    /// this is a section swept down that edge: proud of it at the crown, dying
    /// into the ivory either side.
    ///
    /// It stops below the ears — carried further it breaks out through the back
    /// of the skull, because the outline turns in there and a ridge run
    /// straight on does not.
    static func mane(_ s: Float) -> SCNGeometry {
        let run = crest(steps: 7, from: 3, to: 19)
        guard run.count > 2 else { return Solid().geometry }
        let segments = 14
        let stand: Float = 0.036          // how far the ridge sits proud of the edge
        let sink: Float = 0.007           // and how far its root is buried

        var rings: [[SIMD3<Float>]] = []
        for i in run.indices {
            // Died away at both ends. A ridge of even height stops dead where
            // the run does, and a mane that ends in mid-air reads as a blade
            // stuck on the back rather than as part of the piece.
            let along = Float(i) / Float(run.count - 1)
            let fade = min(1, min(along, 1 - along) / 0.18)
            let rise = stand * (fade * fade * (3 - 2 * fade))
            let before = run[max(0, i - 1)], after = run[min(run.count - 1, i + 1)]
            let tx = after.x - before.x, ty = after.y - before.y
            let length = max(1e-6, (tx * tx + ty * ty).squareRoot())
            let outward = (ty / length, -tx / length)
            let across = run[i].depth * 0.72
            rings.append((0..<segments).map { step in
                let angle = 2 * Float.pi * Float(step) / Float(segments)
                let out = rise * cos(angle) - sink
                return SIMD3((run[i].x + outward.0 * out) * s,
                             (run[i].y + outward.1 * out) * s,
                             across * sin(angle) * s)
            })
        }

        // A swept section is open at both ends; close them with a fan.
        let fan = (1..<(segments - 1)).map { (0, $0, $0 + 1) }
        return skin(rings, closingWith: fan).geometry
    }

    /// The crest of the neck, sampled: the run of the outline the mane rides.
    ///
    /// Taken from the head's own anchors, so it cannot drift off the edge when
    /// the head is reshaped — which it did, twice, when it was a shape of its
    /// own.
    private static func crest(steps: Int, from first: Int, to last: Int) -> Ring {
        let run = Array(knightAnchors[first...last])
        var points: Ring = []
        for i in run.indices {
            let a = run[max(0, i - 1)], b = run[i]
            let c = run[min(run.count - 1, i + 1)], d = run[min(run.count - 1, i + 2)]
            points.append((b.x, b.y, b.depth))
            if i == run.count - 1 { break }
            for step in 1..<steps {
                let t = Float(step) / Float(steps)
                func spline(_ p0: Float, _ p1: Float, _ p2: Float, _ p3: Float) -> Float {
                    let t2 = t * t, t3 = t2 * t
                    return 0.5 * (2 * p1 + (p2 - p0) * t
                                  + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                                  + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
                }
                points.append((spline(a.x, b.x, c.x, d.x), spline(a.y, b.y, c.y, d.y),
                               spline(a.depth, b.depth, c.depth, d.depth)))
            }
        }
        return points
    }
}
