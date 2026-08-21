import ChessCore
import ChessEngine
import ChessTraining
import Observation
import SwiftUI

@MainActor
@Observable
final class EndgameModel {
    private(set) var drill: EndgameDrill?
    private(set) var position = Position()
    private(set) var legalDestinations: [Square: [Square]] = [:]
    private(set) var lastMove: (from: Square, to: Square)?
    private(set) var evaluation: EngineScore?
    private(set) var isThinking = false
    private(set) var isFinished = false
    private(set) var plies = 0
    private(set) var lostAt: (move: String, reason: String)?
    private(set) var outcome: Outcome?

    struct Outcome {
        let success: Bool
        let title: String
        let lines: [String]
    }

    /// You play whichever side starts the drill.
    private(set) var side: PieceColor = .white

    var orientation: PieceColor { side }

    var goalText: String {
        guard let drill else { return "" }
        let colour = L.color(side)
        return drill.goal == .win
            ? L.t("endgame.winAs", "Win as %@.", colour)
            : L.t("endgame.holdAs", "Hold the draw as %@.", colour)
    }

    func load(_ next: EndgameDrill?) {
        guard let next, let start = Position(fen: next.fen) else {
            drill = nil
            return
        }
        drill = next
        position = start
        side = start.sideToMove
        plies = 0
        isFinished = false
        lostAt = nil
        outcome = nil
        lastMove = nil
        evaluation = nil
        refreshDestinations()
    }

    /// Score from your point of view, with mate flattened to a large number.
    private func yourScore(_ score: EngineScore?, toMove: PieceColor) -> Int {
        guard let score else { return 0 }
        return CoachService.score(score, for: side, toMove: toMove)
    }

    func play(from: Square, to: Square, promotion: PieceKind?, engine: StockfishEngine) async -> Bool? {
        guard !isFinished, !isThinking, position.sideToMove == side else { return nil }
        // Notation has to be taken before the move is made: afterwards the
        // position no longer contains the piece that moved, and disambiguation
        // would be computed against the wrong board.
        guard let move = position.legalMoves().first(where: {
            $0.matchesNotation(of: Move(from: from, to: to, promotion: promotion))
        }) else { return nil }
        let played = position.san(for: move)
        position.make(move)
        lastMove = (from: move.from, to: move.to)
        plies += 1
        legalDestinations = [:]

        if let finished = checkOutcome() { return finished }

        isThinking = true
        defer { isThinking = false }

        await updateEvaluation(engine: engine)

        // Has the required result just slipped away?
        if lostAt == nil {
            let cp = yourScore(evaluation, toMove: position.sideToMove)
            if drill?.goal == .win, cp < 180 {
                lostAt = (move: played, reason: L.t("endgame.theWinIsGone", "the win is gone"))
            } else if drill?.goal == .draw, cp < -300 {
                lostAt = (move: played, reason: L.t("endgame.theDrawIsGone", "the draw is gone"))
            }
        }

        if let reply = try? await engine.chooseMove(
            fen: position.fen, depth: SearchBudget.fullStrength.depth,
            movetimeMs: SearchBudget.fullStrength.movetimeMs
           ),
           let parsed = Move(uci: reply),
           let made = position.make(parsed) {
            lastMove = (from: made.from, to: made.to)
            plies += 1
        }

        await updateEvaluation(engine: engine)

        if let finished = checkOutcome() { return finished }

        // 80 moves is generous for any of these; past that the drill is a draw
        // by exhaustion rather than by technique.
        if plies > 160 {
            return conclude(success: drill?.goal == .draw, how: L.t("endgame.moveLimit", "The 80-move limit ran out."))
        }

        refreshDestinations()
        return nil
    }

    private func updateEvaluation(engine: StockfishEngine) async {
        guard !position.isGameOver else {
            evaluation = position.isCheckmate
                ? .mate(position.sideToMove == side ? -1 : 1)
                : .centipawns(0)
            return
        }
        if let analysis = try? await engine.analyse(
            fen: position.fen, depth: SearchBudget.verdict.depth,
            movetimeMs: SearchBudget.verdict.movetimeMs, multiPV: 1
           ) {
            evaluation = analysis.lines.first?.score
        }
    }

