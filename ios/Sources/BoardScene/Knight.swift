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
        // The neck is cut off at 0.580, not lower. Below that the turning
        // draws in to its collar, and a neck this broad meets it corner-first:
        // the corners came through the side of the base as a ring of torn
        // white triangles. What is cut away is buried in the base anyway.
        (-0.182, 0.598, true, 0.086), (-0.189, 0.608, false, 0.094),
        (-0.189, 0.614, false, 0.094),
        (-0.189, 0.668, false, 0.082), (-0.196, 0.712, false, 0.078),
        (-0.207, 0.764, false, 0.075), (-0.218, 0.818, false, 0.073),
        (-0.225, 0.874, false, 0.073),   // the crest at its fullest
        (-0.224, 0.910, false, 0.074), (-0.222, 0.946, false, 0.076),
        (-0.207, 1.001, false, 0.079), (-0.194, 1.027, false, 0.081),
        (-0.163, 1.068, false, 0.083), (-0.136, 1.094, false, 0.082),
        (-0.111, 1.111, false, 0.080),
        // Over the poll, where the mane is cut off square. The ears are not
        // drawn here: in profile the reference's are a bump a hundredth of a
        // unit high, which is a quarter of what the rolled edge takes, so cut
        // into this outline they come out as shards. They are turned
        // separately and stood on the poll, splayed, which is where a horse
        // keeps them and what the reference's front view shows.
        (-0.088, 1.130, false, 0.070), (-0.046, 1.143, true, 0.058),
        (0.006, 1.152, true, 0.058), (0.058, 1.161, true, 0.056),
        // Down the face, which falls forward faster than it looks as if it
        // should: half its travel is spent in the top third.
        (0.062, 1.104, false, 0.074), (0.094, 1.072, false, 0.084),
        (0.135, 1.038, false, 0.086), (0.179, 1.003, false, 0.082),
        (0.220, 0.975, false, 0.076), (0.261, 0.948, false, 0.068),
        // The muzzle: blunt, and the thinnest of the head. It sits at the same
        // height as the neck behind it and is cut half as deep, which is the
        // whole reason the depth follows the outline rather than the height.
        (0.273, 0.936, false, 0.063), (0.279, 0.923, false, 0.059),
        (0.280, 0.895, false, 0.056), (0.270, 0.874, false, 0.057),
        (0.244, 0.851, true, 0.058),
        // Back up the underside of the jaw. The mouth is a **V**, cut up into
        // the head at some forty degrees and closing at the cheek — not the
        // flat slot it was, sawn straight back under the muzzle. It is most of
        // what tells a horse's head from a boot.
        (0.204, 0.854, false, 0.062), (0.155, 0.872, false, 0.066),
        (0.113, 0.890, false, 0.069), (0.076, 0.900, true, 0.072),
        // And down the throat, which is pinched in tight behind the jaw before
        // it opens out into the chest.
        (0.055, 0.893, false, 0.075), (0.030, 0.865, true, 0.078),
        (0.052, 0.828, false, 0.078), (0.088, 0.786, false, 0.078),
        (0.140, 0.735, false, 0.079), (0.173, 0.688, false, 0.081),
        (0.192, 0.653, false, 0.084), (0.205, 0.614, false, 0.090),
        (0.208, 0.608, false, 0.094), (0.196, 0.598, true, 0.086),
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
            let b = anchors[i]
            let c = anchors[(i + 1) % anchors.count]
            let a = anchors[(i - 1 + anchors.count) % anchors.count]
            let d = anchors[(i + 2) % anchors.count]
            points.append((b.x, b.y, b.depth))
            if b.corner || c.corner {
                // Straight into and out of every corner, and sampled all the
                // way. A corner is a cut, and a curve run up to one swings past
                // it: the anchor beyond the foot of the neck is the width of
                // the piece away, across the closing run, and the curve leaving
                // that corner dipped four hundredths below the foot — sweeping
                // the whole depth on its way, which came out as a thin fin
                // hanging down through the collar on either side.
                //
                // Sampled, because left as one long edge the closing run is the
                // only edge on the piece a hundred times the length of its
                // neighbours. Drawing the face in then moves its two ends about
                // while every other point creeps, and the cap over them tears.
                let span = ((c.x - b.x) * (c.x - b.x) + (c.y - b.y) * (c.y - b.y)).squareRoot()
                let cuts = max(1, Int(span / 0.008))
                for cut in 1..<max(2, cuts) {
                    let t = Float(cut) / Float(cuts)
                    points.append((b.x + (c.x - b.x) * t, b.y + (c.y - b.y) * t,
                                   b.depth + (c.depth - b.depth) * t))
                }
                continue
            }
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
        while remaining.count > 3 {
            var clipped = false
            // The best ear going, kept in case none of them is a proper one.
            var fallback = (turn: -Float.greatestFiniteMagnitude, at: 0)

            for k in remaining.indices {
                let i0 = remaining[(k - 1 + remaining.count) % remaining.count]
                let i1 = remaining[k]
                let i2 = remaining[(k + 1) % remaining.count]
                let a = points[i0], b = points[i1], c = points[i2]
                let turn = cross(a, b, c)
                if turn > fallback.turn { fallback = (turn, k) }
                guard turn > 0 else { continue }              // a reflex corner is no ear

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

            // Nothing clean left: take the best corner anyway rather than stop.
            //
            // Stopping is what a straight reading of the algorithm does, and it
            // hands back part of a face. Part of a face is a hole — and the
            // rings this is asked to cut are exactly the awkward cases: nearly
            // straight runs where every corner turns by almost nothing, and
            // rings drawn in far enough to have crossed themselves. A few
            // triangles overlapping inside the piece cost nothing; a hole in
            // the neck one can see through costs the piece.
            if !clipped {
                let k = fallback.at
                let i0 = remaining[(k - 1 + remaining.count) % remaining.count]
                let i1 = remaining[k]
                let i2 = remaining[(k + 1) % remaining.count]
                triangles.append((i0, i1, i2))
                remaining.remove(at: k)
            }
        }
        if remaining.count == 3 { triangles.append((remaining[0], remaining[1], remaining[2])) }
        return triangles
    }

    /// How far the face stands off the plain sweep at a point on it.
    ///
    /// A swept outline gives a lens: one thickness set at the rim and a smooth
    /// dome between. No horse's head is that. It has a cheek that swells, a
    /// socket the eye sits in, a bone running down from it, and a flat along
    /// the nose — and none of them are at the edge, where a swept section is
    /// the only place it can put anything. That is why the cheek stayed flat
    /// however the outline and the depths were tuned: there was nothing in the
    /// method that could put a shape *inside* a face.
    ///
    /// So the modelling is a field, added to the sweep: a handful of swells and
    /// hollows, each a soft round patch, summed. It reads like what a carver
    /// does — take the blank, then add and take away — and because it is a
    /// continuous function of position, the surface stays smooth and the
    /// normals pick the modelling up on their own.
    static func modelling(_ x: Float, _ y: Float) -> Float {
        /// A soft round patch: full at the middle, nothing at the edge, and
        /// flat where it meets the surface either side so it leaves no seam.
        func patch(_ cx: Float, _ cy: Float, _ spread: Float) -> Float {
            let away = ((x - cx) * (x - cx) + (y - cy) * (y - cy)).squareRoot() / spread
            guard away < 1 else { return 0 }
            let t = 1 - away
            return t * t * (3 - 2 * t)
        }

        var relief: Float = 0
        relief += patch(0.030, 0.925, 0.130) * 0.030   // the cheek, the fullest part of the head
        relief += patch(0.145, 0.985, 0.055) * 0.014   // the bone running down from the eye
        relief -= patch(0.100, 1.055, 0.050) * 0.010   // the dish above it
        relief -= patch(0.048, 1.048, 0.042) * 0.024   // the socket
        relief += patch(0.052, 1.042, 0.019) * 0.011   // and the eye sitting in it
        relief -= patch(0.235, 0.945, 0.055) * 0.012   // the flat down the nose
        relief += patch(-0.090, 0.700, 0.100) * 0.010  // the shoulder of the neck
        return relief
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

        // Anywhere the step has turned an edge back on itself, put both its
        // ends back where they were.
        //
        // The area of the whole ring cannot see this. A narrow part folds
        // through itself long before the ring as a whole has lost much size —
        // the bottom of the neck is four tenths across and a quarter deep, so
        // it closes over while the rest is still creeping — and the folded part
        // is then skinned inside out, which shows as a torn hole one can see
        // into the piece through.
        var held = smoothed
        for _ in 0..<2 {
            var pass = held
            for i in 0..<count {
                let j = (i + 1) % count
                let was = (ring[j].x - ring[i].x, ring[j].y - ring[i].y)
                let now = (held[j].x - held[i].x, held[j].y - held[i].y)
                if was.0 * now.0 + was.1 * now.1 <= 0 {
                    pass[i] = ring[i]
                    pass[j] = ring[j]
                }
            }
            held = pass
        }
        return held
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

        // How far the edge may roll in, point by point.
        //
        // A roll is an inset, and an inset wider than the place it is rolling
        // through has nowhere to go: the two sides of a narrow spot roll into
        // each other and come out as a tube hanging off the piece. The mouth
        // did that, and so did the bottom of the neck.
        //
        // One figure for the whole outline is no use — it would have to suit
        // the narrowest place on the piece and would leave the neck square — so
        // it is measured where it is used. Distance to the nearest other part
        // of the outline, and no more than half of it.
        var reach = (0..<count).map { min(roll, outline[$0].depth * 0.9) }
        for i in 0..<count {
            // How far it is from here to the nearest *other* part of the
            // outline — not counting its own neighbourhood, which is always
            // close. The roll may have half of that and no more.
            var nearest = Float.greatestFiniteMagnitude
            for j in 0..<count {
                let apart = min(abs(i - j), count - abs(i - j))
                guard apart > 14 else { continue }
                let dx = outline[j].x - outline[i].x, dy = outline[j].y - outline[i].y
                nearest = min(nearest, (dx * dx + dy * dy).squareRoot())
            }
            reach[i] = min(reach[i], nearest * 0.45)
        }

        // The face, drawn in until there is nothing left of it to draw.
        let full = area(outline)
        var faces: [Ring] = [(0..<count).map { i in
            (outline[i].x - normals[i].0 * reach[i],
             outline[i].y - normals[i].1 * reach[i], outline[i].depth)
        }]
        while faces.count < 10 {
            let next = drawIn(faces[faces.count - 1], by: 0.012)
            guard area(next) > full * 0.12 else { break }
            faces.append(next)
        }
        // Whether each ring still cuts into a whole face is the one number
        // that says if this piece is sound, and it is not visible in a render
        // until something is standing in front of the hole.
        if ProcessInfo.processInfo.environment["DIAG"] != nil {
            for (k, ring) in faces.enumerated() {
                let clipped = earClip(ring.map { ($0.x, $0.y) })
                print("  ring \(k): area \(area(ring)) of \(full), "
                      + "cuts \(clipped.count) of \(ring.count - 2)")
            }
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

        // Nothing below the foot of the piece.
        //
        // Drawing a ring in creeps outwards round a sharp corner — smoothing
        // averages points that are bunched together there, and the average can
        // land outside the ring it came from. At the two corners where the neck
        // is cut off that is downwards, and three hundred vertices ended up
        // below the cut, sweeping the depth of the piece as they went: a thin
        // fin of ivory hanging down through the collar on either side. The
        // underside is a cut and is flat, so this costs nothing.
        let foot = outline.map(\.y).min() ?? 0

        var rings: [[SIMD3<Float>]] = []
        func place(_ ring: Ring, _ sign: Float, _ k: Int) -> [SIMD3<Float>] {
            // The modelling is laid on over the sweep, and faded in from the
            // edge: nothing at the rim, so the silhouette and the roll are left
            // exactly as drawn — but all of it within two rings, not spread
            // across the whole face. Spread out, the modelling only reaches
            // full strength deep in the middle, and the things worth modelling
            // are not in the middle: the eye and the cheekbone sit a fifth of
            // the way in from the edge, and they came out as smudges.
            let ramp = min(1, Float(k) / 2.0)
            let inward = ramp * ramp * (3 - 2 * ramp)
            return ring.map {
                SIMD3($0.x * s, max(foot, $0.y) * s,
                      sign * ($0.depth * lift(k) + modelling($0.x, $0.y) * inward) * s)
            }
        }
        for k in stride(from: faces.count - 1, through: 1, by: -1) {
            rings.append(place(faces[k], -1, k))
        }
        for step in 0...rimSteps {
            let angle = -Float.pi / 2 + Float.pi * Float(step) / Float(rimSteps)
            rings.append((0..<count).map { i in
                let inset = reach[i] * (1 - cos(angle))
                return SIMD3((outline[i].x - normals[i].0 * inset) * s,
                             max(foot, outline[i].y - normals[i].1 * inset) * s,
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
        var head = shell(knightOutline, scale: s, roll: 0.038, bulge: 0.24)
        head.append(ear(s, side: 1))
        head.append(ear(s, side: -1))
        return head.geometry
    }

    /// One ear, turned on its own and stood on the poll.
    ///
    /// A knight's ears are the one part of it that does not live in the
    /// silhouette. Cut into the outline they are a bump a hundredth of a unit
    /// high — less than the rolled edge takes off, so they come out as shards —
    /// and cut deep enough to survive they turn the head into a rabbit's. On
    /// the piece they are two small cones splayed out from the crest, and from
    /// the front they are most of what is up there.
    private static func ear(_ s: Float, side: Float) -> Solid {
        // Long and splayed, and rooted well down inside the head. The
        // reference's reach a fifth of the way out from the middle and stand
        // nearly a third of the head's height — cut short and close they read
        // as bumps, which is what they were.
        let root = SIMD3<Float>(-0.018, 0.962, side * 0.034)
        let tip = SIMD3<Float>(-0.074, 1.198, side * 0.132)
        let steps = 11, segments = 12

        let axis = simd_normalize(tip - root)
        // Any two directions across the axis will do, so long as they are
        // square to it and to each other.
        let aside = simd_normalize(simd_cross(axis, SIMD3<Float>(0, 0, 1)))
        let other = simd_cross(axis, aside)

        var rings: [[SIMD3<Float>]] = []
        for step in 0...steps {
            let along = Float(step) / Float(steps)
            let centre = root + (tip - root) * along
            // Full at the root and rounded over at the tip. Drawn to a point
            // — a cone's straight taper — it comes out as a spine, and two
            // spines over a horse's head read as horns. The width falls away
            // on a quarter ellipse instead, so the last of it turns over into
            // a dome the way an ear does.
            let radius = 0.056 * (1 - along * along).squareRoot() * (1 - along * 0.42) + 0.001
            rings.append((0..<segments).map { segment in
                let angle = 2 * Float.pi * Float(segment) / Float(segments)
                let offset = aside * (radius * cos(angle) * 0.78) + other * (radius * sin(angle))
                return (centre + offset) * s
            })
        }
        let fan = (1..<(segments - 1)).map { (0, $0, $0 + 1) }
        return skin(rings, closingWith: fan)
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
        let run = crest(steps: 7, from: 2, to: 14)
        guard run.count > 2 else { return Solid().geometry }
        let segments = 14
        let stand: Float = 0.012          // how far the ridge sits proud of the edge
        let sink: Float = 0.007           // and how far its root is buried

        var rings: [[SIMD3<Float>]] = []
        for i in run.indices {
            // Died away at both ends. A ridge of even height stops dead where
            // the run does, and a mane that ends in mid-air reads as a blade
            // stuck on the back rather than as part of the piece.
            let along = Float(i) / Float(run.count - 1)
            let fade = min(1, min(along, 1 - along) / 0.18)
            // Both axes of the section die away together, not just the height.
            // Fading the height alone leaves the ends as flat slivers — a ring
            // of points strung along a line with no circle to them — and a
            // sliver skins into a tangle of triangles that tears open the neck
            // where the mane starts and finishes.
            let taper = 0.16 + 0.84 * (fade * fade * (3 - 2 * fade))
            let rise = stand * taper
            let before = run[max(0, i - 1)], after = run[min(run.count - 1, i + 1)]
            let tx = after.x - before.x, ty = after.y - before.y
            let length = max(1e-6, (tx * tx + ty * ty).squareRoot())
            let outward = (ty / length, -tx / length)
            let across = run[i].depth * 0.72 * taper
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
