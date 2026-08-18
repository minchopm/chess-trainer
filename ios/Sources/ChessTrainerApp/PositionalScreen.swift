import ChessCore
import ChessEngine
import ChessTraining
import Observation
import SwiftUI

/// The five assessments, and the evaluation band each covers, in centipawns
/// from White's point of view.
enum Judgement: String, CaseIterable, Identifiable {
    case whiteClear, whiteSlight, balanced, blackSlight, blackClear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .whiteClear: "White is clearly better"
        case .whiteSlight: "White is slightly better"
        case .balanced: "Balanced"
        case .blackSlight: "Black is slightly better"
        case .blackClear: "Black is clearly better"
        }
    }

    static func correct(for centipawns: Int) -> Judgement {
        switch centipawns {
        case 120...: .whiteClear
        case 35..<120: .whiteSlight
        case -35..<35: .balanced
        case -120 ..< -35: .blackSlight
        default: .blackClear
        }
    }
}

@MainActor
@Observable
final class PositionalModel {
    enum Phase { case judging, choosing, done }

    private(set) var exercise: PositionalExercise?
    private(set) var position = Position()
    private(set) var legalDestinations: [Square: [Square]] = [:]
    private(set) var shapes: [BoardShape] = []
    private(set) var phase = Phase.judging
    private(set) var chosenJudgement: Judgement?
    private(set) var judgementWasRight = false
    private(set) var summary: [String] = []
    private(set) var result: Result?
    private(set) var isThinking = false

    struct Result {
        let tone: FeedbackTone
        let title: String
        let lines: [String]
    }

    var orientation: PieceColor { exercise?.sideToMove ?? .white }

    var correctJudgement: Judgement? {
        exercise.map { Judgement.correct(for: $0.cp) }
    }

    func load(_ next: PositionalExercise?) {
        guard let next, let start = Position(fen: next.fen) else {
            exercise = nil
            return
        }
        exercise = next
        position = start
        phase = .judging
        chosenJudgement = nil
        judgementWasRight = false
        result = nil
        shapes = []
        summary = []
        legalDestinations = [:]
    }

    func judge(_ judgement: Judgement) {
        guard phase == .judging, let exercise else { return }
        chosenJudgement = judgement
        judgementWasRight = judgement == Judgement.correct(for: exercise.cp)
        summary = MoveDescription.summary(PositionFeatures(position))
        phase = .choosing

        var map: [Square: [Square]] = [:]
        for move in position.legalMoves() { map[move.from, default: []].append(move.to) }
        legalDestinations = map
    }

    /// Grade the chosen move. Precomputed candidates answer instantly; anything
    /// else asks the engine, which is why this is async.
    func choose(
        from: Square, to: Square, promotion: PieceKind?, engine: StockfishEngine
    ) async -> Bool? {
        guard phase == .choosing, let exercise else { return nil }
        var probe = position
        guard let move = probe.make(Move(from: from, to: to, promotion: promotion)) else { return nil }

        phase = .done
        legalDestinations = [:]
        isThinking = true
        defer { isThinking = false }

        let uci = move.uci
        let known = ([exercise.best] + exercise.alternatives).first { $0.uci == uci }

        var playedCp: Int
        if let known {
            playedCp = known.cp
        } else if probe.isCheckmate {
            playedCp = 10_000
        } else if probe.isDraw {
            playedCp = 0
        } else if let analysis = try? await engine.analyse(fen: probe.fen, depth: 14, multiPV: 1),
                  let line = analysis.lines.first {
            playedCp = CoachService.score(line.score, for: position.sideToMove, toMove: probe.sideToMove)
        } else {
            playedCp = exercise.best.cp
        }

        let lost = max(0, Coach.winProbability(exercise.best.cp) - Coach.winProbability(playedCp))
        let tone: FeedbackTone = lost <= 0.02 ? .correct : (lost <= 0.06 ? .partial : .wrong)

        let bestMove = Move(uci: exercise.best.uci)
            .flatMap { candidate in position.legalMoves().first { $0.matchesNotation(of: candidate) } }
        if let bestMove {
            shapes = [.arrow(bestMove.from, bestMove.to, .good)]
        }

        var lines: [String] = []
        if tone != .correct, let bestMove {
            var afterBest = position
            afterBest.make(bestMove)
            let reasons = MoveDescription.clauses(
                before: PositionFeatures(position), after: PositionFeatures(afterBest),
                move: bestMove, position: position, resulting: afterBest
            )
            let why = reasons.isEmpty ? "" : " — it \(MoveDescription.join(reasons))"
            lines.append("The engine prefers \(position.san(for: bestMove))\(why).")
        }
        lines.append(String(
            format: "Your move: %.2f · best: %.2f · cost: %.1f%% win probability.",
            Double(playedCp) / 100, Double(exercise.best.cp) / 100, lost * 100
        ))
        if let pv = exercise.best.pv {
            lines.append("Main line: \(CoachService.notation(from: position, uciMoves: pv, limit: 8))")
        }

        let played = position.san(for: move)
        result = Result(
            tone: tone,
            title: tone == .correct
                ? "\(played) — the engine's choice too"
                : (tone == .partial ? "\(played) is playable" : "\(played) makes it worse"),
            lines: lines
        )

        return judgementWasRight && tone != .wrong
    }
}