    private func checkOutcome() -> Bool? {
        guard position.isGameOver else { return nil }

        if position.isCheckmate {
            let winner = position.sideToMove.opponent
            return conclude(
                success: winner == side && drill?.goal == .win,
                how: winner == side ? L.t("endgame.youMated", "Checkmate — you delivered it.") : L.t("endgame.youWereMated", "You were checkmated.")
            )
        }

        let how = position.isStalemate ? L.t("endgame.stalemate", "Stalemate.")
            : position.isInsufficientMaterial ? L.t("endgame.insufficient", "Insufficient material.")
            : position.isThreefoldRepetition ? L.t("endgame.repetition", "Threefold repetition.")
            : L.t("endgame.fiftyMove", "Fifty-move rule.")
        return conclude(success: drill?.goal == .draw, how: how)
    }

    @discardableResult
    private func conclude(success: Bool, how: String) -> Bool {
        isFinished = true
        legalDestinations = [:]
        var lines = [how + " " + (success
            ? "That is the result you needed."
            : "You needed to \(drill?.goal == .win ? "win" : "draw") this.")]
        if let lostAt, !success { lines.append(L.t("endgame.wentWrongAt", "It went wrong at %@.", lostAt.move)) }
        if let drill { lines.append(drill.idea) }
        outcome = Outcome(
            success: success,
            title: success ? L.t("endgame.drillPassed", "Drill passed") : L.t("endgame.drillFailed", "Drill failed"),
            lines: lines
        )
        return success
    }

    private func refreshDestinations() {
        guard position.sideToMove == side, !isFinished else {
            legalDestinations = [:]
            return
        }
        var map: [Square: [Square]] = [:]
        for move in position.legalMoves() { map[move.from, default: []].append(move.to) }
        legalDestinations = map
    }
}

