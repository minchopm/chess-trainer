import SwiftUI

/// The house style, carried over from the site.
///
/// A dark theatre: near-black ground, ivory type, one warm light. Every colour
/// is named here so the whole app can be re-graded from one place, which is
/// what the site does and the reason it looks deliberate rather than assembled.
public enum Theatre {
    // Ground
    public static let ink = Color(hex: 0x05060A)
    public static let ink2 = Color(hex: 0x0A0C12)
    public static let ink3 = Color(hex: 0x10131B)
    public static let ink4 = Color(hex: 0x171B26)
    public static let shadow = Color(hex: 0x000000)
    public static let light = Color(hex: 0xFFFFFF)

    // Type
    public static let ivory = Color(hex: 0xE9E4D8)
    public static let ivoryDim = Color(hex: 0xE9E4D8).opacity(0.66)
    public static let ivoryFaint = Color(hex: 0xE9E4D8).opacity(0.42)

    // The one light in the room
    public static let brass = Color(hex: 0xD6A95F)
    public static let brassHot = Color(hex: 0xF0CD8E)
    public static let brassDeep = Color(hex: 0x8A6A2F)
    public static let brassGlow = Color(hex: 0xD6A95F).opacity(0.18)

    // Hairlines
    public static let rule = Color(hex: 0xE9E4D8).opacity(0.12)
    public static let ruleSoft = Color(hex: 0xE9E4D8).opacity(0.06)

    // Verdicts, graded to sit in the same room as the brass.
    public static let good = Color(hex: 0x7FB069)
    public static let warn = Color(hex: 0xD9A441)
    public static let bad = Color(hex: 0xC96A5B)
}

public extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Three faces, the same three the site uses: a Garamond for anything that is
/// announcing something, the system face for prose because it is what the
/// platform reads best, and a monospace for labels — the small-caps-and-
/// tracking treatment that makes a caption look like a title card.
public enum Face {
    /// The scripts the two bundled faces can actually draw.
    ///
    /// Cormorant Garamond has Latin, Cyrillic and the Vietnamese diacritics,
    /// and nothing else: no Greek, Arabic, Hebrew, Devanagari, Thai, or any of
    /// the CJK. JetBrains Mono adds Greek and stops there. The app ships in
    /// thirty-two languages, nine of them in a script neither face has a glyph
    /// for.
    ///
    /// Asking for a face that cannot draw the text does not fail — Core Text
    /// quietly substitutes, glyph by glyph, whatever the system has. So a Thai
    /// heading comes out in the system face at a Garamond's size and spacing,
    /// and a screen that mixes a translated title with a number comes out in
    /// two faces at once. Nothing announces this; it simply stops looking like
    /// the same app.
    ///
    /// So the choice is made deliberately instead: where the house face can
    /// draw the language, it is used; where it cannot, the system's own serif
    /// or monospace is, which is a face designed for that script rather than a
    /// substitution stumbled into.
    private static let scripts = (display: Set(["Latn", "Cyrl"]),
                                  mono: Set(["Latn", "Cyrl", "Grek"]))

    private static let script: String = {
        let language = Locale.current.language
        // Unwritten in the identifier for most languages — "de" does not say
        // Latin — so it has to be filled in from what the language implies.
        return language.script?.identifier
            ?? Locale.Language(identifier: language.maximalIdentifier).script?.identifier
            ?? "Latn"
    }()

    public static func display(_ size: CGFloat) -> Font {
        scripts.display.contains(script)
            ? .custom("CormorantGaramond-SemiBold", size: size)
            : .system(size: size, design: .serif).weight(.semibold)
    }

    public static func displayLight(_ size: CGFloat) -> Font {
        scripts.display.contains(script)
            ? .custom("CormorantGaramond-Light", size: size)
            : .system(size: size, design: .serif).weight(.light)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        scripts.mono.contains(script)
            ? .custom("JetBrainsMono-Regular", size: size).weight(weight)
            : .system(size: size, design: .monospaced).weight(weight)
    }
}

/// A caption in the site's voice: uppercase, tracked out, brass, with a rule
/// running off to the right.
public struct Slug: View {
    let text: String
    var trailingRule = true

    public var body: some View {
        HStack(spacing: 10) {
            Text(text.uppercased())
                .font(Face.mono(10))
                .tracking(3.4)
                .foregroundStyle(Theatre.brass)
            if trailingRule {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Theatre.brassGlow, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
            }
        }
    }
}

/// The card everything sits in: ink, a hairline, and a single highlight along
/// the top edge so it reads as lit rather than drawn.
public struct Panel<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(Theatre.ink3, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Theatre.rule, lineWidth: 0.5)
            )
            .overlay(alignment: .top) {
                LinearGradient(colors: [Theatre.light.opacity(0.06), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 22)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
                    .allowsHitTesting(false)
            }
            .reveal()
    }
}

/// The pill from the site: hairline ghost by default, brass when it is the
/// thing to press.
public struct PillButtonStyle: ButtonStyle {
    public enum Emphasis { case ghost, solid, quiet, danger }

