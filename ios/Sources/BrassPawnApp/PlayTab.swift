import SwiftUI
import ChessTraining

/// The three ways to play a game share one compact section. Everything based
/// on watching an existing game lives in the separate Watch destination.
///
/// Board is the odd one of the three: no opponent is assigned when you arrive,
/// and both sides can change hands mid-game. It sits here rather than beside
/// Watch because what you do on it is play moves.
struct PlayTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case play, online, board
        var id: String { String(describing: self) }
        var label: String {
            switch self {
            case .play: L.t("play.vsAI", "VS AI")
            case .online: L.t("play.multiplayer", "Multiplayer")
            case .board: L.t("play.board", "Board")
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
            case .board: BoardScreen()
            }
        }
    }
}
