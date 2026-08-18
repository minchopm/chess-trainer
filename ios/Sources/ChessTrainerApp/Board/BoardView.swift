import ChessCore
import ChessEngine
import SwiftUI

/// Coaching marks drawn over the board.
public struct BoardShape: Equatable, Sendable, Identifiable {
    public enum Kind: Equatable, Sendable { case arrow(from: Square, to: Square), circle(Square) }

    public let id = UUID()
    public let kind: Kind
    public let colorHint: Hint

    public enum Hint: Equatable, Sendable { case good, suggestion, warning }

    public static func arrow(_ from: Square, _ to: Square, _ hint: Hint = .good) -> BoardShape {
        BoardShape(kind: .arrow(from: from, to: to), colorHint: hint)
    }

    public static func circle(_ square: Square, _ hint: Hint = .suggestion) -> BoardShape {
        BoardShape(kind: .circle(square), colorHint: hint)
    }
}

/// An interactive chessboard.
///
/// Knows no rules: it is handed the position and the legal destinations, and
/// reports attempted moves back. That split is what lets the same view serve a
/// puzzle, a drill and a full game without knowing which it is in.
public struct BoardView: View {
    public let position: Position
    public let orientation: PieceColor
    public let legalDestinations: [Square: [Square]]
    public let lastMove: (from: Square, to: Square)?
    public let shapes: [BoardShape]
    /// Score after each legal move, keyed by UCI, from the mover's point of
    /// view. When present, the hint dots become labelled values.
    public let moveValues: MoveValues?
    public let onMove: (Square, Square, PieceKind?) -> Void

    var theme: BoardTheme = .standard

    @State private var selected: Square?
    @State private var dragging: (from: Square, translation: CGSize)?
    @State private var promotion: (from: Square, to: Square)?

    public init(
        position: Position,
        orientation: PieceColor = .white,
        legalDestinations: [Square: [Square]] = [:],
        lastMove: (from: Square, to: Square)? = nil,
        shapes: [BoardShape] = [],
        moveValues: MoveValues? = nil,
        onMove: @escaping (Square, Square, PieceKind?) -> Void = { _, _, _ in }
    ) {
        self.position = position
        self.orientation = orientation
        self.legalDestinations = legalDestinations
        self.lastMove = lastMove
        self.shapes = shapes
        self.moveValues = moveValues
        self.onMove = onMove
    }

    public var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let squareSize = side / 8

