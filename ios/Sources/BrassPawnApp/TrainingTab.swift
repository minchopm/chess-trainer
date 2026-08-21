import Observation
import SwiftUI
import ChessTraining

/// Practice and Rush share the same puzzles and differ only in what they ask of
/// you, so they belong in one tab rather than competing for a slot in the bar.
struct TrainingTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case practice, rush
        var id: String { rawValue }
        var label: String {
            switch self {
            case .practice: L.t("common.practice", "Practice")
            case .rush: L.t("rush.rush", "Rush")
            }
        }
    }

    @State private var mode = Mode.practice

    var body: some View {
        VStack(spacing: 0) {
            TopBar {
                BrassSegmentedPicker(
                    L.t("common.mode", "Mode"),
                    selection: $mode,
                    options: Array(Mode.allCases)
                ) { option in
                    Text(option.label)
                }
            }

            switch mode {
            case .practice: TacticsScreen()
            case .rush: RushScreen()
            }
        }
    }
}

/// Whether anything on screen would be lost by navigating away.
///
/// Deliberately not "are we on a screen" — a confirmation that fires on every
/// tab is training the user to dismiss confirmations without reading them, and
/// the one time it matters they will tap straight through it. This is set only
/// while there is something real to lose.
@MainActor
@Observable
final class ActivityGuard {
    private(set) var reason: String?
    private(set) var title: String?

    var isActive: Bool { reason != nil }

    func hold(title: String, reason: String) {
        self.title = title
        self.reason = reason
    }

    func release() {
        title = nil
        reason = nil
        wantsExit = false
    }

    /// Set when the menu asks to leave. RootView turns it into the same
    /// confirmation a tab tap used to raise — the question is worth asking
    /// however it was reached.
    var wantsExit = false

    func requestExit() {
        guard isActive else { return }
        wantsExit = true
    }

    func cancelExit() { wantsExit = false }
}
