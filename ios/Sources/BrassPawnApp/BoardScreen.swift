import ChessCore
import ChessEngine
import ChessTraining
import Observation
import SwiftUI

/// Who is playing a side.
///
/// Both seats are free and both can be changed in the middle of a game, which
/// is the whole point of the screen: you take a position from somewhere, push
/// it around by hand, and hand a side over the moment you want to see what an
/// engine would do with it.
enum BoardSeat: String, CaseIterable, Identifiable, Sendable {
    case you, engine
    var id: String { rawValue }

    var label: String {
        switch self {
        case .you: L.t("board.seatYou", "You")
        case .engine: L.t("board.seatEngine", "Engine")
        }
    }
}

/// A board with a line on it and nobody's turn taken for granted.
@MainActor
@Observable
final class BoardModel {
    /// Where the line begins — the opening position, or whatever a FEN said.
    private(set) var start = Position()

    /// The line, with the notation written down beside it.
    ///
    /// SAN is stored rather than re-derived because it depends on the position
    /// the move was played in, and once the board has stepped past that
    /// position it is gone. Recomputing from the current board would quietly
    /// produce a different move number's worth of disambiguation.
    private(set) var line: [(move: Move, san: String)] = []

    /// How far along the line the board is showing. Always `0...line.count`.
    private(set) var ply = 0

    private(set) var position = Position()
    private(set) var legalDestinations: [Square: [Square]] = [:]
    private(set) var lastMove: (from: Square, to: Square)?
    private(set) var isThinking = false

    /// What the last paste did, in words — including what it could not do.
    private(set) var note: String?

    var orientation: PieceColor = .white
    /// Changing a seat has to refresh the board as well as cancel any search:
    /// which squares are movable depends on who holds the side to move, so
    /// handing that side to an engine must take the highlights away.
    var whiteSeat: BoardSeat = .you { didSet { seatChanged() } }
    var blackSeat: BoardSeat = .you { didSet { seatChanged() } }

    init() { rebuild() }

    /// Bumped by anything that makes a search in flight no longer worth
    /// applying: a move played by hand, a step, a new import, a seat changing
    /// hands. The engine reads it before and after its await and drops the
    /// answer if the board it was thinking about is not the board any more.
    private var generation = 0

    private func invalidate() { generation &+= 1 }

    private func seatChanged() {
        invalidate()
        refreshDestinations()
    }

    func seat(for color: PieceColor) -> BoardSeat {
        color == .white ? whiteSeat : blackSeat
    }

    func setSeat(_ seat: BoardSeat, for color: PieceColor) {
        if color == .white { whiteSeat = seat } else { blackSeat = seat }
    }

    var isAtLiveEnd: Bool { ply == line.count }
    var canStepBack: Bool { ply > 0 }
    var canStepForward: Bool { ply < line.count }

    /// Whether an engine owes a move right now.
    ///
    /// Only at the end of the line: stepping back to look at something has to
    /// stop the engines, or the board you are reading moves out from under you.
    var engineOwesMove: Bool {
        isAtLiveEnd && !position.isGameOver && seat(for: position.sideToMove) == .engine
    }

    var statusText: String {
        if position.isCheckmate {
            let winner = position.sideToMove.opponent
            return L.t("board.checkmate", "Checkmate — %@ wins.", L.color(winner))
        }
        if position.isDraw { return L.t("board.draw", "Drawn.") }
        if isThinking { return L.t("board.thinking", "Thinking…") }
        if !isAtLiveEnd {
            return L.t("board.reviewing", "Looking back — play a move to branch from here.")
        }
        return L.t("board.toMove", "%@ to move.", L.color(position.sideToMove))
    }

    // MARK: - Setting it up

    /// Start again from the opening position, both seats untouched.
    func reset() {
        start = Position()
        line = []
        ply = 0
        note = nil
        rebuild()
    }

