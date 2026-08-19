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
        OpponentLevel(id: 0, name: L.t("play.casual", "Casual"), elo: 1400),
        OpponentLevel(id: 1, name: L.t("play.club", "Club"), elo: 1800),
        OpponentLevel(id: 2, name: L.t("play.strongClub", "Strong club"), elo: 2100),
        OpponentLevel(id: 3, name: L.t("play.expert", "Expert"), elo: 2400),
        OpponentLevel(id: 4, name: L.t("play.master", "Master"), elo: 2700),
        OpponentLevel(id: 5, name: L.t("play.fullStrength", "Full strength"), elo: nil),
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

    /// Moves given while the engine is thinking. The rules of the thing live in
    /// PremoveQueue; this holds one and reports what the screen needs.
    private(set) var premoves = PremoveQueue()
    private(set) var premoveDestinations: [Square: [Square]] = [:]

    var premoveCount: Int { premoves.count }
    var premoveWasDropped: Bool { premoves.wasDropped }
    var premoveSquares: [Square] { premoves.squares }

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
            return position.sideToMove == side
                ? L.t("play.checkmateLost", "Checkmate — you lost.")
                : L.t("play.checkmateWon", "Checkmate — you won.")
        }
        if position.isDraw { return L.t("play.draw", "Draw.") }
        if isThinking { return L.t("play.engineThinking", "Engine is thinking…") }
        return position.sideToMove == side
            ? L.t("play.yourMove", "Your move.")
            : L.t("play.engineToMove", "Engine to move.")
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

        premoves.clear()
        premoveDestinations = [:]

        await engine.newGame()
        if side == .black { await playEngineMove(engine: engine) }
        refreshDestinations()
    }

    func play(from: Square, to: Square, promotion: PieceKind?, engine: StockfishEngine) async {
        guard hasStarted, !isThinking, position.sideToMove == side, !position.isGameOver else { return }
        guard let move = position.legalMoves().first(where: {
            $0.matchesNotation(of: Move(from: from, to: to, promotion: promotion))
        }) else { return }

        isThinking = true
        await apply(move, engine: engine)

        if position.isGameOver {
            isThinking = false
            finish()
            return
        }

        await playEngineMove(engine: engine)

        // Whatever was queued now gets its turn, one move at a time, each
        // checked against the board the engine actually left behind.
        while !position.isGameOver, let queued = premoves.next(in: position) {
            refreshPremoveDestinations()
            // Long enough to be seen. A move that appears in the same frame as
            // the engine's reply reads as one event, and you lose track of who
            // played what.
            try? await Task.sleep(for: .milliseconds(280))
            await apply(queued, engine: engine)
            if position.isGameOver { break }
            await playEngineMove(engine: engine)
        }

        isThinking = false
        refreshPremoveDestinations()

        if position.isGameOver { finish() } else { refreshDestinations() }
    }

    /// Play one of your moves and grade it. A queued move is still your move,
    /// so it goes through the same coaching as one played by hand.
    private func apply(_ move: Move, engine: StockfishEngine) async {
        let before = position
        let san = position.san(for: move)
        let captured = position[move.to] != nil
        position.make(move)
        lastMove = (from: move.from, to: move.to)
        moves.append((san: san, grade: nil))
        SoundBoard.shared.play(move: move, captured: captured, resulting: position)
        legalDestinations = [:]
        shapes = []
        // Straight away, not after the coaching search: the whole point of a
        // queued move is that it can be given while the engine is busy.
        refreshPremoveDestinations()

        guard coachingEnabled else { return }
        let coach = CoachService(engine: engine)
        if let review = try? await coach.review(position: before, move: move) {
            latestReview = review
            moves[moves.count - 1].grade = review.assessment.grade
            losses.append(review.assessment.centipawnsLost)
            evaluation = review.scoreAfter
        }
    }

    func queuePremove(from: Square, to: Square, promotion: PieceKind?) {
        guard hasStarted else { return }
        premoves.queue(from: from, to: to, promotion: promotion, in: position, for: side)
        refreshPremoveDestinations()
    }

    func cancelPremoves() {
        premoves.clear()
        refreshPremoveDestinations()
    }

    private func refreshPremoveDestinations() {
        premoveDestinations = hasStarted ? premoves.destinations(in: position, for: side) : [:]
    }

    func takeBack() {
        cancelPremoves()
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
        guard let analysis = try? await engine.analyse(
            fen: position.fen, depth: SearchBudget.hint.depth,
            movetimeMs: SearchBudget.hint.movetimeMs, multiPV: 1
          ),
              let uci = analysis.lines.first?.bestMove,
              let parsed = Move(uci: uci),
              let move = position.legalMoves().first(where: { $0.matchesNotation(of: parsed) })
        else { return }
        shapes = [.arrow(move.from, move.to, .suggestion)]
    }

    /// A limited engine gets its strength from UCI_Elo, so it has no reason to
    /// think for long; full strength is the only setting that needs the time.
    private var budget: SearchBudget { level.elo == nil ? .fullStrength : .limited }

    private func playEngineMove(engine: StockfishEngine) async {
        guard let uci = try? await engine.chooseMove(
            fen: position.fen,
            elo: level.elo,
            depth: budget.depth,
            movetimeMs: budget.movetimeMs
        ), let parsed = Move(uci: uci) else { return }

        let san = position.san(for: position.legalMoves().first { $0.matchesNotation(of: parsed) } ?? parsed)
        let captured = position[parsed.to] != nil
        guard let made = position.make(parsed) else { return }
        lastMove = (from: made.from, to: made.to)
        moves.append((san: san, grade: nil))
        SoundBoard.shared.play(move: made, captured: captured, resulting: position)
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
    @Environment(ActivityGuard.self) private var activity
    @State private var model = PlayModel()
    @State private var values = MoveValueController()
    @State private var recorded = false

    private var material: MaterialBalance { MaterialBalance(model.position) }

    var body: some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: model.level.name,
                    rating: model.level.elo,
                    color: model.side.opponent,
                    material: material
                ),
                bottom: PlayerBar(
                    name: L.t("play.you", "You"),
                    rating: app.progress.overallRating,
                    color: model.side,
                    material: material
                ),
                evaluation: model.evaluation,
                showsEvaluation: true,
                orientation: model.side
            ) {
                BoardView(
                    position: model.position,
                    orientation: model.side,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    shapes: model.shapes,
                    moveValues: values.values,
                    premoveDestinations: model.premoveDestinations,
                    premove: model.premoveSquares,
                    onMove: { from, to, promotion in
                        Task {
                            await model.play(from: from, to: to, promotion: promotion, engine: app.engine)
                            values.invalidate(unless: model.position.fen)
                            await values.refresh(fen: model.position.fen, engine: app.engine)
                        }
                    },
                    onPremove: { from, to, promotion in
                        model.queuePremove(from: from, to: to, promotion: promotion)
                    }
                )
            }
        } panel: {
            if model.hasStarted { gamePanel } else { setupPanel }
        } controls: {
            if model.hasStarted { gameControls } else { EmptyView() }
        }
        .onChange(of: model.summary?.result) { _, _ in
            recordGame()
            activity.release()
        }
        .onChange(of: model.hasStarted) { _, _ in holdWhilePlaying() }
        .onChange(of: model.moves.count) { _, _ in holdWhilePlaying() }
        .onDisappear { activity.release() }
    }

    /// The game is at stake from the moment it starts, not from the first move.
    /// Pressing Start and then wandering off through a tab bar is exactly the
    /// accident this is here to prevent.
    private func holdWhilePlaying() {
        guard model.hasStarted, model.summary == nil else {
            activity.release()
            return
        }
        activity.hold(
            title: L.t("play.abandonThisGame", "Abandon this game?"),
            reason: L.t("play.abandonReason", "You are %lld moves in. Leaving now loses the game and it will not be recorded.", model.moves.count / 2 + 1)
        )
    }

    @ViewBuilder
    private var setupPanel: some View {
        Card {
            Text(L.t("play.newGame", "New game")).font(.headline)
            Text(L.t("play.theEnginePlaysAtThe", "The engine plays at the strength you choose. Coaching grades each of your moves as you make it."))
                .font(.footnote).foregroundStyle(.secondary)

            Picker(L.t("play.strength", "Strength"), selection: Binding(
                get: { model.level }, set: { model.level = $0 }
            )) {
                ForEach(OpponentLevel.all) { level in Text(level.label).tag(level) }
            }

            Picker(L.t("play.youPlay", "You play"), selection: Binding(
                get: { model.side }, set: { model.side = $0 }
            )) {
                Text(L.t("play.white", "White")).tag(PieceColor.white)
                Text(L.t("play.black", "Black")).tag(PieceColor.black)
            }
            .pickerStyle(.segmented)

            Toggle("Coach me after every move", isOn: Binding(
                get: { model.coachingEnabled }, set: { model.coachingEnabled = $0 }
            ))

            Button(L.t("play.startGame", "Start game")) {
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
            Text(L.t("play.opponentIs", "Opponent: %@", model.level.label)).font(.footnote).foregroundStyle(.secondary)

            if model.premoveCount > 0 {
                Label(
                    model.premoveCount == 1
                        ? "1 move queued — it plays as soon as the engine has moved."
                        : "\(model.premoveCount) moves queued — they play in order, and stop if one becomes impossible.",
                    systemImage: "bolt.horizontal.circle"
                )
                .font(.footnote)
                .foregroundStyle(.tint)
            } else if model.premoveWasDropped {
                Label(L.t("play.theQueueWasDroppedThe", "The queue was dropped — the engine's move made it impossible."),
                      systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        if let review = model.latestReview, model.summary == nil {
            Card {
                Text(L.t("play.coach", "Coach")).font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                Text("\(review.playedSAN) — \(review.assessment.grade.label)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(gradeColor(review.assessment.grade))
                Text(review.sentence).font(.footnote).foregroundStyle(.secondary)
                if !review.principalVariation.isEmpty, review.assessment.grade != .best {
                    Text(L.t("play.mainLine", "Main line: %@", review.principalVariation))
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
            Text(L.t("play.moves", "Moves")).font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
            MoveList(moves: model.moves)
        }
    }

    private var gameControls: some View {
        ActionBar(items: [
            // Takeback and Cancel never apply at the same moment — one is for
            // your turn, the other for the engine's — so they share a slot
            // rather than each keeping one it cannot use.
            model.premoveCount == 0
                ? ActionItem(title: L.t("play.takeback", "Takeback"), systemImage: "arrow.uturn.backward",
                             isEnabled: !model.isThinking && model.moves.count >= 2) {
                    model.takeBack()
                }
                : ActionItem(title: L.t("play.cancelPremoves", "Cancel %lld", model.premoveCount), systemImage: "xmark.circle",
                             emphasis: .destructive) {
                    model.cancelPremoves()
                },
            ActionItem(title: L.t("play.hint", "Hint"), systemImage: "lightbulb", isEnabled: !model.isThinking) {
                Task { await model.hint(engine: app.engine) }
            },
            ActionItem(title: values.isEnabled ? L.t("common.hide", "Hide") : L.t("common.values", "Values"),
                       systemImage: "number.square", isEnabled: !model.isThinking) {
                Task { await values.toggle(fen: model.position.fen, engine: app.engine) }
            },
            ActionItem(title: L.t("play.newGame", "New game"), systemImage: "plus.circle", emphasis: .primary) {
                model = PlayModel()
            },
        ])
    }

    static func resultHeadline(_ result: String) -> String {
        switch result {
        case "win": L.t("play.gameOverWon", "Game over — you won")
        case "draw": L.t("play.gameOverDraw", "Game over — draw")
        default: L.t("play.gameOverLost", "Game over — you lost")
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
