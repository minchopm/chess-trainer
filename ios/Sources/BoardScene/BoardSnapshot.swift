#if canImport(UIKit)
import ChessCore
import Metal
import SceneKit
import UIKit

/// A still of the round board, drawn off screen.
///
/// The same scene the player plays on — the room, the set they chose, the
/// light — rendered once into a picture rather than into a view. It is what a
/// shared story looks like when the person sharing it plays in 3D, which is
/// the point: the picture is of their board, not of a diagram.
@MainActor
public enum BoardSnapshot {
    public static func image(
        of position: Position,
        lastMove: (from: Square, to: Square)?,
        orientation: PieceColor,
        style: PieceStyle,
        side: CGFloat = 1080
    ) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let board = LiveBoard(quality: .high, style: style, orientation: orientation)
        // Set first, then marked. Applied in one go, a last move whose square
        // held a piece in the starting array would be animated from there —
        // the board would slide a piece that is not in this game.
        board.apply(position: position, legalDestinations: [:], lastMove: nil)
        board.apply(position: position, legalDestinations: [:], lastMove: lastMove)
        board.camera.fit(aspect: 1)
        board.place()
        board.advance(delta: 1)

        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = board.stage.scene
        renderer.pointOfView = board.stage.cameraNode
        return renderer.snapshot(
            atTime: 0,
            with: CGSize(width: side, height: side),
            antialiasingMode: .multisampling4X
        )
    }
}
#endif