struct EndgameScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = EndgameModel()
    @State private var values = MoveValueController()
    @State private var showsPaywall = false
    @State private var exhausted = false
    @State private var hasStartedAttempt = false

    private var material: MaterialBalance { MaterialBalance(model.position) }

    var body: some View {
        VStack(spacing: 0) {
            TopBar { Spacer() }
            board
        }
    }

    private var board: some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: L.t("endgame.drill", "Drill"),
                    rating: model.drill?.rating,
                    color: model.orientation.opponent,
                    material: material
                ),
                bottom: PlayerBar(
                    name: L.t("endgame.you", "You"),
                    rating: app.progress.rating(.endgame),
                    color: model.orientation,
                    material: material
                ),
                evaluation: model.evaluation,
                showsEvaluation: true,
                orientation: model.orientation
            ) {
                GameBoard(
                    position: model.position,
                    orientation: model.orientation,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    moveValues: values.values,
                    onMove: { from, to, promotion in
                        Task {
                            await play(from, to, promotion)
                            values.invalidate(unless: model.position.fen)
                            await values.refresh(fen: model.position.fen, engine: app.engine)
                        }
                    }
                )
            }
        } panel: {
            if exhausted {
                AllowanceNotice(activity: .endgame)
            } else if let drill = model.drill {
                Card {
                    Text(drill.name).font(Face.display(22))
                    Text(model.goalText).font(.subheadline).foregroundStyle(Theatre.ivoryDim)
                    TagRow(tags: [
                        drill.goal == .win ? L.t("endgame.mustWin", "Must win") : L.t("endgame.mustDraw", "Must draw"),
                        (model.plies + 1) / 2 == 1
                            ? L.t("common.oneMove", "1 move")
                            : L.t("common.moveCount", "%lld moves", (model.plies + 1) / 2),
                    ])
                }

                if model.isThinking {
                    HStack(spacing: 6) {
                        BrassActivityIndicator()
                        Text(L.t("endgame.engineIsThinking", "Engine is thinking…")).font(.footnote).foregroundStyle(Theatre.ivoryDim)
                    }
                }

                if let lostAt = model.lostAt, model.outcome == nil {
                    Card {
                        Text(L.t("endgame.threwItAway", "%@ threw it away", lostAt.move)).font(.subheadline.weight(.semibold))
                        Text(L.t("endgame.afterThatMove", "After that move %@. Play on if you like, or restart and try the correct plan.", lostAt.reason))
                            .font(.footnote).foregroundStyle(Theatre.ivoryDim)
                    }
                }

                if let outcome = model.outcome {
                    Card {
                        Text(outcome.title).font(.subheadline.weight(.semibold))
                            .foregroundStyle(outcome.success ? Theatre.good : Theatre.bad)
                        ForEach(outcome.lines, id: \.self) { line in
                            Text(line).font(.footnote).foregroundStyle(Theatre.ivoryDim)
                        }
                    }
                }

                Card {
                    Text(L.t("endgame.theIdea", "The idea")).font(.caption).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
                    Text(drill.idea).font(.footnote)
                }
            } else {
                Card { Text(L.t("endgame.noEndgameDrillsBundled", "No endgame drills bundled")).font(Face.display(22)) }
            }
        } controls: {
            ActionBar(items: [
                ActionItem(title: L.t("endgame.restart", "Restart"), systemImage: "arrow.counterclockwise",
                           isEnabled: !model.isThinking) {
                    values.reset()
                    model.load(model.drill)
                },
                ActionItem(title: values.isEnabled ? L.t("common.hide", "Hide") : L.t("common.values", "Values"),
                           systemImage: "number.square", isEnabled: !model.isThinking) {
                    Task { await values.toggle(fen: model.position.fen, engine: app.engine) }
                },
                ActionItem(title: L.t("endgame.next", "Next"), systemImage: "forward.end", emphasis: .primary) {
                    next()
                },
            ])
        }
        .task(id: app.library.drills.count) { if model.drill == nil { next() } }
        .fullScreenCover(isPresented: $showsPaywall) { PaywallView(activity: .endgame) }
    }

    private func play(_ from: Square, _ to: Square, _ promotion: PieceKind?) async {
        guard beginAttempt() else { return }
        guard let success = await model.play(
            from: from, to: to, promotion: promotion, engine: app.engine
        ), let drill = model.drill else { return }

        app.update { progress in
            progress.record(
                mode: .endgame, itemID: drill.id, itemRating: drill.rating,
                correct: success, themes: drill.themes
            )
        }
    }

    private func next() {
        exhausted = false
        hasStartedAttempt = false
        values.reset()
        model.load(ItemSelector.nextDrill(from: app.library.drills, progress: app.progress))
    }

    private func beginAttempt() -> Bool {
        guard model.drill != nil, !model.isFinished, !model.isThinking else { return false }
        guard !hasStartedAttempt else { return true }
        guard app.beginAttempt(.endgame) else {
            exhausted = true
            showsPaywall = true
            return false
        }
        exhausted = false
        hasStartedAttempt = true
        return true
    }
}

/// The familiar bar beside the board: white's share of the evaluation.
struct EvaluationBar: View {
    let score: EngineScore?
    /// Which colour is at the bottom of the board. White's share has to grow
    /// from the side White is playing on, or the bar contradicts the board it
    /// stands beside.
    var orientation: PieceColor = .white

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: orientation == .white ? .bottom : .top) {
                Color(white: 0.18)
                Color(white: 0.93).frame(height: geometry.size.height * share)
            }
        }
        .frame(width: 14)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityLabel(L.t("endgame.evaluation", "Evaluation %@", score?.text ?? L.t("endgame.unknown", "unknown")))
    }

    /// Squashed through a logistic curve so the bar moves meaningfully near
    /// equality instead of slamming to one end at the first pawn.
    private var share: Double {
        guard let score else { return 0.5 }
        switch score {
        case .mate(let moves): return moves > 0 ? 1 : 0
        case .centipawns(let cp): return 1 / (1 + exp(-Double(cp) / 320))
        }
    }
}