    /// Read a paste and put it on the board.
    ///
    /// Returns false only when nothing could be read at all. A line that broke
    /// part way is a success with a caveat, not a failure: the moves before the
    /// bad token are a real game and are worth having.
    @discardableResult
    func load(_ text: String) -> Bool {
        guard let imported = GameImport.read(text) else {
            note = L.t("board.unreadable",
                       "That did not read as a game or a position.")
            invalidate()
            return false
        }

        start = imported.start
        line = []
        var replay = imported.start
        for move in imported.moves {
            let san = replay.san(for: move)
            replay.make(move)
            line.append((move: move, san: san))
        }
        // Landing at the end rather than the beginning: somebody who pastes a
        // game wants the position it reached. Stepping back is one button.
        ply = line.count
        note = describe(imported)
        rebuild()
        return true
    }

    private func describe(_ imported: GameImport) -> String {
        if let stopped = imported.stoppedAt {
            return L.t("board.stoppedAt",
                       "Read %lld moves, then stopped at “%@”.",
                       stopped.afterMoves, stopped.token)
        }
        if imported.isEmpty {
            return L.t("board.positionOnly", "Position read.")
        }
        return L.t("board.movesRead", "Read %lld moves.", imported.moves.count)
    }

    // MARK: - Moving about

    func step(to target: Int) {
        let clamped = max(0, min(line.count, target))
        guard clamped != ply else { return }
        ply = clamped
        rebuild()
    }

    func stepBack() { step(to: ply - 1) }
    func stepForward() { step(to: ply + 1) }
    func stepToStart() { step(to: 0) }
    func stepToEnd() { step(to: line.count) }

    func flip() { orientation = orientation.opponent }

    // MARK: - Playing

    /// Play a move by hand.
    ///
    /// Legal from anywhere in the line, including the middle of it: a move
    /// played from a position you stepped back to replaces everything after it,
    /// which is what an analysis board is for. The moves you dropped are gone —
    /// they were one line and now there is another.
    func play(from: Square, to: Square, promotion: PieceKind?) {
        guard !position.isGameOver else { return }
        guard let move = position.legalMoves().first(where: {
            $0.matchesNotation(of: Move(from: from, to: to, promotion: promotion))
        }) else { return }
        append(move)
    }

    private func append(_ move: Move) {
        let san = position.san(for: move)
        let captured = position[move.to] != nil
        if ply < line.count { line.removeSubrange(ply...) }
        var next = position
        guard let made = next.make(move) else { return }
        line.append((move: made, san: san))
        ply = line.count
        position = next
        lastMove = (from: made.from, to: made.to)
        SoundBoard.shared.play(move: made, captured: captured, resulting: position)
        refreshDestinations()
        invalidate()
    }

    /// Let the engines play whatever they owe, one move at a time.
    ///
    /// A loop rather than a single move so that two engine seats play each
    /// other, and a generation check on both sides of the await so that a
    /// search started for a board nobody is looking at any more is dropped
    /// rather than applied.
    func runEngines(_ engine: any Engine, elo: Int?) async {
        guard !isThinking else { return }
        isThinking = true
        defer { isThinking = false }

        while engineOwesMove {
            let token = generation
            let fen = position.fen
            let uci = try? await engine.chooseMove(
                fen: fen, elo: elo, budget: .fullStrength
            )
            // The board can change while the search runs — a seat handed
            // over, a step, a move played by hand. Go round again on the board
            // that is there now rather than returning: the caller that made the
            // change already found this loop running and left it to us, so
            // giving up here strands two engine seats with nobody to move.
            guard token == generation, position.fen == fen else { continue }
            guard let uci, let parsed = Move(uci: uci),
                  let move = position.legalMoves().first(where: { $0.matchesNotation(of: parsed) })
            else { return }
            append(move)
        }
    }

    // MARK: - Derivation

    /// Rebuild the board from the start of the line.
    ///
    /// Replaying is cheap at these lengths and cannot drift the way an undo
    /// stack can — the same reasoning as `PlayModel.takeBack`.
    private func rebuild() {
        var replay = start
        for entry in line.prefix(ply) { replay.make(entry.move) }
        position = replay
        lastMove = ply > 0 ? (from: line[ply - 1].move.from, to: line[ply - 1].move.to) : nil
        refreshDestinations()
        invalidate()
    }

