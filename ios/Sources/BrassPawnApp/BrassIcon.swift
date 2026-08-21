import SwiftUI

/// Loads the app's polished brass artwork for icons that exist in the asset
/// catalog, while keeping an SF Symbol fallback for unrelated platform UI.
struct BrassIcon: View {
    let name: String
    let size: CGFloat

    init(_ name: String, size: CGFloat = 20) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Group {
            if Self.assetNames.contains(name) {
                Image(name)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
            } else {
                Image(systemName: name)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private static let assetNames: Set<String> = [
        "arrow.clockwise", "arrow.counterclockwise", "arrow.uturn.backward", "arrow.up.right",
        "backward.end.fill", "backward.fill", "backward.frame",
        "bolt.horizontal.circle", "chart.line.uptrend.xyaxis",
        "checkmark.circle", "checkmark.circle.fill", "chevron.backward", "chevron.down",
        "chevron.left", "chevron.right", "clock", "crown.fill", "cube", "creditcard", "doc.text",
        "equal.circle", "exclamationmark.triangle", "eye", "flag.checkered",
        "flag.fill", "forward.end", "forward.end.fill", "forward.fill",
        "forward.frame", "gearshape", "infinity", "lightbulb", "lock.shield",
        "magnifyingglass", "number.square", "pause.fill", "play.fill",
        "play.rectangle", "plus.circle", "questionmark.circle", "speaker.slash.fill",
        "speaker.wave.2.fill", "sparkles", "square.grid.3x3",
        "square.grid.3x3.middle.filled", "stop.circle", "target", "trophy.fill",
        "trash", "xmark.circle", "xmark.circle.fill", "timer", "chess",
    ]
}
