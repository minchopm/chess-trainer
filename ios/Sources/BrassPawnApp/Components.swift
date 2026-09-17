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
    /// Whether the board below carries the evaluation bar down its side.
    ///
    /// The layout would rather not know, but it has to: the bar and the blank
    /// strip facing it come out of the width, so a stage of a given width is
    /// forty-four points shorter than a square of it. Without that the column
    /// beside the board is pinned to a height the board never reaches and the
    /// controls at its foot stand clear of everything they belong to — which is
    /// the very thing the pinned height was added to stop.
    var showsEvaluation = false
    @ViewBuilder var board: (CGFloat) -> Board
    @ViewBuilder var panel: Panel
    @ViewBuilder var controls: Controls

    /// A board wider than this stops being easier to read and starts being a
    /// reason to move your head. An iPad Pro in landscape has room for far
    /// more; that does not make more an improvement.
    ///
    /// `nonisolated`, here and on every measurement below, because a `View` is
    /// main-actor isolated and these are plain numbers anything may read —
    /// `Mac.contentWidth` takes two of them from outside the actor.
    nonisolated static var maximumBoard: CGFloat { 560 }
    /// The same rule, at the distance a tablet is held.
    ///
    /// The cap above is set for a phone, which is read at arm's length or
    /// closer. A tablet stands further away, so the board can be larger before
    /// it asks anybody to move their head — and at the phone's cap, a
    /// thirteen-inch screen in portrait ends two fifths of the way down and
    /// leaves the rest dark.
    ///
    /// High enough that on a tablet in landscape it is the *height* that decides
    /// the board, not this. At 720 an iPad had three hundred points of ink under
    /// the board and nothing in them; the room was there and the cap was the
    /// only reason it went unused. Twenty-one centimetres of board on a
    /// thirteen-inch screen is still half the size of a real one.
    nonisolated static var maximumBoardOnTablet: CGFloat { 820 }
    /// Where one becomes the other. No phone is this wide in portrait and no
    /// tablet is narrower.
    nonisolated static var tabletWidth: CGFloat { 700 }
    /// Sixty-ish characters a line. Text set across a full iPad is a wall.
    nonisolated static var maximumText: CGFloat { 620 }
    /// The narrowest the panel beside the board may be squeezed.
    ///
    /// About what it gets on a phone in portrait, which is the width every one
    /// of these panels was written for: a coach's paragraph, two columns of
    /// move notation, a row of buttons. Below it they start wrapping into
    /// columns of two words.
    nonisolated static var minimumPanel: CGFloat { 340 }
    /// The padding around the pair and the gap between them: 12 a side, 16
    /// down the middle.
    nonisolated static var wideSurround: CGFloat { 40 }
    /// The widest the board and the column beside it can between them use.
    ///
    /// Both stop growing at their own caps, so past this a window is only
    /// adding margin. The Mac reads it as the width to centre a screen in.
    nonisolated static var maximumWide: CGFloat { maximumBoardOnTablet + maximumText + wideSurround }

    /// The width the stage gets in portrait.
    ///
    /// In portrait the screen is the cap, and there is no second one. A board
    /// in portrait is as wide as the device lets it be — that is what portrait
    /// is for. The reading caps belong to the wide layout, where a board could
    /// otherwise grow past the point of being easier to read; here the device
    /// has already set the limit, and applying a second one on top of it left a
    /// hundred points of ink down either side of a thirteen-inch iPad.
    ///
    /// Three quarters of the height rather than the two thirds it was, so that
    /// on a tablet it is the width that decides. On a phone the width decided
    /// already and none of this moves it.
    nonisolated static func portraitBoard(in size: CGSize) -> CGFloat {
        min(size.width - 20, size.height * 0.75 - BoardStage<EmptyView>.chromeHeight)
    }

    /// The board the wide layout can give, once the panel beside it has the
    /// width it was written for.
    ///
    /// The board is served first and the panel gets what is left, which is the
    /// other way about from how it started; see the body for why.
    nonisolated static func wideBoard(in size: CGSize, showsEvaluation: Bool) -> CGFloat {
        // What the two of them have to share, once the outer padding and the
        // gap between them are taken out.
        let available = size.width - wideSurround
        let cap = size.width >= tabletWidth ? maximumBoardOnTablet : maximumBoard
        let gutters = showsEvaluation ? BoardStage<EmptyView>.gutters : 0
        return min(
            size.height - 24 - BoardStage<EmptyView>.chromeHeight,
            cap,
            available - minimumPanel - gutters
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            if isWide {
                // The board is served first, and the panel gets what is left.
                //
                // It used to be the other way about: the board took a fixed
                // 54% and the panel everything after it, so on a wide screen
                // every point of extra width went to the column of text — which
                // stops at sixty characters a line and floats the rest of the
                // way in empty ink — while the board sat at a cap set for a
                // phone held at arm's length. On a Mac window that was a board
                // of 560 points beside 560 points of nothing.
                //
                // The board is what the screen is *for*. It takes the height it
                // is given, up to the cap for a screen at this distance, and
                // stops only where the panel would be squeezed below the width
                // it was written for.
                //
                // Reckoned on the board rather than on the stage around it, so
                // that the caps mean what they say and the height below is the
                // height the board actually stands at.
                let gutters = showsEvaluation ? BoardStage<EmptyView>.gutters : 0
                let side = Self.wideBoard(in: geometry.size, showsEvaluation: showsEvaluation)
                HStack(alignment: .top, spacing: 16) {
                    board(side + gutters)
                    VStack(spacing: 12) {
                        ScrollView { VStack(spacing: 12) { panel } }
                        controls
                    }
                    // A column rather than the remainder. Whatever a window
                    // wider than the pair of them adds now goes into the
                    // margins on either side, where it reads as room around a
                    // composition instead of a gap through the middle of one.
                    .frame(maxWidth: Self.maximumText)
                }
                // As tall as the board, so the controls at the foot of the
                // column stand level with the foot of the board.
                //
                // Left to fill the screen, the column was as tall as the window
                // while the board was as tall as the board, and on a screen with
                // height to spare that put the buttons a couple of hundred
                // points below everything they belong to, alone against the
                // ink. The pair is then centred in whatever height is left, so
                // what remains reads as margin above and below rather than as a
                // gap underneath.
                .frame(height: side + BoardStage<EmptyView>.chromeHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 12)
            } else {
                let width = Self.portraitBoard(in: geometry.size)
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
        .appCover(isPresented: $showsPaywall) { PaywallView(activity: activity) }
    }

    private var allowanceTitle: String {
        switch activity {
        case .tactics:
            L.t("store.doneTactics", "Today's free Tactics puzzles are done.")
        case .rush:
            L.t("store.doneRush", "Today's free Rush runs are done.")
        default:
            L.t("store.doneForToday", "That is today's free training")
        }
    }

    private var allowanceExplanation: String {
        switch activity {
        // The count comes from the constant rather than from the sentence, and
        // sits after a colon so it needs no plural agreement — "Free each day:
        // 1" and "Free each day: 5" both read correctly, in every language.
        case .tactics:
            L.t(
                "store.tacticsAllowanceCount",
                "Free each day: %lld Tactics puzzles. Rush has its own separate allowance. Both reset at 9:00 AM local time. Playing against AI or another person remains unlimited.",
                TrainingActivity.tactics.dailyFreeLimit
            )
        case .rush:
            L.t(
                "store.rushAllowanceCount",
                "Free each day: %lld Rush runs, separate from the Tactics allowance. Both reset at 9:00 AM local time. Playing against AI or another person remains unlimited.",
                TrainingActivity.rush.dailyFreeLimit
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
