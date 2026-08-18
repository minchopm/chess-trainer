import ChessTraining
import SwiftUI

public struct RootView: View {
    @State private var app = AppModel()
    @State private var activity = ActivityGuard()
    @State private var selection = Tab.tactics
    @State private var pending: Tab?

    enum Tab: Hashable { case tactics, positional, endgames, play, progress }

    public init() {}

    public var body: some View {
        // The classic tabItem API rather than the newer Tab builder: that one
        // needs iOS 18, and there is no reason to exclude iOS 17 devices from a
        // trainer that asks nothing of the OS.
        TabView(selection: tabSelection) {
            NavigationStack { TrainingTab() }
                .tabItem { Label("Tactics", systemImage: "target") }
                .tag(Tab.tactics)

            NavigationStack { PositionalScreen().navigationTitle("Positional") }
                .tabItem { Label("Positional", systemImage: "square.grid.3x3.middle.filled") }
                .tag(Tab.positional)

            NavigationStack { EndgameScreen().navigationTitle("Endgames") }
                .tabItem { Label("Endgames", systemImage: "flag.checkered") }
                .tag(Tab.endgames)

            NavigationStack { PlayScreen().navigationTitle("Play") }
                .tabItem { Label("Play", systemImage: "person.2") }
                .tag(Tab.play)

            NavigationStack { ProgressScreen().navigationTitle("Progress") }
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.progress)
        }
        .environment(app)
        .environment(activity)
        .confirmationDialog(
            activity.title ?? "Leave?",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) {
                if let pending {
                    activity.release()
                    selection = pending
                }
                pending = nil
            }
            Button("Stay", role: .cancel) { pending = nil }
        } message: {
            Text(activity.reason ?? "")
        }
        .task { await app.start() }
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
            Section("Where you are") {
                LabeledContent("Overall", value: "\(app.progress.overallRating)")
                ForEach(TrainingMode.allCases, id: \.self) { mode in
                    LabeledContent(mode.rawValue.capitalized, value: "\(app.progress.rating(mode))")
                }
                Text("Puzzle ratings run a few hundred points above over-the-board ratings — treat them as a measure of progress against yourself.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Today") {
                let stats = app.progress.sessionStats()
                LabeledContent("Attempted", value: "\(stats.attempted)")
                LabeledContent("Solved", value: "\(stats.solved)")
                LabeledContent("Accuracy", value: "\(Int(stats.accuracy * 100))%")
                LabeledContent("Day streak", value: "\(app.progress.currentStreak)")
            }

            let weak = app.progress.weakestThemes()
            if !weak.isEmpty {
                Section("Weak spots") {
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
                            Text("\(Int(theme.record.accuracy * 100))% of \(theme.record.seen)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }

            Section("Library") {
                LabeledContent("Tactics puzzles", value: "\(app.library.puzzles.count)")
                LabeledContent("Positional", value: "\(app.library.exercises.count)")
                LabeledContent("Endgames", value: "\(app.library.drills.count)")
                LabeledContent("Engine", value: engineText)
            }

            Section {
                NavigationLink("About & licence") { AboutScreen() }
            }

            Section {
                Button("Reset all progress", role: .destructive) { app.resetProgress() }
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
