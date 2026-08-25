import BoardScene
import ChessCore
import ChessEngine
import ChessTraining
import Observation
import SwiftData
import SwiftUI

/// Who is playing a side.
///
/// Both seats are free and both can be changed in the middle of a game, which
/// is the whole point of the screen: you take a position from somewhere, push
/// it around by hand, and hand a side over the moment you want to see what an
/// engine would do with it.
enum BoardSeat: Equatable, Hashable, Identifiable, Sendable {
    case you
    case engine(EngineChoice)

    /// You first, then one entry per engine the app ships. Named rather than
    /// lumped together as "Engine": which one is playing is the interesting
    /// part of this screen, and on six test positions the two disagreed on
    /// four of them.
    static var all: [BoardSeat] { [.you] + EngineChoice.allCases.map(BoardSeat.engine) }

    var id: String {
        switch self {
        case .you: "you"
        case .engine(let choice): choice.rawValue
        }
    }

    var label: String {
        switch self {
        case .you: L.t("board.seatYou", "You")
        case .engine(let choice): choice.name
        }
    }

    /// The engine behind this seat, or nil when a person holds it.
    var choice: EngineChoice? {
        if case .engine(let choice) = self { return choice }
        return nil
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
        abandonSearch()
        refreshDestinations()
    }

    /// The engine currently searching, so a change to the board can cut its
    /// search short rather than let it burn a budget that is about to be
    /// thrown away.
    private var driver: (any Engine)?

    /// Stop a search whose board has just changed under it.
    ///
    /// Only for changes a person made. Not for the engine's own move: the loop
    /// plays one and starts the next search straight away, and a stop arriving
    /// late would cut short the search it was not meant for.
    ///
    /// Without this a handed-over seat left the abandoned search running its
    /// full budget — two and a half seconds, ten at the ceiling — while
    /// `isThinking` held the next one off. Several quick changes queued up
    /// behind each other and the board looked stuck.
    private func abandonSearch() {
        guard isThinking, let driver else { return }
        Task { await driver.stop() }
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
        isAtLiveEnd && !position.isGameOver && seat(for: position.sideToMove) != .you
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
        abandonSearch()
        start = Position()
        line = []
        ply = 0
        note = nil
        rebuild()
    }

    /// Begin again from a position somebody set up or corrected by hand.
    ///
    /// The line goes rather than being replayed onto the new board: the moves
    /// belonged to the position they were played in, and that position is not
    /// this one.
    func begin(from position: Position) {
        abandonSearch()
        start = position
        line = []
        ply = 0
        note = nil
        rebuild()
    }

    /// Take a game over from somewhere else — a recording being watched, a
    /// game out of the history — and stand at the end of what was handed over.
    ///
    /// The moves are replayed rather than trusted: they came from a store that
    /// a future version may have written differently, and a line that stops
    /// making sense half way through is better truncated than crashed on.
    func take(_ handoff: BoardHandoff) {
        abandonSearch()
        start = handoff.start
        line = []
        var replay = handoff.start
        for san in handoff.moves {
            guard let move = replay.move(san: san) else { break }
            line.append((move: move, san: san))
            replay.make(move)
        }
        ply = line.count
        note = line.isEmpty
            ? nil
            : L.t("board.takenOver", "%1$@ — carrying on after %2$lld moves.",
                  handoff.title, line.count)
        rebuild()
    }

