import ChessCore
import ChessEngine
import ChessTraining
import Observation
import SwiftUI

struct OpponentLevel: Identifiable, Hashable {
    let id: Int
    let name: String
    /// nil means no limit — Stockfish at full strength.
    let elo: Int?

    var label: String { elo.map { "\(name) (\($0))" } ?? name }

    static let all: [OpponentLevel] = [
        OpponentLevel(id: 0, name: "Casual", elo: 1400),
        OpponentLevel(id: 1, name: "Club", elo: 1800),
        OpponentLevel(id: 2, name: "Strong club", elo: 2100),
        OpponentLevel(id: 3, name: "Expert", elo: 2400),
        OpponentLevel(id: 4, name: "Master", elo: 2700),
        OpponentLevel(id: 5, name: "Full strength", elo: nil),
    ]
}

@MainActor
@Observable
final class PlayModel {
    private(set) var position = Position()
    private(set) var legalDestinations: [Square: [Square]] = [:]
    private(set) var lastMove: (from: Square, to: Square)?
    private(set) var shapes: [BoardShape] = []
    private(set) var evaluation: EngineScore?
    private(set) var moves: [(san: String, grade: MoveGrade?)] = []
    private(set) var latestReview: MoveReview?
    private(set) var isThinking = false
    private(set) var hasStarted = false
    private(set) var summary: GameSummary?

    var side: PieceColor = .white
    var level = OpponentLevel.all[1]
    var coachingEnabled = true

    struct GameSummary {
        let result: String
        let accuracy: Int
        let blunders: Int
        let mistakes: Int
        let inaccuracies: Int
        let costliest: String?
    }

    private var losses: [Int] = []

    var statusText: String {
        if position.isCheckmate {
            return position.sideToMove == side ? "Checkmate — you lost." : "Checkmate — you won."
        }
        if position.isDraw { return "Draw." }
        if isThinking { return "Engine is thinking…" }
        return position.sideToMove == side ? "Your move." : "Engine to move."
    }

    func start(engine: StockfishEngine) async {
        position = Position()
        moves = []
        losses = []
        latestReview = nil
        summary = nil
        shapes = []
        lastMove = nil
        evaluation = .centipawns(20)
        hasStarted = true

        await engine.newGame()
        if side == .black { await playEngineMove(engine: engine) }
        refreshDestinations()
    }

    func play(from: Square, to: Square, promotion: PieceKind?, engine: StockfishEngine) async {
        guard hasStarted, !isThinking, position.sideToMove == side, !position.isGameOver else { return }
        guard let move = position.legalMoves().first(where: {
            $0.matchesNotation(of: Move(from: from, to: to, promotion: promotion))
        }) else { return }

        let before = position
        let san = position.san(for: move)
        position.make(move)
        lastMove = (from: move.from, to: move.to)
        moves.append((san: san, grade: nil))
        legalDestinations = [:]
        shapes = []
        isThinking = true

        if coachingEnabled {
            let coach = CoachService(engine: engine)
            if let review = try? await coach.review(position: before, move: move) {
                latestReview = review
                moves[moves.count - 1].grade = review.assessment.grade
                losses.append(review.assessment.centipawnsLost)
                evaluation = review.scoreAfter
            }
        }

        if position.isGameOver {
            isThinking = false
            finish()
            return
        }

        await playEngineMove(engine: engine)
        isThinking = false

        if position.isGameOver { finish() } else { refreshDestinations() }
    }

    func takeBack() {
        // Undo is a position rebuild rather than a move stack: replaying from
        // the start is instant at these lengths and cannot drift out of step
        // with the board the way an undo stack can.
        guard moves.count >= 2 else { return }
        moves.removeLast(2)
        losses = Array(losses.dropLast())
        var replay = Position()
        for entry in moves {
            guard let move = replay.move(san: entry.san) else { break }
            replay.make(move)
        }
        position = replay
        latestReview = nil
        lastMove = nil
        refreshDestinations()
    }

    func hint(engine: StockfishEngine) async {
        guard !isThinking, position.sideToMove == side else { return }
        isThinking = true
        defer { isThinking = false }
        guard let analysis = try? await engine.analyse(fen: position.fen, depth: 13, multiPV: 1),
              let uci = analysis.lines.first?.bestMove,
              let parsed = Move(uci: uci),
              let move = position.legalMoves().first(where: { $0.matchesNotation(of: parsed) })
        else { return }
        shapes = [.arrow(move.from, move.to, .suggestion)]
    }

