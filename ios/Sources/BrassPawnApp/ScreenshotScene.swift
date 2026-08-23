#if DEBUG
import ChessCore
import ChessTraining
import Foundation

/// A scene to open straight into, asked for by a launch argument.
///
/// Store screenshots have to be taken in every language the app ships in, which
/// is thirty-one of them. Tapping through the app that many times is both slow
/// and unreliable — a longer translation moves the buttons, so the taps that
/// worked in English miss in German. Naming the scene at launch removes the
/// navigation entirely: a script sets the language, names the scene, and takes
/// the picture.
///
/// Debug only, and deliberately a launch argument rather than a URL scheme. A
/// launch argument cannot be set by another app or by a link, and none of this
/// is compiled into a Release build.
enum ScreenshotScene: String {
    /// The title scene, which is what the app opens on anyway.
    case menu
    /// The turned board with the new-game panel: strength, side, coaching.
    case playSetup
    /// A game under way on the turned board, with the coach's verdict showing.
    case playCoached
    /// The same, after a weak move: the coach naming the mistake and what it
    /// cost. The more useful of the two to show, because "best move" only says
    /// the app agrees with you — this one says it is watching.
    case playMistake
    /// The flat board with what every move is worth written on the squares.
    case playValues
    /// The free board with a different engine on each side.
    case boardEngines
    /// The library of recorded games.
    case watchList
    /// The app playing itself, for a recorded preview: a good move praised, a
    /// weak one caught. Timed rather than tapped, for the same reason the rest
    /// of this exists — a script cannot tap reliably in thirty-one languages.
    case demo
    /// The long preview: the title board turning, a name typed into the search,
    /// a famous game found and watched, then taken over and played on. It
    /// crosses four screens, which is the part worth showing moving.
    case demoWatch
    /// The training preview: the title board turning, puzzles solved one after
    /// another, then a game against the engine with every move's worth written
    /// on the squares. Tactics first because that is the part people come for,
    /// and the values last because they are the part nothing else does.
    case demoTactics

    static let requested: ScreenshotScene? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-shot"), flag + 1 < arguments.count
        else { return nil }
        return ScreenshotScene(rawValue: arguments[flag + 1])
    }()

    /// Which tab the scene lives in.
    var tab: RootView.Tab {
        switch self {
        case .menu, .playSetup, .playCoached, .playMistake, .playValues, .boardEngines, .demo: .play
        case .watchList, .demoWatch: .watch
        case .demoTactics: .tactics
        }
    }

    /// Which of the Play section's modes, where that applies.
    var playMode: PlayTab.Mode? {
        switch self {
        case .boardEngines: .board
        case .playSetup, .playCoached, .playMistake, .playValues, .demo, .demoTactics: .play
        default: nil
        }
    }

    /// The board the scene wants. The turned board photographs better, and the
    /// values are only drawn on the flat one.
    var dimension: BoardDimension? {
        switch self {
        case .playSetup, .playCoached, .playMistake, .boardEngines, .demo: .dimensional
        case .playValues, .demoTactics: .flat
        case .menu, .watchList, .demoWatch: nil
        }
    }

    /// Whether the menu stays up. The title scene wants it, and the long
    /// preview opens on it before moving off.
    var showsMenu: Bool {
        switch self {
        case .menu, .demo, .demoWatch, .demoTactics: true
        default: false
        }
    }

    /// How long the preview lingers on the menu once the board is up.
    ///
    /// Counted from the board appearing rather than from launch — see the wait
    /// in `RootView` — so this is time anybody watching actually gets, and the
    /// same everywhere.
    static let menuDwell: Duration = .milliseconds(2500)

    /// Wait for the recorder to say it is ready.
    ///
    /// The tape cannot be told "start now" — it takes several seconds to begin
    /// writing — so previews used to be recorded from before the launch and cut
    /// afterwards, and finding the cut meant guessing where the app began from
    /// the brightness of the picture. It guessed wrong often enough to be worth
    /// removing: now the app waits, the recorder gets going over a menu that is
    /// already up, and the file needs no front trim at all.
    /// Say the scene is arranged and the picture can be taken.
    ///
    /// Waited for rather than slept through. The sleeps this replaces were
    /// tuned against a warm simulator, and a first launch after a fresh install
    /// takes long enough that they photographed a black screen — or the menu,
    /// still up over the screen that had been asked for.
    static func markReady() {
        let ready = URL.documentsDirectory.appending(path: "shot-ready")
        try? Data().write(to: ready)
    }

    static func waitForRecorder() async {
        let go = URL.documentsDirectory.appending(path: "preview-go")
        for _ in 0..<600 where !FileManager.default.fileExists(atPath: go.path) {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}

/// A piece the preview wants picked up.
///
/// The board keeps its selection to itself, as it should — nothing outside it
/// has any business choosing your piece. This is the one exception, it exists
/// only in a debug build, and it is how a recording shows what a move is worth:
/// the values are drawn against a selected piece, so something has to select
/// one when there is nobody there to tap.
@Observable
@MainActor
final class PreviewSelection {
    static let shared = PreviewSelection()
    var square: Square?
    private init() {}
}
#endif
