import ChessCore
import ChessEngine
import ChessTraining
import Observation
import SwiftData
import SwiftUI

struct OpponentLevel: Identifiable, Hashable {
    let id: Int
    let name: String
    /// nil means no limit — the engine at full strength.
    let elo: Int?

    var label: String { elo.map { "\(name) (\($0))" } ?? name }

    static let fullStrength = OpponentLevel(
        id: 5, name: L.t("play.fullStrength", "Full strength"), elo: nil
    )

    static let all: [OpponentLevel] = [
        OpponentLevel(id: 0, name: L.t("play.casual", "Casual"), elo: 1400),
        OpponentLevel(id: 1, name: L.t("play.club", "Club"), elo: 1800),
        OpponentLevel(id: 2, name: L.t("play.strongClub", "Strong club"), elo: 2100),
        OpponentLevel(id: 3, name: L.t("play.expert", "Expert"), elo: 2400),
        OpponentLevel(id: 4, name: L.t("play.master", "Master"), elo: 2700),
        fullStrength,
    ]

    /// The rungs an engine can actually stand on.
    ///
    /// The ladder is built on `UCI_Elo`, which only Stockfish has. Offering the
    /// same six names for Reckless and quietly giving all of them full strength
    /// would make the app lie in six different ways at once, so an engine that
    /// cannot limit its strength gets the one rung that is true.
    static func available(limitsStrength: Bool) -> [OpponentLevel] {
        limitsStrength ? all : [fullStrength]
    }
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

    /// Bring the chosen rung back inside what the engine can do.
    ///
    /// The engine is chosen in Settings, which can happen between one game and
    /// the next while a level from the other engine's ladder is still selected.
    func clampLevel(limitsStrength: Bool) {
        let available = OpponentLevel.available(limitsStrength: limitsStrength)
        if !available.contains(level) { level = available[0] }
    }
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

