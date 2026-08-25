import ChessTraining
import SwiftUI

/// Brass Pawn, in the ten seconds somebody will give a link in a message.
///
/// The clip plays six tactics and nothing else. It carries no engine — the
/// smallest neural network the app ships is a hundred megabytes on its own,
/// which is the entire budget for a clip — so there is no analysis, no coach
/// and no opponent here. What it can do is put a real position on the real
/// board and let somebody find the move, which is the part that either lands
/// or does not.
///
/// The Game Center spike this target began as answered its question: no. Game
/// Center refuses the clip's bundle outright, so an invitation cannot be played
/// from inside a clip. It is carried across instead — the clip writes the
/// invitation into the shared container, and the app finds it there after the
/// install, so the link still does its work and only does it a minute later.
@main
struct BrassPawnClip: App {
    @State private var model = ClipModel()

    var body: some Scene {
        WindowGroup {
            ClipScreen(model: model)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    model.accept(url)
                }
                .onOpenURL { model.accept($0) }
                .task { model.acceptLaunchArgument() }
        }
    }
}
