import CoreGraphics
import Foundation
import Vision

/// Finding the board in a photograph, so the handles start somewhere useful.
///
/// Vision proposes; the player disposes. A chessboard is a strong quadrilateral
/// full of *other* strong quadrilaterals, and a generic detector will sometimes
/// lock onto an inner block of squares rather than the outer edge. That is fine
/// as long as the answer is a starting position for four handles somebody can
/// drag, and not a verdict.
///
/// Nothing here ships: both requests are in the system, which is the whole
/// reason to prefer them to a model of our own for this particular step.
enum BoardDetector {
    /// The board's four corners in the picture's own pixels, y downwards, or
    /// nil when nothing convincing was found.
    static func corners(in image: CGImage) -> BoardGeometry.Corners? {
        // Rectangles first. Document segmentation was tried first at one point
        // and it is the wrong tool: asked for a page and given a picture that a
        // board fills, it returns the picture's own frame — confidently, with
        // the handles landing on the corners of the photograph rather than the
        // corners of the board. It is kept only as a second opinion.
        if let found = rectangleQuad(in: image), isPlausible(found, in: image) { return found }
        if let found = documentQuad(in: image), isPlausible(found, in: image) { return found }
        return nil
    }

    /// Whether a proposal is worth offering.
    ///
    /// Two ways to be wrong, both seen while building this. Too big and it is
    /// the photograph's own frame. Too small and it is a block of squares from
    /// inside the board — a chessboard is a quadrilateral containing sixty-four
    /// smaller ones, and a detector with no idea what chess is will happily
    /// return one of those. Measured on a rendered board it came back with a
    /// patch covering under three per cent of the picture.
    ///
    /// A wrong proposal is worse than none: four handles in the wrong place all
    /// have to be dragged, where four handles set neutrally are at least
    /// obviously a starting point.
    private static func isPlausible(
        _ corners: BoardGeometry.Corners, in image: CGImage
    ) -> Bool {
        let width = CGFloat(image.width), height = CGFloat(image.height)
        guard !isTheWholeFrame(corners, in: image) else { return false }

        let points = corners.all
        var total: CGFloat = 0
        for index in points.indices {
            let a = points[index], b = points[(index + 1) % points.count]
            total += a.x * b.y - b.x * a.y
        }
        guard abs(total) / 2 >= width * height * 0.25 else { return false }
        return isBoardShaped(points)
    }

    /// Whether a quadrilateral could be a square seen from somewhere.
    ///
    /// Area alone is not enough: a detector grasping at a picture returns large
    /// skewed shapes that pass any size test — one came back with a left side of
    /// ninety pixels against a right side of four hundred and seventy-six, which
    /// no board seen from any chair has ever looked like.
    ///
    /// Two conditions. It must be convex, because a square in perspective is,
    /// and a bow tie is a mis-detection. And opposite sides must be within about
    /// three times each other: perspective shortens the far edge, but a board
    /// photographed to be read is not shortened to a quarter.
    private static func isBoardShaped(_ points: [CGPoint]) -> Bool {
        guard points.count == 4 else { return false }

        var sign: CGFloat = 0
        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % 4]
            let c = points[(index + 2) % 4]
            let cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
            if cross != 0 {
                if sign == 0 { sign = cross > 0 ? 1 : -1 }
                else if (cross > 0 ? 1 : -1) != sign { return false }
            }
        }

        func length(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }
        let top = length(points[0], points[1]), bottom = length(points[3], points[2])
        let left = length(points[0], points[3]), right = length(points[1], points[2])
        for (one, other) in [(top, bottom), (left, right)] {
            let smaller = min(one, other), larger = max(one, other)
            guard smaller > 0, larger / smaller <= 3 else { return false }
        }
        return true
    }

    /// Whether a quadrilateral is really just the edge of the photograph.
    ///
    /// A board photographed to be read fills a good deal of the frame, which is
    /// exactly what makes this worth checking rather than assuming: the frame
    /// and the board are then similar in size, and a detector that has found the
    /// frame looks from the numbers alone as though it has found the board. What
    /// gives it away is the corners sitting on the corners of the picture.
    private static func isTheWholeFrame(
        _ corners: BoardGeometry.Corners, in image: CGImage
    ) -> Bool {
        let width = CGFloat(image.width), height = CGFloat(image.height)
        let slack = min(width, height) * 0.02
        let picture = [
            CGPoint(x: 0, y: 0), CGPoint(x: width, y: 0),
            CGPoint(x: width, y: height), CGPoint(x: 0, y: height),
        ]
        return zip(corners.all, picture).allSatisfy { found, edge in
            abs(found.x - edge.x) <= slack && abs(found.y - edge.y) <= slack
        }
    }

    private static func documentQuad(in image: CGImage) -> BoardGeometry.Corners? {
        let request = VNDetectDocumentSegmentationRequest()
        guard let observation = perform(request, on: image)?.first as? VNRectangleObservation
        else { return nil }
        return convert(observation, width: image.width, height: image.height)
    }

    private static func rectangleQuad(in image: CGImage) -> BoardGeometry.Corners? {
        let request = VNDetectRectanglesRequest()
        // A board photographed from a chair is a long way from square on the
        // sensor, so the tolerances are wide and the filtering is done after.
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.quadratureTolerance = 45
        request.minimumConfidence = 0.3
        // Enough of the frame to be the subject. A board photographed to be
        // read is not a detail in the corner of the picture.
        request.minimumSize = 0.2
        request.maximumObservations = 8

        guard let results = perform(request, on: image) as? [VNRectangleObservation] else { return nil }
        // The largest, because the outer edge of the board encloses every other
        // quadrilateral the detector will have found inside it.
        guard let biggest = results.max(by: { area(of: $0) < area(of: $1) }) else { return nil }
        return convert(biggest, width: image.width, height: image.height)
    }

    private static func perform(_ request: VNRequest, on image: CGImage) -> [VNObservation]? {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let results = request.results, !results.isEmpty else { return nil }
        return results
    }

    private static func area(of observation: VNRectangleObservation) -> CGFloat {
        let points = [
            observation.topLeft, observation.topRight,
            observation.bottomRight, observation.bottomLeft,
        ]
        var total: CGFloat = 0
        for index in points.indices {
            let a = points[index], b = points[(index + 1) % points.count]
            total += a.x * b.y - b.x * a.y
        }
        return abs(total) / 2
    }

    /// Vision reports in a unit square with y upwards; a picture is measured in
    /// pixels with y downwards. Getting this wrong hands back a board flipped
    /// top to bottom, which looks like a detection failure rather than an
    /// arithmetic one.
    private static func convert(
        _ observation: VNRectangleObservation, width: Int, height: Int
    ) -> BoardGeometry.Corners? {
        func point(_ unit: CGPoint) -> CGPoint {
            CGPoint(x: unit.x * CGFloat(width), y: (1 - unit.y) * CGFloat(height))
        }
        // Ordered rather than trusted: Vision's names are its own, and the
        // ordering rule the rest of the app uses is the one that has tests.
        return BoardGeometry.order([
            point(observation.topLeft), point(observation.topRight),
            point(observation.bottomRight), point(observation.bottomLeft),
        ])
    }
}