    private func playEngineMove(engine: StockfishEngine) async {
        guard let uci = try? await engine.chooseMove(
            fen: position.fen,
            elo: level.elo,
            depth: level.elo == nil ? 16 : 12,
            movetimeMs: level.elo == nil ? 0 : 300
        ), let parsed = Move(uci: uci) else { return }

        let san = position.san(for: position.legalMoves().first { $0.matchesNotation(of: parsed) } ?? parsed)
        guard let made = position.make(parsed) else { return }
        lastMove = (from: made.from, to: made.to)
        moves.append((san: san, grade: nil))
    }

    private func finish() {
        legalDestinations = [:]
        let graded = moves.compactMap(\.grade)
        let result = position.isCheckmate
            ? (position.sideToMove == side ? "loss" : "win")
            : "draw"

        summary = GameSummary(
            result: result,
            accuracy: Coach.accuracy(centipawnLosses: losses),
            blunders: graded.filter { $0 == .blunder }.count,
            mistakes: graded.filter { $0 == .mistake }.count,
            inaccuracies: graded.filter { $0 == .inaccuracy }.count,
            costliest: losses.max().flatMap { worst in
                worst < 60 ? "No serious errors — that is the game to build on." : nil
            }
        )
    }

    var finishedGameRecord: GameRecord? {
        guard let summary else { return nil }
        return GameRecord(
            playedAt: Date(), result: summary.result, accuracy: summary.accuracy,
            blunders: summary.blunders, opponentElo: level.elo ?? 3190
        )
    }

    private func refreshDestinations() {
        guard position.sideToMove == side, !position.isGameOver else {
            legalDestinations = [:]
            return
        }
        var map: [Square: [Square]] = [:]
        for move in position.legalMoves() { map[move.from, default: []].append(move.to) }
        legalDestinations = map
    }
}

