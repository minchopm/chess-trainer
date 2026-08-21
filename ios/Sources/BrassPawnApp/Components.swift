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

    /// A board wider than this stops being easier to read and starts being a
    /// reason to move your head. An iPad Pro in landscape has room for far
    /// more; that does not make more an improvement.
    static var maximumBoard: CGFloat { 560 }
    /// Sixty-ish characters a line. Text set across a full iPad is a wall.
    static var maximumText: CGFloat { 620 }

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            if isWide {
                let width = min(
                    geometry.size.width * 0.54,
                    geometry.size.height - 24 - BoardStage<EmptyView>.chromeHeight,
                    Self.maximumBoard
                )
                HStack(alignment: .top, spacing: 16) {
                    board(width).padding(.leading, 12).padding(.vertical, 12)
                    VStack(spacing: 12) {
                        ScrollView { VStack(spacing: 12) { panel }.frame(maxWidth: Self.maximumText) }
                        controls.frame(maxWidth: Self.maximumText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 12)
                    .padding(.vertical, 12)
                }
            } else {
                // The caps only bite on a tablet. On a phone in portrait the
                // board is limited by the width, as it should be.
                let width = min(
                    geometry.size.width - 20,
                    geometry.size.height * 0.66 - BoardStage<EmptyView>.chromeHeight,
                    Self.maximumBoard
                )
                VStack(spacing: 8) {
                    board(width).padding(.top, 4)
                    ScrollView {
                        VStack(spacing: 10) { panel }
                            .padding(.horizontal, 10)
                            .frame(maxWidth: Self.maximumText)
                            .frame(maxWidth: .infinity)
                    }
                    // Clear of the tab bar: buttons that touch it read as part
                    // of it, and the wrong one gets tapped.
                    controls
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                        .frame(maxWidth: Self.maximumText)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Panel(padding: 15) { content }
    }
}

/// The shared stage for modal moments. The darker veil separates the message
/// from the position beneath it, while the restrained brass glow keeps it in
/// the same visual world as the rest of the app.
struct BrassModalBackdrop<Content: View>: View {
    let onBackdropTap: (() -> Void)?
    @ViewBuilder let content: Content

    init(
        onBackdropTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onBackdropTap = onBackdropTap
        self.content = content()
    }

    var body: some View {
        ZStack {
            Theatre.shadow.opacity(0.84)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onBackdropTap?() }

            RadialGradient(
                colors: [Theatre.brassGlow.opacity(0.55), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 330
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            content
                .frame(maxWidth: 400)
                .padding(24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
        .accessibilityAddTraits(.isModal)
    }
}

/// A focused modal surface shared by results, confirmations and allowance
/// notices. Status is communicated by the content and its accent colour; a
/// floating symbol above the panel looked like an extra button and competed
/// with the actual action below.
struct BrassModalPanel<Content: View>: View {
    let tint: Color
    @ViewBuilder let content: Content

    init(
        tint: Color = Theatre.brassHot,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background {
            ZStack {
                BrassPlateShape(cut: 20).fill(LinearGradient(
                    colors: [Theatre.ink4, Theatre.ink2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                RadialGradient(
                    colors: [tint.opacity(0.11), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 210
                )
                .clipShape(BrassPlateShape(cut: 20))
            }
        }
        .overlay {
            BrassPlateShape(cut: 20)
                .strokeBorder(Theatre.brassDeep.opacity(0.72), lineWidth: 0.9)
        }
        .overlay {
            BrassPlateShape(cut: 16, insetAmount: 5)
                .strokeBorder(tint.opacity(0.12), lineWidth: 0.5)
        }
        .shadow(color: Theatre.shadow.opacity(0.72), radius: 28, y: 14)
    }
}

struct TagRow: View {
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .appFont(size: 9, weight: .medium)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(Theatre.brass.opacity(0.9))
                    .background(Theatre.brass.opacity(0.08), in: Capsule())
                    .overlay(Capsule().strokeBorder(Theatre.brass.opacity(0.22), lineWidth: 0.5))
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
                    Text(feedback.title).appFont(size: 21, weight: .semibold)
                    ForEach(feedback.lines, id: \.self) { line in
                        Text(line).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tone: Color {
        switch feedback.tone {
        case .correct: Theatre.good
        case .partial: Theatre.warn
        case .wrong: Theatre.bad
        case .neutral: Theatre.ivoryFaint
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
                Text(L.t("common.nothingBundled", "No %@ bundled", what)).appFont(size: 22, weight: .semibold)
                Text(L.t("common.dataMissing", "The data did not make it into the app bundle. Check that data/%@ is listed in the Xcode target's resources.", file))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)
            } else {
                HStack(spacing: 8) {
                    BrassActivityIndicator(size: 15)
                    Text(L.t("common.loading", "Loading %@…", what)).appFont(.subheadline).foregroundStyle(Theatre.ivoryDim)
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
        BrassModalPanel(tint: Theatre.brassHot) {
            VStack(alignment: .leading, spacing: 14) {
                Text(allowanceTitle)
                    .appFont(.title2, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                Text(allowanceExplanation)
                    .appFont(.subheadline)
                    .foregroundStyle(Theatre.ivoryDim)
                    .fixedSize(horizontal: false, vertical: true)

                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let reset = DailyUsage.nextReset(after: timeline.date)
                    HStack(spacing: 10) {
                        BrassIcon("clock", size: 17)
                            .foregroundStyle(Theatre.brass)
                        Text(L.t("store.resetsIn", "Resets in %@", countdown(from: timeline.date, to: reset)))
                            .appFont(.subheadline, weight: .semibold)
                            .monospacedDigit()
                            .foregroundStyle(Theatre.brassHot)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        BrassPlateShape(cut: 9).fill(Theatre.ink2.opacity(0.82))
                    }
                    .overlay {
                        BrassPlateShape(cut: 9)
                            .strokeBorder(Theatre.brassDeep.opacity(0.46), lineWidth: 0.65)
                    }
                    .accessibilityLabel(L.t("store.resetsIn", "Resets in %@", countdown(from: timeline.date, to: reset)))
                }

                Button { showsPaywall = true } label: {
                    Label {
                        Text(L.t("store.unlockNow", "Upgrade now"))
                    } icon: {
                        BrassIcon("crown.fill", size: 18)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
            }
        }
        .fullScreenCover(isPresented: $showsPaywall) { PaywallView(activity: activity) }
    }

    private var allowanceTitle: String {
        switch activity {
        case .tactics:
            L.t("store.freePuzzleComplete", "You have completed today's free Tactics puzzle")
        case .rush:
            L.t("store.freeRushAttemptUsed", "Today's free Rush attempt has been used")
        default:
            L.t("store.doneForToday", "That is today's free training")
        }
    }

    private var allowanceExplanation: String {
        switch activity {
        case .tactics:
            L.t(
                "store.tacticsAllowance",
                "One completed Tactics puzzle is free each day. Rush has its own separate daily attempt. This resets at 9:00 AM local time. Playing against AI or another person remains unlimited."
            )
        case .rush:
            L.t(
                "store.rushAllowance",
                "One Rush attempt is free each day. It is separate from the daily Tactics puzzle. This resets at 9:00 AM local time. Playing against AI or another person remains unlimited."
            )
        default:
            L.t("store.comeBackAtNine", "The allowance resets every day at 9:00 AM local time. Playing — against the engine or against a person — has no limit and needs nothing.")
        }
    }

    private func countdown(from now: Date, to reset: Date) -> String {
        let total = max(0, Int(reset.timeIntervalSince(now).rounded(.down)))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

/// The same exhausted-state presentation is shared by every limited training
/// mode. The dimming layer locks the exercise while the card itself remains
/// interactive so the player can choose whether to open Purchases.
struct AllowanceLockOverlay: View {
    let activity: TrainingActivity

    var body: some View {
        BrassModalBackdrop {
            AllowanceNotice(activity: activity)
        }
    }
}

private struct AllowanceGateModifier: ViewModifier {
    @Environment(AppModel.self) private var app
    let activity: TrainingActivity
    let hasStartedAttempt: Bool
    let wasDenied: Bool

    func body(content: Content) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let locked = isLocked(at: timeline.date)
            ZStack {
                content
                    .allowsHitTesting(!locked)
                    .accessibilityHidden(locked)

                if locked {
                    AllowanceLockOverlay(activity: activity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: locked)
        }
    }

    private func isLocked(at now: Date) -> Bool {
        guard !hasStartedAttempt, !app.store.isPro,
              app.progress.freeRemaining(activity, at: now) == 0
        else { return false }
        return wasDenied || !app.store.isCheckingEntitlement
    }
}

extension View {
    func allowanceGate(
        activity: TrainingActivity,
        hasStartedAttempt: Bool,
        wasDenied: Bool
    ) -> some View {
        modifier(AllowanceGateModifier(
            activity: activity,
            hasStartedAttempt: hasStartedAttempt,
            wasDenied: wasDenied
        ))
    }
}
