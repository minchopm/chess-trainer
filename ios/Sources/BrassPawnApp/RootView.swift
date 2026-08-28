import BoardScene
import ChessTraining
import SwiftData
import SwiftUI

public struct RootView: View {
    @State private var app = AppModel()
    @State private var activity = ActivityGuard()
    @State private var selection = Tab.tactics
    @State private var navigator = Navigator()

    /// The played games. Built once, here rather than per screen.
    private let history = RootView.openHistory()

    /// The store, falling back to memory when the one on disk will not open.
    ///
    /// A store that will not open costs the history, which is worth losing.
    /// Memory-only keeps every screen working for the session — games written
    /// to it go when the app does, which is the honest failure. If even that
    /// throws there is no context to hand the screens and nothing sensible to
    /// put in its place, so it is allowed to be fatal.
    private static func openHistory() -> ModelContainer {
        if let disk = try? GameHistory.container() { return disk }
        return try! GameHistory.container(inMemory: true)
    }

    public enum Tab: Hashable { case watch, guessTheElo, tactics, positional, endgames, play, progress }

    public init() {
        LaunchClock.mark("RootView init")
    }

    public var body: some View {
        ZStack {
            content
            if navigator.showsMenu {
                // Over the current screen rather than instead of it, so choosing a
                // destination does not rebuild every screen behind it.
                MenuScreen(carving: app.progress.appearance.carving) { tab in
                    selection = tab
                    withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.6)) {
                        navigator.showsMenu = false
                    }
                }
                .environment(app)
                .environment(activity)
                .environment(navigator)
                .transition(.opacity)
                .zIndex(1)
            }

