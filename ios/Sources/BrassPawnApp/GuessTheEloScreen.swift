import ChessCore
import ChessTraining
import Observation
import SwiftUI

/// Watch a real game play itself out, then say how strong the players were.
///
/// The point is not trivia. Judging a game's level is the same skill as judging
/// your own moves — you have to notice which mistakes are being made and which
/// are not, and that is a habit worth training away from the pressure of a
/// position you have to solve.
@MainActor
@Observable
final class GuessTheEloModel {
    private(set) var game: AnnotatedGame?
    private(set) var positions: [Position] = []
    private(set) var notation: [String] = []
    private(set) var ply = 0
    private(set) var isPlaying = false
    private(set) var verdict: EloPairGuess?

    var whiteGuess = 1600
    var blackGuess = 1600
    var speed: Speed = .normal

    private var ticker: Task<Void, Never>?
    private var recent: [String] = []

    enum Speed: Double, CaseIterable, Identifiable {
        case slow = 1.8, normal = 0.9, fast = 0.45

        var id: Double { rawValue }
        var label: String {
            switch self {
            case .slow: "0.5×"
            case .normal: "1×"
            case .fast: "2×"
            }
        }
    }

    var position: Position { positions.indices.contains(ply) ? positions[ply] : Position() }
    var lastMove: (from: Square, to: Square)? {
        guard ply > 0, let move = moves.indices.contains(ply - 1) ? moves[ply - 1] : nil else { return nil }
        return (move.from, move.to)
    }

    var isRevealed: Bool { verdict != nil }
    var isFinished: Bool { ply >= max(0, positions.count - 1) }
    var moveNumber: Int { (ply + 1) / 2 }
    var totalMoves: Int { (max(0, positions.count - 1) + 1) / 2 }

    /// The last full move, written the way it would be on a scoresheet.
    var latestMoveText: String {
        guard ply > 0, ply <= notation.count else { return L.t("guess.aboutToStart", "The game is about to start.") }
        let number = (ply + 1) / 2
        let white = notation[ply - (ply.isMultiple(of: 2) ? 2 : 1)]
        if ply.isMultiple(of: 2) {
            return "\(number). \(white) \(notation[ply - 1])"
        }
        return "\(number). \(white)"
    }

    private var moves: [Move] = []

    func load(_ next: AnnotatedGame?) {
        stop()
        verdict = nil
        ply = 0
        guard let next else {
            game = nil
            positions = []
            notation = []
            moves = []
            return
        }

        game = next
        var replay = Position()
        var built: [Position] = [replay]
        var sans: [String] = []
        var played: [Move] = []

        for uci in next.uciMoves {
            guard let parsed = Move(uci: uci),
                  let legal = replay.legalMoves().first(where: { $0.matchesNotation(of: parsed) })
            else { break }
            sans.append(replay.san(for: legal))
            replay.make(legal)
            played.append(legal)
            built.append(replay)
        }

        positions = built
        notation = sans
        moves = played
        recent.append(next.id)
        if recent.count > 40 { recent.removeFirst() }
    }

    /// A game the viewer has not just seen. The library is sampled evenly across
    /// the rating ladder, so a uniform pick is already a fair spread of answers.
    func pick(from library: [AnnotatedGame]) -> AnnotatedGame? {
        guard !library.isEmpty else { return nil }
        let unseen = library.filter { !recent.contains($0.id) }
        return (unseen.isEmpty ? library : unseen).randomElement()
    }

