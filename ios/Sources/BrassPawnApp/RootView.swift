import ChessTraining
import SwiftUI

public struct RootView: View {
    @State private var app = AppModel()
    @State private var activity = ActivityGuard()
    @State private var selection = Tab.tactics
    @State private var navigator = Navigator()

    public enum Tab: Hashable { case tactics, positional, endgames, play, progress }

    public init() {}

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
                .id(app.progress.appearance.carving)
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
        .animation(.easeOut(duration: 0.2), value: activity.wantsExit)
    }

    private var content: some View {
        selectedScreen
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theatre.ink.ignoresSafeArea())
        .overlay(FilmGrain())
        .environment(app)
        .environment(activity)
        .environment(navigator)
        .environment(\.boardTheme, BoardTheme(style: app.progress.appearance.board))
        .environment(\.pieceSet, app.progress.appearance.pieces)
        .task { await app.start() }
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
                    .font(.footnote)
                    .padding(8)
                    .background(.red.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch selection {
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

struct ProgressScreen: View {
    @Environment(AppModel.self) private var app
    @State private var confirmsReset = false

    var body: some View {
        VStack(spacing: 0) {
            TopBar {
                Text(L.t("progress.progress", "Progress"))
                    .font(Face.display(20))
                    .foregroundStyle(Theatre.ivory)
                    .frame(maxWidth: .infinity)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ratingSection
                    todaySection
                    weakSection
                    onlineSection
                    guessSection
                    librarySection
                    proSection

                    Button { confirmsReset = true } label: {
                        rowLabel(L.t("progress.resetAllProgress", "Reset all progress"), symbol: "trash")
                            .foregroundStyle(Theatre.bad)
                    }
                    .buttonStyle(.plain)
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
                                .font(Face.mono(7)).tracking(0.7)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theatre.brassGlow, in: Capsule())
                        }
                        Spacer()
                        Text(L.t("progress.themeAccuracy", "%lld%% of %lld", Int(theme.record.accuracy * 100), theme.record.seen))
                            .foregroundStyle(Theatre.ivoryDim).monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder private var onlineSection: some View {
        if app.progress.onlineGames > 0 {
            progressSection(L.t("progress.online", "Online")) {
                progressRow(L.t("progress.rating", "Rating"), "\(app.progress.onlineRating)")
                progressRow(L.t("progress.record", "Record"), "\(app.progress.onlineWins)W · \(app.progress.onlineLosses)L · \(app.progress.onlineDraws)D")
                note(L.t("progress.onlineRatingIsKeptApart", "Online rating is kept apart from the training ratings: it measures you against the people you play, not against a library."))
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

    private var proSection: some View {
        progressSection(L.t("store.title", "Brass Pawn Pro")) {
            ProUpsellRow()
            if !app.store.isPro {
                note(L.t("store.freeToday", "Free today: %lld puzzles, %lld Rush run, %lld of each other exercise.",
                            app.progress.freeRemaining(.tactics),
                            app.progress.freeRemaining(.rush),
                            app.progress.freeRemaining(.positional)))
            }
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
        .font(.subheadline)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(.footnote).foregroundStyle(Theatre.ivoryFaint)
    }

    private func rowLabel(_ title: String, symbol: String) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Image(systemName: symbol).font(.caption)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Theatre.ink3, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Theatre.rule, lineWidth: 0.5))
    }

    private var engineText: String {
        switch app.engineState {
        case .starting: "loading"
        case .ready: "ready"
        case .failed: "unavailable"
        }
    }
}
