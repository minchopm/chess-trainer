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
    /// The faintest ivory the app writes in.
    ///
    /// It was 0.42, which is fine behind a title and not fine under one: nearly
    /// every small label in the app is set in this, and at nine points on near
    /// black it was a grey smudge rather than a word.
    public static let ivoryFaint = Color(hex: 0xE9E4D8).opacity(0.58)

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
