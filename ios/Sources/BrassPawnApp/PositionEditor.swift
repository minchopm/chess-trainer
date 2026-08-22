import ChessCore
import ChessTraining
import Observation
import SwiftUI

/// What a tap on a square does.
enum EditorBrush: Equatable {
    case place(Piece)
    case erase
}

/// A board you build by hand.
///
/// Its state is a loose map of squares to pieces rather than a `Position`,
/// because half-built boards are the normal case here: two white kings while
/// you move one of them, no black king at all for the first ten taps. A
/// `Position` cannot hold any of that — it refuses to parse a FEN whose kings
/// are missing or adjacent — so the editor keeps its own state and hands over
/// only when the result is a real position.
@MainActor
@Observable
final class PositionEditorModel {
    private(set) var pieces: [Square: Piece] = [:]
    var sideToMove: PieceColor = .white
    private(set) var castling: CastlingRights = []
    var brush: EditorBrush = .place(Piece(.white, .pawn))
    var orientation: PieceColor = .white

    init(_ position: Position = Position(), orientation: PieceColor = .white) {
        self.orientation = orientation
        load(position)
    }

    /// Start from a loose map of pieces.
    ///
    /// What a photograph produces cannot be a `Position`: nothing was
    /// recognised on an unread board, and a board without kings is not a
    /// position the parser will accept. Handing the map straight over is the
    /// honest route — the editor was built to hold exactly this.
    init(pieces: [Square: Piece], orientation: PieceColor = .white) {
        self.orientation = orientation
        self.pieces = pieces
        sideToMove = .white
        castling = []
    }

    func load(_ position: Position) {
        pieces = [:]
        for index in 0..<64 where position[Square(index)] != nil {
            pieces[Square(index)] = position[Square(index)]
        }
        sideToMove = position.sideToMove
        castling = position.castling
    }

    // MARK: - Editing

    func tap(_ square: Square) {
        switch brush {
        case .erase:
            pieces[square] = nil
        case .place(let piece):
            // Tapping a square that already holds the armed piece clears it, so
            // a misplaced piece comes off with the same finger that put it down.
            pieces[square] = pieces[square] == piece ? nil : piece
        }
        pruneCastling()
    }

    func clear() {
        pieces = [:]
        castling = []
    }

    func resetToOpening() { load(Position()) }

    func flip() { orientation = orientation.opponent }

    func setCastling(_ right: CastlingRights, on: Bool) {
        if on { castling.insert(right) } else { castling.remove(right) }
        pruneCastling()
    }

    /// Whether a right is even available to offer.
    ///
    /// Castling needs the king and the rook on their home squares. A right left
    /// ticked after either has been moved away writes a FEN that says something
    /// untrue, and the engines believe it.
    func canCastle(_ right: CastlingRights) -> Bool {
        switch right {
        case .whiteKingside: has(.white, .king, "e1") && has(.white, .rook, "h1")
        case .whiteQueenside: has(.white, .king, "e1") && has(.white, .rook, "a1")
        case .blackKingside: has(.black, .king, "e8") && has(.black, .rook, "h8")
        case .blackQueenside: has(.black, .king, "e8") && has(.black, .rook, "a8")
        default: false
        }
    }

    private func has(_ color: PieceColor, _ kind: PieceKind, _ name: String) -> Bool {
        guard let square = Square(name) else { return false }
        return pieces[square] == Piece(color, kind)
    }

    private func pruneCastling() {
        for right in [CastlingRights.whiteKingside, .whiteQueenside, .blackKingside, .blackQueenside]
        where castling.contains(right) && !canCastle(right) {
            castling.remove(right)
        }
    }

    // MARK: - Reading it back

