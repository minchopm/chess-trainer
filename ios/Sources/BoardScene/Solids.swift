import SceneKit
import simd

/// A pile of triangles, each carrying its own face normal.
///
/// Flat-shaded on purpose. The site's pieces are merged into one unindexed
/// buffer and then have their normals computed, which gives every triangle the
/// plane it lies in — so a turned piece reads as forty-eight facets catching
/// the light rather than as a mathematically smooth surface. Copying the
/// smoothing would have been the mistake: at this segment count the facets are
/// most of what makes the ivory look turned.
struct Solid {
    private(set) var positions: [SCNVector3] = []
    private(set) var normals: [SCNVector3] = []

    mutating func triangle(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) {
        let edge1 = b - a, edge2 = c - a
        let cross = simd_cross(edge1, edge2)
        let length = simd_length(cross)
        // A degenerate triangle has no plane to lie in. They turn up wherever a
        // profile touches the axis — the tip of a finial, the underside of a
        // base — and a zero normal there would be a black speck on every piece.
        guard length > 1e-9 else { return }
        let normal = cross / length

        for point in [a, b, c] {
            positions.append(SCNVector3(point.x, point.y, point.z))
            normals.append(SCNVector3(normal.x, normal.y, normal.z))
        }
    }

    /// A triangle carrying normals of its own, for a surface that is meant to
    /// look smooth rather than turned.
    ///
    /// The lathe pieces want their facets — at forty-eight segments the facets
    /// are most of what makes the ivory look turned. The knight is the one
    /// piece that is not turned, and on a curved face those same facets read as
    /// scratches drawn across the cheek.
    mutating func triangle(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>,
                           normals na: SIMD3<Float>, _ nb: SIMD3<Float>, _ nc: SIMD3<Float>) {
        let cross = simd_cross(b - a, c - a)
        guard simd_length(cross) > 1e-9 else { return }
        for (point, normal) in [(a, na), (b, nb), (c, nc)] {
            positions.append(SCNVector3(point.x, point.y, point.z))
            normals.append(SCNVector3(normal.x, normal.y, normal.z))
        }
    }

    mutating func quad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>) {
        triangle(a, b, c)
        triangle(a, c, d)
    }

    mutating func append(_ other: Solid) {
        positions += other.positions
        normals += other.normals
    }

    var geometry: SCNGeometry {
        let vertexSource = SCNGeometrySource(vertices: positions)
        let normalSource = SCNGeometrySource(normals: normals)
        let indices = (0..<Int32(positions.count)).map { $0 }
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        return SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
    }
}

// MARK: - The lathe

/// A point on a turning profile: how far from the axis, and how high.
typealias Turn = (r: Float, y: Float)

extension Solid {
    /// Revolves a profile around the Y axis — the same operation that makes a
    /// real Staunton set on a real lathe, which is why the profiles below read
    /// like a turner's notes rather than like a mesh.
    static func revolved(_ profile: [Turn], segments: Int = 48,
                         from start: Float = 0, through sweep: Float = 2 * .pi) -> Solid {
        var solid = Solid()
        guard profile.count > 1 else { return solid }

        // Never exactly zero: a ring of radius zero collapses to a point and
        // takes its triangles' normals with it.
        let points = profile.map { Turn(r: max($0.r, 0.0001), y: $0.y) }
        let partial = sweep < 2 * .pi - 0.0001

        for step in 0..<segments {
            let a = start + Float(step) / Float(segments) * sweep
            let b = start + Float(step + 1) / Float(segments) * sweep
            let (sa, ca) = (sinf(a), cosf(a))
            let (sb, cb) = (sinf(b), cosf(b))

            for i in 0..<(points.count - 1) {
                let lower = points[i], upper = points[i + 1]
                // Wound so the face normal points away from the axis. Taken the
                // other way round the normals point inward, which is not a
                // subtle error: the front faces are culled, the inside of the
                // piece is what gets drawn, and a solid ivory rook renders as a
                // glass one.
                solid.quad(
                    SIMD3(upper.r * ca, upper.y, upper.r * sa),
                    SIMD3(upper.r * cb, upper.y, upper.r * sb),
                    SIMD3(lower.r * cb, lower.y, lower.r * sb),
                    SIMD3(lower.r * ca, lower.y, lower.r * sa)
                )
            }
        }

        // A partial sweep is an open shell, and an open shell seen from inside
        // is a hole. The two radial faces close it.
        if partial {
            for (angle, flip) in [(start, false), (start + sweep, true)] {
                let (sa, ca) = (sinf(angle), cosf(angle))
                for i in 0..<(points.count - 1) {
                    let lower = points[i], upper = points[i + 1]
                    let outerLow = SIMD3(lower.r * ca, lower.y, lower.r * sa)
                    let outerHigh = SIMD3(upper.r * ca, upper.y, upper.r * sa)
                    let axisLow = SIMD3<Float>(0, lower.y, 0)
                    let axisHigh = SIMD3<Float>(0, upper.y, 0)
                    if flip {
                        solid.quad(axisLow, outerLow, outerHigh, axisHigh)
                    } else {
                        solid.quad(axisHigh, outerHigh, outerLow, axisLow)
                    }
                }
            }
        }

        return solid
    }

