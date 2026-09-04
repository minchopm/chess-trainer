import ChessCore
import SceneKit
import Testing
@testable import BoardScene

/// What the walnut set has to be true of, measured off the meshes.
///
/// Every one of these is a fault that was in the set at some point during the
/// modelling and that a render did not obviously show. They are cheap — the
/// whole suite builds six pieces and walks their vertices — and they are the
/// only reason the numbers in `ParlourSet`'s documentation can be trusted,
/// since a height written in a comment and a height the lathe actually produces
/// are two different things.
@Suite("the walnut set")
@MainActor
struct ParlourSetShape {

    /// Every vertex of a piece, in the piece's own space.
    private func corners(of kind: PieceKind) -> [SIMD3<Float>] {
        var out: [SIMD3<Float>] = []
        let node = TurnedPieces.node(for: kind, style: .parlour)
        node.enumerateHierarchy { child, _ in
            guard let geometry = child.geometry else { return }
            // The knight's head and mane are turned a quarter of the way round
            // before they are added, so a vertex has to be taken through the
            // node's own transform to land where the piece actually wears it.
            let transform = child.simdWorldTransform
            for source in geometry.sources(for: .vertex) {
                let stride = source.dataStride, offset = source.dataOffset
                source.data.withUnsafeBytes { raw in
                    for index in 0..<source.vectorCount {
                        let base = index * stride + offset
                        let x = raw.loadUnaligned(fromByteOffset: base, as: Float.self)
                        let y = raw.loadUnaligned(fromByteOffset: base + 4, as: Float.self)
                        let z = raw.loadUnaligned(fromByteOffset: base + 8, as: Float.self)
                        let placed = transform * SIMD4<Float>(x, y, z, 1)
                        out.append(SIMD3(placed.x, placed.y, placed.z))
                    }
                }
            }
        }
        return out
    }

