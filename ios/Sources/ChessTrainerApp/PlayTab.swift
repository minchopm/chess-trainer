import SwiftUI

/// Playing a game and watching one are the same subject seen from two sides, so
/// they share a tab rather than each taking a slot in a bar that only holds
/// five.
struct PlayTab: View {
    enum Mode: String, CaseIterable, Identifiable {
        case play = "Play"
        case guessTheElo = "Guess the Elo"
        var id: String { rawValue }
    }

    @State private var mode = Mode.play

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 2)

            switch mode {
            case .play: PlayScreen()
            case .guessTheElo: GuessTheEloScreen()
            }
        }
    }
}
