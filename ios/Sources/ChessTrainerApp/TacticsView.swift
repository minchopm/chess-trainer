import ChessCore
import ChessTraining
import Observation
import SwiftUI

@MainActor
@Observable
final class TacticsModel {
    private(set) var puzzle: Puzzle?
    private(set) var reason: SelectionReason = .level
    private(set) var position = Position()
    private(set) var legalDestinations: [Square: [Square]] = [:]
    private(set) var lastMove: (from: Square, to: Square)?
    private(set) var shapes: [BoardShape] = []
    private(set) var feedback: Feedback?
    /// Set when the puzzle ends, for the completion overlay.
    private(set) var completion: CompletionResult?
    private(set) var isFinished = false
    /// True while the opponent's reply is on its way, so the view can say so.
    private(set) var isReplying = false

    private var step = 0
    private var mistakes = 0
    private var hintLevel = 0

    struct Feedback: Identifiable {
        let id = UUID()
        let tone: Tone
        let title: String
        let lines: [String]

        enum Tone { case correct, partial, wrong, neutral }
    }

    var orientation: PieceColor { puzzle?.sideToMove ?? .white }

    var prompt: String {
        guard let puzzle else { return "" }
        let side = L.color(puzzle.sideToMove)
        return isFinished
            ? L.t("tactics.sideToPlaySolution", "%@ to play — solution", side)
            : L.t("common.sideToPlay", "%@ to play", side)
    }

    /// What the puzzle is asking for, reading both the miner's theme vocabulary
    /// and Lichess', since a merged library contains both.
    var objective: String {
        guard let puzzle else { return "" }
        let themes = Set(puzzle.themes)
        if puzzle.mate || themes.contains("mate") {
            if let inN = puzzle.themes.first(where: { $0.hasPrefix("mateIn") }) {
                return L.t("tactics.mateIn", "Mate in %@.", String(inN.dropFirst("mateIn".count)))
            }
            return L.t("tactics.findForcedMate", "Find the forced mate.")
        }
        if themes.contains("defensiveMove") || themes.contains("equality") {
            return L.t("tactics.findTheSave", "Find the move that saves the position.")
        }
        if themes.contains("crushing") { return L.t("tactics.crushingBlow", "Find the crushing blow.") }
        if themes.contains("winsMaterial") || themes.contains("hangingPiece") {
            return L.t("tactics.winMaterial", "Win material.")
        }
        // Lichess' "advantage" tag describes how much better the solution is
        // than the alternatives, not how good the position becomes. Calling a
        // +0.5 position "a clear advantage" is simply untrue.
        if themes.contains("advantage") {
            return L.t("tactics.oneMoveBetter", "One move is clearly better than the rest.")
        }
        return L.t("tactics.strongestContinuation", "Find the strongest continuation.")
    }

    func load(_ selection: Selection<Puzzle>?) {
        guard let selection, let start = Position(fen: selection.item.fen) else {
            puzzle = nil
            return
        }
        puzzle = selection.item
        reason = selection.reason
        position = start
        step = 0
        mistakes = 0
        hintLevel = 0
        isFinished = false
        isReplying = false
        feedback = nil
        completion = nil
        shapes = []
        lastMove = nil
        refreshDestinations()
    }

    /// Async because the opponent's reply must be *seen*.
    ///
    /// Applying both moves in one synchronous block leaves SwiftUI rendering
    /// only the final state: the board jumps two plies at once and it reads as
    /// though the opponent never moved. The pause between them is not polish —
    /// without it the reply is invisible, and a puzzle line you cannot watch is
    /// a puzzle line you cannot learn from.
    func play(from: Square, to: Square, promotion: PieceKind?) async -> (solved: Bool, usedHint: Bool)? {
        guard let puzzle, !isFinished, step < puzzle.solution.count else { return nil }

        let expected = puzzle.solution[step]
        let attempted = "\(from)\(to)\(promotion?.letter.description ?? "")"

        // Tolerate a missing promotion suffix: the board only asks for one when
        // the move actually promotes.
        guard attempted == expected || "\(from)\(to)" == String(expected.prefix(4)) else {
            registerWrongMove(from: from, to: to, promotion: promotion)
            return nil
        }

        apply(uci: expected)
        step += 1

        if step >= puzzle.solution.count { return finish(solved: true) }

        // The opponent's reply is part of the puzzle. Let the first move land
        // and animate before the answer arrives.
        isReplying = true
        legalDestinations = [:]
        try? await Task.sleep(for: .milliseconds(420))
        isReplying = false

        guard let puzzle = self.puzzle, step < puzzle.solution.count else { return nil }
        apply(uci: puzzle.solution[step])
        step += 1

        if step >= puzzle.solution.count { return finish(solved: true) }

        refreshDestinations()
        feedback = Feedback(tone: .neutral, title: L.t("tactics.goodKeepGoing", "Good — keep going."), lines: [])
        return nil
    }

    /// Replay the same puzzle. The attempt has already been recorded, so this
    /// is practice rather than a second chance at the rating.
    func retry() {
        guard let puzzle, let start = Position(fen: puzzle.fen) else { return }
        position = start
        step = 0
        mistakes = 0
        hintLevel = 0
        isFinished = false
        isReplying = false
        feedback = nil
        completion = nil
        shapes = []
        lastMove = nil
        refreshDestinations()
    }