    /// Both sides are movable when a person holds them, because on this board
    /// there is no "your" colour — you are pushing the pieces about.
    private func refreshDestinations() {
        guard !position.isGameOver, seat(for: position.sideToMove) == .you else {
            legalDestinations = [:]
            return
        }
        var map: [Square: [Square]] = [:]
        for move in position.legalMoves() { map[move.from, default: []].append(move.to) }
        legalDestinations = map
    }
}

// MARK: - The screen

/// A free board: bring a position, push it about, hand either side to an engine.
struct BoardScreen: View {
    @Environment(AppModel.self) private var app
    @State private var model = BoardModel()
    @State private var values = MoveValueController()
    @State private var isImporting = false

    private var material: MaterialBalance { MaterialBalance(model.position) }

    /// The engine plays at whatever the chosen engine can do. There is no
    /// ladder here on purpose — this board is for looking at positions, and a
    /// deliberately weakened answer is the wrong tool for that even when the
    /// engine can give one.
    private var seatName: (PieceColor) -> String {
        { color in
            model.seat(for: color) == .engine
                ? app.engineChoice.name
                : L.t("board.seatYou", "You")
        }
    }

    var body: some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: seatName(model.orientation.opponent),
                    color: model.orientation.opponent,
                    material: material
                ),
                bottom: PlayerBar(
                    name: seatName(model.orientation),
                    color: model.orientation,
                    material: material
                ),
                orientation: model.orientation
            ) {
                GameBoard(
                    position: model.position,
                    orientation: model.orientation,
                    legalDestinations: model.legalDestinations,
                    lastMove: model.lastMove,
                    onMove: { from, to, promotion in
                        model.play(from: from, to: to, promotion: promotion)
                        driveEngines()
                    }
                )
            }
        } panel: {
            panel
        } controls: {
            controls
        }
        .sheet(isPresented: $isImporting) { ImportSheet(model: model, isPresented: $isImporting) }
        // A seat handed to an engine has to start thinking without waiting for
        // a move to be played, or handing over the side to move does nothing
        // visible until you poke the board.
        .onChange(of: model.whiteSeat) { _, _ in driveEngines() }
        .onChange(of: model.blackSeat) { _, _ in driveEngines() }
        // Stepping forward onto the end of the line puts an engine back on
        // move, and it has to notice. This also covers an import that lands on
        // a position an engine holds — `load` moves `ply` to the end.
        .onChange(of: model.ply) { _, _ in driveEngines() }
    }

    private func driveEngines() {
        Task { await model.runEngines(app.engine, elo: nil) }
    }

    @ViewBuilder
    private var panel: some View {
        Card {
            Text(model.statusText).appFont(size: 22, weight: .semibold)

            if let note = model.note {
                Text(note).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
            }

            seatPicker(L.color(.white), color: .white)
            seatPicker(L.color(.black), color: .black)

            if model.line.isEmpty {
                Text(L.t("board.empty",
                         "Paste a game or a position to start from, or just play moves."))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryFaint)
            } else {
                LineView(line: model.line, ply: model.ply) { model.step(to: $0) }
            }
        }
    }

    /// The caption is drawn here rather than left to the picker, which takes a
    /// title for accessibility and does not show it. Two identical You/Engine
    /// rows with nothing to tell them apart is not a control, it is a guess.
    private func seatPicker(_ title: String, color: PieceColor) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .appFont(size: 9)
                .tracking(1.5)
                .foregroundStyle(Theatre.ivoryFaint)

            BrassSegmentedPicker(
                title,
                selection: Binding(
                    get: { model.seat(for: color) },
                    set: { model.setSeat($0, for: color) }
                ),
                options: Array(BoardSeat.allCases)
            ) { seat in
                Text(seat.label)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                stepButton("backward.end.fill", enabled: model.canStepBack) { model.stepToStart() }
                stepButton("chevron.left", enabled: model.canStepBack) { model.stepBack() }
                stepButton("chevron.right", enabled: model.canStepForward) { model.stepForward() }
                stepButton("forward.end.fill", enabled: model.canStepForward) { model.stepToEnd() }
            }

            HStack(spacing: 8) {
                Button(L.t("board.import", "Paste a game")) { isImporting = true }
                    .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                Button(L.t("board.flip", "Flip")) { model.flip() }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                Button(L.t("board.startOver", "Start over")) {
                    model.reset()
                    driveEngines()
                }
                .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
            }
        }
    }

    private func stepButton(
        _ icon: String, enabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            BrassIcon(icon, size: 16)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .background(Theatre.brass.opacity(enabled ? 0.16 : 0.05), in: .rect(cornerRadius: 8))
        .foregroundStyle(enabled ? Theatre.brass : Theatre.ivoryFaint)
        .disabled(!enabled)
    }
}