    /// A piece stands as tall as the set says it does.
    ///
    /// The heights in `ParlourSet.height` are the set's specification — the
    /// table in its documentation is read off them, and so is the claim that
    /// the pieces grade the way a real Staunton set does. But nothing makes
    /// them true: each profile ends wherever its last point and its finial
    /// happen to land, and the king's cross in particular is a cylinder placed
    /// by its centre, so half its length is arithmetic done by hand. Two of
    /// these were out by a twentieth of a square when first written.
    @Test("every piece is the height it claims", arguments: PieceKind.allCases)
    func height(_ kind: PieceKind) {
        let top = corners(of: kind).map(\.y).max() ?? 0
        let wanted = ParlourSet.height[kind] ?? 0
        #expect(abs(top - wanted) < 0.02,
                "\(kind) stands \(top) but the set says \(wanted)")
    }

    /// A piece starts on the board rather than under it.
    @Test("every piece stands on the square", arguments: PieceKind.allCases)
    func grounded(_ kind: PieceKind) {
        let bottom = corners(of: kind).map(\.y).min() ?? 0
        #expect(bottom > -0.01 && bottom < 0.01,
                "\(kind) has its underside at \(bottom) rather than on the square")
    }

    /// No base crosses into the next square.
    ///
    /// This set is deliberately wide-footed — that is most of the point of it,
    /// and the king's foot is 0.79 of a square across. Half a square is where
    /// it has to stop: past that two neighbours on the back rank interpenetrate,
    /// and what that costs is not only the join but the shadow between them,
    /// which is what separates eight pieces from one dark mass.
    @Test("no base crosses into the next square", arguments: PieceKind.allCases)
    func footprint(_ kind: PieceKind) {
        let reach = corners(of: kind)
            .map { ($0.x * $0.x + $0.z * $0.z).squareRoot() }
            .max() ?? 0
        #expect(reach < 0.5, "\(kind) reaches \(reach) from the middle of its square")
    }

    /// A battlement is a closed solid.
    ///
    /// Both rooks are built from `Solid.sector`, and both were built from a
    /// partial `Solid.revolved` before it — which closes an open sweep with two
    /// radial faces run all the way to the axis, so each merlon dragged a pair
    /// of blades through the middle of the piece and the hollow came out full
    /// of them. Nothing on a chessboard shows it; a shot from straight overhead
    /// does, and `OrbitCamera.elevationRange` goes to .pi/2.
    ///
    /// Counting edges settles it: on a closed surface every edge belongs to
    /// exactly two triangles. The old construction fails this — its radial
    /// faces meet the axis in a seam that belongs to one triangle only.
    @Test("a battlement is closed")
    func battlementWatertight() {
        let block = Solid.sector(inner: 0.184, outer: 0.242, bottom: 0.86, top: 1.08,
                                 from: 0, through: 0.5)
        func corner(_ point: SCNVector3) -> String {
            String(format: "%.4f,%.4f,%.4f", point.x, point.y, point.z)
        }
        var edges: [String: Int] = [:]
        for triangle in stride(from: 0, to: block.positions.count, by: 3) {
            let a = block.positions[triangle]
            let b = block.positions[triangle + 1]
            let c = block.positions[triangle + 2]
            for (from, to) in [(a, b), (b, c), (c, a)] {
                edges[[corner(from), corner(to)].sorted().joined(separator: "|"), default: 0] += 1
            }
        }
        let open = edges.filter { $0.value == 1 }
        #expect(open.isEmpty,
                "\(open.count) of \(edges.count) edges belong to one triangle only, so the block is a shell")
    }

    /// Neither rook has anything standing in its hollow.
    ///
    /// The watertightness of one block does not prove the rook is right — the
    /// old build produced closed geometry too, just with blades in the middle
    /// of it. This is the assertion that would have caught it: above the
    /// rampart floor, no triangle of either rook comes anywhere near the axis.
    @Test("the rook's hollow is empty", arguments: [PieceStyle.plain, .banded, .parlour])
    func rookIsHollow(_ style: PieceStyle) {
        let node = TurnedPieces.node(for: .rook, style: style)
        // Well above the rampart, so the turning's own cap is not counted.
        let floor: Float = style == .parlour ? 0.95 : 0.62
        var nearest = Float.greatestFiniteMagnitude
        node.enumerateHierarchy { child, _ in
            guard let geometry = child.geometry else { return }
            for source in geometry.sources(for: .vertex) {
                let stride = source.dataStride, offset = source.dataOffset
                source.data.withUnsafeBytes { raw in
                    for index in 0..<source.vectorCount {
                        let base = index * stride + offset
                        let x = raw.loadUnaligned(fromByteOffset: base, as: Float.self)
                        let y = raw.loadUnaligned(fromByteOffset: base + 4, as: Float.self)
                        let z = raw.loadUnaligned(fromByteOffset: base + 8, as: Float.self)
                        // `continue`, not `return`. Inside a
                        // `withUnsafeBytes` closure a `return` leaves the
                        // closure, so the scan stopped at the first vertex
                        // below the floor — which is the base, the first vertex
                        // there is. The test passed on the broken rook.
                        guard y > floor else { continue }
                        nearest = min(nearest, (x * x + z * z).squareRoot())
                    }
                }
            }
        }
        #expect(nearest > 0.05,
                "the \(style) rook has geometry \(nearest) from the axis above its rampart, so something is standing in the hollow")
    }

    /// The knight's head lands inside its base's shoulder.
    ///
    /// The head is the site's mesh, scaled — it is drawn on its own scale where
    /// it stands 1.198 tall and its neck starts at 0.598, and the base's
    /// shoulder is written as multiples of that same scale so the two move
    /// together. If they ever come apart the neck meets the base off the
    /// straight-sided part of the shoulder, and what that looks like is a ring
    /// of torn triangles round the collar — which reads exactly like a badly
    /// seated band, and is why this is measured rather than looked at.
    @Test("the knight's neck lands on the shoulder")
    func knightSeated() {
        let scale = (ParlourSet.height[.knight] ?? 1.24) / 1.198
        let head = TurnedPieces.knightHead(scale)
        var lowest = Float.greatestFiniteMagnitude
        for source in head.sources(for: .vertex) {
            let stride = source.dataStride, offset = source.dataOffset
            source.data.withUnsafeBytes { raw in
                for index in 0..<source.vectorCount {
                    let y = raw.loadUnaligned(fromByteOffset: index * stride + offset + 4,
                                              as: Float.self)
                    lowest = min(lowest, y)
                }
            }
        }
        // The shoulder is the straight-sided run from 0.586 to 0.602 on the
        // head's own scale. The neck has to come down into it, not onto the
        // slope above it or the collar below.
        #expect(lowest >= 0.580 * scale && lowest <= 0.604 * scale,
                "the head's underside is at \(lowest), and the shoulder runs \(0.586 * scale) to \(0.602 * scale)")
    }

    /// The set is graded, and graded the right way round.
    ///
    /// A set where the bishop outranks the queen reads as wrong long before
    /// anybody works out why — the site's own `TurnedPieces` says so, and this
    /// is that sentence as an assertion.
    @Test("the pieces rank in the right order")
    func ranking() {
        let order: [PieceKind] = [.pawn, .rook, .knight, .bishop, .queen, .king]
        for (shorter, taller) in zip(order, order.dropFirst()) {
            let low = ParlourSet.height[shorter] ?? 0
            let high = ParlourSet.height[taller] ?? 0
            #expect(low < high, "the \(shorter) at \(low) is not shorter than the \(taller) at \(high)")
        }
    }
}