    /// Read a paste and put it on the board.
    ///
    /// Returns false only when nothing could be read at all. A line that broke
    /// part way is a success with a caveat, not a failure: the moves before the
    /// bad token are a real game and are worth having.
    @discardableResult
    func load(_ text: String) -> Bool {
        abandonSearch()
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
        abandonSearch()
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
    func runEngines(resolve: (EngineChoice) async -> (any Engine)?) async {
        guard !isThinking else { return }
        isThinking = true
        defer {
            isThinking = false
            driver = nil
        }

        while engineOwesMove {
            // Looked up per move rather than passed in once: the two sides can
            // be held by different engines, and either can change hands while
            // this loop is running.
            guard let choice = seat(for: position.sideToMove).choice,
                  let engine = await resolve(choice) else { return }
            driver = engine

            let token = generation
            let fen = position.fen
            let uci = try? await engine.chooseMove(fen: fen, elo: nil, budget: .fullStrength)

            // The board can change while the search runs — a seat handed over,
            // a step, a move played by hand. Go round again on the board that
            // is there now rather than returning: the caller that made the
            // change found this loop running and left it to us, so giving up
            // here strands two engine seats with nobody to move.
            guard token == generation, position.fen == fen else {
                // Give the stop fired for that change a moment to land, so it
                // cuts short the search it was meant for and not the next one.
                await Task.yield()
                continue
            }
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
    @Environment(Navigator.self) private var navigator
    @State private var model = BoardModel()
    @State private var values = MoveValueController()
    @State private var isImporting = false
    /// The board the editor opens on. Presented by identity rather than a flag
    /// because two things feed it — the Set up button and a photograph — and a
    /// flag would have to be paired with somewhere to put the position.
    @State private var editorSeed: EditorSeed?
    @State private var isPhotographing = false
    @Environment(\.modelContext) private var history
    /// The line that has already been written down, so a board that reaches
    /// checkmate and is then stepped about does not file the same game twice.
    @State private var saved: String?
    #if DEBUG
    /// One move in the preview, not a move every two seconds for ever.
    @State private var previewHasMoved = false
    #endif

    private var material: MaterialBalance { MaterialBalance(model.position) }

    /// Whoever holds the side, named. No ladder here on purpose — this board
    /// is for looking at positions, and a deliberately weakened answer is the
    /// wrong tool for that even when the engine can give one.
    private var seatName: (PieceColor) -> String {
        { color in model.seat(for: color).label }
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
        // Seeded with what is on the board, so the editor is a way to adjust a
        // position as well as to build one — which is what anything read off a
        // photograph will need.
        .sheet(item: $editorSeed) { seed in
            PositionEditorSheet(
                model: seed.editor(orientation: model.orientation)
            ) { position in
                model.begin(from: position)
                driveEngines()
            }
        }
        #if canImport(UIKit)
        // Whatever a photograph produces goes to the editor, always. Even the
        // best published reader gets a few squares wrong on an average board,
        // so correcting it is the feature and not a safety net.
        .sheet(isPresented: $isPhotographing) {
            PhotoBoardSheet(isPresented: $isPhotographing, reader: UnreadBoard()) { pieces in
                editorSeed = EditorSeed(pieces: pieces)
            }
        }
        #endif
        // A seat handed to an engine has to start thinking without waiting for
        // a move to be played, or handing over the side to move does nothing
        // visible until you poke the board.
        .onChange(of: model.whiteSeat) { _, _ in driveEngines() }
        .onChange(of: model.blackSeat) { _, _ in driveEngines() }
        // Stepping forward onto the end of the line puts an engine back on
        // move, and it has to notice. This also covers an import that lands on
        // a position an engine holds — `load` moves `ply` to the end.
        .onChange(of: model.ply) { _, _ in driveEngines() }
        // A Stockfish kept alive is its networks kept in memory. Nothing on
        // this screen needs a second engine once the screen is gone.
        .onDisappear { Task { await app.releaseSpare() } }
        #if DEBUG
        // The end of the long preview: the game arrives from the library and a
        // move is played on it, because "carry on from here" is a promise and a
        // preview should show it kept.
        .task(id: model.ply) {
            guard ScreenshotScene.requested == .demoWatch, !previewHasMoved,
                  !model.line.isEmpty, model.isAtLiveEnd else { return }
            previewHasMoved = true
            try? await Task.sleep(for: .seconds(2))
            guard let uci = try? await app.engine.chooseMove(
                fen: model.position.fen, budget: .hint
            ), let move = Move(uci: uci) else { return }
            model.play(from: move.from, to: move.to, promotion: move.promotion)
        }
        .task {
            guard ScreenshotScene.requested == .boardEngines else { return }
            // A named opening rather than the empty array: a board with a game
            // on it photographs better than a board waiting for one.
            model.load("1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6")
            model.setSeat(.engine(.stockfish), for: .white)
            model.setSeat(.engine(.reckless), for: .black)
            // Said here rather than left to the play screen, which does not
            // own this one: the free board is its own mode, so the play
            // screen's signal only ever arrived by accident — and did not, for
            // eighteen of the twenty-nine languages.
            //
            // Then wait for the board to fade itself in. Saying ready the
            // instant the game was loaded was near enough on most launches and
            // not near enough on two: Hindi and Simplified Chinese have a
            // typeface to load first, which pushed the first frame past the
            // moment the shutter went, and both listings had a picture of an
            // empty room. Waiting on the board rather than on a longer sleep
            // keeps the composition — this is meant to be caught early, while
            // the loaded game is still settling onto the squares.
            for _ in 0..<200 where !BoardSceneDebug.boardHasAppeared {
                try? await Task.sleep(for: .milliseconds(50))
            }
            ScreenshotScene.markReady()
        }
        #endif
        // Only a finished game is kept. This board spends most of its life
        // holding positions somebody is poking at, and filing every poke would
        // bury the games worth having.
        .onChange(of: model.position.isGameOver) { _, over in
            guard over, model.isAtLiveEnd else { return }
            saveFinishedGame()
        }
        // Taken on appearing rather than watched for, because the hand-over
        // happens on another screen: by the time this one exists the game is
        // already waiting.
        .onAppear {
            guard let handoff = navigator.boardHandoff else { return }
            navigator.boardHandoff = nil
            model.take(handoff)
            driveEngines()
        }
    }

    /// Write the game down.
    ///
    /// The result is recorded from your side when you held one, and as the bare
    /// score when both sides were engines — there is no "you" in that game to
    /// have won it.
    private func saveFinishedGame() {
        let notation = model.line.map(\.san).joined(separator: " ")
        guard !notation.isEmpty, saved != notation else { return }
        saved = notation

        let winner: PieceColor? = model.position.isCheckmate ? model.position.sideToMove.opponent : nil
        let yours: PieceColor? = if model.whiteSeat == .you { .white }
            else if model.blackSeat == .you { .black } else { nil }

        let result: String = if let yours, let winner { winner == yours ? "win" : "loss" }
            else if winner == nil { "draw" }
            else if winner == .white { "1-0" } else { "0-1" }

        history.insert(SavedGame(
            startFEN: model.start.fen,
            notation: notation,
            result: result,
            white: model.whiteSeat == .you ? "" : model.whiteSeat.label,
            black: model.blackSeat == .you ? "" : model.blackSeat.label,
            yourColor: yours.map { $0 == .white ? "white" : "black" },
            source: "board"
        ))
        try? history.save()
    }

    private func driveEngines() {
        Task { await model.runEngines { await app.engine(for: $0) } }
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
                options: BoardSeat.all
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
                Button(L.t("board.setUp", "Set up")) {
                    editorSeed = EditorSeed(position: model.position)
                }
                .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                #if canImport(UIKit)
                Button(L.t("board.fromPhoto", "Photo")) { isPhotographing = true }
                    .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                #endif
            }

            HStack(spacing: 8) {
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


/// A board on its way to the editor.
///
/// Carries pieces rather than a `Position` because a photograph may yield
/// something that is not one — an unread board has no kings, and the parser
/// refuses that. Wrapped with an id because two photographs of the same board
/// would otherwise be the same sheet.
private struct EditorSeed: Identifiable {
    let id = UUID()
    let pieces: [Square: Piece]
    let sideToMove: PieceColor
    let castling: CastlingRights

    init(position: Position) {
        var found: [Square: Piece] = [:]
        for index in 0..<64 where position[Square(index)] != nil {
            found[Square(index)] = position[Square(index)]
        }
        pieces = found
        sideToMove = position.sideToMove
        castling = position.castling
    }

    /// From a photograph: white to move and no castling rights, because a
    /// picture says nothing about either and guessing would be inventing.
    init(pieces: [Square: Piece]) {
        self.pieces = pieces
        sideToMove = .white
        castling = []
    }
}


@MainActor
private extension EditorSeed {
    func editor(orientation: PieceColor) -> PositionEditorModel {
        let model = PositionEditorModel(pieces: pieces, orientation: orientation)
        model.sideToMove = sideToMove
        for right in [CastlingRights.whiteKingside, .whiteQueenside, .blackKingside, .blackQueenside]
        where castling.contains(right) {
            model.setCastling(right, on: true)
        }
        return model
    }
}
