import ChessCore
import ChessTraining
import SwiftUI

struct TacticsScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = TacticsModel()
    @State private var values = MoveValueController()

    var body: some View {
        content
            .overlay(alignment: .bottom) {
                if let completion = model.completion {
                    CompletionOverlay(
                        result: completion,
                        primaryTitle: L.t("tactics.nextPuzzle", "Next puzzle"),
                        onPrimary: next,
                        onRetry: { model.retry() }
                    )
                    .padding(.bottom, 8)
                }
            }
            .animation(.spring(duration: 0.35), value: model.completion)
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
                BoardView(
                    position: model.position,
                    orientation: model.orientation,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    shapes: model.shapes,
                    moveValues: values.values,
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
        .task(id: app.library.puzzles.count) { if model.puzzle == nil { next() } }
    }

    @ViewBuilder
    private var puzzleDetails: some View {
        if let puzzle = model.puzzle {
            Card {
                Text(model.prompt).font(.headline)
                Text(model.objective).font(.subheadline).foregroundStyle(.secondary)

                if let why = model.reason.explanation {
                    Text(why).font(.footnote).foregroundStyle(.secondary)
                }

                if model.isReplying {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text(L.t("tactics.opponentReplies", "Opponent replies…")).font(.footnote).foregroundStyle(.secondary)
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
            if let feedback = model.feedback, model.completion == nil {
                FeedbackCard(feedback: feedback)
            }

            if model.isFinished {
                Card {
                    Text(L.t("tactics.themes", "Themes")).font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                    TagRow(tags: motifsFirst(puzzle.themes).map(Themes.readable))
                }
            }
        }
    }

    private var controls: some View {
        ActionBar(items: [
            ActionItem(title: L.t("tactics.hint", "Hint"), systemImage: "lightbulb", isEnabled: !model.isFinished) {
                model.requestHint()
            },
            ActionItem(title: values.isEnabled ? L.t("common.hide", "Hide") : L.t("common.values", "Values"),
                       systemImage: "number.square", isEnabled: !model.isFinished) {
                model.noteAidUsed()
                Task { await values.toggle(fen: model.position.fen, engine: app.engine) }
            },
            ActionItem(title: L.t("tactics.solution", "Solution"), systemImage: "eye", isEnabled: !model.isFinished) {
                record(model.revealSolution())
            },
            ActionItem(title: L.t("tactics.skip", "Skip"), systemImage: "forward.end",
                       emphasis: model.isFinished ? .normal : .primary,
                       isEnabled: !model.isFinished) {
                next()
            },
        ])
    }

    private var material: MaterialBalance { MaterialBalance(model.position) }

    private func handleMove(from: Square, to: Square, promotion: PieceKind?) {
        Task {
            record(await model.play(from: from, to: to, promotion: promotion))
            await values.refresh(fen: model.position.fen, engine: app.engine)
        }
    }

    private func record(_ outcome: (solved: Bool, usedHint: Bool)?) {
        guard let outcome, let puzzle = model.puzzle else { return }
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
        values.reset()
        model.load(ItemSelector.nextPuzzle(from: app.library.puzzles, progress: app.progress))
    }

    /// Show the skills first; the descriptive tags are filler beside them.
    private func motifsFirst(_ themes: [String]) -> [String] {
        (themes.filter(Themes.isMotif) + themes.filter { !Themes.isMotif($0) }).prefix(7).map { $0 }
    }
}
