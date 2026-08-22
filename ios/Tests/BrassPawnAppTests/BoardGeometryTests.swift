import CoreGraphics
import Testing
@testable import BrassPawnApp

/// Four taps into a board.
@Suite("Reading a board off a photograph")
struct BoardGeometryTests {
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    @Test("Corners tapped in order come back in order")
    func inOrderStaysInOrder() {
        let corners = BoardGeometry.order([p(0, 0), p(100, 0), p(100, 100), p(0, 100)])
        #expect(corners?.topLeft == p(0, 0))
        #expect(corners?.topRight == p(100, 0))
        #expect(corners?.bottomRight == p(100, 100))
        #expect(corners?.bottomLeft == p(0, 100))
    }

    /// The whole point of inferring: somebody looking at a board that is upside
    /// down to them will not start where you expected.
    @Test("Corners tapped in any order are sorted out")
    func anyOrderIsSorted() {
        let expected = BoardGeometry.order([p(0, 0), p(100, 0), p(100, 100), p(0, 100)])
        for shuffled in [
            [p(100, 100), p(0, 100), p(0, 0), p(100, 0)],
            [p(0, 100), p(100, 0), p(0, 0), p(100, 100)],
            [p(100, 0), p(0, 0), p(0, 100), p(100, 100)],
        ] {
            #expect(BoardGeometry.order(shuffled) == expected, "\(shuffled)")
        }
    }

    /// A board seen from the side is a trapezium, not a square: the far edge is
    /// shorter than the near one.
    @Test("A board seen at an angle is still sorted correctly")
    func perspectiveQuadIsSorted() {
        let corners = BoardGeometry.order([
            p(40, 10), p(160, 10),      // far edge, foreshortened
            p(200, 120), p(0, 120),     // near edge, wide
        ])
        #expect(corners?.topLeft == p(40, 10))
        #expect(corners?.topRight == p(160, 10))
        #expect(corners?.bottomRight == p(200, 120))
        #expect(corners?.bottomLeft == p(0, 120))
    }

    @Test("Fewer or more than four points is not a board")
    func wrongCountIsRefused() {
        #expect(BoardGeometry.order([p(0, 0), p(1, 0), p(1, 1)]) == nil)
        #expect(BoardGeometry.order([p(0, 0), p(1, 0), p(1, 1), p(0, 1), p(2, 2)]) == nil)
    }

    /// Four taps along a line are a mis-tap, and rectifying them would stretch
    /// a sliver of photograph across a whole board.
    @Test("Four points in a line are not a board")
    func degenerateQuadIsRefused() {
        #expect(BoardGeometry.order([p(0, 0), p(10, 0), p(20, 0), p(30, 0)]) == nil)
    }

    // MARK: - Cutting it up

    @Test("a1 is the bottom left and h8 the top right")
    func squaresAreWhereChessPutsThem() {
        let a1 = BoardGeometry.square(file: 0, rank: 0, side: 800)
        #expect(a1.minX == 0)
        #expect(a1.minY == 700)

        let h8 = BoardGeometry.square(file: 7, rank: 7, side: 800)
        #expect(h8.minX == 700)
        #expect(h8.minY == 0)
    }

    @Test("The sixty-four squares tile the board exactly")
    func squaresTileTheBoard() {
        let side: CGFloat = 800
        var covered: CGFloat = 0
        for file in 0..<8 {
            for rank in 0..<8 {
                let square = BoardGeometry.square(file: file, rank: rank, side: side)
                #expect(square.width == side / 8)
                covered += square.width * square.height
            }
        }
        // Spelled with a named CGFloat rather than `800 * 800`: inside the
        // macro that literal comes out an Int, and the comparison then fails
        // against a value that prints identically.
        #expect(covered == side * side)
    }

    /// A piece stands on its square and is photographed from the side, so the
    /// crop has to reach upwards or it catches a base and no piece.
    @Test("The crop for a piece reaches above its square")
    func pieceCropReachesUp() {
        let square = BoardGeometry.square(file: 4, rank: 3, side: 800)
        let crop = BoardGeometry.pieceCrop(file: 4, rank: 3, side: 800)

        #expect(crop.maxY == square.maxY, "the crop must sit on the square")
        #expect(crop.minY < square.minY, "and reach above it")
        #expect(crop.width == square.width)
    }

    @Test("A crop near the top of the board is not taken off the edge")
    func cropIsClampedAtTheTop() {
        let crop = BoardGeometry.pieceCrop(file: 0, rank: 7, side: 800)
        #expect(crop.minY >= 0)
        #expect(crop.maxY <= 800)
    }
}

/// The board's own size, which has to divide into eight without leaving a
/// fraction behind.
@Suite("Sizing the board")
struct BoardSideTests {
    /// Each rank rounding its own boundary while the pieces on it round theirs
    /// is what makes rows look as though they have drifted apart.
    @Test("Every square is a whole number of device pixels")
    func squaresLandOnPixels() {
        for scale in [CGFloat(1), 2, 3] {
            for available in stride(from: CGFloat(200), through: 800, by: 7.3) {
                for rim in [CGFloat(0), 12, 19.03, 41.6] {
                    let side = BoardGeometry.snappedSide(
                        available: available, rim: rim, scale: scale
                    )
                    let pixels = (side / 8) * scale
                    #expect(
                        abs(pixels - pixels.rounded()) < 0.0001,
                        "side \(side) at scale \(scale) gives \(pixels) pixels a square"
                    )
                }
            }
        }
    }

    /// Snapping may only ever take room away, or the board grows out of the
    /// space it was given — which on a phone means off the side of the screen.
    @Test("Snapping never asks for more room than there is")
    func neverGrows() {
        for available in stride(from: CGFloat(100), through: 900, by: 11.7) {
            for rim in [CGFloat(0), 12, 30] {
                let side = BoardGeometry.snappedSide(available: available, rim: rim, scale: 3)
                #expect(side <= available - rim + 0.0001)
                #expect(side > available - rim - 8 / 3 - 0.0001, "and never gives up a whole square")
            }
        }
    }

    @Test("A board with no room is nothing, not a negative")
    func noRoomIsZero() {
        #expect(BoardGeometry.snappedSide(available: 10, rim: 40, scale: 3) == 0)
    }
}
