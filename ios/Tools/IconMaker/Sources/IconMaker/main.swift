import AppKit
import CoreGraphics
import CoreText
import Foundation

// Draws the app icon: a knight on a board-coloured ground.
//
// Generated rather than drawn by hand so it can be regenerated at any size, and
// so the repository carries the recipe instead of an opaque binary.

let size = 1024
let arguments = CommandLine.arguments
let outputPath = arguments.count > 1 ? arguments[1] : "AppIcon.png"

guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("could not create a drawing context") }

let dark = CGColor(red: 0.365, green: 0.294, blue: 0.212, alpha: 1)
let light = CGColor(red: 0.925, green: 0.898, blue: 0.831, alpha: 1)

// A quiet checker pattern rather than a full board: at icon size, eight ranks
// turn into noise.
context.setFillColor(dark)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

let cell = size / 4
context.setFillColor(CGColor(red: 0.408, green: 0.333, blue: 0.243, alpha: 1))
for row in 0..<4 {
    for column in 0..<4 where (row + column) % 2 == 0 {
        context.fill(CGRect(x: column * cell, y: row * cell, width: cell, height: cell))
    }
}

let glyph = "♞" as NSString
let fontSize = CGFloat(size) * 0.62
let font = NSFont(name: "Apple Symbols", size: fontSize)
    ?? NSFont.systemFont(ofSize: fontSize)

let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor(cgColor: light)!,
]
let bounds = glyph.size(withAttributes: attributes)

let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext
glyph.draw(
    at: CGPoint(
        x: (CGFloat(size) - bounds.width) / 2,
        y: (CGFloat(size) - bounds.height) / 2
    ),
    withAttributes: attributes
)
NSGraphicsContext.restoreGraphicsState()

guard let image = context.makeImage() else { fatalError("could not render the icon") }
let bitmap = NSBitmapImageRep(cgImage: image)
guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("could not encode PNG")
}
try data.write(to: URL(fileURLWithPath: outputPath))
print("wrote \(outputPath) (\(size)×\(size))")