    func play() {
        guard !isFinished, !isPlaying else { return }
        isPlaying = true
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let interval = self.speed.rawValue
                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled { return }
                guard self.isPlaying else { return }
                self.step(by: 1)
                if self.isFinished {
                    self.isPlaying = false
                    return
                }
            }
        }
    }

    func pause() {
        isPlaying = false
        ticker?.cancel()
        ticker = nil
    }

    func toggle() { isPlaying ? pause() : play() }

    func step(by delta: Int) {
        ply = min(max(0, ply + delta), max(0, positions.count - 1))
    }

    /// Stepping by hand means watching, not scrubbing past the answer, so it
    /// stops the film rather than fighting it.
    func stepManually(by delta: Int) {
        pause()
        step(by: delta)
    }

    func seekManually(to target: Int) {
        pause()
        ply = min(max(0, target), max(0, positions.count - 1))
    }

    func cycleSpeed() {
        let speeds = Array(Speed.allCases)
        let index = speeds.firstIndex(of: speed) ?? 1
        speed = speeds[(index + 1) % speeds.count]
    }

    func lockIn() -> EloPairGuess? {
        guard let game, verdict == nil else { return nil }
        pause()
        let result = EloPairGuess(
            whiteGuess: whiteGuess,
            blackGuess: blackGuess,
            whiteActual: game.white,
            blackActual: game.black
        )
        verdict = result
        return result
    }

    func stop() {
        pause()
    }
}

