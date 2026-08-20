import ChessTraining
import SwiftUI

public struct RootView: View {
    @State private var app = AppModel()
    @State private var activity = ActivityGuard()
    @State private var selection = Tab.tactics
    @State private var pending: Tab?
    @State private var navigator = Navigator()

    public enum Tab: Hashable { case tactics, positional, endgames, play, progress }

    public init() {}

    public var body: some View {
        ZStack {
            tabs
            if navigator.showsMenu {
                // Over the tabs rather than instead of them, so choosing a
                // destination does not rebuild every screen behind it.
                MenuScreen { tab in
                    selection = tab
                    withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.6)) {
                        navigator.showsMenu = false
                    }
                }
                .environment(app)
                .environment(activity)
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

    private var tabs: some View {
        // The classic tabItem API rather than the newer Tab builder: that one
        // needs iOS 18, and there is no reason to exclude iOS 17 devices from a
        // trainer that asks nothing of the OS.
        TabView(selection: tabSelection) {
            NavigationStack { TrainingTab().hideNavigationBar() }
                .hideTabBar(while: activity.isActive)
                .tabItem { Label(L.t("progress.tactics", "Tactics"), systemImage: "target") }
                .tag(Tab.tactics)

            NavigationStack { PositionalScreen().hideNavigationBar() }
                .hideTabBar(while: activity.isActive)
                .tabItem { Label(L.t("progress.positional", "Positional"), systemImage: "square.grid.3x3.middle.filled") }
                .tag(Tab.positional)

            NavigationStack { EndgameScreen().hideNavigationBar() }
                .hideTabBar(while: activity.isActive)
                .tabItem { Label(L.t("progress.endgames", "Endgames"), systemImage: "flag.checkered") }
                .tag(Tab.endgames)

            NavigationStack { PlayTab().hideNavigationBar() }
                .hideTabBar(while: activity.isActive)
                .tabItem { Label(L.t("progress.play", "Play"), systemImage: "person.2") }
                .tag(Tab.play)

            NavigationStack {
                // Progress keeps its bar: it pushes to the About screen, and a
                // pushed view needs somewhere to put its back button.
                ProgressScreen().navigationTitle(L.t("progress.progress", "Progress"))
            }
                .tabItem { Label(L.t("progress.progress", "Progress"), systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.progress)
        }
        .tint(Theatre.brass)
        .background(Theatre.ink.ignoresSafeArea())
        .overlay(FilmGrain())
        .environment(app)
        .environment(activity)
        .environment(navigator)
        .environment(\.boardTheme, BoardTheme(style: app.progress.appearance.board))
        .environment(\.pieceSet, app.progress.appearance.pieces)
        .confirmationDialog(
            activity.title ?? "Leave?",
            isPresented: Binding(
                get: { pending != nil || activity.wantsExit },
                set: { if !$0 { pending = nil; activity.cancelExit() } }
            ),
            titleVisibility: .visible
        ) {
            Button(L.t("progress.leave", "Leave"), role: .destructive) {
                if let pending {
                    activity.release()
                    selection = pending
                }
                pending = nil
            }
            Button(L.t("progress.stay", "Stay"), role: .cancel) { pending = nil }
        } message: {
            Text(activity.reason ?? "")
        }
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
}

extension RootView {
    /// Intercepts tab changes so an active run or game can ask first. When
    /// nothing is at stake the change goes straight through.
    var tabSelection: Binding<Tab> {
        Binding(
            get: { selection },
            set: { requested in
                guard requested != selection else { return }
                if activity.isActive {
                    pending = requested
                } else {
                    selection = requested
                }
            }
        )
    }
}

struct ProgressScreen: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            Section(L.t("progress.whereYouAre", "Where you are")) {
                LabeledContent(L.t("progress.overall", "Overall"), value: "\(app.progress.overallRating)")
                ForEach(TrainingMode.allCases, id: \.self) { mode in
                    LabeledContent(mode.rawValue.capitalized, value: "\(app.progress.rating(mode))")
                }
                Text(L.t("progress.puzzleRatingsRunAFew", "Puzzle ratings run a few hundred points above over-the-board ratings — treat them as a measure of progress against yourself."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(L.t("progress.today", "Today")) {
                let stats = app.progress.sessionStats()
                LabeledContent(L.t("progress.attempted", "Attempted"), value: "\(stats.attempted)")
                LabeledContent(L.t("progress.solved", "Solved"), value: "\(stats.solved)")
                LabeledContent(L.t("progress.accuracy", "Accuracy"), value: "\(Int(stats.accuracy * 100))%")
                LabeledContent(L.t("progress.dayStreak", "Day streak"), value: "\(app.progress.currentStreak)")
            }

            let weak = app.progress.weakestThemes()
            if !weak.isEmpty {
                Section(L.t("progress.weakSpots", "Weak spots")) {
                    let targeted = Set(app.progress.trainingTargets().map(\.name))
                    ForEach(weak, id: \.name) { theme in
                        HStack {
                            Text(Themes.readable(theme.name))
                            if targeted.contains(theme.name) {
                                Text("targeting")
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.tint.opacity(0.2), in: Capsule())
                            }
                            Spacer()
                            Text(L.t("progress.themeAccuracy", "%lld%% of %lld", Int(theme.record.accuracy * 100), theme.record.seen))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }

            if app.progress.onlineGames > 0 {
                Section(L.t("progress.online", "Online")) {
                    LabeledContent(L.t("progress.rating", "Rating"), value: "\(app.progress.onlineRating)")
                    LabeledContent(L.t("progress.record", "Record"), value: "\(app.progress.onlineWins)W · \(app.progress.onlineLosses)L · \(app.progress.onlineDraws)D")
                    Text(L.t("progress.onlineRatingIsKeptApart", "Online rating is kept apart from the training ratings: it measures you against the people you play, not against a library."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            let guesses = app.progress.eloGuessStats
            if guesses.judged > 0 {
                Section(L.t("progress.guessTheElo", "Guess the Elo")) {
                    LabeledContent(L.t("progress.gamesJudged", "Games judged"), value: "\(guesses.judged)")
                    LabeledContent(L.t("progress.averageMiss", "Average miss"), value: "\(guesses.averageError) points")
                    LabeledContent(L.t("progress.closest", "Closest"), value: "\(guesses.bestError) points")
                    if abs(guesses.bias) >= 40 {
                        Text(guesses.bias > 0
                            ? L.t("progress.biasHigh", "You read games as stronger than they are, by %lld points on average.", abs(guesses.bias))
                            : L.t("progress.biasLow", "You read games as weaker than they are, by %lld points on average.", abs(guesses.bias)))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }

            Section(L.t("progress.library", "Library")) {
                LabeledContent(L.t("progress.tacticsPuzzles", "Tactics puzzles"), value: "\(app.library.puzzles.count)")
                LabeledContent(L.t("progress.positional", "Positional"), value: "\(app.library.exercises.count)")
                LabeledContent(L.t("progress.endgames", "Endgames"), value: "\(app.library.drills.count)")
                LabeledContent(L.t("progress.games", "Games"), value: "\(app.library.games.count)")
                LabeledContent(L.t("progress.engine", "Engine"), value: engineText)
            }

            Section {
                ProUpsellRow()
            } footer: {
                if !app.store.isPro {
                    Text(L.t("store.freeToday", "Free today: %lld puzzles, %lld Rush run, %lld of each other exercise.",
                             app.progress.freeRemaining(.tactics),
                             app.progress.freeRemaining(.rush),
                             app.progress.freeRemaining(.positional)))
                }
            }

            Section {
                NavigationLink("About & licence") { AboutScreen() }
            }

            Section {
                Button(L.t("progress.resetAllProgress", "Reset all progress"), role: .destructive) { app.resetProgress() }
            }
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
