import CoreGraphics
import Foundation

/// Turning four tapped points into a board.
///
/// The corners are tapped rather than found. Board detection by line-finding is
/// the part of every published pipeline that breaks on real photographs — the
/// best-measured one locates the board in 34% of phone photos, and every error
/// after that is downstream of the miss. Four taps cost the player a moment and
/// take that failure to nothing.
enum BoardGeometry {
    /// The four corners, named, whatever order they were tapped in.
    struct Corners: Equatable {
        var topLeft: CGPoint
        var topRight: CGPoint
        var bottomRight: CGPoint
        var bottomLeft: CGPoint

        var all: [CGPoint] { [topLeft, topRight, bottomRight, bottomLeft] }
    }

    /// Sort four taps into corners.
    ///
    /// Inferred rather than demanded in a fixed order: asking somebody to start
    /// at a particular corner is asking them to get it wrong on a board that is
    /// upside down to them. The points are put in a ring around their own
    /// centre, and the one nearest the top left of the picture is called the
    /// top left.
    ///
    /// Image coordinates, y downwards. Returns nil unless there are exactly
    /// four points and they make a quadrilateral with some area to it — four
    /// taps in nearly a line are a mis-tap, not a board.
    static func order(_ points: [CGPoint]) -> Corners? {
        guard points.count == 4 else { return nil }

        let centre = CGPoint(
            x: points.map(\.x).reduce(0, +) / 4,
            y: points.map(\.y).reduce(0, +) / 4
        )
        let ring = points.sorted {
            atan2($0.y - centre.y, $0.x - centre.x) < atan2($1.y - centre.y, $1.x - centre.x)
        }

        guard let start = ring.enumerated().min(by: { $0.element.x + $0.element.y < $1.element.x + $1.element.y })?.offset
        else { return nil }

        let rotated = (0..<4).map { ring[(start + $0) % 4] }
        let corners = Corners(
            topLeft: rotated[0], topRight: rotated[1],
            bottomRight: rotated[2], bottomLeft: rotated[3]
        )
        guard area(of: rotated) > 1 else { return nil }
        return corners
    }

    /// Twice the signed area, by the shoelace formula. Sign is discarded: which
    /// way round the ring runs depends on the photograph, not on the board.
    private static func area(of points: [CGPoint]) -> CGFloat {
        var total: CGFloat = 0
        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            total += a.x * b.y - b.x * a.y
        }
        return abs(total) / 2
    }

    /// The largest board side that puts a whole number of device pixels in
    /// every square.
    ///
    /// Left to itself the side is whatever is left after the rim, and a square
    /// is an eighth of that — a fraction. Each rank then rounds its own
    /// boundary independently while the pieces drawn on it round theirs, and a
    /// rank can end up a pixel out of step with the one above. It reads as rows
    /// drifting rather than as a fault, which is why it is worth making
    /// impossible rather than watching for.
    static func snappedSide(available: CGFloat, rim: CGFloat, scale: CGFloat) -> CGFloat {
        let step = 8 / max(scale, 1)
        let side = max(0, available - rim)
        return (side / step).rounded(.down) * step
    }

    /// The square of a rectified board, as a fraction of its side.
    ///
    /// `file` and `rank` are the chess ones — file 0 is the a-file, rank 0 is
    /// rank 1 — and the board is assumed rectified with a8 at the top left,
    /// which is what the corner order produces.
    static func square(file: Int, rank: Int, side: CGFloat) -> CGRect {
        let step = side / 8
        return CGRect(
            x: CGFloat(file) * step,
            y: CGFloat(7 - rank) * step,
            width: step, height: step
        )
    }

    /// The crop to classify for one square.
    ///
    /// Taller than the square itself and reaching upwards, because a piece
    /// stands *on* its square and is photographed from the side: the square
    /// alone holds a base and no piece. The extra height is the cost of seeing
    /// what is standing there.
    static func pieceCrop(file: Int, rank: Int, side: CGFloat, heightMultiple: CGFloat = 2.4) -> CGRect {
        let base = square(file: file, rank: rank, side: side)
        let tall = base.height * heightMultiple
        return CGRect(
            x: base.minX,
            y: max(0, base.maxY - tall),
            width: base.width,
            height: min(tall, base.maxY)
        )
    }
}
