import SwiftUI
import ChessTraining

/// The two ways to play a game share one compact section. Everything based on
/// watching an existing game lives in the separate Watch destination.
struct PlayTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case play, online
        var id: String { String(describing: self) }
        var label: String {
            switch self {
            case .play: L.t("progress.play", "Play")
            case .online: L.t("progress.online", "Online")
            }
        }
    }

    @Environment(AppModel.self) private var app
    @Environment(Navigator.self) private var navigator

    /// The clock, when there is one to show.
    private var mode: Mode { navigator.playMode }

    private var clocks: ClockStrip? {
        guard mode == .online, let session = app.matchmaker.session else { return nil }
        return ClockStrip(session: session, now: app.matchmaker.now)
    }

    var body: some View {
        @Bindable var navigator = navigator
        return VStack(spacing: 0) {
            TopBar(clocks: clocks) {
                BrassSegmentedPicker(
                    L.t("play.mode", "Mode"),
                    selection: $navigator.playMode,
                    options: Array(Mode.allCases)
                ) { option in
                    Text(option.label)
                }
            }

            switch mode {
            case .play: PlayScreen()
            case .online: OnlineScreen()
            }
        }
    }
}
