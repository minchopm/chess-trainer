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
            if parts.isEmpty {
                parts.append(L.t(
                    "coach.engineAgrees", "%@ is what the engine plays too.",
                    playedSAN.notation
                ))
            }
        } else if let bestMove {
            var afterBest = position
            afterBest.make(bestMove)
            let reasons = MoveDescription.clauses(
                before: PositionFeatures(position),
                after: PositionFeatures(afterBest),
                move: bestMove, position: position, resulting: afterBest
            )
            // Whole sentences with numbered arguments, not English fragments
            // glued together. The old version built "X was stronger — it Y,
            // costing about Z pawns." in code and translated only Y, so an
            // Arabic reader got an Arabic clause inside an English sentence.
            let better = position.san(for: bestMove).notation
            let threwAwayMate = assessment.centipawnsLost >= 9000
            let cost = Self.pawnFormatter
                .string(from: NSNumber(value: Double(assessment.centipawnsLost) / 100)) ?? ""

            if reasons.isEmpty {
                parts.append(threwAwayMate
                    ? L.t("coach.strongerMate",
                          "%@ was stronger, and it throws away a forced mate.", better)
                    : L.t("coach.strongerCost",
                          "%1$@ was stronger, costing about %2$@ pawns.", better, cost))
            } else {
                let why = MoveDescription.join(reasons)
                parts.append(threwAwayMate
                    ? L.t("coach.strongerReasonMate",
                          "%1$@ was stronger — it %2$@, and it throws away a forced mate.",
                          better, why)
                    : L.t("coach.strongerReasonCost",
                          "%1$@ was stronger — it %2$@, costing about %3$@ pawns.",
                          better, why, cost))
            }
        }

        return parts.joined(separator: " ")
    }

    /// The cost in pawns, in the reader's own numerals.
    private static let pawnFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

extension String {
    /// Chess notation, kept the way round it is written.
    ///
    /// A move and a variation are Latin letters and Western digits, and dropped
    /// into a right-to-left sentence the bidirectional algorithm reorders them:
    /// "1.e4 c5 2.Nf3 e6" came out as "1.Nc3 Nc6 3.e6 2.Nf3 c5 e4", which is
    /// not a variation any more. An isolate says: whatever surrounds this, read
    /// it forwards. It costs two invisible characters and is the difference
    /// between notation and nonsense.
    var notation: String { "\u{2066}\(self)\u{2069}" }
}