            ZStack(alignment: .topLeading) {
                squares(squareSize: squareSize)
                overlay(squareSize: squareSize, side: side)
                pieces(squareSize: squareSize)
                // Painted after the pieces: a badge on an occupied square is a
                // capture, and those are the values worth reading.
                hints(squareSize: squareSize)

                // One transparent layer over the whole board carries the
                // gesture. Attaching it to the pieces instead puts a separate
                // gesture on each piece, sized to that piece — and pieces do
                // not take hits, so nothing would respond.
                Color.clear
                    .frame(width: side, height: side)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(squareSize: squareSize))
                if let promotion {
                    PromotionPicker(
                        color: position[promotion.from]?.color ?? .white,
                        squareSize: squareSize,
                        position: point(for: promotion.to, squareSize: squareSize),
                        pointsDown: displayRank(of: promotion.to) == 0,
                        onPick: { kind in
                            onMove(promotion.from, promotion.to, kind)
                            self.promotion = nil
                        },
                        onCancel: { self.promotion = nil }
                    )
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Layers

    private func squares(squareSize: CGFloat) -> some View {
        ForEach(0..<64, id: \.self) { index in
            let square = Square(index)
            let isLight = (square.file + square.rank) % 2 == 1
            Rectangle()
                .fill(isLight ? theme.lightSquare : theme.darkSquare)
                .overlay { squareHighlight(square) }
                .frame(width: squareSize, height: squareSize)
                .offset(offset(for: square, squareSize: squareSize))
        }
    }

    @ViewBuilder
    private func squareHighlight(_ square: Square) -> some View {
        if isInCheck(square) {
            RadialGradient(
                colors: [theme.check.opacity(0.95), theme.check.opacity(0)],
                center: .center, startRadius: 0, endRadius: 30
            )
        } else if selected == square {
            theme.selection
        } else if let lastMove, lastMove.from == square || lastMove.to == square {
            theme.lastMove
        }
    }

    private func hints(squareSize: CGFloat) -> some View {
        ForEach(destinations(from: selected), id: \.index) { square in
            Group {
                if let score = value(moving: selected, to: square) {
                    valueBadge(score: score, squareSize: squareSize)
                } else if position[square] == nil {
                    Circle()
                        .fill(theme.hint)
                        .frame(width: squareSize * 0.28, height: squareSize * 0.28)
                } else {
                    Circle()
                        .strokeBorder(theme.hint, lineWidth: squareSize * 0.09)
                        .frame(width: squareSize * 0.92, height: squareSize * 0.92)
                }
            }
            .frame(width: squareSize, height: squareSize)
            .offset(offset(for: square, squareSize: squareSize))
            .allowsHitTesting(false)
        }
    }

    /// The evaluation of moving the selected piece to this square.
    ///
    /// Shown as what the position becomes, in pawns, rather than as the loss
    /// against the best move: "+1.4" is a number you can carry into your own
    /// thinking, while "−0.3 worse than best" only makes sense next to a best
    /// move you have not been told.
    private func value(moving from: Square?, to square: Square) -> Int? {
        guard let from, let values = moveValues else { return nil }
        return matchingScore(from: from, to: square, in: values)
    }

    private func valueBadge(score: Int, squareSize: CGFloat) -> some View {
        let loss = max(0, (moveValues?.best ?? score) - score)
        // Sized against the square and pinned to one line: at default sizing the
        // label wrapped to two lines and swallowed the piece underneath it.
        return Text(Self.pawns(score))
            .font(.system(size: squareSize * 0.24, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(.white)
            .padding(.horizontal, squareSize * 0.07)
            .padding(.vertical, squareSize * 0.03)
            .background(Self.valueColor(loss: loss).opacity(0.92), in: Capsule())
            .shadow(color: .black.opacity(0.45), radius: 1, y: 0.5)
            // Sit low in the square so the piece it covers stays readable.
            .frame(width: squareSize, height: squareSize, alignment: .bottom)
            .padding(.bottom, squareSize * 0.04)
    }

    /// Promotions have four entries per destination; the queen stands for them.
    private func matchingScore(from: Square, to: Square, in values: MoveValues) -> Int? {
        if let exact = values.score(for: "\(from)\(to)") { return exact }
        for suffix in ["q", "r", "b", "n"] {
            if let promoted = values.score(for: "\(from)\(to)\(suffix)") { return promoted }
        }
        return nil
    }

    static func pawns(_ centipawns: Int) -> String {
        // Mate is stored flattened as ±(10000 − moves), so the distance can be
        // read back out. "#3" says far more than a bare "#".
        if abs(centipawns) >= 9000 {
            let moves = 10_000 - abs(centipawns)
            let distance = moves > 0 ? "\(moves)" : ""
            return centipawns > 0 ? "#\(distance)" : "−#\(distance)"
        }
        let value = Double(centipawns) / 100
        return String(format: "%@%.1f", value >= 0 ? "+" : "−", abs(value))
    }

    /// Green for the best move, sliding through amber to red as it gets worse.
    /// The thresholds are the same ones the coach grades by, so a square that
    /// looks red here would be called a mistake there.
    static func valueColor(loss: Int) -> Color {
        switch loss {
        case ..<15: Color(red: 0.16, green: 0.55, blue: 0.24)
        case ..<60: Color(red: 0.35, green: 0.52, blue: 0.22)
        case ..<150: Color(red: 0.72, green: 0.55, blue: 0.13)
        case ..<350: Color(red: 0.75, green: 0.38, blue: 0.14)
        default: Color(red: 0.68, green: 0.22, blue: 0.18)
        }
    }

    private func pieces(squareSize: CGFloat) -> some View {
        ForEach(0..<64, id: \.self) { index in
            let square = Square(index)
            if let piece = position[square] {
                PieceView(piece: piece, size: squareSize)
                    .offset(offset(for: square, squareSize: squareSize))
                    .offset(dragging?.from == square ? dragging!.translation : .zero)
                    .zIndex(dragging?.from == square ? 2 : 1)
                    .animation(dragging == nil ? .easeOut(duration: 0.13) : nil, value: position.fen)
                    .allowsHitTesting(false)
            }
        }
    }

    private func overlay(squareSize: CGFloat, side: CGFloat) -> some View {
        Canvas { context, _ in
            for shape in shapes {
                let color = shapeColor(shape.colorHint)
                switch shape.kind {
                case .circle(let square):
                    let centre = centre(of: square, squareSize: squareSize)
                    let radius = squareSize * 0.42
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: centre.x - radius, y: centre.y - radius,
                            width: radius * 2, height: radius * 2
                        )),
                        with: .color(color), lineWidth: squareSize * 0.07
                    )
                case .arrow(let from, let to):
                    drawArrow(context: context, from: from, to: to, squareSize: squareSize, color: color)
                }
            }
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
    }

    private func drawArrow(
        context: GraphicsContext, from: Square, to: Square, squareSize: CGFloat, color: Color
    ) {
        let start = centre(of: from, squareSize: squareSize)
        let end = centre(of: to, squareSize: squareSize)
        let delta = CGSize(width: end.x - start.x, height: end.y - start.y)
        let length = max(1, sqrt(delta.width * delta.width + delta.height * delta.height))
        let unit = CGPoint(x: delta.width / length, y: delta.height / length)

        // Stop short of the centre so the head sits inside the target square.
        let head = CGPoint(x: end.x - unit.x * squareSize * 0.34, y: end.y - unit.y * squareSize * 0.34)
        let tail = CGPoint(x: start.x + unit.x * squareSize * 0.2, y: start.y + unit.y * squareSize * 0.2)

        var shaft = Path()
        shaft.move(to: tail)
        shaft.addLine(to: head)
        context.stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: squareSize * 0.13, lineCap: .round))

