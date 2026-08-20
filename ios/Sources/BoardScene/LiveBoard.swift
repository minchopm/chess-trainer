import ChessCore
import SceneKit
import simd

/// A board being played on, rather than watched.
///
/// It holds no rules of its own. The screen above it owns the position and the
/// legal moves and hands both down; this decides what that looks like, what a
/// tap on the wood means, and where the camera stands.
@MainActor
public final class LiveBoard: SceneDriver {
    public let stage: Stage
    public var camera: OrbitCamera

    /// Called when a tap completes a move. Promotion is left to the caller:
    /// the piece and the square are known here, the choice is not.
    public var onMove: ((Square, Square) -> Void)?
    /// Called when a move is chosen while it is not your turn. The screen
    /// decides whether to queue it.
    public var onPremove: ((Square, Square) -> Void)?

    public private(set) var selected: Square?

    private var position = Position()
    private var legal: [Square: [Square]] = [:]
    private var premoves: [Square: [Square]] = [:]
    private var lastMove: (from: Square, to: Square)?
    private let highlights = Highlights()
    private var clock: TimeInterval = 0
    private var pendingSync = false

    public init(quality: SceneQuality = .high, style: PieceStyle = .plain, orientation: PieceColor = .white) {
        self.stage = Stage(quality: quality, style: style, playable: true)
        // The playing board gets a square of the screen rather than the whole
        // of it, so it is framed for a square: near enough that the board fills
        // the width, high enough to read the squares as squares.
        self.camera = OrbitCamera(
            azimuth: Self.azimuth(for: orientation),
            elevation: 0.95,
            distance: 11.4,
            target: SIMD3<Float>(0, 0.2, 0)
        )
        stage.scene.rootNode.addChildNode(highlights.node)
        stage.board.set(position)
        place()
    }

    /// Where the camera stands so that a player's own pieces are nearest.
    public static func azimuth(for orientation: PieceColor) -> Float {
        orientation == .white ? 0 : .pi
    }

    public func look(from orientation: PieceColor) {
        camera.azimuth = Self.azimuth(for: orientation)
        place()
    }

    /// The screen's state, arriving from above.
    ///
    /// When the new position is the old one plus the move that is being
    /// reported, the piece travels; otherwise the board is simply set, which is
    /// what a new puzzle or a rewind wants.
    public func apply(
        position next: Position,
        legalDestinations: [Square: [Square]],
        premoveDestinations: [Square: [Square]] = [:],
        lastMove move: (from: Square, to: Square)?
    ) {
        legal = legalDestinations
        premoves = premoveDestinations

        let moved = move != nil && (move!.from != lastMove?.from || move!.to != lastMove?.to)
        lastMove = move

        if moved, let move, let mover = position[move.from], next[move.to] != nil {
            // En passant takes a pawn that is not on the destination square,
            // and castling brings a rook with it. Both are read off the two
            // positions rather than trusted to a flag.
            var captured: Square? = position[move.to] != nil ? move.to : nil
            if mover.kind == .pawn, move.from.file != move.to.file, position[move.to] == nil {
                captured = Square(file: move.to.file, rank: move.from.rank)
            }
            stage.board.slide(from: move.from, to: move.to, hop: mover.kind == .knight, captured: captured)

            if mover.kind == .king, abs(move.to.file - move.from.file) == 2 {
                let rank = move.from.rank
                let kingside = move.to.file > move.from.file
                stage.board.slide(
                    from: Square(file: kingside ? 7 : 0, rank: rank),
                    to: Square(file: kingside ? 5 : 3, rank: rank),
                    hop: false, captured: nil
                )
            }
            pendingSync = true
        } else if next.hash != position.hash {
            stage.board.set(next)
            pendingSync = false
        }

        position = next
        selected = nil
        refresh()
    }

    /// A tap on a square: pick a piece up, put it down, or change your mind.
    ///
    /// When it is not your turn the same taps queue a move instead of playing
    /// one, which is the only way a premove can exist on a board you have to
    /// tap twice.
    public func tap(_ square: Square) {
        let table = legal.isEmpty ? premoves : legal
        let queueing = legal.isEmpty

        if let selected, table[selected]?.contains(square) == true {
            self.selected = nil
            refresh()
            if queueing { onPremove?(selected, square) } else { onMove?(selected, square) }
            return
        }

        if table[square]?.isEmpty == false {
            selected = square == selected ? nil : square
        } else {
            selected = nil
        }
        refresh()
    }

    private var destinationsForSelection: [Square] {
        guard let selected else { return [] }
        return (legal.isEmpty ? premoves : legal)[selected] ?? []
    }

    public func advance(delta: Float) {
        clock += TimeInterval(delta)
        stage.board.update(delta: delta)
        stage.followPlay(clock: clock)

        if pendingSync, stage.board.isIdle {
            // Promotion, and anything else the slide could not express, lands
            // here — once the piece has stopped moving, not while it is.
            stage.board.set(position)
            pendingSync = false
            refresh()
        }

        place()
    }

    /// Turns a point on the board into the square under it.
    public static func square(at point: SIMD3<Float>) -> Square? {
        let file = Int((point.x + 4).rounded(.down))
        let rank = Int((4 - point.z).rounded(.down))
        guard (0..<8).contains(file), (0..<8).contains(rank) else { return nil }
        return Square(file: file, rank: rank)
    }

    private func refresh() {
        highlights.show(selected: selected, destinations: destinationsForSelection, lastMove: lastMove)
    }

    public func place() {
        let eye = camera.eye(clock: clock)
        stage.cameraNode.position = SCNVector3(eye.x, eye.y, eye.z)
        stage.cameraNode.look(
            at: SCNVector3(camera.target.x, camera.target.y, camera.target.z),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
    }
}
