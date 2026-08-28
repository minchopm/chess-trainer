#if canImport(UIKit)
import SceneKit
import SwiftUI
import UIKit

/// TEMPORARY — measuring the launch.
@MainActor
public enum LaunchClock {
    static let zero = CFAbsoluteTimeGetCurrent()
    public static func mark(_ what: String) {
        print(String(format: "⏱ %7.1f ms  %@", (CFAbsoluteTimeGetCurrent() - zero) * 1000, what))
    }
    public static func took(_ what: String, _ seconds: CFTimeInterval) {
        print(String(format: "⏱ %7.1f ms  %@ took %.1f ms",
                     (CFAbsoluteTimeGetCurrent() - zero) * 1000, what, seconds * 1000))
    }
}

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
        LaunchClock.mark("makeUIView")
        let view = SCNView()
        // Hidden until it has been framed. `SCNView()` is born without a size,
        // and the camera's distance is solved from the view's aspect — so the
        // frames drawn before SwiftUI lays it out are composed for a shape the
        // view does not have. On a phone that showed as a board too large for
        // the screen for the first second of every launch, which then shrank
        // into place. A fade is cheaper to look at than a jump.
        view.alpha = 0
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
        // Framed here as well as on the display link. This runs as soon as
        // SwiftUI has laid the view out, which is a good deal earlier than the
        // first tick — and until it is framed the view is hidden, so every
        // frame of waiting is a frame of nothing.
        context.coordinator.fit(view.bounds.size)
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
        /// When the view last took the shape it currently has.
        private var framedAt: CFTimeInterval = 0
        /// Whether anything has been drawn since it took that shape.
        private var drawnSinceFraming = 0
        private var ticks = 0
        weak var view: SCNView?

        /// How long the view must hold one shape before the board is shown.
        ///
        /// A tenth of a second and a bit: several turns of the runloop, which
        /// is what the second layout pass takes to arrive, and short enough
        /// that nobody waits through it.
        private static let settle: CFTimeInterval = 0.12

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
            guard size.width > 1, size.height > 1, size != framedFor else {
                drawnSinceFraming += 1
                reveal()
                return
            }
            LaunchClock.mark("laid out at \(Int(size.width))×\(Int(size.height)) — settle restarts")
            framedFor = size
            framedAt = CACurrentMediaTime()
            drawnSinceFraming = 0
            sequence?.camera.fit(aspect: Float(size.width / size.height))
            sequence?.place()
        }

        /// Show the board once its size has stopped changing.
        ///
        /// Revealing on the first measurement was not enough. SwiftUI lays this
        /// out more than once on the way in — the second pass reports a
        /// different height once the rest of the screen has resolved — and the
        /// board was already visible by then, so the correction read as the
        /// scene jumping. So it waits for the shape to hold still.
        ///
        /// It waits on the clock, and that is the point. This used to wait for
        /// eight drawn frames, which sounds like the same thing and is not: the
        /// second layout pass is a main-thread event that arrives when the
        /// runloop reaches it, and has nothing to do with how fast this device
        /// draws. Counting frames tied the wait to the renderer, so the slower
        /// the device the longer its board was missing — which is exactly
        /// backwards. Measured on a simulator, those eight frames cost a
        /// quarter of a second warm and a second and a third cold, for a guard
        /// that never needed more than a tenth.
        ///
        /// One drawn frame is still required. Not for the picture — `place()`
        /// has already moved the camera by then, so the next frame out is
        /// correct either way — but because a view that is not being drawn at
        /// all should not be faded in as though it were.
        private func reveal() {
            guard drawnSinceFraming >= 8, let view, view.alpha == 0 else { return }
            #if DEBUG
            BoardSceneDebug.boardHasAppeared = true
            #endif
            LaunchClock.mark("reveal — fade of 350 ms begins")
            UIView.animate(withDuration: 0.35) { view.alpha = 1 }
        }

        @objc private func tick(_ link: CADisplayLink) {
            guard let sequence else { return }
            if ticks < 3 { ticks += 1; LaunchClock.mark("tick \(ticks)") }
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

#if DEBUG
/// Whether the title board has been framed and shown.
///
/// For recorded previews only. The board is built from a size the view does not
/// have until it has been laid out, so it appears a second or two after the
/// screen around it — and a preview that leaves the menu on a timer started at
/// launch was leaving it exactly as the board arrived.
@MainActor
public enum BoardSceneDebug {
    /// Set the moment a turned board fades itself in.
    ///
    /// Not only the title one, despite where it started: the free board asks
    /// the same question, and a screenshot taken before the answer is yes is a
    /// photograph of an empty room.
    public static var boardHasAppeared = false

    /// Put the title game back to its first move.
    ///
    /// The board plays a game, lets the mate stand, clears, and waits again
    /// before the next one starts — close to seven still seconds in a cycle of
    /// about nineteen. A recording that began inside that gap opened on a board
    /// that looked broken, and waiting for the app to be ready made landing in
    /// the gap more likely rather than less. Called just before the tape rolls,
    /// so a preview always opens on a game that is under way.
    public static var restartTitleGame: (() -> Void)?
}
#endif