    /// En passant is always written as unavailable. Setting it needs to know the
    /// move that was just played, which an editor does not have, and a wrong en
    /// passant square is a worse answer than no en passant square.
    var fen: String {
        var rows: [String] = []
        for rank in stride(from: 7, through: 0, by: -1) {
            var row = ""
            var empty = 0
            for file in 0..<8 {
                if let piece = pieces[Square(file: file, rank: rank)] {
                    if empty > 0 { row += String(empty); empty = 0 }
                    row.append(piece.character)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { row += String(empty) }
            rows.append(row)
        }

        var rights = ""
        if castling.contains(.whiteKingside) { rights += "K" }
        if castling.contains(.whiteQueenside) { rights += "Q" }
        if castling.contains(.blackKingside) { rights += "k" }
        if castling.contains(.blackQueenside) { rights += "q" }

        return "\(rows.joined(separator: "/")) \(sideToMove == .white ? "w" : "b")"
            + " \(rights.isEmpty ? "-" : rights) - 0 1"
    }

    private func count(_ color: PieceColor, _ kind: PieceKind? = nil) -> Int {
        pieces.values.filter { $0.color == color && (kind == nil || $0.kind == kind) }.count
    }

    private func square(of piece: Piece) -> Square? {
        pieces.first { $0.value == piece }?.key
    }

    /// What is wrong with the board, in one sentence, or nil when nothing is.
    ///
    /// Checked here rather than left to `Position(fen:)` because the parser
    /// answers only yes or no, and "no" with no reason is not something you can
    /// act on when you are staring at thirty-two pieces.
    var problem: String? {
        for color in PieceColor.allCases where count(color, .king) != 1 {
            return count(color, .king) == 0
                ? L.t("editor.needsKing", "%@ has no king.", L.color(color))
                : L.t("editor.oneKing", "%@ has more than one king.", L.color(color))
        }

        if pieces.contains(where: { $0.value.kind == .pawn && ($0.key.rank == 0 || $0.key.rank == 7) }) {
            return L.t("editor.pawnOnEdge", "A pawn cannot stand on the first or the last rank.")
        }

        for color in PieceColor.allCases {
            if count(color, .pawn) > 8 {
                return L.t("editor.tooManyPawns", "%@ has more than eight pawns.", L.color(color))
            }
            if count(color) > 16 {
                return L.t("editor.tooManyPieces", "%@ has more than sixteen pieces.", L.color(color))
            }
        }

        if let white = square(of: Piece(.white, .king)), let black = square(of: Piece(.black, .king)),
           abs(white.file - black.file) <= 1, abs(white.rank - black.rank) <= 1 {
            return L.t("editor.kingsTouch", "The kings are standing next to each other.")
        }

        // The side that is not to move must not be in check: that position can
        // only be reached by a move nobody would be allowed to make.
        var fields = fen.split(separator: " ").map(String.init)
        fields[1] = sideToMove == .white ? "b" : "w"
        if let mirrored = Position(fen: fields.joined(separator: " ")), mirrored.isCheck {
            return L.t("editor.wrongSideInCheck",
                       "%1$@ is in check, so it cannot be %2$@ to move.",
                       L.color(sideToMove.opponent), L.color(sideToMove))
        }

        guard Position(fen: fen) != nil else {
            return L.t("editor.unusable", "This is not a position that can be played.")
        }
        return nil
    }

    /// The finished position, or nil while something is still wrong with it.
    var position: Position? { problem == nil ? Position(fen: fen) : nil }
}

// MARK: - The board you tap on

/// A board that draws a loose map of pieces rather than a `Position`, because
/// the whole point of the editor is the states a `Position` refuses to hold.
private struct EditorBoard: View {
    @Environment(\.boardTheme) private var theme

    let pieces: [Square: Piece]
    let orientation: PieceColor
    let tap: (Square) -> Void

    /// Square by construction, and sized by whatever room it is given.
    ///
    /// The geometry is read from inside rather than passed in: a board told one
    /// width while its container was given another drew over the label beneath
    /// it, and the only number that cannot disagree with the layout is the one
    /// the layout hands back.
    var body: some View {
        GeometryReader { geometry in
            let squareSize = geometry.size.width / 8
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { column in
                            let square = square(row: row, column: column)
                            Button { tap(square) } label: {
                                ZStack {
                                    ((square.file + square.rank) % 2 == 0
                                        ? theme.darkSquare : theme.lightSquare)
                                    if let piece = pieces[square] {
                                        PieceView(piece: piece, size: squareSize)
                                            .padding(squareSize * 0.06)
                                    }
                                }
                                .frame(width: squareSize, height: squareSize)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 4))
    }

    private func square(row: Int, column: Int) -> Square {
        Square(
            file: orientation == .white ? column : 7 - column,
            rank: orientation == .white ? 7 - row : row
        )
    }
}

// MARK: - The sheet

/// Set a position up by hand.
///
/// Reached from the free board, and the correction step anything automatic will
/// need: a position read off a photograph is right about most squares and wrong
/// about a few, and there has to be somewhere to fix the few.
struct PositionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var model: PositionEditorModel
    let use: (Position) -> Void

    private static let order: [PieceKind] = [.king, .queen, .rook, .bishop, .knight, .pawn]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L.t("editor.title", "Set the position up"))
                    .appFont(size: 22, weight: .semibold)

                EditorBoard(
                    pieces: model.pieces,
                    orientation: model.orientation,
                    tap: { model.tap($0) }
                )
                .frame(maxWidth: 340)
                .frame(maxWidth: .infinity, alignment: .center)

                Card {
                    palette

                    BrassSegmentedPicker(
                        L.t("editor.toMove", "To move"),
                        selection: Binding(get: { model.sideToMove }, set: { model.sideToMove = $0 }),
                        options: [PieceColor.white, PieceColor.black]
                    ) { color in
                        Text(L.color(color))
                    }

                    castlingRow
                }

                // The reason is worth more than the refusal. "Not a position" in
                // front of thirty-two pieces is not something anybody can act on.
                if let problem = model.problem {
                    Text(problem)
                        .appFont(.footnote)
                        .foregroundStyle(Color(red: 0.851, green: 0.439, blue: 0.373))
                }

                controls
            }
            .padding(20)
        }
        .background(Theatre.ink.ignoresSafeArea())
    }

    @ViewBuilder
    private var palette: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(L.t("editor.piece", "Piece").uppercased())
                .appFont(size: 9)
                .tracking(1.5)
                .foregroundStyle(Theatre.ivoryFaint)

            ForEach(PieceColor.allCases, id: \.self) { color in
                HStack(spacing: 6) {
                    ForEach(Self.order, id: \.self) { kind in
                        swatch(Piece(color, kind))
                    }
                }
            }

            Button {
                model.brush = .erase
            } label: {
                Label {
                    Text(L.t("editor.erase", "Eraser"))
                } icon: {
                    BrassIcon("eraser", size: 15)
                }
                .appFont(.footnote)
                .foregroundStyle(model.brush == .erase ? Theatre.brassHot : Theatre.ivoryDim)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    private func swatch(_ piece: Piece) -> some View {
        let armed = model.brush == .place(piece)
        return Button {
            model.brush = .place(piece)
        } label: {
            PieceView(piece: piece, size: 34)
                .frame(width: 40, height: 40)
                .background(
                    Theatre.brass.opacity(armed ? 0.28 : 0.08),
                    in: .rect(cornerRadius: 7)
                )
                .overlay {
                    if armed {
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(Theatre.brass, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var castlingRow: some View {
        // Only the rights the board can actually support are shown. A tick box
        // for a castling that the pieces make impossible is a question with one
        // answer, and it invites the player to give the other one.
        let available: [(CastlingRights, String)] = [
            (.whiteKingside, "O-O \(L.color(.white))"),
            (.whiteQueenside, "O-O-O \(L.color(.white))"),
            (.blackKingside, "O-O \(L.color(.black))"),
            (.blackQueenside, "O-O-O \(L.color(.black))"),
        ].filter { model.canCastle($0.0) }

        if !available.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                Text(L.t("editor.castling", "Castling").uppercased())
                    .appFont(size: 9)
                    .tracking(1.5)
                    .foregroundStyle(Theatre.ivoryFaint)

                FlowLayout(spacing: 6) {
                    ForEach(available, id: \.0.rawValue) { right, label in
                        let on = model.castling.contains(right)
                        Button {
                            model.setCastling(right, on: !on)
                        } label: {
                            Text(label)
                                .appFont(.footnote)
                                .foregroundStyle(on ? Theatre.brassHot : Theatre.ivoryDim)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Theatre.brass.opacity(on ? 0.22 : 0.07),
                                    in: .rect(cornerRadius: 7)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(L.t("editor.clear", "Empty board")) { model.clear() }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                Button(L.t("editor.opening", "Opening")) { model.resetToOpening() }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                Button(L.t("board.flip", "Flip")) { model.flip() }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
            }

            HStack(spacing: 8) {
                Button(L.t("common.cancel", "Cancel")) { dismiss() }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))

                Spacer()

                Button(L.t("editor.use", "Use this position")) {
                    guard let position = model.position else { return }
                    use(position)
                    dismiss()
                }
                .buttonStyle(PillButtonStyle(
                    emphasis: .solid, enabled: model.position != nil, usesBodySize: true
                ))
                .disabled(model.position == nil)
            }
        }
    }
}
