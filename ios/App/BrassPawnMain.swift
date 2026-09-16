import BrassPawnApp
import SwiftUI

@main
struct BrassPawnMain: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theatre.brass)
                // How small the window may be dragged, and what its title bar
                // says. Nothing at all on iOS.
                .macWindow()
        }
    }
}
