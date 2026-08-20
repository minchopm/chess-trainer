import SwiftUI
import ChessTraining

/// Playing the engine, playing a person, and watching two strangers play are
/// the same subject seen from three sides, so they share a tab rather than each
/// taking a slot in a bar that only holds five.
struct PlayTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case play, online, guessTheElo
        var id: String { String(describing: self) }
        var label: String {
            switch self {
            case .play: L.t("progress.play", "Play")
            case .online: L.t("progress.online", "Online")
            case .guessTheElo: L.t("progress.guessTheElo", "Guess the Elo")
            }
        }
    }

    @Environment(AppModel.self) private var app
    @State private var mode = Mode.play

    /// The clock, when there is one to show.
    private var clocks: ClockStrip? {
        guard mode == .online, let session = app.matchmaker.session else { return nil }
        return ClockStrip(session: session, now: app.matchmaker.now)
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(clocks: clocks) {
                Picker(L.t("play.mode", "Mode"), selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            switch mode {
            case .play: PlayScreen()
            case .online: OnlineScreen()
            case .guessTheElo: GuessTheEloScreen()
            }
        }
    }
}
