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
        HStack(spacing: 6) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 3) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 16, weight: .medium))
                        Text(item.title)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(foreground(for: item))
                .background(background(for: item), in: RoundedRectangle(cornerRadius: 12))
                .opacity(item.isEnabled ? 1 : 0.35)
                .disabled(!item.isEnabled)
            }
        }
    }

    private func foreground(for item: ActionItem) -> Color {
        switch item.emphasis {
        case .primary: .white
        case .destructive: Color(red: 0.90, green: 0.42, blue: 0.38)
        case .normal: .primary
        }
    }

    private func background(for item: ActionItem) -> some ShapeStyle {
        switch item.emphasis {
        case .primary: AnyShapeStyle(Color.accentColor)
        case .destructive, .normal: AnyShapeStyle(.quaternary)
        }
    }
}
