import SwiftUI

/// The shape every training mode takes: board, then a panel, then controls.
///
/// On a phone that stacks vertically with the board on top; in landscape or on
/// an iPad the panel moves beside it, because a board squeezed into half the
/// height of a landscape screen is unusable.
struct TrainingLayout<Board: View, Panel: View, Controls: View>: View {
    @ViewBuilder var board: Board
    @ViewBuilder var panel: Panel
    @ViewBuilder var controls: Controls

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            if isWide {
                HStack(alignment: .top, spacing: 16) {
                    board.padding(.leading, 12).padding(.vertical, 12)
                    VStack(spacing: 12) {
                        ScrollView { VStack(spacing: 12) { panel }.padding(.trailing, 12) }
                        controls.padding(.trailing, 12)
                    }
                    .padding(.vertical, 12)
                }
            } else {
                VStack(spacing: 12) {
                    board.padding(.horizontal, 12).padding(.top, 8)
                    ScrollView { VStack(spacing: 12) { panel }.padding(.horizontal, 12) }
                    controls.padding(.horizontal, 12).padding(.bottom, 8)
                }
            }
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TagRow: View {
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Wraps its children onto as many lines as they need. SwiftUI has no built-in
/// equivalent, and a tag row that clips is worse than one that wraps.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var rows = 1.0
        var x = 0.0
        var rowHeight = 0.0
        var total = 0.0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                total += rowHeight + spacing
                rows += 1
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: total + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight = 0.0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct FeedbackCard: View {
    let feedback: TacticsModel.Feedback

    var body: some View {
        Card {
            HStack(spacing: 8) {
                Rectangle().fill(tone).frame(width: 3)
                VStack(alignment: .leading, spacing: 6) {
                    Text(feedback.title).font(.subheadline.weight(.semibold))
                    ForEach(feedback.lines, id: \.self) { line in
                        Text(line).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tone: Color {
        switch feedback.tone {
        case .correct: Color(red: 0.424, green: 0.749, blue: 0.451)
        case .partial: Color(red: 0.867, green: 0.706, blue: 0.353)
        case .wrong: Color(red: 0.851, green: 0.439, blue: 0.373)
        case .neutral: Color.secondary
        }
    }
}

struct EmptyLibraryNotice: View {
    var body: some View {
        Card {
            Text("No puzzles bundled").font(.headline)
            Text("The data files did not make it into the app bundle. Check that data/tactics.json is listed in the Xcode target's resources.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