struct PlayScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = PlayModel()
    @State private var values = MoveValueController()
    @State private var recorded = false

    var body: some View {
        TrainingLayout {
            HStack(spacing: 8) {
                EvaluationBar(score: model.evaluation)
                BoardView(
                    position: model.position,
                    orientation: model.side,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    shapes: model.shapes,
                    moveValues: values.values,
                    onMove: { from, to, promotion in
                        Task {
                            await model.play(from: from, to: to, promotion: promotion, engine: app.engine)
                            values.invalidate(unless: model.position.fen)
                            await values.refresh(fen: model.position.fen, engine: app.engine)
                        }
                    }
                )
            }
        } panel: {
            if model.hasStarted { gamePanel } else { setupPanel }
        } controls: {
            if model.hasStarted { gameControls } else { EmptyView() }
        }
        .onChange(of: model.summary?.result) { _, _ in recordGame() }
    }

    @ViewBuilder
    private var setupPanel: some View {
        Card {
            Text("New game").font(.headline)
            Text("The engine plays at the strength you choose. Coaching grades each of your moves as you make it.")
                .font(.footnote).foregroundStyle(.secondary)

            Picker("Strength", selection: Binding(
                get: { model.level }, set: { model.level = $0 }
            )) {
                ForEach(OpponentLevel.all) { level in Text(level.label).tag(level) }
            }

            Picker("You play", selection: Binding(
                get: { model.side }, set: { model.side = $0 }
            )) {
                Text("White").tag(PieceColor.white)
                Text("Black").tag(PieceColor.black)
            }
            .pickerStyle(.segmented)

            Toggle("Coach me after every move", isOn: Binding(
                get: { model.coachingEnabled }, set: { model.coachingEnabled = $0 }
            ))

            Button("Start game") {
                recorded = false
                Task { await model.start(engine: app.engine) }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var gamePanel: some View {
        Card {
            Text(model.statusText).font(.headline)
            Text("Opponent: \(model.level.label)").font(.footnote).foregroundStyle(.secondary)
        }

        if let review = model.latestReview, model.summary == nil {
            Card {
                Text("Coach").font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                Text("\(review.playedSAN) — \(review.assessment.grade.label)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(gradeColor(review.assessment.grade))
                Text(review.sentence).font(.footnote).foregroundStyle(.secondary)
                if !review.principalVariation.isEmpty, review.assessment.grade != .best {
                    Text("Main line: \(review.principalVariation)")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }

        if let summary = model.summary {
            Card {
                Text(Self.resultHeadline(summary.result))
                    .font(.subheadline.weight(.semibold))
                Text(Self.errorBreakdown(summary))
                    .font(.footnote).foregroundStyle(.secondary)
                if let costliest = summary.costliest {
                    Text(costliest).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }

        Card {
            Text("Moves").font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
            MoveList(moves: model.moves)
        }
    }

    private var gameControls: some View {
        HStack {
            Button("Takeback") { model.takeBack() }
                .disabled(model.isThinking || model.moves.count < 2)
            Button("Hint") { Task { await model.hint(engine: app.engine) } }
                .disabled(model.isThinking)
            Button(values.isEnabled ? "Hide values" : "Values") {
                Task { await values.toggle(fen: model.position.fen, engine: app.engine) }
            }
            .disabled(model.isThinking)
            Spacer()
            Button("New game") { model = PlayModel() }
                .buttonStyle(.borderedProminent)
        }
        .buttonStyle(.bordered)
    }

    static func resultHeadline(_ result: String) -> String {
        switch result {
        case "win": "Game over — you won"
        case "draw": "Game over — draw"
        default: "Game over — you lost"
        }
    }

    static func errorBreakdown(_ summary: PlayModel.GameSummary) -> String {
        func plural(_ count: Int, _ singular: String, _ many: String) -> String {
            "\(count) \(count == 1 ? singular : many)"
        }
        let parts = [
            plural(summary.blunders, "blunder", "blunders"),
            plural(summary.mistakes, "mistake", "mistakes"),
            plural(summary.inaccuracies, "inaccuracy", "inaccuracies"),
        ]
        return "Accuracy \(summary.accuracy)% · " + parts.joined(separator: ", ") + "."
    }

    private func gradeColor(_ grade: MoveGrade) -> Color {
        switch grade {
        case .best, .excellent, .good: Color(red: 0.424, green: 0.749, blue: 0.451)
        case .inaccuracy: Color(red: 0.867, green: 0.706, blue: 0.353)
        case .mistake, .blunder: Color(red: 0.851, green: 0.439, blue: 0.373)
        }
    }

    private func recordGame() {
        guard !recorded, let record = model.finishedGameRecord else { return }
        recorded = true
        app.update { $0.record(game: record) }
    }
}

/// One move of a game, with the coach's verdict on it if there is one.
struct PlayedMove: Identifiable {
    let id: Int
    let san: String
    let grade: MoveGrade?
}

struct MoveList: View {
    let moves: [(san: String, grade: MoveGrade?)]

    /// Built outside `body`, and as a named type rather than a labelled tuple:
    /// the type checker gives up on inferring nested tuples inside a view
    /// builder, and reports it as an expression that is simply "too complex".
    private struct Pair: Identifiable {
        let id: Int
        let white: PlayedMove
        let black: PlayedMove?
    }

    private var pairs: [Pair] {
        var result: [Pair] = []
        var index = 0
        while index < moves.count {
            let white = PlayedMove(id: index, san: moves[index].san, grade: moves[index].grade)
            var black: PlayedMove?
            if index + 1 < moves.count {
                black = PlayedMove(id: index + 1, san: moves[index + 1].san, grade: moves[index + 1].grade)
            }
            result.append(Pair(id: index / 2 + 1, white: white, black: black))
            index += 2
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(pairs) { pair in
                HStack(spacing: 8) {
                    Text("\(pair.id).")
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                    moveText(pair.white)
                    if let black = pair.black {
                        moveText(black)
                    } else {
                        Color.clear.frame(width: 62, height: 1)
                    }
                    Spacer()
                }
                .font(.system(.footnote, design: .monospaced))
            }
        }
    }

    private func moveText(_ move: PlayedMove) -> some View {
        Text(move.san)
            .foregroundStyle(color(for: move.grade))
            .frame(width: 62, alignment: .leading)
    }

    private func color(for grade: MoveGrade?) -> Color {
        switch grade {
        case .inaccuracy: Color(red: 0.867, green: 0.706, blue: 0.353)
        case .mistake, .blunder: Color(red: 0.851, green: 0.439, blue: 0.373)
        default: Color.primary
        }
    }
}
