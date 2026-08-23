#if DEBUG
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
        }
    }

    /// Which of the Play section's modes, where that applies.
    var playMode: PlayTab.Mode? {
        switch self {
        case .boardEngines: .board
        case .playSetup, .playCoached, .playMistake, .playValues, .demo: .play
        default: nil
        }
    }

    /// The board the scene wants. The turned board photographs better, and the
    /// values are only drawn on the flat one.
    var dimension: BoardDimension? {
        switch self {
        case .playSetup, .playCoached, .playMistake, .boardEngines, .demo: .dimensional
        case .playValues: .flat
        case .menu, .watchList, .demoWatch: nil
        }
    }

    /// Whether the menu stays up. The title scene wants it, and the long
    /// preview opens on it before moving off.
    var showsMenu: Bool { self == .menu || self == .demoWatch }

    /// How long the preview lingers on the menu before going to work.
    static let menuDwell: Duration = .seconds(3)
}
#endif
