import ChessCore
import SwiftUI

/// The way back to the first screen.
///
/// One flag, shared, because "go to the main menu" has to be sayable from a
/// menu inside a game without that menu knowing anything about tabs.
@Observable
@MainActor
final class Navigator {
    var showsMenu = true

    /// Which of the Play section's modes is showing. Watch has its own route.
    ///
    /// Here rather than in the tab's own @State, because the menu sits over the
    /// tabs and dismissing it changes the shape of the view tree — which is
    /// enough for SwiftUI to rebuild the tab and reset anything it was holding.
    /// A choice made in the menu has to outlive the menu.
    var playMode: PlayTab.Mode = .play

    /// A game handed to the free board from somewhere that is not the free
    /// board — a recording being watched, a game out of the history.
    ///
    /// Carried here rather than pushed as a navigation value because the board
    /// is a mode inside a tab, not a destination: whoever hands the game over
    /// cannot reach it directly, and the board picks it up when it next
    /// appears. Cleared on being taken, so coming back to Board a week later
    /// does not silently reload a game you had moved on from.
    var boardHandoff: BoardHandoff?

    /// A destination asked for by a screen that cannot reach the tab state.
    var pendingTab: RootView.Tab?

    /// Open the free board on a position, with the moves that led to it.
    func continueOnBoard(_ handoff: BoardHandoff) {
        boardHandoff = handoff
        playMode = .board
        pendingTab = .play
    }

    func goToMenu() {
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)) { showsMenu = true }
    }
}

/// A game on its way to the free board.
///
/// The moves are the ones actually played up to the point being continued
/// from — not the whole game. Continuing from move twenty of a forty-move game
/// means the other twenty never happened, which is the whole idea: one line,
/// carried on, rather than a tree of variations nobody asked for.
struct BoardHandoff: Equatable {
    let title: String
    let start: Position
    let moves: [String]

    static func == (lhs: BoardHandoff, rhs: BoardHandoff) -> Bool {
        lhs.title == rhs.title && lhs.start.fen == rhs.start.fen && lhs.moves == rhs.moves
    }
}
