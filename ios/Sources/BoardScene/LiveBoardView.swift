#if canImport(UIKit)
import ChessCore
import SceneKit
import SwiftUI
import UIKit

/// The playable board, hosted in SwiftUI.
///
/// A tap picks a piece up and a second tap puts it down; dragging turns the
/// room. Dragging a piece the way the flat board allows is deliberately not
/// wired: from a camera that can be anywhere, a drag has no fixed relationship
/// to a rank or a file, and a piece that follows the finger diagonally when the
/// board is turned forty degrees is worse than no drag at all.
public struct LiveBoardView: UIViewRepresentable {
    private let board: LiveBoard
    private let position: Position
    private let legalDestinations: [Square: [Square]]
    private let premoveDestinations: [Square: [Square]]
    private let lastMove: (from: Square, to: Square)?
    private let orientation: PieceColor

    public init(
        board: LiveBoard,
        position: Position,
        legalDestinations: [Square: [Square]] = [:],
        premoveDestinations: [Square: [Square]] = [:],
        lastMove: (from: Square, to: Square)? = nil,
        orientation: PieceColor = .white
    ) {
        self.board = board
        self.position = position
        self.legalDestinations = legalDestinations
        self.premoveDestinations = premoveDestinations
        self.lastMove = lastMove
        self.orientation = orientation
    }

    public func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = board.stage.scene
        view.pointOfView = board.stage.cameraNode
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling2X
        view.rendersContinuously = true
        view.allowsCameraControl = false
        view.isPlaying = true

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Driver.tapped(_:)))
        view.addGestureRecognizer(tap)
        let drag = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Driver.dragged(_:)))
        view.addGestureRecognizer(drag)

        context.coordinator.start(board: board, orientation: orientation)
        board.apply(position: position, legalDestinations: legalDestinations,
                    premoveDestinations: premoveDestinations, lastMove: lastMove)
        return view
    }

    public func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.look(orientation)
        board.apply(position: position, legalDestinations: legalDestinations,
                    premoveDestinations: premoveDestinations, lastMove: lastMove)
    }

    public static func dismantleUIView(_ view: SCNView, coordinator: Driver) {
        coordinator.stop()
        view.isPlaying = false
    }

    public func makeCoordinator() -> Driver { Driver() }

    @MainActor
    public final class Driver: NSObject {
        private var link: CADisplayLink?
        private var board: LiveBoard?
        private var last = CFTimeInterval(0)
        private var orientation: PieceColor?

        func start(board: LiveBoard, orientation: PieceColor) {
            self.board = board
            self.orientation = orientation
            board.look(from: orientation)
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        /// Turning the board to the other player is a move of the camera, not a
        /// cut. Only done when the side actually changes: calling it on every
        /// SwiftUI update would cancel a drag the viewer was in the middle of.
        func look(_ side: PieceColor) {
            guard side != orientation, let board else { return }
            orientation = side
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.7
            board.look(from: side)
            SCNTransaction.commit()
        }

        func stop() {
            link?.invalidate()
            link = nil
        }

        @objc private func tick(_ link: CADisplayLink) {
            guard let board else { return }
            if last == 0 { last = link.timestamp }
            let delta = Float(min(link.timestamp - last, 0.05))
            last = link.timestamp
            board.advance(delta: delta)
        }

        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            guard let board, let view = gesture.view as? SCNView else { return }
            let point = gesture.location(in: view)
            let hits = view.hitTest(point, options: [
                .searchMode: SCNHitTestSearchMode.all.rawValue,
                .ignoreHiddenNodes: true,
            ])
            // The wood, not the piece standing on it: a tap on a rook is a tap
            // on the rook's square, and only the surface knows which square
            // that is.
            guard let hit = hits.first(where: { $0.node.name == Stage.surfaceName }) else { return }
            let world = hit.worldCoordinates
            guard let square = LiveBoard.square(at: SIMD3(Float(world.x), Float(world.y), Float(world.z)))
            else { return }
            board.tap(square)
        }

        @objc func dragged(_ gesture: UIPanGestureRecognizer) {
            guard let board, let view = gesture.view else { return }
            let translation = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            let scale = Float.pi * 1.4 / Float(max(view.bounds.width, 1))
            board.camera.turn(
                by: -Float(translation.x) * scale,
                and: Float(translation.y) * scale * 0.7
            )
        }
    }
}
#endif
