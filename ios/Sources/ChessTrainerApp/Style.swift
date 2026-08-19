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
    public static func display(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-SemiBold", size: size)
    }

    public static func displayLight(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Light", size: size)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .custom("JetBrainsMono-Regular", size: size).weight(weight)
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
                LinearGradient(colors: [Color.white.opacity(0.06), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 22)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
                    .allowsHitTesting(false)
            }
    }
}

/// The pill from the site: hairline ghost by default, brass when it is the
/// thing to press.
public struct PillButtonStyle: ButtonStyle {
    public enum Emphasis { case ghost, solid, quiet }

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
            .background(background, in: Capsule())
            .overlay(Capsule().strokeBorder(border, lineWidth: 0.75))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch emphasis {
        case .solid: Color(hex: 0x120E06)
        case .ghost: Theatre.ivory
        case .quiet: Theatre.ivoryDim
        }
    }

    private var background: Color {
        switch emphasis {
        case .solid: Theatre.brass
        case .ghost, .quiet: Color.white.opacity(0.03)
        }
    }

    private var border: Color {
        switch emphasis {
        case .solid: Theatre.brass
        case .ghost: Theatre.rule
        case .quiet: Theatre.ruleSoft
        }
    }
}