    func revealSolution() -> (solved: Bool, usedHint: Bool)? {
        guard !isFinished else { return nil }
        return finish(solved: false, revealed: true)
    }

    /// Record that the solver was helped, without showing a hint. Used by the
    /// move-value overlay, which helps at least as much as a hint does.
    func noteAidUsed() {
        guard !isFinished else { return }
        hintLevel = max(hintLevel, 1)
    }

    func requestHint() {
        guard let puzzle, !isFinished, step < puzzle.solution.count else { return }
        hintLevel += 1
        let uci = puzzle.solution[step]
        guard let from = Square(uci.prefix(2)), let to = Square(uci.dropFirst(2).prefix(2)) else { return }

        if hintLevel == 1 {
            shapes = [.circle(from)]
            let piece = position[from].map { MoveDescription.name(of: $0.kind) } ?? "piece"
            feedback = Feedback(tone: .neutral, title: L.t("tactics.moveThePiece", "Move the %@ on %@.", piece, "\(from)"), lines: [])
        } else {
            shapes = [.arrow(from, to, .suggestion)]
            feedback = Feedback(tone: .neutral, title: L.t("tactics.thatIsTheMovePlay", "That is the move — play it on the board."), lines: [])
        }
    }

    // MARK: - Internals

    private func registerWrongMove(from: Square, to: Square, promotion: PieceKind?) {
        mistakes += 1
        var probe = position
        let played = probe.make(Move(from: from, to: to, promotion: promotion))
        let name = played.map { position.san(for: $0) } ?? "That move"
        feedback = Feedback(
            tone: .wrong,
            title: L.t("tactics.notTheOne", "%@ is not the one", name),
            lines: [mistakes == 1
                ? L.t("tactics.tryForcing", "There is a stronger move here. Look at the most forcing options first — checks, captures, threats.")
                : L.t("tactics.stillNotIt", "Still not it. Try a hint, or reveal the solution and study the idea.")]
        )
    }

    private func apply(uci: String) {
        guard let move = Move(uci: uci), let made = position.make(move) else { return }
        lastMove = (from: made.from, to: made.to)
        shapes = []
    }

    private func finish(solved: Bool, revealed: Bool = false) -> (solved: Bool, usedHint: Bool) {
        guard let puzzle else { return (false, false) }
        isFinished = true
        legalDestinations = [:]
        shapes = []

        // Play out the rest so the whole idea is visible on the board.
        while step < puzzle.solution.count {
            apply(uci: puzzle.solution[step])
            step += 1
        }

        let counted = solved && !revealed && mistakes == 0
        let reasons = explanation()
        feedback = Feedback(
            tone: counted ? .correct : (revealed ? .wrong : .partial),
            title: revealed
                ? L.t("tactics.solutionTitle", "Solution")
                : (mistakes == 0 ? L.t("tactics.solved", "Solved") : L.t("tactics.solvedNotFirst", "Solved, but not first time")),
            lines: [notation()] + reasons
        )
        completion = CompletionResult(
            verdict: counted ? .success : (revealed ? .failure : .partial),
            title: revealed
                ? L.t("tactics.solutionShown", "Solution shown")
                : (mistakes == 0 ? L.t("tactics.solved", "Solved") : L.t("tactics.solvedSecondTry", "Solved on the second try")),
            detail: reasons.first ?? (revealed ? L.t("tactics.studyTheIdea", "Study the idea — it will come back for review.") : nil),
            line: notation()
        )
        return (counted, hintLevel > 0)
    }

    private func refreshDestinations() {
        var map: [Square: [Square]] = [:]
        for move in position.legalMoves() { map[move.from, default: []].append(move.to) }
        legalDestinations = map
    }

    /// The whole line in readable notation.
    private func notation() -> String {
        guard let puzzle, var replay = Position(fen: puzzle.fen) else { return "" }
        var text = ""
        for uci in puzzle.solution {
            guard let move = Move(uci: uci),
                  let legal = replay.legalMoves().first(where: { $0.matchesNotation(of: move) })
            else { break }
            let number = replay.fullmoveNumber
            let san = replay.san(for: legal)
            if replay.sideToMove == .white {
                text += "\(number).\(san) "
            } else {
                text += text.isEmpty ? "\(number)...\(san) " : "\(san) "
            }
            replay.make(legal)
        }
        return text.trimmingCharacters(in: .whitespaces)
    }

    /// Narrate the solver's moves through the feature layer.
    private func explanation() -> [String] {
        guard let puzzle, var replay = Position(fen: puzzle.fen) else { return [] }
        var lines: [String] = []
        for (index, uci) in puzzle.solution.enumerated() {
            guard let parsed = Move(uci: uci),
                  let move = replay.legalMoves().first(where: { $0.matchesNotation(of: parsed) })
            else { break }
            let before = PositionFeatures(replay)
            let san = replay.san(for: move)
            let source = replay
            replay.make(move)
            guard index % 2 == 0 else { continue }
            if let sentence = MoveDescription.sentence(
                san: san, before: before, after: PositionFeatures(replay),
                move: move, position: source, resulting: replay
            ) {
                lines.append(sentence)
            }
        }
        return lines
    }
}