            if activity.wantsExit {
                BrassConfirmationOverlay(
                    title: activity.title ?? "Leave?",
                    message: activity.reason ?? "",
                    confirmTitle: L.t("progress.leave", "Leave"),
                    cancelTitle: L.t("progress.stay", "Stay"),
                    onConfirm: confirmExit,
                    onCancel: cancelExit
                )
                .zIndex(3)
            }
        }
        // An invitation link opens the App Clip only for somebody who does not
        // have the app. Anybody who does gets sent straight here instead, so
        // the app has to be able to read the same link — otherwise the people
        // most likely to accept an invitation are the ones it never reaches.
        // Stored rather than acted on: the multiplayer screen picks it up when
        // it is opened, which is where accepting belongs.
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL,
                  let invitation = Invitation(url: url)
            else { return }
            accept(invitation)
        }
        .onOpenURL { url in
            guard let invitation = Invitation(url: url) else { return }
            accept(invitation)
        }
        .appTypeface(app.progress.appearance.typeface)
        .animation(.easeOut(duration: 0.2), value: activity.wantsExit)
        .modelContainer(history)
        #if DEBUG
        .task { await leaveMenuForPreview() }
        #endif
    }

    /// Put an invitation where the multiplayer screen will find it, and open
    /// that screen. Not `.play`'s default mode: somebody who followed an
    /// invitation wants the opponent it names, not the engine.
    private func accept(_ invitation: Invitation) {
        SharedContainer.store(invitation)
        navigator.playMode = .online
        navigator.pendingTab = .play
        navigator.showsMenu = false
    }

    #if DEBUG
    /// Open straight into the scene a launch argument asked for.
    ///
    /// After `app.start()` rather than before: the scenes that want a board
    /// need the engine, and the appearance is written into the progress file,
    /// which is loaded by then.
    private func applyScreenshotScene() {
        guard let scene = ScreenshotScene.requested else { return }
        if let dimension = scene.dimension {
            app.update { $0.appearance.dimension = dimension }
        }
        if let mode = scene.playMode { navigator.playMode = mode }
        navigator.showsMenu = scene.showsMenu
        // The destination waits for the menu to leave, rather than being built
        // behind it. A screen with a board of its own was loading a second
        // scene while the title board was still finding its feet, and neither
        // of them appeared until both were ready.
        if !scene.showsMenu { selection = scene.tab }
    }
    #endif

    #if DEBUG
    /// The long preview opens on the title board and lets it turn a while
    /// before going anywhere, so the recording starts on something worth
    /// looking at rather than on a list.
    ///
    /// On its own clock, not behind `app.start()`. Hanging it off the engine
    /// meant the dwell began whenever a hundred megabytes of networks had
    /// finished loading, which on a cold launch left the menu sitting there for
    /// most of the recording.
    private func leaveMenuForPreview() async {
        guard let scene = ScreenshotScene.requested else { return }

        // The title scene is a picture of the menu, so it is ready once the
        // board it is a picture of is on screen.
        if scene == .menu {
            for _ in 0..<200 where !BoardSceneDebug.boardHasAppeared {
                try? await Task.sleep(for: .milliseconds(50))
            }
            try? await Task.sleep(for: .milliseconds(600))
            ScreenshotScene.markReady()
            return
        }

        guard scene == .demo || scene == .demoWatch || scene == .demoTactics
        else { return }
        // From when the board is on screen, not from launch. It is built from
        // a size that does not exist until the view has been laid out, so it
        // arrives a second or two after everything around it.
        for _ in 0..<200 where !BoardSceneDebug.boardHasAppeared {
            try? await Task.sleep(for: .milliseconds(50))
        }
        // Said before waiting, not after: this is what the recorder is waiting
        // for. Rolling the tape on a timer instead meant the front of the file
        // held however long that particular cold launch had taken, which was
        // four seconds one run and eleven the next.
        // Back to the first move before the tape rolls, so the recording opens
        // on a game in progress rather than on the several still seconds
        // between one game and the next.
        BoardSceneDebug.restartTitleGame?()
        // The restarted game waits before its first move, as it does for
        // anybody opening the app. Spend that pause before the tape rolls
        // rather than in front of it.
        try? await Task.sleep(for: .milliseconds(2600))
        ScreenshotScene.markReady()
        await ScreenshotScene.waitForRecorder()
        try? await Task.sleep(for: ScreenshotScene.menuDwell)
        selection = scene.tab
        // Cut, rather than dissolve. The menu's usual fade leaves it lying over
        // the screen behind it for long enough to record, and the preview then
        // reads as two screens at once instead of one after the other.
        navigator.showsMenu = false
    }
    #endif

    private var content: some View {
        selectedScreen
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theatre.ink.ignoresSafeArea())
        .overlay(FilmGrain())
        .environment(app)
        .environment(activity)
        .environment(navigator)
        .environment(\.boardTheme, BoardTheme(style: app.progress.appearance.board,
                                              lightTone: app.progress.appearance.lightTone))
        .environment(\.pieceSet, app.progress.appearance.pieces)
        .environment(\.showsBoardCoordinates, app.progress.appearance.showsCoordinates)
        .task {
            // Before the engine, not after. The scene only moves the navigation
            // and the appearance, neither of which waits on anything, while
            // `start()` loads a hundred megabytes of networks — long enough
            // that a screenshot taken meanwhile catches the menu instead.
            #if DEBUG
            applyScreenshotScene()
            #endif
            await app.start()
        }
        // A screen that cannot reach the tab state asks for a destination here.
        .onChange(of: navigator.pendingTab) { _, tab in
            guard let tab else { return }
            navigator.pendingTab = nil
            selection = tab
        }
        .onAppear {
            SoundBoard.shared.isEnabled = app.progress.appearance.soundsOn
            SoundBoard.shared.volume = app.progress.appearance.volume
        }
        .onChange(of: app.progress.appearance.soundsOn) { _, on in
            SoundBoard.shared.isEnabled = on
        }
        .onChange(of: app.progress.appearance.volume) { _, level in
            SoundBoard.shared.volume = level
        }
        .overlay(alignment: .top) {
            if case .failed(let message) = app.engineState {
                Text(message)
                    .appFont(.footnote)
                    .padding(8)
                    .background(Theatre.bad.opacity(0.85), in: Capsule())
                    .foregroundStyle(Theatre.light)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch selection {
        case .watch: ClassicsScreen()
        case .guessTheElo: GuessTheEloTab()
        case .tactics: TrainingTab()
        case .positional: PositionalScreen()
        case .endgames: EndgameScreen()
        case .play: PlayTab()
        case .progress: ProgressScreen()
        }
    }

    private func confirmExit() {
        if activity.wantsExit {
            activity.release()
            navigator.goToMenu()
        }
    }

    private func cancelExit() {
        activity.cancelExit()
    }
}

