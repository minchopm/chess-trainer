#if canImport(UIKit)
import SceneKit
import SwiftUI
import UIKit

/// The 3D board, hosted in SwiftUI.
///
/// Driven by a display link on the main thread rather than by SceneKit's own
/// render-loop delegate. The delegate is called on the render thread, and every
/// safe way to get from there back to the scene's own actor either costs a
/// frame or risks a trap; a display link is already where the scene lives.
public struct BoardSceneView: UIViewRepresentable {
    private let sequence: any SceneDriver
    private let interactive: Bool

    public init(sequence: any SceneDriver, interactive: Bool = true) {
        self.sequence = sequence
        self.interactive = interactive
    }

    public func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = sequence.stage.scene
        view.pointOfView = sequence.stage.cameraNode
        view.backgroundColor = Colour.ink
        view.antialiasingMode = .multisampling2X
        view.preferredFramesPerSecond = 60
        view.rendersContinuously = true
        // SceneKit's own camera controller would fight the orbit and give the
        // viewer a second, differently-behaved way to move the same camera.
        view.allowsCameraControl = false
        view.isPlaying = true

        if interactive {
            let drag = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Driver.dragged(_:)))
            view.addGestureRecognizer(drag)
            let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Driver.pinched(_:)))
            view.addGestureRecognizer(pinch)
        }

        context.coordinator.start(sequence: sequence)
        context.coordinator.view = view
        return view
    }

    public func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.view = view
    }

    public static func dismantleUIView(_ view: SCNView, coordinator: Driver) {
        coordinator.stop()
        view.isPlaying = false
    }

    public func makeCoordinator() -> Driver { Driver() }

    /// Turns the display link into frames, and gestures into camera moves.
    @MainActor
    public final class Driver: NSObject {
        private var link: CADisplayLink?
        private var sequence: (any SceneDriver)?
        private var last = CFTimeInterval(0)
        private var startZoom: Float = 1
        /// Only re-framed when the view actually changes shape; doing it every
        /// frame would undo a pinch as fast as it was made.
        private var framedFor: CGSize = .zero
        weak var view: SCNView?

        func start(sequence: any SceneDriver) {
            self.sequence = sequence
            sequence.place()
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        func stop() {
            link?.invalidate()
            link = nil
        }

        func fit(_ size: CGSize) {
            guard size.width > 1, size.height > 1, size != framedFor else { return }
            framedFor = size
            sequence?.camera.fit(aspect: Float(size.width / size.height))
            sequence?.place()
        }

        @objc private func tick(_ link: CADisplayLink) {
            guard let sequence else { return }
            fit(view?.bounds.size ?? .zero)
            if last == 0 { last = link.timestamp }
            // Clamped: a frame that took a second is an app coming back from
            // the background, and the pieces should not teleport to catch up.
            let delta = Float(min(link.timestamp - last, 0.05))
            last = link.timestamp
            sequence.advance(delta: delta)
        }


        @objc func dragged(_ gesture: UIPanGestureRecognizer) {
            guard let sequence, let view = gesture.view else { return }
            let translation = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            // A full width of dragging turns the board most of the way round.
            let scale = Float.pi * 1.6 / Float(max(view.bounds.width, 1))
            sequence.camera.turn(
                by: -Float(translation.x) * scale,
                and: Float(translation.y) * scale * 0.8
            )
            sequence.place()
        }

        @objc func pinched(_ gesture: UIPinchGestureRecognizer) {
            guard let sequence else { return }
            if gesture.state == .began { startZoom = sequence.camera.zoom }
            sequence.camera.pinch(to: startZoom / Float(gesture.scale))
            sequence.place()
        }
    }
}
#endif
