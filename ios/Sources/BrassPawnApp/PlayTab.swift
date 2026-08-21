import SwiftUI
import ChessTraining

/// Playing the engine, playing a person, and watching two strangers play are
/// the same subject seen from three sides, so they share a tab rather than each
/// taking a slot in a bar that only holds five.
struct PlayTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case play, online, watch, guessTheElo
        var id: String { String(describing: self) }
        var label: String {
            switch self {
            case .play: L.t("progress.play", "Play")
            case .online: L.t("progress.online", "Online")
            case .watch: L.t("progress.watch", "Watch")
            case .guessTheElo: L.t("progress.guessTheElo", "Guess the Elo")
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
            TopBar(clocks: mode == .watch ? nil : clocks) {
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
            case .watch: ClassicsScreen()
            case .guessTheElo: GuessTheEloScreen()
            }
        }
    }
}
