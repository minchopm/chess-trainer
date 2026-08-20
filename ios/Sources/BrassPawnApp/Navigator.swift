import SwiftUI

/// The way back to the first screen.
///
/// One flag, shared, because "go to the main menu" has to be sayable from a
/// menu inside a game without that menu knowing anything about tabs.
@Observable
@MainActor
final class Navigator {
    var showsMenu = true

    func goToMenu() {
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)) { showsMenu = true }
    }
}
