import SwiftUI

/// The way back to the first screen.
///
/// One flag, shared, because "go to the main menu" has to be sayable from a
/// menu inside a game without that menu knowing anything about tabs.
@Observable
@MainActor
final class Navigator {
    var showsMenu = true

    /// Which of the Play tab's four things is showing.
    ///
    /// Here rather than in the tab's own @State, because the menu sits over the
    /// tabs and dismissing it changes the shape of the view tree — which is
    /// enough for SwiftUI to rebuild the tab and reset anything it was holding.
    /// A choice made in the menu has to outlive the menu.
    var playMode: PlayTab.Mode = .play

    func goToMenu() {
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)) { showsMenu = true }
    }
}