/// The line, with the move the board is showing marked and every move a target.
private struct LineView: View {
    let line: [(move: Move, san: String)]
    let ply: Int
    let jump: (Int) -> Void

    private struct Pair: Identifiable {
        let id: Int
        let white: (index: Int, san: String)?
        let black: (index: Int, san: String)?
    }

    private var pairs: [Pair] {
        var result: [Pair] = []
        var index = 0
        while index < line.count {
            let white = (index: index, san: line[index].san)
            var black: (index: Int, san: String)?
            if index + 1 < line.count {
                black = (index: index + 1, san: line[index + 1].san)
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
                    entry(pair.white)
                    entry(pair.black)
                    Spacer()
                }
                .appFont(.footnote)
            }
        }
    }

    @ViewBuilder
    private func entry(_ move: (index: Int, san: String)?) -> some View {
        if let move {
            // The index is a move's position in the line; stepping *to* it means
            // showing the board after it, which is one greater.
            Button { jump(move.index + 1) } label: {
                Text(move.san)
                    .foregroundStyle(ply == move.index + 1 ? Theatre.brass : Theatre.ivory)
                    .frame(width: 62, alignment: .leading)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(width: 62, height: 1)
        }
    }
}

/// The clipboard, under one name.
///
/// Not in `Platform.swift`, which is about what the Mac is missing. This is a
/// genuine difference — both platforms have a pasteboard and they are spelled
/// differently — and one screen uses it.
private enum Clipboard {
    static var text: String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #elseif canImport(AppKit)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }
}

/// Where a pasted game comes in.
///
/// A text box rather than a bare "paste" button, because the two ways people
/// arrive are different: a PGN copied from a site is on the clipboard, and a
/// line out of a book is typed. The box takes both, and shows what it made of
/// the text before the sheet closes over it.
private struct ImportSheet: View {
    let model: BoardModel
    @Binding var isPresented: Bool

    @State private var text = ""
    @State private var failed = false

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.t("board.importTitle", "Paste a game or a position"))
                .appFont(size: 22, weight: .semibold)

            Text(L.t("board.importHint",
                     "A FEN, a PGN, or just the moves — 1.e4 e5 or e2e4 e7e5. Comments, move numbers and variations are ignored."))
                .appFont(.footnote)
                .foregroundStyle(Theatre.ivoryDim)

            TextEditor(text: $text)
                .appFont(.footnote)
                .scrollContentBackground(.hidden)
                .background(Theatre.brass.opacity(0.08), in: .rect(cornerRadius: 10))
                .frame(minHeight: 140)

            if failed {
                Text(L.t("board.unreadable", "That did not read as a game or a position."))
                    .appFont(.footnote)
                    .foregroundStyle(Color(red: 0.851, green: 0.439, blue: 0.373))
            }

            HStack(spacing: 8) {
                Button(L.t("board.fromClipboard", "From clipboard")) {
                    if let clipboard = Clipboard.text { text = clipboard }
                }
                .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))

                Spacer()

                Button(L.t("common.cancel", "Cancel")) { isPresented = false }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))

                // `enabled` as well as `.disabled`: the style takes a plain
                // flag rather than reading the environment, so without it the
                // button is inert but still looks live.
                Button(L.t("board.readIt", "Read it")) {
                    if model.load(text) { isPresented = false } else { failed = true }
                }
                .buttonStyle(PillButtonStyle(
                    emphasis: .solid, enabled: hasText, usesBodySize: true
                ))
                .disabled(!hasText)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theatre.ink2)
        .onChange(of: text) { _, _ in failed = false }
    }
}
