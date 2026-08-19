import ChessCore
import ChessTraining
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
    /// Where each piece could go if it were your turn. Used only when there are
    /// no legal destinations — that is, when the opponent is to move — so that
    /// a move can be queued rather than refused.
    public let premoveDestinations: [Square: [Square]]
    /// Squares taking part in a queued move, to be marked on the board.
    public let premove: [Square]?
    public let onMove: (Square, Square, PieceKind?) -> Void
    public let onPremove: (Square, Square, PieceKind?) -> Void

    @Environment(\.boardTheme) private var theme
    @Environment(\.pieceSet) private var pieceSet

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
        premoveDestinations: [Square: [Square]] = [:],
        premove: [Square]? = nil,
        onMove: @escaping (Square, Square, PieceKind?) -> Void = { _, _, _ in },
        onPremove: @escaping (Square, Square, PieceKind?) -> Void = { _, _, _ in }
    ) {
        self.position = position
        self.orientation = orientation
        self.legalDestinations = legalDestinations
        self.lastMove = lastMove
        self.shapes = shapes
        self.moveValues = moveValues
        self.premoveDestinations = premoveDestinations
        self.premove = premove
        self.onMove = onMove
        self.onPremove = onPremove
    }

    /// True when the board is taking moves for later rather than for now.
    private var isQueueing: Bool { legalDestinations.isEmpty && !premoveDestinations.isEmpty }

    public var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let squareSize = side / 8

            ZStack(alignment: .topLeading) {
                squares(squareSize: squareSize, side: side)
                overlay(squareSize: squareSize, side: side)
                pieces(squareSize: squareSize, side: side)
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
                            deliver(promotion.from, promotion.to, kind)
                            self.promotion = nil
                        },
                        onCancel: { self.promotion = nil }
                    )
                }
            }
            .frame(width: side, height: side)
            // A chessboard is not mirrored in Arabic or Hebrew: a1 is at the
            // bottom left of every board in the world, and flipping it would
            // turn the coordinates the pieces are named by into a lie.
            .environment(\.layoutDirection, .leftToRight)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Layers

    /// One Canvas rather than 64 views.
    ///
    /// Selecting a piece changes state that every square depends on, and
    /// sixty-four views each re-evaluated, laid out and composited is enough
    /// work to be felt as a delay between the tap and the highlight. A canvas
    /// redraw is one pass with no view identity to reconcile.
    private func squares(squareSize: CGFloat, side: CGFloat) -> some View {
        Canvas { context, _ in
            // Resolved once per redraw rather than per square: sixty-four
            // resolves of the same two images is sixty-two too many.
            let tiles: [GraphicsContext.ResolvedImage]? = theme.textures.map {
                [context.resolve(Image($0.light)), context.resolve(Image($0.dark))]
            }
            for index in 0..<64 {
                let square = Square(index)
                let origin = point(for: square, squareSize: squareSize)
                let rect = CGRect(x: origin.x, y: origin.y, width: squareSize, height: squareSize)
                let isLight = (square.file + square.rank) % 2 == 1
                context.fill(Path(rect), with: .color(isLight ? theme.lightSquare : theme.darkSquare))
                if let tile = tiles?[isLight ? 0 : 1] {
                    context.draw(tile, in: rect)
                }

                if isInCheck(square) {
                    context.fill(
                        Path(rect),
                        with: .radialGradient(
                            Gradient(colors: [theme.check.opacity(0.95), theme.check.opacity(0)]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: 0, endRadius: squareSize * 0.62
                        )
                    )
                } else if selected == square {
                    context.fill(Path(rect), with: .color(theme.selection))
                } else if let lastMove, lastMove.from == square || lastMove.to == square {
                    context.fill(Path(rect), with: .color(theme.lastMove))
                } else if let premove, premove.contains(square) {
                    context.fill(Path(rect), with: .color(theme.premove))
                }
            }
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
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
        guard let from, !isQueueing, let values = moveValues else { return nil }
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

    /// One Canvas for all thirty-two pieces.
    ///
    /// Each image is resolved once per kind and colour and then drawn wherever
    /// that piece stands, so a full board costs twelve resolves rather than
    /// thirty-two, and the shadow is a single offscreen pass for the whole
    /// layer instead of one per piece.
    private func pieces(squareSize: CGFloat, side: CGFloat) -> some View {
        Canvas { context, _ in
            var art: [Piece: GraphicsContext.ResolvedImage] = [:]
            var glyphs: [Piece: (fill: GraphicsContext.ResolvedText, rim: GraphicsContext.ResolvedText)] = [:]
            let fontSize = squareSize * 0.78
            let rimWidth = max(0.7, squareSize * 0.022)

            for color in PieceColor.allCases {
                for kind in PieceKind.allCases {
                    let piece = Piece(color, kind)
                    switch pieceSet {
                    case .carved:
                        art[piece] = context.resolve(Image(PieceArt.name(for: piece)))
                    case .glyph:
                        let text = Text(PieceGlyph.text(for: kind)).font(.system(size: fontSize))
                        glyphs[piece] = (
                            fill: context.resolve(text.foregroundStyle(PieceGlyph.fill(for: color))),
                            rim: context.resolve(text.foregroundStyle(PieceGlyph.rim(for: color)))
                        )
                    }
                }
            }

            context.drawLayer { layer in
                layer.addFilter(.shadow(
                    color: .black.opacity(pieceSet == .carved ? 0.35 : 0.3),
                    radius: squareSize * 0.045, x: 0, y: squareSize * 0.03
                ))

                func draw(_ piece: Piece, at origin: CGPoint) {
                    let square = CGRect(x: origin.x, y: origin.y, width: squareSize, height: squareSize)
                    if let image = art[piece] {
                        // The art is centred on its own square canvas, so the
                        // board square is the frame and nothing is nudged.
                        layer.draw(image, in: square)
                        return
                    }
                    guard let glyph = glyphs[piece] else { return }
                    let centre = CGPoint(x: square.midX, y: square.midY)
                    for direction in PieceGlyph.rimOffsets {
                        layer.draw(glyph.rim, at: CGPoint(
                            x: centre.x + direction.x * rimWidth,
                            y: centre.y + direction.y * rimWidth
                        ))
                    }
                    layer.draw(glyph.fill, at: centre)
                }

                for index in 0..<64 {
                    let square = Square(index)
                    guard let piece = position[square], dragging?.from != square else { continue }
                    draw(piece, at: point(for: square, squareSize: squareSize))
                }

                // The piece under the finger goes last, so it is over the rest.
                if let dragging, let piece = position[dragging.from] {
                    let origin = point(for: dragging.from, squareSize: squareSize)
                    draw(piece, at: CGPoint(
                        x: origin.x + dragging.translation.width,
                        y: origin.y + dragging.translation.height
                    ))
                }
            }
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
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
        deliver(from, to, nil)
    }

    private func deliver(_ from: Square, _ to: Square, _ kind: PieceKind?) {
        if isQueueing { onPremove(from, to, kind) } else { onMove(from, to, kind) }
    }

    private func canMove(from square: Square) -> Bool {
        !destinations(from: square).isEmpty
    }

    private func destinations(from square: Square?) -> [Square] {
        guard let square else { return [] }
        return (isQueueing ? premoveDestinations[square] : legalDestinations[square]) ?? []
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

/// One piece, for the places that are not the board itself — the promotion
/// picker and anything else that wants a single piece at a given size.
struct PieceView: View {
    let piece: Piece
    let size: CGFloat
    @Environment(\.pieceSet) private var pieceSet

    var body: some View {
        Group {
            switch pieceSet {
            case .carved:
                Image(PieceArt.name(for: piece))
                    .resizable()
                    .scaledToFit()
            case .glyph:
                ZStack {
                    ForEach(Array(PieceGlyph.rimOffsets.enumerated()), id: \.offset) { _, direction in
                        Text(PieceGlyph.text(for: piece.kind))
                            .font(.system(size: size * 0.78))
                            .foregroundStyle(PieceGlyph.rim(for: piece.color))
                            .offset(x: direction.x * max(0.7, size * 0.022),
                                    y: direction.y * max(0.7, size * 0.022))
                    }
                    Text(PieceGlyph.text(for: piece.kind))
                        .font(.system(size: size * 0.78))
                        .foregroundStyle(PieceGlyph.fill(for: piece.color))
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.35), radius: size * 0.045, y: size * 0.03)
    }
}

private struct BoardThemeKey: EnvironmentKey {
    static var defaultValue: BoardTheme { .standard }
}

private struct PieceSetKey: EnvironmentKey {
    static var defaultValue: PieceSet { .carved }
}

extension EnvironmentValues {
    var boardTheme: BoardTheme {
        get { self[BoardThemeKey.self] }
        set { self[BoardThemeKey.self] = newValue }
    }

    var pieceSet: PieceSet {
        get { self[PieceSetKey.self] }
        set { self[PieceSetKey.self] = newValue }
    }
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
