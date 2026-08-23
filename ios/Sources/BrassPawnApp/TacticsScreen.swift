import ChessCore
import ChessTraining
import SwiftUI

struct TacticsScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = TacticsModel()
    @State private var values = MoveValueController()
    @State private var exhausted = false
    @State private var hasStartedAttempt = false
    @State private var hasCountedCompletion = false
    @State private var showsSolutionReplay = false
    #if DEBUG
    @Environment(Navigator.self) private var navigator
    @State private var hasRunPreview = false
    #endif

    var body: some View {
        content
            .allowanceGate(
                activity: .tactics,
                hasStartedAttempt: hasStartedAttempt,
                wasDenied: exhausted
            )
            .fullScreenCover(item: wrongFeedbackBinding) { feedback in
                WrongMoveOverlay(
                    feedback: feedback,
                    onDismiss: { model.dismissWrongFeedback() }
                )
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: completionIsPresented) {
                if showsSolutionReplay,
                   let puzzle = model.puzzle,
                   let start = Position(fen: puzzle.fen) {
                    ReplayViewer(
                        title: L.t("tactics.solutionTitle", "Solution"),
                        subtitle: L.t("common.sideToPlay", "%@ to play", L.color(puzzle.sideToMove)),
                        startingPosition: start,
                        notation: model.solutionReplayNotation,
                        onDismiss: { showsSolutionReplay = false }
                    )
                } else if let completion = model.completion {
                    CompletionOverlay(
                        result: completion,
                        primaryTitle: L.t("tactics.nextPuzzle", "Next puzzle"),
                        onPrimary: { next() },
                        onRetry: { model.retry() },
                        replayTitle: L.t("tactics.watchSolution", "Watch solution"),
                        onReplay: { showsSolutionReplay = true }
                    )
                    .presentationBackground(.clear)
                    .interactiveDismissDisabled()
                }
            }
    }

    private var content: some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: L.t("tactics.puzzle", "Puzzle"),
                    rating: model.puzzle?.rating,
                    color: model.orientation.opponent,
                    material: material
                ),
                bottom: PlayerBar(
                    name: L.t("tactics.you", "You"),
                    rating: app.progress.rating(.tactics),
                    color: model.orientation,
                    material: material
                )
            ) {
                GameBoard(
                    position: model.position,
                    orientation: model.orientation,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    shapes: model.shapes,
                    moveValues: values.displayedValues,
                    onMove: handleMove
                )
            }
        } panel: {
            if model.puzzle == nil {
                LibraryNotice(isLoaded: app.isLibraryLoaded, what: "puzzles", file: "tactics.json")
            } else {
                puzzleDetails
            }
        } controls: {
            controls
        }
        .task(id: app.library.puzzles.count) {
            if model.puzzle == nil { next() }
            #if DEBUG
            await runTacticsPreview()
            #endif
        }
    }

    @ViewBuilder
    private var puzzleDetails: some View {
        if let puzzle = model.puzzle {
            Card {
                Text(model.prompt).appFont(size: 22, weight: .semibold)
                Text(model.objective).appFont(.subheadline).foregroundStyle(Theatre.ivoryDim)

                if let why = model.reason.explanation {
                    Text(why).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                }

                if model.isReplying {
                    HStack(spacing: 6) {
                        BrassActivityIndicator(size: 15)
                        Text(L.t("tactics.opponentReplies", "Opponent replies…")).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                    }
                }

                // The rating already stands in the row above the board.
                TagRow(tags: [
                    puzzle.solverMoveCount == 1
                        ? L.t("common.oneMove", "1 move")
                        : L.t("common.moveCount", "%lld moves", puzzle.solverMoveCount),
                ])
            }

            // The completion overlay carries the verdict once the puzzle ends,
            // so the inline card would just repeat it behind the overlay.
            if let feedback = model.feedback,
               model.completion == nil,
               model.wrongFeedback == nil {
                FeedbackCard(feedback: feedback)
            }

            if model.isFinished {
                Card {
                    Text(L.t("tactics.themes", "Themes")).appFont(.caption).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
                    TagRow(tags: motifsFirst(puzzle.themes).map(Themes.readable))
                }
            }
        }
    }

    private var controls: some View {
        ActionBar(items: [
            ActionItem(title: L.t("tactics.hint", "Hint"), systemImage: "lightbulb", isEnabled: !model.isFinished) {
                guard beginAttempt() else { return }
                model.requestHint()
            },
            ActionItem(title: values.isEnabled ? L.t("common.hide", "Hide") : L.t("common.values", "Values"),
                       systemImage: "number.square", isEnabled: !model.isFinished) {
                if values.isEnabled {
                    values.toggle(fen: model.position.fen, engine: app.engine)
                    return
                }
                guard beginAttempt() else { return }
                model.noteAidUsed()
                values.toggle(fen: model.position.fen, engine: app.engine)
            },
            ActionItem(title: L.t("tactics.solution", "Solution"), systemImage: "eye", isEnabled: !model.isFinished) {
                guard beginAttempt() else { return }
                record(model.revealSolution())
            },
            ActionItem(title: skipTitle, systemImage: "forward.end",
                       emphasis: model.isFinished ? .normal : .primary,
                       isEnabled: canSkip) {
                skipPuzzle()
            },
        ])
    }

    private var material: MaterialBalance { MaterialBalance(model.position) }

    private var wrongFeedbackBinding: Binding<TacticsModel.Feedback?> {
        Binding(
            get: { model.wrongFeedback },
            set: { feedback in
                if feedback == nil { model.dismissWrongFeedback() }
            }
        )
    }

    private var completionIsPresented: Binding<Bool> {
        Binding(
            get: { model.completion != nil },
            set: { _ in }
        )
    }

    private func handleMove(from: Square, to: Square, promotion: PieceKind?) {
        guard beginAttempt() else { return }
        Task {
            record(await model.play(from: from, to: to, promotion: promotion))
            await values.refresh(fen: model.position.fen, engine: app.engine)
        }
    }

    private func record(_ outcome: (solved: Bool, usedHint: Bool)?) {
        guard let outcome, let puzzle = model.puzzle else { return }
        // Tactics grants one *completed puzzle*, not one attempt. Wrong moves,
        // hints and skipping do not spend it. The first finish (solved or
        // revealed) does; replaying that same puzzle afterwards remains free
        // practice and is not recorded twice.
        guard !hasCountedCompletion, app.beginAttempt(.tactics) else { return }
        hasCountedCompletion = true
        app.update { progress in
            progress.record(
                mode: .tactics,
                itemID: puzzle.id,
                itemRating: puzzle.rating,
                correct: outcome.solved,
                themes: puzzle.themes,
                usedHint: outcome.usedHint
            )
        }
    }

    private func next() {
        showsSolutionReplay = false
        exhausted = false
        hasStartedAttempt = false
        hasCountedCompletion = false
        values.reset()
        model.load(ItemSelector.nextPuzzle(from: app.library.puzzles, progress: app.progress))
    }

    private func skipPuzzle() {
        guard model.puzzle != nil, !model.isFinished, app.useTacticsSkip() else { return }
        next()
    }

    private var canSkip: Bool {
        guard model.puzzle != nil, !model.isFinished else { return false }
        return app.store.isPro || app.progress.freeTacticsSkipsRemaining() > 0
    }

    private var skipTitle: String {
        guard !app.store.isPro else { return L.t("tactics.skip", "Skip") }
        return L.t(
            "tactics.skipRemaining",
            "Skip · %lld",
            app.progress.freeTacticsSkipsRemaining()
        )
    }

    #if DEBUG
    /// Solve puzzles for the recorded preview, then hand over to the game.
    ///
    /// The moves come from the puzzle's own solution rather than from an
    /// engine: the point is to show the training working at the pace someone
    /// would actually see it, and a search would both take longer and
    /// occasionally disagree with the puzzle.
    private func runTacticsPreview() async {
        guard ScreenshotScene.requested == .demoTactics,
              !app.library.puzzles.isEmpty, !hasRunPreview else { return }
        hasRunPreview = true

        // The screen is mounted behind the menu from launch, so wait for the
        // menu to go before solving anything anybody can see.
        while navigator.showsMenu { try? await Task.sleep(for: .milliseconds(50)) }
        try? await Task.sleep(for: .milliseconds(700))

        // Two, not three. The brief is a third of the recording on the
        // training and the rest on the game, and a third of half a minute is
        // two puzzles at a pace anybody can follow.
        for _ in 0..<2 {
            await solveCurrentPuzzle()
            try? await Task.sleep(for: .milliseconds(900))
            next()
            try? await Task.sleep(for: .milliseconds(600))
        }

        // On to the game, where the same board says what each move is worth.
        navigator.playMode = .play
        navigator.pendingTab = .play
    }

    /// Play the solver's side of the current puzzle, a move at a time.
    ///
    /// Bounded rather than "until finished": a move the model declines to
    /// accept would otherwise leave this spinning, and a preview that hangs is
    /// worse than one that moves on.
    private func solveCurrentPuzzle() async {
        for _ in 0..<8 {
            guard let uci = model.expectedSolverMove,
                  let from = Square(String(uci.prefix(2))),
                  let to = Square(String(uci.dropFirst(2).prefix(2)))
            else { return }
            let promotion = uci.count > 4 ? PieceKind(letter: Array(uci)[4]) : nil
            handleMove(from: from, to: to, promotion: promotion)
            // Long enough for the model's own pause on the opponent's reply,
            // which is what makes the line readable rather than a jump.
            try? await Task.sleep(for: .milliseconds(1100))
        }
    }
    #endif

    private func beginAttempt() -> Bool {
        guard model.puzzle != nil, !model.isFinished else { return false }
        guard !hasStartedAttempt else { return true }
        guard app.hasAllowance(for: .tactics) else {
            exhausted = true
            return false
        }
        exhausted = false
        hasStartedAttempt = true
        return true
    }

    /// Show the skills first; the descriptive tags are filler beside them.
    private func motifsFirst(_ themes: [String]) -> [String] {
        (themes.filter(Themes.isMotif) + themes.filter { !Themes.isMotif($0) }).prefix(7).map { $0 }
    }
}

private struct WrongMoveOverlay: View {
    let feedback: TacticsModel.Feedback
    let onDismiss: () -> Void

    var body: some View {
        BrassModalBackdrop(onBackdropTap: onDismiss) {
            BrassModalPanel(tint: Theatre.bad) {
                Text(feedback.title)
                    .appFont(.title2, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)

                ForEach(feedback.lines, id: \.self) { line in
                    Text(line)
                        .appFont(.subheadline)
                        .foregroundStyle(Theatre.ivoryDim)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(L.t("common.tryAgain", "Try again"), action: onDismiss)
                    .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