/// Guess the Elo is a first-class destination from the main menu, separate
/// from the library of games that can simply be watched.
private struct GuessTheEloTab: View {
    var body: some View {
        VStack(spacing: 0) {
            TopBar {
                Text(L.t("progress.guessTheElo", "Guess the Elo"))
                    .appFont(size: 20, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .frame(maxWidth: .infinity)
            }
            GuessTheEloScreen()
        }
        .background(Theatre.ink.ignoresSafeArea())
    }
}

struct ProgressScreen: View {
    @Environment(AppModel.self) private var app
    @State private var confirmsReset = false

    var body: some View {
        VStack(spacing: 0) {
            TopBar {
                Text(L.t("progress.progress", "Progress"))
                    .appFont(size: 20, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .frame(maxWidth: .infinity)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ratingSection
                    todaySection
                    weakSection
                    againstTheClockSection
                    onlineSection
                    guessSection
                    librarySection

                    Button { confirmsReset = true } label: {
                        rowLabel(L.t("progress.resetAllProgress", "Reset all progress"), symbol: "trash")
                            .foregroundStyle(Theatre.bad)
                    }
                    .buttonStyle(BrassPressStyle())
                }
                .padding(14)
                .padding(.bottom, 18)
            }
        }
        .background(Theatre.ink.ignoresSafeArea())
        .overlay {
            if confirmsReset {
                BrassConfirmationOverlay(
                    title: L.t("progress.resetAllProgress", "Reset all progress"),
                    message: "Your ratings, records and history will be cleared.",
                    confirmTitle: L.t("progress.resetAllProgress", "Reset all progress"),
                    cancelTitle: L.t("progress.stay", "Stay"),
                    onConfirm: {
                        app.resetProgress()
                        confirmsReset = false
                    },
                    onCancel: { confirmsReset = false }
                )
            }
        }
        .animation(.easeOut(duration: 0.2), value: confirmsReset)
    }

    private var ratingSection: some View {
        progressSection(L.t("progress.whereYouAre", "Where you are")) {
            progressRow(L.t("progress.overall", "Overall"), "\(app.progress.overallRating)")
            ForEach(TrainingMode.allCases, id: \.self) { mode in
                progressRow(mode.rawValue.capitalized, "\(app.progress.rating(mode))")
            }
            note(L.t("progress.puzzleRatingsRunAFew", "Puzzle ratings run a few hundred points above over-the-board ratings — treat them as a measure of progress against yourself."))
        }
    }

    private var todaySection: some View {
        let stats = app.progress.sessionStats()
        return progressSection(L.t("progress.today", "Today")) {
            progressRow(L.t("progress.attempted", "Attempted"), "\(stats.attempted)")
            progressRow(L.t("progress.solved", "Solved"), "\(stats.solved)")
            progressRow(L.t("progress.accuracy", "Accuracy"), "\(Int(stats.accuracy * 100))%")
            progressRow(L.t("progress.dayStreak", "Day streak"), "\(app.progress.currentStreak)")
        }
    }

    @ViewBuilder private var weakSection: some View {
        let weak = app.progress.weakestThemes()
        if !weak.isEmpty {
            progressSection(L.t("progress.weakSpots", "Weak spots")) {
                let targeted = Set(app.progress.trainingTargets().map(\.name))
                ForEach(weak, id: \.name) { theme in
                    HStack {
                        Text(Themes.readable(theme.name))
                        if targeted.contains(theme.name) {
                            Text("targeting")
                                .appFont(size: 7).tracking(0.7)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theatre.brassGlow, in: Capsule())
                        }
                        Spacer()
                        Text(L.t("progress.themeAccuracy", "%lld%% of %lld", Int(theme.record.accuracy * 100), theme.record.seen))
                            .foregroundStyle(Theatre.ivoryDim).monospacedDigit()
                    }
                    .appFont(.subheadline)
                }
            }
        }
    }

