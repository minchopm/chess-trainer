import SwiftUI

/// One control in the bar under the board.
struct ActionItem: Identifiable {
    enum Emphasis { case normal, primary, destructive }

    let id = UUID()
    let title: String
    let systemImage: String
    var emphasis: Emphasis = .normal
    var isEnabled = true
    let action: () -> Void
}

/// The row of controls under the board.
///
/// Icon above a small label, in equal-width slots. Plain buttons of different
/// styles and widths made the row read as a pile of unrelated choices and cost
/// more height than the board could spare; this is one object with one rhythm,
/// and it leaves the space where it belongs — on the position.
struct ActionBar: View {
    let items: [ActionItem]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 5) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 15, weight: .regular))
                        Text(item.title)
                            .font(Face.mono(9, weight: .medium))
                            .tracking(1.1)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ActionPillStyle(emphasis: item.emphasis, enabled: item.isEnabled))
                .disabled(!item.isEnabled)
            }
        }
    }
}

/// The same pill as the site's buttons, sized for a thumb and stacked icon over
/// label. Brass for the move-on action, a hairline ghost for the rest, and the
/// faintest possible fill so the row reads as one control surface without
/// turning into four grey boxes.
private struct ActionPillStyle: ButtonStyle {
    let emphasis: ActionItem.Emphasis
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background {
                BrassPlateShape(cut: 10).fill(background)
            }
            .overlay {
                BrassPlateShape(cut: 10).strokeBorder(border, lineWidth: 0.8)
            }
            .shadow(color: emphasis == .primary ? Theatre.brassGlow : .clear, radius: 12, y: 3)
            .contentShape(BrassPlateShape(cut: 10))
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch emphasis {
        case .primary: Theatre.brassHot
        case .destructive: Theatre.bad
        case .normal: Theatre.ivory
        }
    }

    private var background: AnyShapeStyle {
        switch emphasis {
        case .primary: AnyShapeStyle(LinearGradient(
            colors: [Theatre.ink4, Theatre.ink2],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        case .destructive: AnyShapeStyle(LinearGradient(
            colors: [Theatre.bad.opacity(0.16), Theatre.ink2],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        case .normal: AnyShapeStyle(LinearGradient(
            colors: [Theatre.ink3, Theatre.ink2],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private var border: Color {
        switch emphasis {
        case .primary: Theatre.brassHot.opacity(0.8)
        case .destructive: Theatre.bad.opacity(0.68)
        case .normal: Theatre.brassDeep.opacity(0.5)
        }
    }
}
