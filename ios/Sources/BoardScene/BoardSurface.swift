import CoreGraphics
import Foundation

/// The board surface, drawn rather than downloaded.
///
/// A drawn texture costs nothing to ship and can be re-graded from the palette,
/// which an image cannot. The grain is a few hundred translucent strokes:
/// enough that the squares stop looking like flat colour under a moving light,
/// which is the only job it has.
///
/// 1024px, not 2048. The board is never more than about twelve hundred points
/// wide on screen, so the larger texture buys nothing visible and costs four
/// times the drawing work.
enum BoardSurface {
    /// A fixed sequence, so the board is the same board every launch.
    ///
    /// The site reaches for Math.random here and gets away with it because a
    /// web page is built once and thrown away. A texture that comes out
    /// differently on every launch is a variable in every screenshot taken to
    /// check something else.
    private struct Grain: RandomNumberGenerator {
        private var state: UInt64 = 0x2545F4914F6CDD1D
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
        mutating func unit() -> CGFloat { CGFloat(next() >> 11) / CGFloat(1 << 53) }
        mutating func signed() -> CGFloat { unit() - 0.5 }
    }

    private static let light = (r: 0.788, g: 0.741, b: 0.639)  // #c9bda3
    private static let dark = (r: 0.271, g: 0.239, b: 0.188)   // #453d30

    static func texture(size: Int = 1024) -> CGImage? {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        var grain = Grain()
        let square = CGFloat(size) / 8

        for file in 0..<8 {
            for rank in 0..<8 {
                let isLight = (file + rank) % 2 == 0
                let tone = isLight ? light : dark
                let x = CGFloat(file) * square, y = CGFloat(rank) * square
                ctx.setFillColor(red: tone.r, green: tone.g, blue: tone.b, alpha: 1)
                ctx.fill(CGRect(x: x, y: y, width: square, height: square))

                // Grain, running along the file the square sits in.
                ctx.saveGState()
                ctx.clip(to: CGRect(x: x, y: y, width: square, height: square))
                if isLight {
                    ctx.setStrokeColor(red: 0.353, green: 0.290, blue: 0.188, alpha: 0.09)
                } else {
                    ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 0.22)
                }
                ctx.setLineWidth(1.2 * CGFloat(size) / 1024)
                for _ in 0..<18 {
                    let line = y + grain.unit() * square
                    ctx.move(to: CGPoint(x: x, y: line))
                    ctx.addCurve(
                        to: CGPoint(x: x + square, y: line + grain.signed() * 4),
                        control1: CGPoint(x: x + square * 0.33, y: line + grain.signed() * 7),
                        control2: CGPoint(x: x + square * 0.66, y: line + grain.signed() * 7)
                    )
                    ctx.strokePath()
                }
                ctx.restoreGState()
            }
        }

        // A hairline between the squares, the way an inlaid board actually reads.
        ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 0.32)
        ctx.setLineWidth(2 * CGFloat(size) / 1024)
        for i in 0...8 {
            let offset = CGFloat(i) * square
            ctx.move(to: CGPoint(x: offset, y: 0))
            ctx.addLine(to: CGPoint(x: offset, y: CGFloat(size)))
            ctx.move(to: CGPoint(x: 0, y: offset))
            ctx.addLine(to: CGPoint(x: CGFloat(size), y: offset))
        }
        ctx.strokePath()

        return ctx.makeImage()
    }

    /// Roughness varies with the grain, so the light travels across the wood
    /// instead of sitting on it.
    static func roughness(size: Int = 256) -> CGImage? {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        var grain = Grain()
        ctx.setFillColor(red: 0.478, green: 0.478, blue: 0.478, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))
        for _ in 0..<900 {
            ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: grain.unit() * 0.06)
            ctx.fill(CGRect(
                x: grain.unit() * CGFloat(size), y: grain.unit() * CGFloat(size),
                width: grain.unit() * 16 + 3, height: 1
            ))
        }
        return ctx.makeImage()
    }

    /// Something for the ivory and the brass to reflect, and nothing more.
    ///
    /// Bright at the top, because this stands in for a lit ceiling rather than
    /// for the night sky the camera is actually in. An environment as dark as
    /// the scene reflects nothing, and the ivory loses its sheen.
    /// Two to one, because that is what a sphere unwrapped is. The site can
    /// hand three.js an eight-by-thirty-two strip and say "equirectangular";
    /// SceneKit reads the aspect ratio to decide what it has been given, and a
    /// tall strip is quietly not an environment at all — the ivory loses its
    /// sheen and nothing says why.
    static func environment(width: Int = 512, height: Int = 256) -> CGImage? {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let stops: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.00, 1.000, 0.965, 0.902),  // #fff6e6
            (0.35, 0.784, 0.761, 0.706),  // #c8c2b4
            (0.52, 0.361, 0.376, 0.439),  // #5c6070
            (0.70, 0.133, 0.149, 0.184),  // #22262f
            (1.00, 0.039, 0.043, 0.063),  // #0a0b10
        ]
        let gradient = CGGradient(
            colorsSpace: space,
            colors: stops.map { CGColor(red: $0.1, green: $0.2, blue: $0.3, alpha: 1) } as CFArray,
            locations: stops.map(\.0)
        )
        guard let gradient else { return nil }
        // Top of the image is the top of the sky, so the gradient runs down.
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: CGFloat(height)), end: CGPoint(x: 0, y: 0),
            options: []
        )
        return ctx.makeImage()
    }

    /// A soft round dot, for dust in the light.
    static func dust(size: Int = 64) -> CGImage? {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        let mid = CGFloat(size) / 2
        let gradient = CGGradient(
            colorsSpace: space,
            colors: [
                CGColor(red: 1, green: 1, blue: 1, alpha: 1),
                CGColor(red: 1, green: 1, blue: 1, alpha: 0.45),
                CGColor(red: 1, green: 1, blue: 1, alpha: 0),
            ] as CFArray,
            locations: [0, 0.35, 1]
        )
        guard let gradient else { return nil }
        ctx.drawRadialGradient(
            gradient, startCenter: CGPoint(x: mid, y: mid), startRadius: 0,
            endCenter: CGPoint(x: mid, y: mid), endRadius: mid, options: []
        )
        return ctx.makeImage()
    }
}
