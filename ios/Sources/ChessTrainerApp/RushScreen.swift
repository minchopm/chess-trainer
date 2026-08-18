import ChessCore
import ChessTraining
import Observation
import SwiftUI


@MainActor
@Observable
final class RushModel {
    enum Phase: Equatable { case setup, running, finished }

    private(set) var phase = Phase.setup
    private(set) var run: RushRun?
    private(set) var puzzle: Puzzle?
    private(set) var position = Position()
    private(set) var legalDestinations: [Square: [Square]] = [:]
    private(set) var lastMove: (from: Square, to: Square)?
    private(set) var remaining: TimeInterval = 0
    private(set) var flash: Flash?
    private(set) var summary: RushRun?

    var settings = RushSettings()

    /// Brief feedback between puzzles — a run has no room for a paragraph.
    struct Flash: Equatable {
        let solved: Bool
        let text: String
    }

    private var step = 0
    private var used: Set<String> = []
    private var ticker: Task<Void, Never>?
    private var library: [Puzzle] = []
    private var practiceRating = 1200

    var isRunning: Bool { phase == .running }
    var orientation: PieceColor { puzzle?.sideToMove ?? .white }

    var clockText: String {
        let seconds = Int(remaining.rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// Red for the last thirty seconds, so the clock is felt as well as read.
    var clockIsUrgent: Bool { remaining <= 30 }

    func start(library: [Puzzle], practiceRating: Int) {
        self.library = library
        self.practiceRating = practiceRating
        used = []
        summary = nil
        flash = nil
        run = RushRun(settings: settings)
        remaining = settings.duration
        phase = .running
        advance()

        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, let run = self.run, self.phase == .running else { return }
                self.remaining = run.remaining()
                if !run.hasTimeLeft() { self.finish() }
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        if phase == .running { finish() }
    }

    func reset() {
        ticker?.cancel()
        ticker = nil
        phase = .setup
        run = nil
        puzzle = nil
        summary = nil
        flash = nil
    }

    /// @returns true when the attempt finished the puzzle, with the outcome.
    func play(from: Square, to: Square, promotion: PieceKind?) async -> Bool? {
        guard phase == .running, let puzzle, step < puzzle.solution.count else { return nil }

        let expected = puzzle.solution[step]
        let attempted = "\(from)\(to)\(promotion?.letter.description ?? "")"
        guard attempted == expected || "\(from)\(to)" == String(expected.prefix(4)) else {
            return conclude(solved: false)
        }

        apply(uci: expected)
        step += 1
        if step >= puzzle.solution.count { return conclude(solved: true) }

        legalDestinations = [:]
        try? await Task.sleep(for: .milliseconds(260))
        guard phase == .running, let current = self.puzzle, step < current.solution.count else { return nil }
        apply(uci: current.solution[step])
        step += 1

        if step >= current.solution.count { return conclude(solved: true) }
        refreshDestinations()
        return nil
    }

    private func conclude(solved: Bool) -> Bool {
        guard var current = run else { return solved }
        current.record(solved: solved)
        run = current

        flash = Flash(
            solved: solved,
            text: solved
                ? (current.streak >= 3 ? "\(current.streak) in a row" : "Solved")
                : "Missed — \(RushRun.allowedMisses - current.missed) left"
        )

        if current.isOver || !current.hasTimeLeft() {
            finish()
        } else {
            advance()
        }
        return solved
    }

    private func advance() {
        guard let current = run else { return }
        let next = ItemSelector.nextRushPuzzle(
            from: library,
            targetRating: current.targetRating(practiceRating: practiceRating),
            excluding: used
        )
        guard let next, let start = Position(fen: next.fen) else {
            finish()
            return
        }
        used.insert(next.id)
        puzzle = next
        position = start
        step = 0
        lastMove = nil
        refreshDestinations()
    }

    private func finish() {
        ticker?.cancel()
        ticker = nil
        summary = run
        phase = .finished
        legalDestinations = [:]
    }

    private func apply(uci: String) {
        guard let move = Move(uci: uci), let made = position.make(move) else { return }
        lastMove = (from: made.from, to: made.to)
    }

    private func refreshDestinations() {
        var map: [Square: [Square]] = [:]
        for move in position.legalMoves() { map[move.from, default: []].append(move.to) }
        legalDestinations = map
    }
}

struct RushScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(ActivityGuard.self) private var activity
    @State private var model = RushModel()

    private var material: MaterialBalance { MaterialBalance(model.position) }

    var body: some View {
        Group {
            switch model.phase {
            case .setup: setup
            case .running, .finished: playing
            }
        }
        .sheet(isPresented: .constant(model.phase == .finished)) {
            if let summary = model.summary { RushSummary(run: summary, model: model, app: app) }
        }
        .onDisappear {
            model.stop()
            activity.release()
        }
        .onChange(of: model.isRunning) { _, running in
            if running {
                activity.hold(
                    title: "End your run?",
                    reason: "The clock is still going. Leaving now ends the run and keeps the score so far."
                )
            } else {
                activity.release()
            }
        }
    }

    private var setup: some View {
        ScrollView {
            VStack(spacing: 14) {
                Card {
                    Text("Rush").font(.headline)
                    Text("Solve as many as you can before the clock runs out. Puzzles start easy and get harder as you go. Three misses ends the run.")
                        .font(.footnote).foregroundStyle(.secondary)

                    Picker("Time", selection: Binding(
                        get: { model.settings.duration },
                        set: { model.settings.duration = $0 }
                    )) {
                        ForEach(RushSettings.choices, id: \.self) { choice in
                            Text(RushSettings.label(for: choice)).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)

                    Button("Start run") {
                        model.start(
                            library: app.library.puzzles,
                            practiceRating: app.progress.rating(.tactics)
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                }

                if !records.isEmpty {
                    Card {
                        Text("Your best").font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                        ForEach(records, id: \.key) { entry in
                            HStack {
                                Text(RushSettings.label(for: TimeInterval(entry.key)))
                                Spacer()
                                Text("\(entry.value.solved) solved · best streak \(entry.value.bestStreak)")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.footnote)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private var records: [(key: Int, value: RushRecord)] {
        app.progress.rushRecordsByDuration.sorted { $0.key < $1.key }
    }

    private var playing: some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: "Puzzle",
                    rating: model.puzzle?.rating,
                    color: model.orientation.opponent,
                    material: material
                ),
                bottom: PlayerBar(
                    name: "You",
                    rating: app.progress.rating(.tactics),
                    color: model.orientation,
                    material: material
                )
            ) {
                BoardView(
                    position: model.position,
                    orientation: model.orientation,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    onMove: { from, to, promotion in
                        Task { _ = await model.play(from: from, to: to, promotion: promotion) }
                    }
                )
            }
        } panel: {
            scoreboard
        } controls: {
            ActionBar(items: [
                ActionItem(title: "End run", systemImage: "stop.circle", emphasis: .destructive) {
                    model.stop()
                },
            ])
        }
    }

    private var scoreboard: some View {
        Card {
            HStack(alignment: .firstTextBaseline) {
                Text(model.clockText)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(model.clockIsUrgent ? Color.red : Color.primary)
                    .contentTransition(.numericText(countsDown: true))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(model.run?.solved ?? 0) / \(model.settings.target)")
                        .font(.title3.weight(.semibold)).monospacedDigit()
                    Text(missesText).font(.caption).foregroundStyle(.secondary)
                }
            }

            if let flash = model.flash {
                Label(flash.text, systemImage: flash.solved ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(flash.solved ? Color.green : Color.red)
                    .transition(.opacity)
                    .id(flash.text)
            }

            if let puzzle = model.puzzle {
                Text("\(puzzle.sideToMove == .white ? "White" : "Black") to play")
                    .font(.subheadline.weight(.medium))
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.flash)
    }

    private var missesText: String {
        let missed = model.run?.missed ?? 0
        let left = RushRun.allowedMisses - missed
        return "\(left) miss\(left == 1 ? "" : "es") left"
    }
}

struct RushSummary: View {
    let run: RushRun
    let model: RushModel
    let app: AppModel

    @State private var recorded = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: run.completedTarget ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 44))
                .foregroundStyle(run.completedTarget ? Color.yellow : Color.accentColor)
                .padding(.top, 28)

            Text(headline).font(.title2.weight(.semibold))

            HStack(spacing: 28) {
                stat("\(run.solved)", "solved")
                stat("\(run.bestStreak)", "best streak")
                stat("\(run.missed)", "missed")
            }

            if let best = app.progress.rushRecordsByDuration[Int(run.settings.duration)],
               run.solved >= best.solved {
                Label("New personal best", systemImage: "sparkles")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.yellow)
            }

            Spacer()

            VStack(spacing: 10) {
                Button("Run again") {
                    model.start(library: app.library.puzzles, practiceRating: app.progress.rating(.tactics))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Done") { model.reset() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
        .onAppear {
            guard !recorded else { return }
            recorded = true
            app.update {
                $0.record(rush: RushRecord(
                    solved: run.solved, bestStreak: run.bestStreak,
                    duration: run.settings.duration, achievedAt: Date()
                ))
            }
        }
    }

    private var headline: String {
        if run.completedTarget { return "All \(run.settings.target) done" }
        if run.endedByMisses { return "Three misses" }
        return "Time"
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title.weight(.semibold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
