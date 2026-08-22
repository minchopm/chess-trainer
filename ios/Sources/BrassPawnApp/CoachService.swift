import ChessCore
import ChessEngine
import ChessTraining
import Foundation

/// What the coach says about one move you played.
struct MoveReview: Sendable {
    let played: Move
    let playedSAN: String
    let assessment: MoveAssessment
    let scoreAfter: EngineScore?
    let bestSAN: String?
    let bestMove: Move?
    let principalVariation: String
    let sentence: String
}

/// Wraps the engine in the questions the trainer actually asks it.
///
/// Everything here converts scores into the mover's point of view before
/// comparing them. UCI reports from the side to move, so a score taken after a
/// move belongs to the *opponent* — comparing the two raw is the single easiest
/// way to grade every move exactly backwards.
struct CoachService {
    let engine: any Engine

    /// Score for `color`, given a score reported for whoever is to move in `position`.
    static func score(_ score: EngineScore, for color: PieceColor, toMove: PieceColor) -> Int {
        score.pointOfView(sideToMove: color == toMove).comparable
    }

    func review(
        position: Position,
        move: Move,
        budget: SearchBudget = .coaching
    ) async throws -> MoveReview {
        let mover = position.sideToMove
        let playedSAN = position.san(for: move)

        let before = try await engine.analyse(
            fen: position.fen, depth: budget.depth, movetimeMs: budget.movetimeMs, multiPV: 2
        )
        let bestUCI = before.lines.first?.bestMove ?? before.bestMove
        let bestMove = bestUCI.flatMap { Move(uci: $0) }
            .flatMap { candidate in position.legalMoves().first { $0.matchesNotation(of: candidate) } }

        let scoreBefore = before.lines.first.map {
            Self.score($0.score, for: mover, toMove: mover)
        } ?? 0

        var after = position
        after.make(move)
        let wasEngineChoice = bestMove.map { $0.matchesNotation(of: move) } ?? false

        var scoreAfterValue = scoreBefore
        var scoreAfter: EngineScore? = before.lines.first?.score
        if !wasEngineChoice {
            if after.isCheckmate {
                scoreAfterValue = 10_000                       // you just mated them
                scoreAfter = .mate(1)
            } else if after.isDraw {
                scoreAfterValue = 0
                scoreAfter = .centipawns(0)
            } else {
                let result = try await engine.analyse(
                    fen: after.fen, depth: budget.depth, movetimeMs: budget.movetimeMs, multiPV: 1
                )
                if let line = result.lines.first {
                    scoreAfterValue = Self.score(line.score, for: mover, toMove: after.sideToMove)
                    scoreAfter = line.score.pointOfView(sideToMove: after.sideToMove == mover)
                }
            }
        }

        let assessment = Coach.assess(
            before: scoreBefore, after: scoreAfterValue, wasEngineChoice: wasEngineChoice
        )

        return MoveReview(
            played: move,
            playedSAN: playedSAN,
            assessment: assessment,
            scoreAfter: scoreAfter,
            bestSAN: bestMove.map { position.san(for: $0) },
            bestMove: bestMove,
            principalVariation: Self.notation(from: position, uciMoves: before.lines.first?.moves ?? []),
            sentence: Self.explain(
                position: position, move: move, playedSAN: playedSAN,
                assessment: assessment, bestMove: bestMove, wasEngineChoice: wasEngineChoice
            )
        )
    }

    /// Render a principal variation as readable notation.
    static func notation(from position: Position, uciMoves: [String], limit: Int = 6) -> String {
        var replay = position
        var text = ""
        for uci in uciMoves.prefix(limit) {
            guard let parsed = Move(uci: uci),
                  let move = replay.legalMoves().first(where: { $0.matchesNotation(of: parsed) })
            else { break }
            let number = replay.fullmoveNumber
            let san = replay.san(for: move)
            if replay.sideToMove == .white {
                text += "\(number).\(san) "
            } else {
                text += text.isEmpty ? "\(number)...\(san) " : "\(san) "
            }
            replay.make(move)
        }
        return text.trimmingCharacters(in: .whitespaces)
    }

    static func explain(
        position: Position,
        move: Move,
        playedSAN: String,
        assessment: MoveAssessment,
        bestMove: Move?,
        wasEngineChoice: Bool
    ) -> String {
        var resulting = position
        resulting.make(move)

        var parts: [String] = []
        if let sentence = MoveDescription.sentence(
            san: playedSAN,
            before: PositionFeatures(position),
            after: PositionFeatures(resulting),
            move: move, position: position, resulting: resulting
        ) {
            parts.append(sentence)
        }

        if wasEngineChoice {
            if parts.isEmpty { parts.append("\(playedSAN) is what the engine plays too.") }
        } else if let bestMove {
            var afterBest = position
            afterBest.make(bestMove)
            let reasons = MoveDescription.clauses(
                before: PositionFeatures(position),
                after: PositionFeatures(afterBest),
                move: bestMove, position: position, resulting: afterBest
            )
            let why = reasons.isEmpty ? "" : " — it \(MoveDescription.join(reasons))"
            let cost = assessment.centipawnsLost >= 9000
                ? "and it throws away a forced mate"
                : String(format: "costing about %.2f pawns", Double(assessment.centipawnsLost) / 100)
            parts.append("\(position.san(for: bestMove)) was stronger\(why), \(cost).")
        }

        return parts.joined(separator: " ")
    }
}