        let wing = squareSize * 0.22
        let normal = CGPoint(x: -unit.y, y: unit.x)
        var tip = Path()
        tip.move(to: CGPoint(x: end.x - unit.x * squareSize * 0.08, y: end.y - unit.y * squareSize * 0.08))
        tip.addLine(to: CGPoint(x: head.x + normal.x * wing * 0.6, y: head.y + normal.y * wing * 0.6))
        tip.addLine(to: CGPoint(x: head.x - normal.x * wing * 0.6, y: head.y - normal.y * wing * 0.6))
        tip.closeSubpath()
        context.fill(tip, with: .color(color))
    }

    private func shapeColor(_ hint: BoardShape.Hint) -> Color {
        switch hint {
        case .good: theme.coachArrow
        case .suggestion: Color(red: 0.357, green: 0.608, blue: 0.835)
        case .warning: theme.check
        }
    }

    // MARK: - Interaction

    private func dragGesture(squareSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard promotion == nil else { return }
                let start = square(at: value.startLocation, squareSize: squareSize)
                guard let start, canMove(from: start) else { return }
                if selected != start { selected = start }
                dragging = (from: start, translation: value.translation)
            }
            .onEnded { value in
                guard promotion == nil else { return }
                let start = square(at: value.startLocation, squareSize: squareSize)
                let end = square(at: value.location, squareSize: squareSize)
                dragging = nil

                // A tap: either select a piece, or complete a two-tap move.
                if start == end {
                    handleTap(on: start)
                    return
                }
                guard let start, let end, destinations(from: start).contains(end) else {
                    selected = nil
                    return
                }
                selected = nil
                attempt(from: start, to: end)
            }
    }

    private func handleTap(on square: Square?) {
        guard let square else { selected = nil; return }
        if let selected, destinations(from: selected).contains(square) {
            let from = selected
            self.selected = nil
            attempt(from: from, to: square)
            return
        }
        selected = canMove(from: square) ? square : nil
    }

    private func attempt(from: Square, to: Square) {
        // A pawn reaching the last rank needs the player to choose a piece
        // before the move means anything.
        if position[from]?.kind == .pawn, to.relativeRank(for: position[from]!.color) == 8 {
            promotion = (from: from, to: to)
            return
        }
        onMove(from, to, nil)
    }

    private func canMove(from square: Square) -> Bool {
        !(legalDestinations[square] ?? []).isEmpty
    }

    private func destinations(from square: Square?) -> [Square] {
        guard let square else { return [] }
        return legalDestinations[square] ?? []
    }

    private func isInCheck(_ square: Square) -> Bool {
        position.isCheck && position[square] == Piece(position.sideToMove, .king)
    }

    // MARK: - Geometry

    /// Column shown on screen, accounting for which way the board faces.
    private func displayFile(of square: Square) -> Int {
        orientation == .white ? square.file : 7 - square.file
    }

    /// Row from the top of the screen.
    private func displayRank(of square: Square) -> Int {
        orientation == .white ? 7 - square.rank : square.rank
    }

    private func offset(for square: Square, squareSize: CGFloat) -> CGSize {
        CGSize(
            width: CGFloat(displayFile(of: square)) * squareSize,
            height: CGFloat(displayRank(of: square)) * squareSize
        )
    }

    private func point(for square: Square, squareSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(displayFile(of: square)) * squareSize,
            y: CGFloat(displayRank(of: square)) * squareSize
        )
    }

    private func centre(of square: Square, squareSize: CGFloat) -> CGPoint {
        let origin = point(for: square, squareSize: squareSize)
        return CGPoint(x: origin.x + squareSize / 2, y: origin.y + squareSize / 2)
    }

    private func square(at point: CGPoint, squareSize: CGFloat) -> Square? {
        let column = Int(point.x / squareSize)
        let row = Int(point.y / squareSize)
        guard (0..<8).contains(column), (0..<8).contains(row) else { return nil }
        let file = orientation == .white ? column : 7 - column
        let rank = orientation == .white ? 7 - row : row
        return Square(file: file, rank: rank)
    }
}

