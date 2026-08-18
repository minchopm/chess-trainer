import ChessTraining
import SwiftUI

public struct RootView: View {
    @State private var app = AppModel()

    public init() {}

    public var body: some View {
        // The classic tabItem API rather than the newer Tab builder: that one
        // needs iOS 18, and there is no reason to exclude iOS 17 devices from a
        // trainer that asks nothing of the OS.
        TabView {
            NavigationStack { TacticsScreen().navigationTitle("Tactics") }
                .tabItem { Label("Tactics", systemImage: "target") }

            NavigationStack { PositionalScreen().navigationTitle("Positional") }
                .tabItem { Label("Positional", systemImage: "square.grid.3x3.middle.filled") }

            NavigationStack { EndgameScreen().navigationTitle("Endgames") }
                .tabItem { Label("Endgames", systemImage: "flag.checkered") }

            NavigationStack { PlayScreen().navigationTitle("Play") }
                .tabItem { Label("Play", systemImage: "person.2") }

            NavigationStack { ProgressScreen().navigationTitle("Progress") }
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .environment(app)
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