enum FeedbackTone { case correct, partial, wrong, neutral }

struct PositionalScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = PositionalModel()

    var body: some View {
        TrainingLayout {
            BoardView(
                position: model.position,
                orientation: model.orientation,
                legalDestinations: model.legalDestinations,
                shapes: model.shapes,
                onMove: { from, to, promotion in
                    Task { await choose(from, to, promotion) }
                }
            )
        } panel: {
            if model.exercise == nil {
                Card {
                    Text("No positional exercises bundled").font(.headline)
                    Text("Generate them with scripts/generate-positions.mjs in the web project, then copy positions.json into Resources/Data.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                content
            }
        } controls: {
            HStack {
                Spacer()
                Button(model.phase == .done ? "Next position" : "Skip") { next() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .task { if model.exercise == nil { next() } }
    }

    @ViewBuilder
    private var content: some View {
        Card {
            Text("\(model.orientation == .white ? "White" : "Black") to move — how do you assess this?")
                .font(.headline)
            Text("No tactics here. Weigh structure, activity, king safety and space.")
                .font(.subheadline).foregroundStyle(.secondary)
        }

        if model.phase == .judging {
            VStack(spacing: 8) {
                ForEach(Judgement.allCases) { judgement in
                    Button { model.judge(judgement) } label: {
                        Text(judgement.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
            }
        } else {
            judgementResult
        }

        if model.isThinking {
            HStack(spacing: 6) {
                ProgressView()
                Text("Checking your move with the engine…").font(.footnote).foregroundStyle(.secondary)
            }
        }

        if let result = model.result {
            Card {
                HStack(spacing: 8) {
                    Rectangle().fill(color(for: result.tone)).frame(width: 3)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.title).font(.subheadline.weight(.semibold))
                        ForEach(result.lines, id: \.self) { line in
                            Text(line).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var judgementResult: some View {
        if let exercise = model.exercise, let correct = model.correctJudgement {
            Card {
                HStack(spacing: 8) {
                    Rectangle().fill(color(for: model.judgementWasRight ? .correct : .partial)).frame(width: 3)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.judgementWasRight
                             ? "Right read"
                             : "Engine says: \(correct.label.lowercased()) (\(EngineScore.centipawns(exercise.cp).text))")
                            .font(.subheadline.weight(.semibold))
                        ForEach(model.summary, id: \.self) { line in
                            Text(line).font(.footnote).foregroundStyle(.secondary)
                        }
                        if model.phase == .choosing {
                            Text("Now play the move you would choose.")
                                .font(.subheadline.weight(.semibold))
                                .padding(.top, 2)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func color(for tone: FeedbackTone) -> Color {
        switch tone {
        case .correct: Color(red: 0.424, green: 0.749, blue: 0.451)
        case .partial: Color(red: 0.867, green: 0.706, blue: 0.353)
        case .wrong: Color(red: 0.851, green: 0.439, blue: 0.373)
        case .neutral: Color.secondary
        }
    }

    private func choose(_ from: Square, _ to: Square, _ promotion: PieceKind?) async {
        guard let correct = await model.choose(
            from: from, to: to, promotion: promotion, engine: app.engine
        ), let exercise = model.exercise else { return }

        app.update { progress in
            progress.record(
                mode: .positional, itemID: exercise.id, itemRating: exercise.rating,
                correct: correct, themes: exercise.themes
            )
        }
    }

    private func next() {
        model.load(ItemSelector.nextExercise(from: app.library.exercises, progress: app.progress))
    }
}