struct GuessTheEloScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = GuessTheEloModel()
    @State private var exhausted = false
    @State private var hasStartedAttempt = false

    var body: some View {
        Group {
            if app.library.games.isEmpty {
                LibraryNotice(isLoaded: app.isLibraryLoaded, what: "games", file: "games.json")
                    .padding(12)
            } else {
                content
                    .allowanceGate(
                        activity: .guessTheElo,
                        hasStartedAttempt: hasStartedAttempt,
                        wasDenied: exhausted
                    )
            }
        }
        .task(id: app.library.games.count) { if model.game == nil { next() } }
        .onDisappear { model.stop() }
        .overlay {
            if let verdict = model.verdict, let game = model.game {
                resultOverlay(verdict: verdict, game: game)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.isRevealed)
    }

    private var content: some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: L.t("guess.black", "Black"),
                    rating: model.isRevealed ? model.game?.black : nil,
                    mysteryRating: !model.isRevealed,
                    color: .black,
                    material: MaterialBalance(model.position)
                ),
                bottom: PlayerBar(
                    name: L.t("guess.white", "White"),
                    rating: model.isRevealed ? model.game?.white : nil,
                    mysteryRating: !model.isRevealed,
                    color: .white,
                    material: MaterialBalance(model.position)
                )
            ) {
                GameBoard(position: model.position, lastMove: model.lastMove)
            }
        } panel: {
            // The guesses come first, directly under the board. They are the
            // one thing on this screen the player actually changes.
            guessCard
        } controls: {
            controls
        }
    }

    private var guessCard: some View {
        Card {
            Text(L.t("guess.yourGuessLichessRating", "Your guess, Lichess rating"))
                .appFont(.caption, weight: .medium)
                .textCase(.uppercase)
                .foregroundStyle(Theatre.ivoryDim)

            eloSlider(
                L.color(.white),
                value: Binding(get: { model.whiteGuess }, set: { model.whiteGuess = $0 })
            )

            Divider().overlay(Theatre.rule)

            eloSlider(
                L.color(.black),
                value: Binding(get: { model.blackGuess }, set: { model.blackGuess = $0 })
            )
        }
    }

    private func eloSlider(_ label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .appFont(.subheadline, weight: .medium)
                Spacer()
                Text(verbatim: "\(value.wrappedValue)")
                    .appFont(.title3, weight: .semibold)
            }

            BrassSlider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int(($0 / Double(EloGuess.step)).rounded()) * EloGuess.step }
                ),
                in: Double(EloGuess.range.lowerBound)...Double(EloGuess.range.upperBound),
                step: Double(EloGuess.step)
            )
            .accessibilityLabel(label)
            .accessibilityValue("\(value.wrappedValue) Elo")
        }
        .padding(.vertical, 2)
    }

    private func resultOverlay(verdict: EloPairGuess, game: AnnotatedGame) -> some View {
        let tint = verdictTint(for: verdict.verdict)

        return BrassModalBackdrop {
            BrassModalPanel(tint: tint) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(verdict.verdict.title)
                                .appFont(.title2, weight: .semibold)
                                .foregroundStyle(Theatre.ivory)
                            Text(verdict.summary)
                                .appFont(.subheadline)
                                .foregroundStyle(Theatre.ivoryDim)
                        }
                        Spacer(minLength: 8)
                        Text(verbatim: "+\(verdict.points)")
                            .appFont(.headline, weight: .bold)
                            .monospacedDigit()
                            .foregroundStyle(tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(tint.opacity(0.10), in: Capsule())
                            .overlay {
                                Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 0.65)
                            }
                    }

                    VStack(spacing: 0) {
                        ratingResult(
                            L.color(.white),
                            guessed: verdict.white.guess,
                            actual: game.white
                        )
                        Divider().overlay(Theatre.rule)
                        ratingResult(
                            L.color(.black),
                            guessed: verdict.black.guess,
                            actual: game.black
                        )
                    }
                    .padding(.horizontal, 12)
                    .background {
                        BrassPlateShape(cut: 10).fill(Theatre.ink2.opacity(0.72))
                    }
                    .overlay {
                        BrassPlateShape(cut: 10)
                            .strokeBorder(Theatre.brassDeep.opacity(0.40), lineWidth: 0.65)
                    }

                    let stats = app.progress.eloGuessStats
                    if stats.judged > 1 {
                        Text(L.t("guess.judgedSummary", "%lld games judged · average miss %lld points", stats.judged, stats.averageError))
                            .appFont(.caption)
                            .foregroundStyle(Theatre.ivoryDim)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: next) {
                        Label {
                            Text(L.t("guess.newGame", "New game"))
                        } icon: {
                            BrassIcon("arrow.clockwise", size: 18)
                        }
                            .appFont(.body, weight: .semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                }
            }
        }
    }

    private func ratingResult(_ color: String, guessed: Int, actual: Int) -> some View {
        HStack(spacing: 18) {
            Text(color)
                .appFont(.subheadline, weight: .medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            revealValue(L.t("guess.youSaid", "You said"), guessed)
            revealValue(L.t("guess.actual", "Actual"), actual)
        }
        .padding(.vertical, 10)
    }

    private func revealValue(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).appFont(.caption2).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
            Text(verbatim: "\(value)").appFont(.title3, weight: .semibold)
        }
    }

    private func verdictTint(for verdict: EloGuess.Verdict) -> Color {
        switch verdict {
        case .spot:
            Theatre.good
        case .close:
            Theatre.good
        case .fair:
            Theatre.warn
        case .off:
            Theatre.bad
        }
    }

    private var controls: some View {
        ReplayTransport(
            position: model.ply,
            count: max(0, model.positions.count - 1),
            isPlaying: model.isPlaying,
            speedLabel: model.speed.label,
            usesPlainLabels: true,
            showsPositionSlider: false,
            showsEndButtons: false,
            primaryAction: ActionItem(
                title: L.t("guess.lockIn", "Lock in"),
                systemImage: "checkmark.circle",
                emphasis: .primary,
                action: lockIn
            ),
            onSeek: model.seekManually,
            onToggle: model.toggle,
            onCycleSpeed: model.cycleSpeed
        )
    }

    private func lockIn() {
        guard model.game != nil, !model.isRevealed, beginAttempt() else { return }
        guard let game = model.game, let verdict = model.lockIn() else { return }
        app.update { progress in
            progress.eloGuesses.append(
                EloGuessRecord(
                    gameID: game.id,
                    whiteGuess: verdict.white.guess,
                    whiteActual: verdict.white.actual,
                    blackGuess: verdict.black.guess,
                    blackActual: verdict.black.actual
                )
            )
        }
    }

    private func next() {
        exhausted = false
        hasStartedAttempt = false
        model.load(model.pick(from: app.library.games))
    }

    private func beginAttempt() -> Bool {
        guard !hasStartedAttempt else { return true }
        guard app.beginAttempt(.guessTheElo) else {
            model.pause()
            exhausted = true
            return false
        }
        exhausted = false
        hasStartedAttempt = true
        return true
    }
}
