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
    private(set) var verdict: EloGuess?

    /// Where the slider sits. Starts mid-ladder rather than at an end, so the
    /// first move of the slider is a decision instead of a correction.
    var guess = 1500
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

    func lockIn() -> EloGuess? {
        guard let game, verdict == nil else { return nil }
        let result = EloGuess(guess: guess, actual: game.averageRating)
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
    @State private var showsPaywall = false
    @State private var exhausted = false

    var body: some View {
        Group {
            if app.library.games.isEmpty {
                LibraryNotice(isLoaded: app.isLibraryLoaded, what: "games", file: "games.json")
                    .padding(12)
            } else {
                content
            }
        }
        .task(id: app.library.games.count) { if model.game == nil { next(interactive: false) } }
        .fullScreenCover(isPresented: $showsPaywall) { PaywallView(activity: .guessTheElo) }
        .onDisappear { model.stop() }
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
            if exhausted { AllowanceNotice(activity: .guessTheElo) }
            // The guess comes first, directly under the board. It is the one
            // thing on this screen you actually do, and a slider that has to be
            // scrolled to is a slider you will not move.
            if let verdict = model.verdict, let game = model.game {
                revealCard(verdict: verdict, game: game)
            } else {
                guessCard
            }
            filmCard
        } controls: {
            controls
        }
    }

    private var filmCard: some View {
        Card {
            HStack(alignment: .firstTextBaseline) {
                Text(model.latestMoveText)
                    .font(.system(.headline, design: .monospaced))
                    .contentTransition(.identity)
                Spacer()
                Text(verbatim: "\(model.moveNumber)/\(model.totalMoves)")
                    .font(.subheadline).monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            BrassProgressBar(
                value: Double(model.ply),
                total: Double(max(1, model.positions.count - 1))
            )

            // Everything about the game except what it is worth: naming the
            // opening and the clock is fair, naming the result is not — a game
            // that ends in a queen sacrifice reads very differently once you
            // know it worked.
            if let game = model.game, !model.isRevealed {
                Text(game.subtitle).font(.footnote).foregroundStyle(.secondary)
            }

            BrassSegmentedPicker(
                L.t("guess.speed", "Speed"),
                selection: Binding(get: { model.speed }, set: { model.speed = $0 }),
                options: Array(GuessTheEloModel.Speed.allCases)
            ) { speed in
                Text(speed.label)
            }
            .padding(.top, 2)
        }
    }

    private var guessCard: some View {
        Card {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: "\(model.guess)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(L.t("guess.yourGuessLichessRating", "your guess, Lichess rating")).font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            BrassSlider(
                value: Binding(
                    get: { Double(model.guess) },
                    set: { model.guess = Int(($0 / Double(EloGuess.step)).rounded()) * EloGuess.step }
                ),
                in: Double(EloGuess.range.lowerBound)...Double(EloGuess.range.upperBound),
                step: Double(EloGuess.step)
            )
        }
    }

    private func revealCard(verdict: EloGuess, game: AnnotatedGame) -> some View {
        Card {
            HStack(spacing: 8) {
                Text(verdict.verdict.title).font(Face.display(22))
                Spacer()
                Text(verbatim: "+\(verdict.points)")
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Text(verdict.summary).font(.subheadline).foregroundStyle(.secondary)

            HStack(spacing: 18) {
                revealValue(L.t("guess.youSaid", "You said"), verdict.guess)
                revealValue(L.color(.white), game.white)
                revealValue(L.color(.black), game.black)
            }
            .padding(.top, 2)

            Text([game.subtitle, resultText(game.result), terminationText(game)]
                .compactMap { $0 }.joined(separator: " · "))
                .font(.footnote).foregroundStyle(.secondary)

            let stats = app.progress.eloGuessStats
            if stats.judged > 1 {
                Text(L.t("guess.judgedSummary", "%lld games judged · average miss %lld points", stats.judged, stats.averageError))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func revealValue(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption2).textCase(.uppercase).foregroundStyle(.secondary)
            Text(verbatim: "\(value)").font(Face.display(22)).monospacedDigit()
        }
    }

    private func resultText(_ result: String) -> String {
        switch result {
        case "1-0": L.t("result.whiteWon", "White won")
        case "0-1": L.t("result.blackWon", "Black won")
        case "1/2-1/2": L.t("result.drawn", "Drawn")
        default: result
        }
    }

    private func terminationText(_ game: AnnotatedGame) -> String? {
        game.termination == "Time forfeit" ? L.t("result.onTime", "on time") : nil
    }

    private var controls: some View {
        ActionBar(items: [
            ActionItem(title: L.t("guess.back", "Back"), systemImage: "backward.frame", isEnabled: model.ply > 0) {
                model.stepManually(by: -1)
            },
            ActionItem(title: model.isPlaying ? L.t("guess.pause", "Pause") : L.t("guess.play", "Play"),
                       systemImage: model.isPlaying ? "pause.fill" : "play.fill",
                       isEnabled: !model.isFinished) {
                model.toggle()
            },
            ActionItem(title: L.t("guess.forward", "Forward"), systemImage: "forward.frame", isEnabled: !model.isFinished) {
                model.stepManually(by: 1)
            },
            model.isRevealed
                ? ActionItem(title: L.t("guess.nextGame", "Next game"), systemImage: "forward.end", emphasis: .primary) { next() }
                : ActionItem(title: L.t("guess.lockIn", "Lock in"), systemImage: "checkmark.circle", emphasis: .primary) { lockIn() },
        ])
    }

    private func lockIn() {
        guard let game = model.game, let verdict = model.lockIn() else { return }
        app.update { progress in
            progress.eloGuesses.append(
                EloGuessRecord(gameID: game.id, guess: verdict.guess, actual: verdict.actual)
            )
        }
    }

    private func next(interactive: Bool = true) {
        guard app.canStart(.guessTheElo) else {
            if interactive { showsPaywall = true } else { exhausted = true }
            return
        }
        exhausted = false
        app.consume(.guessTheElo)
        model.load(model.pick(from: app.library.games))
        model.play()
    }
}