    var emphasis: Emphasis = .ghost
    var enabled = true

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Face.mono(11, weight: .medium))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                BrassPlateShape(cut: 10).fill(background)
            }
            .overlay {
                BrassPlateShape(cut: 10).strokeBorder(border, lineWidth: 0.8)
            }
            .shadow(color: glow, radius: 10, y: 3)
            // A custom style can make the control look larger than its Text
            // label. Keep the interactive area identical to the visible pill.
            .contentShape(BrassPlateShape(cut: 10))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch emphasis {
        case .solid: Theatre.brassHot
        case .ghost: Theatre.ivory
        case .danger: Theatre.bad
        case .quiet: Theatre.ivoryDim
        }
    }

    private var background: AnyShapeStyle {
        switch emphasis {
        case .solid:
            AnyShapeStyle(LinearGradient(
                colors: [Theatre.ink4, Theatre.ink2],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .ghost:
            AnyShapeStyle(LinearGradient(
                colors: [Theatre.ink3, Theatre.ink2],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .quiet:
            AnyShapeStyle(Theatre.ink2)
        case .danger:
            AnyShapeStyle(LinearGradient(
                colors: [Theatre.bad.opacity(0.18), Theatre.ink2],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        }
    }

    private var border: Color {
        switch emphasis {
        case .solid: Theatre.brassHot.opacity(0.82)
        case .ghost: Theatre.brassDeep.opacity(0.55)
        case .quiet: Theatre.ruleSoft
        case .danger: Theatre.bad.opacity(0.75)
        }
    }

    private var glow: Color {
        switch emphasis {
        case .solid: Theatre.brassGlow
        case .danger: Theatre.bad.opacity(0.10)
        case .ghost, .quiet: .clear
        }
    }
}

/// The clipped metal plate used by every interactive surface in the app.
public struct BrassPlateShape: InsettableShape {
    public var cut: CGFloat
    public var insetAmount: CGFloat = 0

    public init(cut: CGFloat, insetAmount: CGFloat = 0) {
        self.cut = cut
        self.insetAmount = insetAmount
    }

    public func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let corner = min(cut, min(bounds.width, bounds.height) / 2)
        // Half the corner value would be a straight bevel. Moving the control
        // point only a little farther inward keeps a restrained concave bow
        // without producing the deep semicircular scallop of the full value.
        let curve = corner * 0.65
        var path = Path()

        // Each corner is carved into the plate with a concave curve. The old
        // straight diagonal read as a clipped rectangle; the inward bow gives
        // buttons the softer ornamental silhouette used by the rest of the
        // brasswork while preserving the same outer measurements.
        path.move(to: CGPoint(x: bounds.minX + corner, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX - corner, y: bounds.minY))
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX, y: bounds.minY + corner),
            control: CGPoint(x: bounds.maxX - curve, y: bounds.minY + curve)
        )
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - corner))
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX - corner, y: bounds.maxY),
            control: CGPoint(x: bounds.maxX - curve, y: bounds.maxY - curve)
        )
        path.addLine(to: CGPoint(x: bounds.minX + corner, y: bounds.maxY))
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX, y: bounds.maxY - corner),
            control: CGPoint(x: bounds.minX + curve, y: bounds.maxY - curve)
        )
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY + corner))
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX + corner, y: bounds.minY),
            control: CGPoint(x: bounds.minX + curve, y: bounds.minY + curve)
        )
        path.closeSubpath()
        return path
    }

    public func inset(by amount: CGFloat) -> BrassPlateShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

public struct BrassPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Labels frequently contain a full-width plate around a small
            // icon or word. The whole plate, not only the opaque glyphs, is
            // the button.
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// The projector never quite stops flickering.
///
/// The site draws this with an SVG noise filter and shifts it four times a
/// second; here it is one tiled texture moved the same way, which costs a
/// texture rather than a filter per frame. It sits above everything and takes
/// no touches, and it holds still for anyone who has asked the system for less
/// motion — a grain that crawls is exactly the kind of movement that setting
/// exists to stop.
public struct FilmGrain: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let steps: [CGSize] = [
        CGSize(width: 0, height: 0),
        CGSize(width: -8, height: 4),
        CGSize(width: 4, height: -8),
        CGSize(width: -4, height: -4),
    ]

    public init() {}

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 0.2)) { context in
            let step = reduceMotion
                ? 0
                : Int(context.date.timeIntervalSinceReferenceDate / 0.2) % Self.steps.count
            Image("grain")
                .resizable(resizingMode: .tile)
                .offset(Self.steps[step])
                // Plain compositing, like the site. An overlay blend does
                // nothing against a ground this dark — it scales the base
                // towards itself, and almost-black scaled towards anything is
                // still almost-black. Measured: zero variance on the
                // background. Laid over at low opacity, the tile lifts the ink
                // a few per cent and the texture is there.
                .opacity(0.045)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// The site's reveal: a panel does not appear, it rises into place.
///
/// The easing is the site's own — a curve that arrives fast and settles — and
/// the distance is small on purpose. Anything further reads as a screen being
/// assembled in front of you rather than as one that was already there.
public struct Reveal: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    var delay: Double = 0

    public func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.55).delay(delay)) {
                    shown = true
                }
            }
    }
}

public extension View {
    func reveal(delay: Double = 0) -> some View { modifier(Reveal(delay: delay)) }
}