/// One piece.
///
/// The rim is four offset copies rather than one enlarged copy behind the fill.
/// Scaling a glyph up to peek out from behind it sounds equivalent and is not:
/// it thickens by a percentage, so a dense glyph like the queen gets a hairline
/// while a slender one like the bishop or knight is swallowed and reads as the
/// opposite colour. An offset outline is the same width whatever the shape.
struct PieceView: View {
    let piece: Piece
    let size: CGFloat

    private var fill: Color {
        piece.color == .white ? Color(white: 0.98) : Color(white: 0.10)
    }

    private var rim: Color {
        piece.color == .white ? Color(white: 0.10) : Color(white: 0.95)
    }

    var body: some View {
        let glyph = PieceGlyph.text(for: piece)
        let fontSize = size * 0.78
        let width = max(0.7, size * 0.022)

        ZStack {
            ForEach(Array(Self.rimOffsets.enumerated()), id: \.offset) { _, direction in
                Text(glyph)
                    .font(.system(size: fontSize))
                    .foregroundStyle(rim)
                    .offset(x: direction.x * width, y: direction.y * width)
            }
            Text(glyph)
                .font(.system(size: fontSize))
                .foregroundStyle(fill)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: size * 0.03, y: size * 0.02)
    }

    /// Eight directions, so the outline is even rather than cross-shaped.
    private static let rimOffsets: [(x: CGFloat, y: CGFloat)] = [
        (1, 0), (-1, 0), (0, 1), (0, -1),
        (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7), (-0.7, -0.7),
    ]
}

struct PromotionPicker: View {
    let color: PieceColor
    let squareSize: CGFloat
    let position: CGPoint
    let pointsDown: Bool
    let onPick: (PieceKind) -> Void
    let onCancel: () -> Void

    private let choices: [PieceKind] = [.queen, .rook, .bishop, .knight]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.45)
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            VStack(spacing: 0) {
                ForEach(pointsDown ? choices : choices.reversed(), id: \.rawValue) { kind in
                    Button { onPick(kind) } label: {
                        PieceView(piece: Piece(color, kind), size: squareSize)
                            .frame(width: squareSize, height: squareSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(white: 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.6), radius: 10, y: 3)
            .offset(
                x: position.x,
                y: pointsDown ? position.y : position.y - squareSize * 3
            )
        }
    }
}
