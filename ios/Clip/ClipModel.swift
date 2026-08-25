import ChessCore
import ChessTraining
import Foundation
import Observation

/// The whole of the App Clip's state: six positions, and how far through them
/// somebody has got.
///
/// No engine, no rating, no schedule, no progress kept between launches. A clip
/// is a demonstration, and everything it does not carry is a reason it stays
/// small enough to arrive in a second.
@MainActor
@Observable
final class ClipModel {
    enum Verdict: Equatable {
        case waiting
        case wrong
        case solved
    }

    /// After this many, the App Store card comes up of its own accord. Three is
    /// enough to have felt the thing work and not so many that the offer
    /// arrives after the interest has gone.
    static let offerAfter = 3

    private(set) var puzzles: [Puzzle] = []
    private(set) var index = 0
    private(set) var position = Position()
    private(set) var verdict: Verdict = .waiting
    private(set) var solvedCount = 0
    private(set) var lastMove: (from: Square, to: Square)?
    /// Set once, when the third puzzle is solved, so the offer is made once
    /// rather than every time the count is looked at.
    private(set) var shouldOfferApp = false

    /// Who sent the link, if anybody did. Shown at the top, and handed to the
    /// app through the shared container so an install does not lose it.
    var invitation: Invitation?

    /// How far into the current solution we are. The solution alternates
    /// solver, opponent, solver…; this counts only the moves already played.
    private var ply = 0

    var puzzle: Puzzle? { puzzles.indices.contains(index) ? puzzles[index] : nil }
    var isFinished: Bool { index >= puzzles.count }

    /// True while the board should refuse input: the opponent is replying, or
    /// the puzzle is over and the next one is on its way.
    private(set) var isBusy = false

    init() {
        load()
    }

    private func load() {
        struct File: Decodable { let puzzles: [Puzzle] }
        guard let url = Bundle.main.url(forResource: "clip-tactics", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else { return }
        puzzles = file.puzzles
        start()
    }

    private func start() {
        guard let puzzle, let fresh = Position(fen: puzzle.fen) else { return }
        position = fresh
        ply = 0
        verdict = .waiting
        lastMove = nil
        isBusy = false
    }

    var legalDestinations: [Square: [Square]] {
        guard !isBusy, !isFinished else { return [:] }
        var moves: [Square: [Square]] = [:]
        for move in position.legalMoves() {
            moves[move.from, default: []].append(move.to)
        }
        return moves
    }

    /// A move from the board. Right moves advance the line; wrong ones are
    /// shown as wrong and taken back, because a demonstration that punishes you
    /// for a first guess is not a demonstration of anything good.
    func play(from: Square, to: Square, promotion kind: PieceKind?) {
        guard !isBusy, let puzzle, ply < puzzle.solution.count else { return }
        let attempted = Move(from: from, to: to, promotion: kind).uci
        let expected = puzzle.solution[ply]

        // A promotion the player was not asked about: the board only offers a
        // picker when there is a choice, and the solution always names one.
        guard attempted == expected || attempted == String(expected.dropLast()) else {
            verdict = .wrong
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                if verdict == .wrong { verdict = .waiting }
            }
            return
        }

        apply(expected)
        ply += 1

        if ply >= puzzle.solution.count {
            finish()
        } else {
            replyForOpponent()
        }
    }

    private func apply(_ uci: String) {
        guard let move = Move(uci: uci) else { return }
        _ = position.make(uci: uci)
        lastMove = (move.from, move.to)
    }

    private func replyForOpponent() {
        guard let puzzle, ply < puzzle.solution.count else { return }
        isBusy = true
        let reply = puzzle.solution[ply]
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            apply(reply)
            ply += 1
            isBusy = false
        }
    }

    private func finish() {
        verdict = .solved
        solvedCount += 1
        isBusy = true
        if solvedCount == Self.offerAfter { shouldOfferApp = true }
    }

    /// Called by the view once it has shown the solved state for a moment.
    func advance() {
        index += 1
        if isFinished {
            verdict = .waiting
            isBusy = true
        } else {
            start()
        }
    }

    func offerWasShown() {
        shouldOfferApp = false
    }

    /// Take the invitation out of the URL that launched us and leave a copy
    /// where the app will find it if this ends in an install.
    func accept(_ url: URL) {
        guard let invitation = Invitation(url: url) else { return }
        self.invitation = invitation
        SharedContainer.store(invitation)
    }

    /// The same invocation URL, read from the environment.
    ///
    /// This is where Xcode puts it when a clip is run from a scheme, and the
    /// only way to arrive at an invitation on a simulator — `simctl` has no
    /// notion of an App Clip invocation. On a device the value is absent and
    /// the user activity does the work instead.
    func acceptLaunchArgument() {
        guard invitation == nil,
              let text = ProcessInfo.processInfo.environment["_XCAppClipURL"],
              let url = URL(string: text)
        else { return }
        accept(url)
    }
}
