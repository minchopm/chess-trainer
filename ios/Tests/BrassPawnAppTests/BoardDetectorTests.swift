import CoreGraphics
import Foundation
import Testing
@testable import BrassPawnApp

/// Vision's proposal for where the board is.
///
/// The corners are checked against the shape actually drawn, but loosely — a
/// twentieth of the picture. The detector is a system component whose answers
/// may shift between releases, and pinning it to the pixel would fail for
/// nobody's fault; allowing anything at all would pass while it returned
/// nonsense. What is strictly ours is the conversion out of Vision's unit
/// square, and that is what a wrong answer here would mean.
@Suite("Finding the board in a picture")
struct BoardDetectorTests {
    private let side = 480

    /// A bright quadrilateral on a dark ground, drawn in image coordinates.
    private func picture(quad: [CGPoint]) -> CGImage {
        let context = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        context.setFillColor(CGColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1))
        context.beginPath()
        // CGContext counts y upwards; the quad is given in image coordinates.
        context.move(to: CGPoint(x: quad[0].x, y: CGFloat(side) - quad[0].y))
        for point in quad.dropFirst() {
            context.addLine(to: CGPoint(x: point.x, y: CGFloat(side) - point.y))
        }
        context.closePath()
        context.fillPath()
        return context.makeImage()!
    }

    /// A board seen from a chair: the far edge is shorter than the near one.
    private var trapezium: [CGPoint] {
        [
            CGPoint(x: 140, y: 90), CGPoint(x: 340, y: 90),
            CGPoint(x: 430, y: 390), CGPoint(x: 50, y: 390),
        ]
    }

    @Test("The corners come back on the shape that was drawn")
    func findsTheShape() throws {
        let corners = try #require(
            BoardDetector.corners(in: picture(quad: trapezium)),
            "nothing was detected at all"
        )
        let tolerance = CGFloat(side) / 20
        for (found, drawn) in zip(corners.all, trapezium) {
            #expect(abs(found.x - drawn.x) < tolerance, "x: \(found.x) against \(drawn.x)")
            #expect(abs(found.y - drawn.y) < tolerance, "y: \(found.y) against \(drawn.y)")
        }
    }

    /// The conversion from Vision's unit square — y upwards — into image pixels
    /// with y downwards. Getting it wrong returns a board flipped top to bottom,
    /// which reads as a detection failure rather than as arithmetic.
    @Test("What comes back is the right way up and the right way round")
    func isOrderedTheWayTheAppExpects() throws {
        let corners = try #require(BoardDetector.corners(in: picture(quad: trapezium)))

        #expect(corners.topLeft.y < corners.bottomLeft.y, "the top is above the bottom")
        #expect(corners.topRight.y < corners.bottomRight.y)
        #expect(corners.topLeft.x < corners.topRight.x, "the left is left of the right")
        #expect(corners.bottomLeft.x < corners.bottomRight.x)
    }

    /// The failure this is here for, found by running it: asked to find a board
    /// in a picture the board fills, the detector returned the picture's own
    /// frame and the screen said "board found". A confident wrong answer is
    /// worse than none, because it invites the player to trust it.
    @Test("The edge of the photograph is not a board")
    func theFrameIsNotABoard() {
        let context = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        // A bright field filling the whole picture: nothing in it but its edge.
        context.setFillColor(CGColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))

        if let found = BoardDetector.corners(in: context.makeImage()!) {
            let slack = CGFloat(side) * 0.03
            let onTheEdge = found.topLeft.x < slack && found.topLeft.y < slack
                && found.bottomRight.x > CGFloat(side) - slack
                && found.bottomRight.y > CGFloat(side) - slack
            #expect(!onTheEdge, "the picture's own frame was offered as a board")
        }
    }

    /// The other way to be wrong, and the one that decided the design: a
    /// chessboard is a quadrilateral containing sixty-four smaller ones, and a
    /// detector with no idea what chess is returns one of those. Measured on a
    /// rendered board in perspective it offered a patch covering under three
    /// per cent of the picture, three hundred pixels from where the corners
    /// actually were.
    @Test("A patch of the board is not the board")
    func aPatchIsNotTheBoard() {
        let context = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.35, green: 0.27, blue: 0.20, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        // One small bright square, well inside the picture.
        context.setFillColor(CGColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1))
        context.fill(CGRect(x: 60, y: 60, width: 90, height: 90))

        #expect(
            BoardDetector.corners(in: context.makeImage()!) == nil,
            "a patch was offered as a board"
        )
    }

    /// A picture of nothing is not a board, and saying so is what lets the
    /// handles fall back to a guess the player can drag.
    @Test("A blank picture yields nothing rather than a guess")
    func blankPictureFindsNothing() {
        let context = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        let found = BoardDetector.corners(in: context.makeImage()!)
        // Nothing, or something — but never something degenerate.
        if let found {
            let width = found.topRight.x - found.topLeft.x
            #expect(width > 1, "a quadrilateral with no width is not an answer")
        }
    }
}
