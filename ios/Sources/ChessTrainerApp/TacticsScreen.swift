import ChessCore
import ChessTraining
import SwiftUI

struct TacticsScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = TacticsModel()
    @State private var values = MoveValueController()

    var body: some View {
        TrainingLayout {
            BoardView(
                position: model.position,
                orientation: model.orientation,
                legalDestinations: model.legalDestinations,
                lastMove: model.lastMove,
                shapes: model.shapes,
                moveValues: values.values,
                onMove: handleMove
            )
        } panel: {
            if model.puzzle == nil {
                EmptyLibraryNotice()
            } else {
                puzzleDetails
            }
        } controls: {
            controls
        }
        .task { if model.puzzle == nil { next() } }
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

                TagRow(tags: [
                    "Rating \(puzzle.rating)",
                    "\(puzzle.solverMoveCount) move\(puzzle.solverMoveCount == 1 ? "" : "s")",
                ])
            }

            if let feedback = model.feedback {
                FeedbackCard(feedback: feedback)
            }

            if model.isFinished {
                Card {
                    Text("Themes").font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                    TagRow(tags: motifsFirst(puzzle.themes).map(Themes.readable))
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button("Hint") { model.requestHint() }
                .disabled(model.isFinished)
            Button(values.isEnabled ? "Hide values" : "Values") {
                // Seeing every move's value is a stronger hint than the hint
                // button, so it is scored the same way.
                model.noteAidUsed()
                Task { await values.toggle(fen: model.position.fen, engine: app.engine) }
            }
            .disabled(model.isFinished)
            Button("Solution") { record(model.revealSolution()) }
                .disabled(model.isFinished)
            Spacer()
            Button(model.isFinished ? "Next puzzle" : "Skip") { next() }
                .buttonStyle(.borderedProminent)
        }
        .buttonStyle(.bordered)
    }

    private func handleMove(from: Square, to: Square, promotion: PieceKind?) {
        record(model.play(from: from, to: to, promotion: promotion))
        Task { await values.refresh(fen: model.position.fen, engine: app.engine) }
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
