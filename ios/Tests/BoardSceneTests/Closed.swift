import Testing
import SceneKit
@testable import BoardScene

/// The knight's head has to be a closed surface.
///
/// It is the one piece not turned on the lathe, and it is built by drawing its
/// outline inwards ring by ring — which can fold, and did. A fold shows up in a
/// render as a torn hole, and it took three wrong diagnoses to place one of
/// them: it appeared as a ring of shards round the collar, which reads exactly
/// like a badly seated band, so the band was moved and grooved and reseated
/// while the hole stayed where it was.
///
/// Counting edges settles it in a tenth of a second. On a closed surface every
/// edge belongs to exactly two triangles; on a torn one it does not.
@Suite("The knight is closed")
struct KnightClosed {
    @Test("every edge belongs to two triangles")
    func watertight() {
        let solid = TurnedPieces.shell(TurnedPieces.knightOutline, scale: 1,
                                       roll: 0.038, bulge: 0.24)
        func corner(_ point: SCNVector3) -> String {
            String(format: "%.4f,%.4f,%.4f", point.x, point.y, point.z)
        }

        var edges: [String: Int] = [:]
        for triangle in stride(from: 0, to: solid.positions.count, by: 3) {
            let a = solid.positions[triangle]
            let b = solid.positions[triangle + 1]
            let c = solid.positions[triangle + 2]
            for (from, to) in [(a, b), (b, c), (c, a)] {
                edges[[corner(from), corner(to)].sorted().joined(separator: "|"), default: 0] += 1
            }
        }

        let open = edges.filter { $0.value == 1 }
        #expect(open.isEmpty, "\(open.count) of \(edges.count) edges belong to one triangle only, so the head has a hole in it")
    }
}
