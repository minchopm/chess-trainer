import ChessCore
import Foundation
import SceneKit
import simd

/// A recorded game, played back.
///
/// The difference between this and the first screen's sequence is that this one
/// can be wound backwards, which means it cannot work forwards only: it holds
/// the position after every ply and sets the board to one of them, rather than
/// replaying from the start every time the scrubber moves.
@MainActor
public final class GamePlayer: SceneDriver {
    public let stage: Stage
    public var camera: OrbitCamera

    public private(set) var plies: [Ply] = []
    private var positions: [Position] = [Position()]

    /// How many plies have been played. 0 is the starting array.
    public private(set) var index = 0
    public private(set) var isPlaying = false

    /// Seconds between moves at normal speed.
    public var pace: Double = 0.72
    public var speed: Double = 1

    /// Called whenever the position changes, so the screen can follow along.
    public var onChange: ((Int) -> Void)?

    private var wait: Double = 0
    private var clock: TimeInterval = 0

    public var count: Int { plies.count }
    public var isAtEnd: Bool { index >= plies.count }
    public var isAtStart: Bool { index == 0 }
    /// The array currently shown by the replay. The flat Watch board reads
    /// this while the dimensional Watch board reads the same position through
    /// the SceneKit stage, keeping both presentations on one transport.
    public var currentPosition: Position { positions[index] }
    public var lastMove: (from: Square, to: Square)? {
        guard index > 0 else { return nil }
        let ply = plies[index - 1]
        return (ply.from, ply.to)
    }

    public init(quality: SceneQuality = .high, style: PieceStyle = .plain) {
        self.stage = Stage(quality: quality, style: style)
        self.camera = OrbitCamera(azimuth: -0.5, elevation: 0.72, distance: 15.6,
                                  target: SIMD3<Float>(0, 0.5, 0))
        place()
    }

    public func load(notation: String) {
        load(position: Position(), notation: notation)
    }

    /// Load a recording that begins from a composed or mid-game position.
    /// This gives tactic solutions the same player as Watch without pretending
    /// their first move was played from the standard starting array.
    public func load(position: Position, notation: String) {
        let line = ShowGames.line(from: position, notation: notation)
        plies = line.plies
        positions = line.positions
        index = 0
        isPlaying = false
        stage.board.set(positions[0])
        onChange?(index)
    }

    public func play() {
        guard !isAtEnd else { return }
        isPlaying = true
        wait = 0
    }

    public func pause() { isPlaying = false }

    public func toggle() { isPlaying ? pause() : play() }

    /// Steps by whole plies. Forward by one animates, because that is a move
    /// being played; anything else is a jump, because a scrubber dragged across
    /// twenty moves is not twenty moves being played.
    public func step(_ delta: Int) {
        pause()
        if delta == 1, !isAtEnd {
            stage.board.play(plies[index])
            index += 1
            onChange?(index)
        } else {
            seek(to: index + delta)
        }
    }

    public func seek(to target: Int) {
        let clamped = min(max(target, 0), plies.count)
        guard clamped != index else { return }
        index = clamped
        stage.board.set(positions[index])
        onChange?(index)
    }

    public func advance(delta: Float) {
        clock += TimeInterval(delta)
        stage.board.update(delta: delta)
        stage.followPlay(clock: clock)
        place()

        guard isPlaying, stage.board.isIdle else { return }
        wait -= Double(delta) * max(0.1, speed)
        guard wait <= 0 else { return }

        guard !isAtEnd else {
            isPlaying = false
            return
        }
        stage.board.play(plies[index])
        index += 1
        wait = pace
        onChange?(index)
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

/// Anything that owns a scene and wants a frame.
///
/// Three things drive the same room — the first screen, a game being watched
/// and a game being played — and they differ only in what they do with a
/// frame. The host view below does not need to know which it has.
@MainActor
public protocol SceneDriver: AnyObject {
    var stage: Stage { get }
    var camera: OrbitCamera { get set }
    func advance(delta: Float)
    func place()
}
