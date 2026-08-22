import ChessCore
import CoreGraphics
import Foundation
import Testing
@testable import BrassPawnApp

/// Straightening a photograph out.
@Suite("Straightening a photographed board")
struct BoardPhotoTests {
    private let side = 240

    /// A black square with a white patch in one corner, named in image
    /// coordinates — y downwards, the way a tap on a picture reads.
    private func image(patchAt corner: (x: Int, y: Int)) -> CGImage {
        let context = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        // CGContext counts y upwards, so an image-coordinate y is flipped here.
        let patch = 48
        context.fill(CGRect(
            x: corner.x, y: side - corner.y - patch, width: patch, height: patch
        ))
        return context.makeImage()!
    }

    /// Mean brightness of a corner of an image, in image coordinates.
    private func brightness(of image: CGImage, atTopLeft: Bool) -> Double {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Rows are laid out top first, so the top-left of the image is row 0.
        let rows = atTopLeft ? (0..<height / 8) : ((height - height / 8)..<height)
        var total = 0.0
        var count = 0
        for row in rows {
            for column in 0..<(width / 8) {
                total += Double(pixels[(row * width + column) * 4])
                count += 1
            }
        }
        return total / Double(max(1, count))
    }

    /// The bug this is here for: Core Image counts y upwards and a tap counts
    /// it downwards, and getting that wrong produces a board upside down rather
    /// than an error — which is the kind of mistake that survives a review.
    @Test("Straightening a picture by its own corners leaves it the way up it was")
    func rectifyingKeepsTheWayUp() throws {
        let source = image(patchAt: (x: 0, y: 0))          // white patch, top left
        let corners = BoardGeometry.Corners(
            topLeft: .init(x: 0, y: 0),
            topRight: .init(x: side, y: 0),
            bottomRight: .init(x: side, y: side),
            bottomLeft: .init(x: 0, y: side)
        )
        let rectified = try #require(BoardPhoto.rectify(source, corners: corners))

        #expect(brightness(of: rectified, atTopLeft: true) > 200, "the patch left the top")
        #expect(brightness(of: rectified, atTopLeft: false) < 55, "something arrived at the bottom")
    }

    @Test("A patch at the bottom stays at the bottom")
    func rectifyingKeepsTheBottom() throws {
        let source = image(patchAt: (x: 0, y: side - 48))
        let corners = BoardGeometry.Corners(
            topLeft: .init(x: 0, y: 0),
            topRight: .init(x: side, y: 0),
            bottomRight: .init(x: side, y: side),
            bottomLeft: .init(x: 0, y: side)
        )
        let rectified = try #require(BoardPhoto.rectify(source, corners: corners))

        #expect(brightness(of: rectified, atTopLeft: false) > 200)
        #expect(brightness(of: rectified, atTopLeft: true) < 55)
    }

    @Test("Straightening produces a square of the size the cutter expects")
    func rectifiedIsTheExpectedSquare() throws {
        let source = image(patchAt: (x: 0, y: 0))
        let corners = BoardGeometry.Corners(
            topLeft: .init(x: 10, y: 20),
            topRight: .init(x: 200, y: 5),
            bottomRight: .init(x: 230, y: 210),
            bottomLeft: .init(x: 0, y: 190)
        )
        let rectified = try #require(BoardPhoto.rectify(source, corners: corners))
        #expect(rectified.width == Int(BoardPhoto.side))
        #expect(rectified.height == Int(BoardPhoto.side))
    }

    @Test("A straightened board cuts into sixty-four crops, one per square")
    func cutsIntoSixtyFour() throws {
        let source = image(patchAt: (x: 0, y: 0))
        let corners = BoardGeometry.Corners(
            topLeft: .init(x: 0, y: 0),
            topRight: .init(x: side, y: 0),
            bottomRight: .init(x: side, y: side),
            bottomLeft: .init(x: 0, y: side)
        )
        let rectified = try #require(BoardPhoto.rectify(source, corners: corners))
        let crops = BoardPhoto.crops(from: rectified)

        #expect(crops.count == 64)
        #expect(Set(crops.map(\.square)).count == 64, "every square is covered exactly once")
        #expect(crops.allSatisfy { $0.image.width > 0 && $0.image.height > 0 })
    }

    /// Until there is a model, the reader recognises nothing — and says so by
    /// returning nothing, rather than by guessing at an empty board.
    @Test("The unread board reads nothing")
    func unreadBoardIsEmpty() async throws {
        let source = image(patchAt: (x: 0, y: 0))
        let corners = BoardGeometry.Corners(
            topLeft: .init(x: 0, y: 0), topRight: .init(x: side, y: 0),
            bottomRight: .init(x: side, y: side), bottomLeft: .init(x: 0, y: side)
        )
        let rectified = try #require(BoardPhoto.rectify(source, corners: corners))
        let found = await UnreadBoard().read(BoardPhoto.crops(from: rectified))
        #expect(found.isEmpty)
    }
}