    static func sphere(radius: Float, at centre: SIMD3<Float>, segments: Int = 32, rings: Int = 16) -> Solid {
        var solid = Solid()
        for ring in 0..<rings {
            let phi0 = Float(ring) / Float(rings) * .pi
            let phi1 = Float(ring + 1) / Float(rings) * .pi
            for step in 0..<segments {
                let t0 = Float(step) / Float(segments) * 2 * .pi
                let t1 = Float(step + 1) / Float(segments) * 2 * .pi
                func point(_ phi: Float, _ theta: Float) -> SIMD3<Float> {
                    SIMD3(
                        centre.x + radius * sinf(phi) * cosf(theta),
                        centre.y + radius * cosf(phi),
                        centre.z + radius * sinf(phi) * sinf(theta)
                    )
                }
                solid.quad(point(phi0, t0), point(phi0, t1), point(phi1, t1), point(phi1, t0))
            }
        }
        return solid
    }

    /// A capped cylinder, centred on its own middle the way three's is.
    static func cylinder(radius: Float, height: Float, at centre: SIMD3<Float>, segments: Int = 12,
                         axis: Axis = .y) -> Solid {
        var solid = Solid()
        let half = height / 2

        for step in 0..<segments {
            let a = Float(step) / Float(segments) * 2 * .pi
            let b = Float(step + 1) / Float(segments) * 2 * .pi
            let (ca, sa) = (cosf(a) * radius, sinf(a) * radius)
            let (cb, sb) = (cosf(b) * radius, sinf(b) * radius)

            let bottomA = axis.place(ca, -half, sa) + centre
            let bottomB = axis.place(cb, -half, sb) + centre
            let topB = axis.place(cb, half, sb) + centre
            let topA = axis.place(ca, half, sa) + centre

            solid.quad(topA, topB, bottomB, bottomA)
            solid.triangle(axis.place(0, half, 0) + centre, topB, topA)
            solid.triangle(axis.place(0, -half, 0) + centre, bottomA, bottomB)
        }

        return solid
    }

    /// A ring lying flat in the XZ plane.
    static func ring(radius: Float, tube: Float, at centre: SIMD3<Float>,
                     segments: Int = 40, tubeSegments: Int = 12) -> Solid {
        var solid = Solid()
        func point(_ major: Float, _ minor: Float) -> SIMD3<Float> {
            let r = radius + tube * cosf(minor)
            return SIMD3(centre.x + r * cosf(major), centre.y + tube * sinf(minor), centre.z + r * sinf(major))
        }
        for i in 0..<segments {
            let m0 = Float(i) / Float(segments) * 2 * .pi
            let m1 = Float(i + 1) / Float(segments) * 2 * .pi
            for j in 0..<tubeSegments {
                let n0 = Float(j) / Float(tubeSegments) * 2 * .pi
                let n1 = Float(j + 1) / Float(tubeSegments) * 2 * .pi
                solid.quad(point(m0, n1), point(m1, n1), point(m1, n0), point(m0, n0))
            }
        }
        return solid
    }

    /// A block of wall: the solid between two radii, two heights and two
    /// angles, closed on all six sides.
    ///
    /// This is here because `revolved` cannot do it, in a way that is easy to
    /// miss. A partial sweep is an open shell, so `revolved` closes it with two
    /// radial faces — and it closes them **to the axis**, because the profiles
    /// it is built for start there. Hand it a profile that does not, which is
    /// what a battlement is, and each piece drags a pair of blade-shaped faces
    /// right through the middle of the turning. On a rook the battlements come
    /// out attached to a five-spoked fan filling the hollow they are supposed
    /// to stand around: invisible from a chair, plain from straight overhead,
    /// and `OrbitCamera` lets the camera go straight overhead.
    ///
    /// Both rooks use this. Angles follow `revolved`: where the sweep starts,
    /// and how far it goes.
    static func sector(inner: Float, outer: Float, bottom: Float, top: Float,
                       from start: Float, through sweep: Float, segments: Int = 8) -> Solid {
        var solid = Solid()
        func at(_ radius: Float, _ y: Float, _ angle: Float) -> SIMD3<Float> {
            SIMD3(radius * cosf(angle), y, radius * sinf(angle))
        }

        for step in 0..<segments {
            let a = start + sweep * Float(step) / Float(segments)
            let b = start + sweep * Float(step + 1) / Float(segments)
            solid.quad(at(outer, top, a), at(outer, top, b),
                       at(outer, bottom, b), at(outer, bottom, a))
            solid.quad(at(inner, top, b), at(inner, top, a),
                       at(inner, bottom, a), at(inner, bottom, b))
            solid.quad(at(inner, top, a), at(inner, top, b),
                       at(outer, top, b), at(outer, top, a))
            // The underside, which on a rook is buried in the rim and never
            // seen — but drawn, so the block is a closed solid rather than a
            // shell with a hole in the bottom for the light to get into.
            solid.quad(at(outer, bottom, a), at(outer, bottom, b),
                       at(inner, bottom, b), at(inner, bottom, a))
        }

        // The two square-cut ends, which on a rook are what the gaps between
        // the battlements actually are.
        for (angle, opening) in [(start, true), (start + sweep, false)] {
            let corners = [at(inner, bottom, angle), at(outer, bottom, angle),
                           at(outer, top, angle), at(inner, top, angle)]
            if opening {
                solid.quad(corners[3], corners[2], corners[1], corners[0])
            } else {
                solid.quad(corners[0], corners[1], corners[2], corners[3])
            }
        }
        return solid
    }

    enum Axis {
        case y, x
        func place(_ x: Float, _ y: Float, _ z: Float) -> SIMD3<Float> {
            switch self {
            case .y: SIMD3(x, y, z)
            case .x: SIMD3(y, x, z)
            }
        }
    }
}
