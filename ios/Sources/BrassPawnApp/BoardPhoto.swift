import ChessCore
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// A photograph of a board, straightened out and cut into squares.
///
/// Everything here is geometry — no model, no weights, no licence. What it
/// produces is sixty-four little pictures and their squares, which is the input
/// a classifier wants and the thing a classifier cannot do for itself.
enum BoardPhoto {
    /// How big a rectified board is made.
    ///
    /// Eight hundred gives each square a hundred pixels, and each piece crop
    /// rather more than that vertically — enough for a small classifier without
    /// carrying a photograph's worth of pixels around.
    static let side: CGFloat = 800

    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Straighten the board out.
    ///
    /// Corners arrive in image coordinates, y downwards, because that is what a
    /// tap on a picture gives you. Core Image counts y upwards, so they are
    /// flipped on the way in — a mismatch that produces a board upside down
    /// rather than an error, which is the kind of bug that survives a review.
    static func rectify(_ image: CGImage, corners: BoardGeometry.Corners) -> CGImage? {
        let source = CIImage(cgImage: image)
        let height = CGFloat(image.height)
        func flipped(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x, y: height - point.y) }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = source
        filter.topLeft = flipped(corners.topLeft)
        filter.topRight = flipped(corners.topRight)
        filter.bottomRight = flipped(corners.bottomRight)
        filter.bottomLeft = flipped(corners.bottomLeft)
        guard let corrected = filter.outputImage else { return nil }

        // Scaled to a fixed square so every square crop is the same size
        // whatever the photograph was, which is what a classifier expects.
        let extent = corrected.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        let scaled = corrected.transformed(by: CGAffineTransform(
            scaleX: side / extent.width, y: side / extent.height
        ))
        return context.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: side, height: side))
    }

    /// One crop per square, with the square it belongs to.
    ///
    /// The board is taken as a8 at the top left, which is what the corner
    /// ordering produces: the first corner named is the one nearest the top
    /// left of the picture. Which way round the board actually faces is a
    /// separate question, and one the player answers by turning it.
    static func crops(from rectified: CGImage) -> [(square: Square, image: CGImage)] {
        var result: [(Square, CGImage)] = []
        for file in 0..<8 {
            for rank in 0..<8 {
                let rect = BoardGeometry.pieceCrop(file: file, rank: rank, side: side)
                guard let crop = rectified.cropping(to: rect) else { continue }
                result.append((Square(file: file, rank: rank), crop))
            }
        }
        return result
    }
}

/// What a classifier has to do.
///
/// A protocol rather than a concrete model because the model is the one part of
/// this that is not written yet, and everything around it — the photograph, the
/// corners, the rectification, the editor that corrects the answer — is worth
/// having before it arrives.
protocol SquareReader: Sendable {
    /// What is standing on each square. A square left out of the answer is one
    /// the reader could not call, which is not the same as an empty square.
    func read(_ crops: [(square: Square, image: CGImage)]) async -> [Square: Piece]
}

/// The reader used until there is a model: it recognises nothing.
///
/// Not a placeholder that pretends. A photograph read by this gives an empty
/// board with the perspective taken out, which is a real head start on setting
/// a position up by hand and is honest about what it did.
struct UnreadBoard: SquareReader {
    func read(_ crops: [(square: Square, image: CGImage)]) async -> [Square: Piece] { [:] }
}
