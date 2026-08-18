import Observation
import SwiftUI

/// Practice and Rush share the same puzzles and differ only in what they ask of
/// you, so they belong in one tab rather than competing for a slot in the bar.
struct TrainingTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case practice = "Practice"
        case rush = "Rush"
        var id: String { rawValue }
    }

    @State private var mode = Mode.practice

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            switch mode {
            case .practice: TacticsScreen()
            case .rush: RushScreen()
            }
        }
        .navigationTitle(mode == .practice ? "Tactics" : "Rush")
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
    }
}