    func start(engine: any Engine) async {
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

    func play(from: Square, to: Square, promotion: PieceKind?, engine: any Engine) async {
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
    private func apply(_ move: Move, engine: any Engine) async {
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

    func hint(engine: any Engine) async {
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

    private func playEngineMove(engine: any Engine) async {
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
    @Environment(\.modelContext) private var history

    private var material: MaterialBalance { MaterialBalance(model.position) }

    /// What to call the opponent.
    ///
    /// A rated rung already names itself — "Club", "Expert" — and which engine
    /// is behind it is a detail. An unrated one only said "Full strength", which
    /// leaves out the part the player chose, so there it is the engine's name.
    private var opponentName: String {
        model.level.elo == nil ? app.engineChoice.name : model.level.name
    }

    private var opponentLabel: String {
        model.level.elo.map { "\(opponentName) (\($0))" } ?? opponentName
    }

    var body: some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: opponentName,
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
                GameBoard(
                    position: model.position,
                    orientation: model.side,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    shapes: model.shapes,
                    moveValues: values.displayedValues,
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
        .onAppear { model.clampLevel(limitsStrength: app.engineChoice.limitsStrength) }
        .onChange(of: app.engineChoice) { _, choice in
            model.clampLevel(limitsStrength: choice.limitsStrength)
        }
        .onChange(of: model.hasStarted) { _, _ in holdWhilePlaying() }
        .onChange(of: model.moves.count) { _, _ in holdWhilePlaying() }
        .onDisappear { activity.release() }
        #if DEBUG
        .task { await openScreenshotScene() }
        #endif
    }

    #if DEBUG
    /// Put the screen into the state a store screenshot wants.
    ///
    /// The position is the same in every language — only the words around it
    /// change — so it is played here rather than tapped in, which keeps the
    /// thirty-one pictures identical but for their text.
    private func openScreenshotScene() async {
        guard let scene = ScreenshotScene.requested else { return }
        guard scene == .playCoached || scene == .playMistake || scene == .playValues
                || scene == .demo
        else { return }

        // Wait for a real engine. The scene is applied before `app.start()` has
        // finished, so this screen can appear while `app.engine` is still the
        // networkless placeholder — and a search on that fails quietly, which
        // shows up as a board where the engine never replies and the coach
        // never speaks.
        for _ in 0..<200 where app.engineState != .ready {
            try? await Task.sleep(for: .milliseconds(150))
        }
        guard app.engineState == .ready else { return }

        await model.start(engine: app.engine)

        if scene == .demo {
            await runDemo()
            return
        }

        // g4 for the mistake: a first move weak enough to be graded and famous
        // enough that nobody has to be told why.
        let move = scene == .playMistake ? ("g2", "g4") : ("e2", "e4")
        guard let from = Square(move.0), let to = Square(move.1) else { return }
        await model.play(from: from, to: to, promotion: nil, engine: app.engine)

        if scene == .playValues {
            values.invalidate(unless: model.position.fen)
            values.toggle(fen: model.position.fen, engine: app.engine)
        }
    }

    /// Play a short game against the clock, for a recorded preview.
    ///
    /// Two moves and two verdicts: e4 praised, then the queen out early and
    /// caught. Qh5 rather than something sharper because it is legal after
    /// every reply Black has to 1.e4, so the sequence cannot break depending on
    /// what the engine chose.
    private func runDemo() async {
        func pause(_ seconds: Double) async {
            try? await Task.sleep(for: .seconds(seconds))
        }
        func play(_ from: String, _ to: String) async {
            guard let a = Square(from), let b = Square(to) else { return }
            await model.play(from: a, to: b, promotion: nil, engine: app.engine)
        }

        await pause(2.5)          // the board, before anything happens to it
        await play("e2", "e4")    // and the engine's reply, and the verdict
        await pause(5)
        await play("d1", "h5")    // the queen out early
        await pause(6)
    }
    #endif

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
            Text(L.t("play.newGame", "New game")).appFont(size: 22, weight: .semibold)
            // Two sentences or one, because the first of them is only true when
            // there is a ladder to choose from. Promising a choice of strength
            // directly above the line explaining there is none is worse than
            // saying nothing about it.
            Text(app.engineChoice.limitsStrength
                 ? L.t("play.theEnginePlaysAtThe", "The engine plays at the strength you choose. Coaching grades each of your moves as you make it.")
                 : L.t("play.coachingGradesEveryMove", "Coaching grades each of your moves as you make it."))
                .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)

            if app.engineChoice.limitsStrength {
                BrassCyclePicker(
                    L.t("play.strength", "Strength"),
                    selection: Binding(get: { model.level }, set: { model.level = $0 }),
                    options: OpponentLevel.all,
                    label: \.label
                )
            } else {
                // No picker rather than a picker with one entry: a control that
                // cannot be changed invites the player to try.
                Text(L.t("play.engineHasNoLadder",
                         "%@ plays at full strength — it has no rating limiter. Change the engine in Settings to play a rated opponent.",
                         app.engineChoice.name))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryFaint)
            }

            BrassSegmentedPicker(
                L.t("play.youPlay", "You play"),
                selection: Binding(get: { model.side }, set: { model.side = $0 }),
                options: [PieceColor.white, PieceColor.black]
            ) { side in
                Text(side == .white
                    ? L.t("play.white", "White")
                    : L.t("play.black", "Black"))
            }

            BrassToggle("Coach me after every move", isOn: Binding(
                get: { model.coachingEnabled }, set: { model.coachingEnabled = $0 }
            ))

            Button(L.t("play.startGame", "Start game")) {
                recorded = false
                Task { await model.start(engine: app.engine) }
            }
            .buttonStyle(PillButtonStyle(emphasis: .solid))
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var gamePanel: some View {
        Card {
            Text(model.statusText).appFont(size: 22, weight: .semibold)
            Text(L.t("play.opponentIs", "Opponent: %@", opponentLabel)).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)

            if model.premoveCount > 0 {
                Label {
                    Text(model.premoveCount == 1
                        ? "1 move queued — it plays as soon as the engine has moved."
                        : "\(model.premoveCount) moves queued — they play in order, and stop if one becomes impossible.")
                } icon: {
                    BrassIcon("bolt.horizontal.circle", size: 18)
                }
                .appFont(.footnote)
                .foregroundStyle(Theatre.brass)
            } else if model.premoveWasDropped {
                Label {
                    Text(L.t("play.theQueueWasDroppedThe", "The queue was dropped — the engine's move made it impossible."))
                } icon: {
                    BrassIcon("exclamationmark.triangle", size: 18)
                }
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)
            }
        }

        if let review = model.latestReview, model.summary == nil {
            Card {
                Text(L.t("play.coach", "Coach")).appFont(.caption).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
                Text("\(review.playedSAN) — \(review.assessment.grade.label)")
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(gradeColor(review.assessment.grade))
                Text(review.sentence).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                if !review.principalVariation.isEmpty, review.assessment.grade != .best {
                    Text(L.t("play.mainLine", "Main line: %@", review.principalVariation.notation))
                        .appFont(.caption).foregroundStyle(Theatre.ivoryFaint)
                }
            }
        }

        if let summary = model.summary {
            Card {
                Text(Self.resultHeadline(summary.result))
                    .appFont(.subheadline, weight: .semibold)
                Text(Self.errorBreakdown(summary))
                    .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                if let costliest = summary.costliest {
                    Text(costliest).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                }
            }
        }

        Card {
            Text(L.t("play.moves", "Moves")).appFont(.caption).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
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
                    values.invalidate(unless: model.position.fen)
                    Task { await values.refresh(fen: model.position.fen, engine: app.engine) }
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
                values.toggle(fen: model.position.fen, engine: app.engine)
            },
            ActionItem(title: L.t("play.newGame", "New game"), systemImage: "plus.circle", emphasis: .primary) {
                values.reset()
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

        // The progress record is the rating input; this is the game itself, so
        // it can be watched back and picked up again.
        history.insert(SavedGame(
            playedAt: record.playedAt,
            notation: model.moves.map(\.san).joined(separator: " "),
            result: record.result,
            white: model.side == .white ? "" : opponentLabel,
            black: model.side == .black ? "" : opponentLabel,
            yourColor: model.side == .white ? "white" : "black",
            opponentElo: model.level.elo,
            accuracy: record.accuracy,
            source: "play"
        ))
        try? history.save()
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
                        .foregroundStyle(Theatre.ivoryDim)
                        .frame(width: 28, alignment: .trailing)
                    moveText(pair.white)
                    if let black = pair.black {
                        moveText(black)
                    } else {
                        Color.clear.frame(width: 62, height: 1)
                    }
                    Spacer()
                }
                .appFont(.footnote)
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
        default: Theatre.ivory
        }
    }
}