    /// Timed puzzles and games against the engine — rated, and each in a pool
    /// of its own, so they are shown apart from the untimed libraries above.
    @ViewBuilder private var againstTheClockSection: some View {
        let runs = Set(app.progress.rushRecords.map { Int($0.duration) / 60 }).sorted()
        let engineGames = app.progress.gamesPlayed(.engine)
        if !runs.isEmpty || engineGames > 0 {
            progressSection(L.t("progress.againstTheClock", "Timed & engine")) {
                ForEach(runs, id: \.self) { minutes in
                    progressRow(
                        L.t("progress.rushMinutes", "Rush · %lld min", minutes),
                        "\(app.progress.rating(.rush(minutes: minutes)))"
                    )
                }
                if engineGames > 0 {
                    progressRow(L.t("progress.engine", "Engine"), "\(app.progress.rating(.engine))")
                }
                note(L.t("progress.everyPoolIsRatedApart", "Each of these is rated on its own. Solving with a clock running is a different skill from solving with all afternoon, and beating a bot whose strength you chose is a different measure again."))
            }
        }
    }

    @ViewBuilder private var onlineSection: some View {
        // One row per clock, and only for the clocks actually played. A rating
        // nobody has earned yet is a 1200 that means nothing.
        let played = TimeControl.allCases.filter {
            app.progress.gamesPlayed(.online(minutes: $0.minutes)) > 0
        }
        if !played.isEmpty {
            progressSection(L.t("progress.online", "Online")) {
                ForEach(played) { control in
                    progressRow(
                        "\(control.label) · \(control.name)",
                        "\(app.progress.rating(.online(minutes: control.minutes)))"
                    )
                }
                progressRow(L.t("progress.record", "Record"), "\(app.progress.onlineWins)W · \(app.progress.onlineLosses)L · \(app.progress.onlineDraws)D")
                note(L.t("progress.onlineRatingIsKeptApart", "Online rating is kept apart from the training ratings: it measures you against the people you play, not against a library. Each clock is rated on its own — three minutes and thirty are different games."))
            }
        }
    }

    @ViewBuilder private var guessSection: some View {
        let guesses = app.progress.eloGuessStats
        if guesses.judged > 0 {
            progressSection(L.t("progress.guessTheElo", "Guess the Elo")) {
                progressRow(L.t("progress.gamesJudged", "Games judged"), "\(guesses.judged)")
                progressRow(L.t("progress.averageMiss", "Average miss"), "\(guesses.averageError) points")
                progressRow(L.t("progress.closest", "Closest"), "\(guesses.bestError) points")
                if abs(guesses.bias) >= 40 {
                    note(guesses.bias > 0
                        ? L.t("progress.biasHigh", "You read games as stronger than they are, by %lld points on average.", abs(guesses.bias))
                        : L.t("progress.biasLow", "You read games as weaker than they are, by %lld points on average.", abs(guesses.bias)))
                }
            }
        }
    }

    private var librarySection: some View {
        progressSection(L.t("progress.library", "Library")) {
            progressRow(L.t("progress.tacticsPuzzles", "Tactics puzzles"), "\(app.library.puzzles.count)")
            progressRow(L.t("progress.positional", "Positional"), "\(app.library.exercises.count)")
            progressRow(L.t("progress.endgames", "Endgames"), "\(app.library.drills.count)")
            progressRow(L.t("progress.games", "Games"), "\(app.library.games.count)")
            progressRow(L.t("progress.engine", "Engine"), engineText)
        }
    }

    private func progressSection<Content: View>(
        _ title: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Slug(text: title)
            Panel { content() }
        }
    }

    private func progressRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(Theatre.ivory)
            Spacer(minLength: 10)
            Text(value).foregroundStyle(Theatre.ivoryDim).monospacedDigit()
        }
        .appFont(.subheadline)
    }

    private func note(_ text: String) -> some View {
        Text(text).appFont(.footnote).foregroundStyle(Theatre.ivoryFaint)
    }

    private func rowLabel(_ title: String, symbol: String) -> some View {
        HStack {
            Text(title).appFont(.subheadline)
            Spacer()
            BrassIcon(symbol, size: 18)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background {
            BrassPlateShape(cut: 10).fill(Theatre.ink3)
        }
        .overlay {
            BrassPlateShape(cut: 10)
                .strokeBorder(Theatre.brassDeep.opacity(0.45), lineWidth: 0.65)
        }
    }

    private var engineText: String {
        switch app.engineState {
        case .starting: "loading"
        case .ready: "ready"
        case .failed: "unavailable"
        }
    }
}
