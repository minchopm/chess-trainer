import BoardScene
import ChessEngine
import ChessCore
import ChessTraining
import SwiftUI

/// The board every screen asks for, flat or in the round.
///
/// One call site, one set of arguments, and the player's own choice decides
/// which of the two draws it. The arguments are the flat board's, because the
/// flat board is the one that can express all of them: arrows, per-move values
/// and a piece dragged across the squares are all things a fixed overhead grid
/// can do and a camera that can be anywhere cannot.
struct GameBoard: View {
    @Environment(AppModel.self) private var app

    let position: Position
    var orientation: PieceColor = .white
    var legalDestinations: [Square: [Square]] = [:]
    var lastMove: (from: Square, to: Square)?
    var shapes: [BoardShape] = []
    var moveValues: MoveValues?
    var premoveDestinations: [Square: [Square]] = [:]
    var premove: [Square]?
    var onMove: (Square, Square, PieceKind?) -> Void = { _, _, _ in }
    var onPremove: (Square, Square, PieceKind?) -> Void = { _, _, _ in }

    var body: some View {
        #if canImport(UIKit)
        if app.progress.appearance.dimension.isDimensional {
            DimensionalBoard(
                position: position,
                orientation: orientation,
                legalDestinations: legalDestinations,
                premoveDestinations: premoveDestinations,
                lastMove: lastMove,
                moveValues: moveValues,
                onMove: onMove,
                onPremove: onPremove
            )
            // The set is built into the geometry, so changing it builds a new
            // board rather than repainting this one.
            .id(app.progress.appearance.carving)
        } else {
            flat
        }
        #else
        flat
        #endif
    }

    private var flat: some View {
        BoardView(
            position: position,
            orientation: orientation,
            legalDestinations: legalDestinations,
            lastMove: lastMove,
            shapes: shapes,
            moveValues: moveValues,
            premoveDestinations: premoveDestinations,
            premove: premove,
            onMove: onMove,
            onPremove: onPremove
        )
    }
}

#if canImport(UIKit)
/// The round board, plus the one thing it cannot decide for itself.
///
/// A promotion is a choice, and the scene has no way to ask for one: the
/// squares it draws are in a room, and a menu has to be in front of the
/// screen. So the scene reports the move and the choice is made here.
private struct DimensionalBoard: View {
    @Environment(AppModel.self) private var app

    let position: Position
    let orientation: PieceColor
    let legalDestinations: [Square: [Square]]
    let premoveDestinations: [Square: [Square]]
    let lastMove: (from: Square, to: Square)?
    let moveValues: MoveValues?
    let onMove: (Square, Square, PieceKind?) -> Void
    let onPremove: (Square, Square, PieceKind?) -> Void

    @State private var board: LiveBoard?
    @State private var promotion: (from: Square, to: Square, queued: Bool)?

    var body: some View {
        ZStack {
            if let board {
                LiveBoardView(
                    board: board,
                    position: position,
                    legalDestinations: legalDestinations,
                    premoveDestinations: premoveDestinations,
                    lastMove: lastMove,
                    orientation: orientation
                )
            }
            if let promotion {
                PromotionChoice(colour: position[promotion.from]?.color ?? orientation) { kind in
                    if promotion.queued {
                        onPremove(promotion.from, promotion.to, kind)
                    } else {
                        onMove(promotion.from, promotion.to, kind)
                    }
                    self.promotion = nil
                }
            }
        }
        .onAppear(perform: build)
        .onChange(of: valuesBySquare) { _, values in board?.show(values: values) }
        .task(id: valuesBySquare) { board?.show(values: valuesBySquare) }
        .onChange(of: app.progress.appearance.showsCoordinates) { _, showing in
            board?.stage.setCoordinates(showing)
        }
    }

    /// The values the scene needs, keyed by where the move lands and formatted
    /// the way the reader's language writes a number.
    ///
    /// Only for a square that can actually be reached from the piece in hand —
    /// the scene decides which of these to draw, but there is no reason to hand
    /// it the whole position's worth.
    private var valuesBySquare: [Square: ValuePlate] {
        guard let moveValues else { return [:] }
        var plates: [Square: ValuePlate] = [:]
        for (uci, score) in moveValues.byMove {
            guard uci.count >= 4,
                  let to = Square(uci.dropFirst(2).prefix(2)) else { continue }
            let plate = ValuePlate(text: BoardView.pawns(score),
                                   loss: max(0, moveValues.best - score))
            // A promotion offers the same square four times; the queen's value
            // is the one worth showing.
            if plates[to] == nil || plate.loss < plates[to]!.loss { plates[to] = plate }
        }
        return plates
    }

    private func build() {
        guard board == nil else { return }
        let live = LiveBoard(
            quality: SceneQuality.forThisDevice,
            style: app.progress.appearance.carving == .banded ? .banded : .plain,
            orientation: orientation
        )
        live.onMove = { from, to in
            if isPromotion(from: from, to: to) {
                promotion = (from, to, false)
            } else {
                onMove(from, to, nil)
            }
        }
        live.onPremove = { from, to in
            if isPromotion(from: from, to: to) {
                promotion = (from, to, true)
            } else {
                onPremove(from, to, nil)
            }
        }
        live.stage.setCoordinates(app.progress.appearance.showsCoordinates)
        live.show(values: valuesBySquare)
        board = live
    }

    private func isPromotion(from: Square, to: Square) -> Bool {
        guard let piece = position[from], piece.kind == .pawn else { return false }
        return to.rank == piece.color.promotionRank
    }
}

/// Four pieces and a question.
private struct PromotionChoice: View {
    @Environment(\.pieceSet) private var pieceSet
    let colour: PieceColor
    let onPick: (PieceKind) -> Void

    private static let kinds: [PieceKind] = [.queen, .rook, .bishop, .knight]

    var body: some View {
        VStack(spacing: 12) {
            Slug(text: L.t("board.promoteTo", "Promote to"), trailingRule: false)
            HStack(spacing: 10) {
                ForEach(Self.kinds, id: \.self) { kind in
                    Button { onPick(kind) } label: {
                        Image(PieceArt.name(for: colour, kind, set: pieceSet))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)
                            .padding(8)
                            .background {
                                BrassPlateShape(cut: 9).fill(Theatre.ink4)
                            }
                            .overlay {
                                BrassPlateShape(cut: 9)
                                    .strokeBorder(Theatre.brassDeep.opacity(0.55), lineWidth: 0.75)
                            }
                    }
                    .buttonStyle(BrassPressStyle())
                }
            }
        }
        .padding(18)
        .background(Theatre.ink2.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theatre.rule, lineWidth: 0.5))
        .shadow(color: Theatre.shadow.opacity(0.6), radius: 24, y: 10)
    }
}
#endif
