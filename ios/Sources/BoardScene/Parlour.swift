import CoreGraphics
import Foundation

/// The board the walnut set stands on: a framed maple-and-walnut board on a
/// table, under a lamp.
///
/// The app's other board is a theatre. It is an unframed field of squares on a
/// black plinth in a black room, lit by one hard spot from off-stage, and it is
/// very good at what it is for — a title sequence playing famous games to
/// itself. It is also the reason a screenshot of the app does not look like a
/// photograph of a chess board: photographs of chess boards have a frame, a
/// table, and light that comes from a lamp in the room rather than from a
/// lighting rig outside it.
///
/// Three things do most of the work here, and none of them is the pieces:
///
/// **A frame.** A board is a piece of furniture, and the frame is what says so.
/// It also does something for the play: it separates the field from whatever is
/// behind it, so the outermost rank stops floating.
///
/// **An inlay line.** Two hairlines and a light band between the frame and the
/// field. It costs three strokes and it is the single detail that reads as
/// craftsmanship — a frame butted straight onto the squares reads as a printed
/// border however good the grain on either side of it is.
///
/// **Somewhere to stand.** The table. A board on a black void is lit from
/// nowhere and bounces light into nothing; a board on a table sits in a room,
/// and the warm light coming back up off the wood under it is most of what
/// fills in the dark side of the pieces.
///
/// Everything is drawn rather than photographed, for the same reason
/// `BoardSurface` is: a drawn texture ships for nothing and can be re-graded
/// from the numbers, and a photograph of a board cannot be relit.
enum Parlour {
    /// A fixed sequence, so the board is the same board every launch — see
    /// `BoardSurface.Grain`, which this is a copy of for the same reason.
    private struct Grain: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
        mutating func unit() -> CGFloat { CGFloat(next() >> 11) / CGFloat(1 << 53) }
        mutating func signed() -> CGFloat { unit() - 0.5 }
    }

    private typealias Tone = (r: CGFloat, g: CGFloat, b: CGFloat)

    /// Maple and walnut, as the wood is rather than as the lamp leaves it.
    ///
    /// Warmer and more saturated than `BoardSurface`'s pair, which are numbers
    /// measured off an already-lit board. These go under a warm lamp that takes
    /// colour out of what it hits, so they have to start with some to lose.
    private static let maple: Tone = (0.847, 0.737, 0.557)      // #d8bc8e
    private static let walnut: Tone = (0.427, 0.290, 0.204)     // #6d4a34
    /// The frame, which is a darker cut of the same walnut.
    private static let frame: Tone = (0.369, 0.231, 0.153)      // #5e3b27
    /// The boxwood line in the inlay.
    private static let inlay: Tone = (0.878, 0.808, 0.639)      // #e0cea3
    /// The table: oak, old, and darker than any of it.
    private static let oak: Tone = (0.239, 0.157, 0.106)        // #3d281b

    private static func fill(_ ctx: CGContext, _ tone: Tone, _ rect: CGRect) {
        ctx.setFillColor(red: tone.r, green: tone.g, blue: tone.b, alpha: 1)
        ctx.fill(rect)
    }

    private static func context(_ width: Int, _ height: Int) -> CGContext? {
        CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }

    /// Grain: a handful of long translucent strokes, drifting as they run.
    ///
    /// The only job it has is to stop a square looking like flat colour when a
    /// light moves across it. Which means it has to run *along* something — a
    /// square filled with noise reads as sandpaper, and a square with a
    /// direction in it reads as sawn wood.
    private static func grain(_ ctx: CGContext, in rect: CGRect, _ random: inout Grain,
                              strokes: Int, alpha: CGFloat, dark: Bool, along vertical: Bool) {
        ctx.saveGState()
        ctx.clip(to: rect)
        if dark {
            ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: alpha)
        } else {
            ctx.setStrokeColor(red: 0.404, green: 0.290, blue: 0.161, alpha: alpha)
        }
        ctx.setLineWidth(max(0.8, rect.width / 90))
        let run = vertical ? rect.height : rect.width
        let across = vertical ? rect.width : rect.height
        for _ in 0..<strokes {
            let offset = random.unit() * across
            func point(_ along: CGFloat, _ wander: CGFloat) -> CGPoint {
                vertical
                    ? CGPoint(x: rect.minX + offset + wander, y: rect.minY + along)
                    : CGPoint(x: rect.minX + along, y: rect.minY + offset + wander)
            }
            let sway = across * 0.06
            ctx.move(to: point(0, 0))
            ctx.addCurve(
                to: point(run, random.signed() * sway),
                control1: point(run * 0.33, random.signed() * sway * 2),
                control2: point(run * 0.66, random.signed() * sway * 2)
            )
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    /// The playing field: sixty-four squares and nothing else.
    ///
    /// The texture covers exactly the 8×8, with no frame drawn into it. That is
    /// not a stylistic choice — `PlayingBoard.position(of:)` puts a1 at the
    /// corner of an eight-unit field, so a border drawn inside this image would
    /// shift every square out from under the piece standing on it. The frame is
    /// the board's own rim, and it lives in `border(size:)`.
    static func field(size: Int = 1024) -> CGImage? {
        guard let ctx = context(size, size) else { return nil }
        var random = Grain(seed: 0x9E3779B97F4A7C15)
        let square = CGFloat(size) / 8

        for file in 0..<8 {
            for rank in 0..<8 {
                let light = (file + rank) % 2 == 0
                let cell = CGRect(x: CGFloat(file) * square, y: CGFloat(rank) * square,
                                  width: square, height: square)
                fill(ctx, light ? maple : walnut, cell)
                // The grain runs along the file on light squares and across it
                // on dark ones, because that is how a board is veneered: a
                // sheet is cut into squares and alternate squares are turned
                // ninety degrees. It is why a real board shimmers as you lean
                // over it and a painted one does not.
                grain(ctx, in: cell, &random, strokes: 16, alpha: light ? 0.10 : 0.17,
                      dark: !light, along: light)
            }
        }

        // A hairline between the squares, the way an inlaid board reads.
        ctx.setStrokeColor(red: 0.11, green: 0.06, blue: 0.03, alpha: 0.30)
        ctx.setLineWidth(1.6 * CGFloat(size) / 1024)
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

    /// The frame, drawn onto the whole top of the board block.
    ///
    /// Only the ring outside the field is ever seen — the field sits on top of
    /// the middle of it — but the middle is drawn anyway rather than left
    /// transparent, so that a board built with the field switched off, or one
    /// seen edge-on where the two surfaces are a hair apart, is still walnut
    /// rather than a hole.
    ///
    /// `boardShare` is the field's share of the block's width, and it has to be
    /// the same fraction the geometry uses or the inlay lands on the squares.
    static func border(size: Int = 1024, boardShare: CGFloat = 8.0 / 9.1) -> CGImage? {
        guard let ctx = context(size, size) else { return nil }
        let side = CGFloat(size)
        let rim = side * (1 - boardShare) / 2
        var random = Grain(seed: 0xD1B54A32D192ED03)

        fill(ctx, frame, CGRect(x: 0, y: 0, width: side, height: side))

        // Mitred, which means the grain on each of the four sides runs along
        // that side and the four meet on the diagonals. Drawn as one sheet of
        // grain instead, the corners come out with the grain running straight
        // through them — which is what a printed board looks like, and is the
        // giveaway from any angle that shows two sides at once.
        for side_ in 0..<4 {
            ctx.saveGState()
            ctx.translateBy(x: side / 2, y: side / 2)
            ctx.rotate(by: CGFloat(side_) * .pi / 2)
            ctx.translateBy(x: -side / 2, y: -side / 2)
            // The mitre: the trapezoid this side owns, from the outer edge in
            // to the field, closing at forty-five degrees at both ends.
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 0, y: 0))
            ctx.addLine(to: CGPoint(x: side, y: 0))
            ctx.addLine(to: CGPoint(x: side - rim, y: rim))
            ctx.addLine(to: CGPoint(x: rim, y: rim))
            ctx.closePath()
            ctx.clip()
            grain(ctx, in: CGRect(x: 0, y: 0, width: side, height: rim), &random,
                  strokes: 22, alpha: 0.20, dark: true, along: false)
            // A soft highlight along the outer edge, where a moulded rim
            // catches the light whichever way the board is turned.
            ctx.setStrokeColor(red: 0.71, green: 0.52, blue: 0.35, alpha: 0.34)
            ctx.setLineWidth(rim * 0.16)
            ctx.move(to: CGPoint(x: 0, y: rim * 0.08))
            ctx.addLine(to: CGPoint(x: side, y: rim * 0.08))
            ctx.strokePath()
            ctx.restoreGState()
        }

        // The inlay: a dark hairline, a band of boxwood, and a second dark
        // hairline, laid in the walnut just outside the squares. Three strokes,
        // and the reason the board looks made rather than printed.
        //
        // Measured in board units from the *outer* edge inwards, because that
        // is where the geometry's edge is and a band placed relative to the
        // field would move if the rim's width ever changed. One unit is one
        // square, which is `side * boardShare / 8` pixels.
        let unit = side * boardShare / 8
        func band(from: CGFloat, through: CGFloat, _ tone: Tone, _ alpha: CGFloat) {
            let middle = (from + through) / 2 * unit
            ctx.setStrokeColor(red: tone.r, green: tone.g, blue: tone.b, alpha: alpha)
            ctx.setLineWidth((through - from) * unit)
            ctx.stroke(CGRect(x: middle, y: middle,
                              width: side - 2 * middle, height: side - 2 * middle))
        }
        let hairline: Tone = (0.110, 0.063, 0.031)
        band(from: 0.445, through: 0.465, hairline, 0.88)
        band(from: 0.465, through: 0.525, inlay, 1.0)
        band(from: 0.525, through: 0.550, hairline, 0.88)

        return ctx.makeImage()
    }

    /// The files and ranks, cut from the same boxwood as the inlay line.
    ///
    /// `BoardSurface.coordinates` draws them; this only says what they are made
    /// of, and it lives here so the number sits beside the `inlay` it has to
    /// match. On the theatre's black plinth the letters are paint — pale grey
    /// on a dark ground, which is what a printed board has. On a walnut frame
    /// with a boxwood line already running round it, paint is the one thing
    /// they cannot be: a board like this has its letters *inlaid*, in the same
    /// wood, and grey ones read as a label stuck to the furniture.
    static func letters(size: Int = 1024, boardShare: CGFloat = 8.0 / 9.1) -> CGImage? {
        BoardSurface.coordinates(size: size, boardShare: boardShare,
                                 ink: (inlay.r, inlay.g, inlay.b, 0.88))
    }

    /// The table, in sawn planks.
    ///
    /// Wide boards with a dark seam between them and one or two knots, because
    /// the reference's table is old and the board is standing on the join
    /// between two of its planks. It is far darker than the chess board: it has
    /// to read as the thing underneath, and a table as bright as the field
    /// competes with the squares for the eye.
    static func planks(size: Int = 1024, boards: Int = 5) -> CGImage? {
        guard let ctx = context(size, size) else { return nil }
        let side = CGFloat(size)
        var random = Grain(seed: 0x2545F4914F6CDD1D)
        fill(ctx, oak, CGRect(x: 0, y: 0, width: side, height: side))

        let plank = side / CGFloat(boards)
        for board in 0..<boards {
            let strip = CGRect(x: 0, y: CGFloat(board) * plank, width: side, height: plank)
            // Each plank a shade different from its neighbours, which is most
            // of what makes them read as separate boards rather than as one
            // surface with lines drawn on it.
            // Barely different from its neighbours. Half a stop between planks
            // is enough to read as separate boards; a whole one and the table
            // is stripes, which competes with the squares.
            let shade = 0.90 + random.unit() * 0.18
            fill(ctx, (oak.r * shade, oak.g * shade, oak.b * shade), strip)
            grain(ctx, in: strip, &random, strokes: 26, alpha: 0.26, dark: true, along: false)

            // A knot or two. Rings rather than a blob: a filled ellipse reads
            // as a stain.
            if random.unit() > 0.45 {
                let centre = CGPoint(x: random.unit() * side,
                                     y: strip.midY + random.signed() * plank * 0.5)
                ctx.saveGState()
                ctx.clip(to: strip)
                for ring in 0..<5 {
                    let radius = plank * (0.05 + CGFloat(ring) * 0.035)
                    ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 0.30 - CGFloat(ring) * 0.05)
                    ctx.setLineWidth(max(1, plank * 0.018))
                    ctx.strokeEllipse(in: CGRect(x: centre.x - radius * 1.7, y: centre.y - radius,
                                                 width: radius * 3.4, height: radius * 2))
                }
                ctx.restoreGState()
            }

            // The seam, and the light on the lip of the plank below it.
            ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 0.62)
            ctx.setLineWidth(max(1.5, side / 420))
            ctx.move(to: CGPoint(x: 0, y: strip.minY))
            ctx.addLine(to: CGPoint(x: side, y: strip.minY))
            ctx.strokePath()
            ctx.setStrokeColor(red: 0.51, green: 0.36, blue: 0.24, alpha: 0.16)
            ctx.setLineWidth(max(1, side / 640))
            ctx.move(to: CGPoint(x: 0, y: strip.minY + side / 380))
            ctx.addLine(to: CGPoint(x: side, y: strip.minY + side / 380))
            ctx.strokePath()
        }
        return ctx.makeImage()
    }

    /// The wall behind, as the lamp lights it.
    ///
    /// A gradient rather than a texture, and it is doing a job rather than
    /// decorating: it is what the board's far edge is seen *against*. In the
    /// theatre that job is done by nothing — the far edge meets black and the
    /// board simply stops — which is right for a shot lit from off-stage and
    /// wrong for a room.
    static func wall(width: Int = 256, height: Int = 256) -> CGImage? {
        guard let ctx = context(width, height) else { return nil }
        let stops: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.00, 0.086, 0.071, 0.059),
            (0.42, 0.180, 0.145, 0.114),
            (0.74, 0.310, 0.251, 0.192),
            (1.00, 0.408, 0.333, 0.255),
        ]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: stops.map { CGColor(red: $0.1, green: $0.2, blue: $0.3, alpha: 1) } as CFArray,
            locations: stops.map(\.0)
        ) else { return nil }
        // Brightest at the bottom, which is where the lamp is: a lamp on a side
        // table lights the wall from below its own shade, and the pool of light
        // on the wall falls off upwards.
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: CGFloat(height)),
                               end: CGPoint(x: 0, y: 0), options: [])
        return ctx.makeImage()
    }

    /// Something for the boxwood to reflect: a lit room rather than a lit stage.
    ///
    /// Two to one, because that is what a sphere unwrapped is — SceneKit reads
    /// the aspect ratio to decide what it has been handed, and a strip of any
    /// other shape is quietly not an environment at all.
    static func environment(width: Int = 512, height: Int = 256) -> CGImage? {
        guard let ctx = context(width, height) else { return nil }
        let stops: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.00, 0.988, 0.933, 0.824),   // the ceiling the lamp is throwing at
            (0.30, 0.706, 0.620, 0.502),
            (0.52, 0.404, 0.333, 0.263),
            (0.74, 0.204, 0.163, 0.125),
            (1.00, 0.106, 0.086, 0.067),   // the table, which is what is under it
        ]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: stops.map { CGColor(red: $0.1, green: $0.2, blue: $0.3, alpha: 1) } as CFArray,
            locations: stops.map(\.0)
        ) else { return nil }
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: CGFloat(height)),
                               end: CGPoint(x: 0, y: 0), options: [])
        return ctx.makeImage()
    }
}
