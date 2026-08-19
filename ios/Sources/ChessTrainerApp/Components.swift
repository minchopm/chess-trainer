import ChessTraining
import SwiftUI

/// The shape every training mode takes: board, then a panel, then controls.
///
/// On a phone that stacks vertically with the board on top; in landscape or on
/// an iPad the panel moves beside it, because a board squeezed into half the
/// height of a landscape screen is unusable.
struct TrainingLayout<Board: View, Panel: View, Controls: View>: View {
    /// Handed the width the board may use. A board is the one part of the
    /// screen whose size must be decided rather than negotiated: left to a
    /// stack it comes out as tall as its share of the column, which on a phone
    /// is a good deal less than the screen is wide.
    @ViewBuilder var board: (CGFloat) -> Board
    @ViewBuilder var panel: Panel
    @ViewBuilder var controls: Controls

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            if isWide {
                let width = min(
                    geometry.size.width * 0.54,
                    geometry.size.height - 24 - BoardStage<EmptyView>.chromeHeight
                )
                HStack(alignment: .top, spacing: 16) {
                    board(width).padding(.leading, 12).padding(.vertical, 12)
                    VStack(spacing: 12) {
                        ScrollView { VStack(spacing: 12) { panel }.padding(.trailing, 12) }
                        controls.padding(.trailing, 12)
                    }
                    .padding(.vertical, 12)
                }
            } else {
                // The cap only bites on a short screen; on a phone in portrait
                // the board is limited by the width, as it should be.
                let width = min(
                    geometry.size.width - 20,
                    geometry.size.height * 0.66 - BoardStage<EmptyView>.chromeHeight
                )
                VStack(spacing: 8) {
                    board(width).padding(.top, 4)
                    ScrollView { VStack(spacing: 10) { panel }.padding(.horizontal, 10) }
                    // Clear of the tab bar: buttons that touch it read as part
                    // of it, and the wrong one gets tapped.
                    controls.padding(.horizontal, 10).padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
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

/// Nothing to show yet — and which of the two reasons it is.
///
/// The data is read off the main actor so the first screen appears at once,
/// which means every mode has a moment where its library is legitimately empty.
/// Announcing "nothing was bundled" during that moment accuses the build of a
/// fault it does not have.
struct LibraryNotice: View {
    let isLoaded: Bool
    let what: String
    let file: String

    var body: some View {
        Card {
            if isLoaded {
                Text(L.t("common.nothingBundled", "No %@ bundled", what)).font(.headline)
                Text(L.t("common.dataMissing", "The data did not make it into the app bundle. Check that data/%@ is listed in the Xcode target's resources.", file))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(L.t("common.loading", "Loading %@…", what)).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }
}


/// Shown in place of the next exercise once a free day is spent.
///
/// Deliberately not a sheet: opening the app should never be answered with a
/// demand for money. The offer sits on the screen and waits to be tapped.
struct AllowanceNotice: View {
    let activity: TrainingActivity
    @State private var showsPaywall = false

    var body: some View {
        Card {
            Text(L.t("store.doneForToday", "That is today's free training")).font(.headline)
            Text(L.t("store.comeBackTomorrow", "The allowance resets at midnight. Playing — against the engine or against a person — has no limit and needs nothing."))
                .font(.footnote).foregroundStyle(.secondary)
            Button(L.t("store.unlockNow", "Unlock unlimited training")) { showsPaywall = true }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
        }
        .sheet(isPresented: $showsPaywall) { PaywallView(activity: activity) }
    }
}
