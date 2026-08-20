import ChessCore
import Foundation
import SceneKit
import simd

/// Where the camera stands, and how it drifts.
///
/// The site flies a spline because it is driven by the page scrolling. Nothing
/// scrolls here, so the shot is an orbit the viewer can turn instead — the same
/// three-quarter opening angle, with the same slow handheld float on top of it
/// so a still shot never sits perfectly still.
public struct OrbitCamera: Sendable {
    /// Standing on White's side, three-quarters on. The key is high and behind
    /// the black king from here, so the shadows fall down the board towards the
    /// viewer — which is the shot the site opens on.
    public var azimuth: Float = -0.72
    public var elevation: Float = 0.66
    public private(set) var distance: Float = 19.5
    public var target = SIMD3<Float>(0, 1.15, 0)

    /// How the viewer has pinched, as a multiple of the framed distance rather
    /// than as a distance of its own — so a zoom survives turning the board.
    public private(set) var zoom: Float = 1

    /// The shape of the view, remembered so the framing can be redone when the
    /// board turns.
    private var aspect: Float = 0.5

    /// Low enough to keep the board a board, high enough not to fall under it.
    public static let elevationRange: ClosedRange<Float> = 0.06...1.32
    public static let distanceRange: ClosedRange<Float> = 7.5...32
    public static let zoomRange: ClosedRange<Float> = 0.55...1.9

    public init(azimuth: Float = -0.72, elevation: Float = 0.66,
                distance: Float = 19.5, target: SIMD3<Float> = SIMD3(0, 1.15, 0)) {
        self.azimuth = azimuth
        self.elevation = elevation
        self.distance = distance
        self.target = target
    }

    /// Turning the board changes how much of it faces the camera.
    ///
    /// Square on, a board is nine units across; turned to the diagonal it is
    /// nearly thirteen. Framing it once and leaving the camera there means it
    /// either wastes the screen at one angle or loses its corners at the other,
    /// and losing the corners means losing the pieces standing on them. So the
    /// distance is part of the turn: the camera draws back into the diagonal
    /// and comes in again as the board squares up.
    public mutating func turn(by deltaAzimuth: Float, and deltaElevation: Float) {
        azimuth += deltaAzimuth
        elevation = min(max(elevation + deltaElevation, Self.elevationRange.lowerBound),
                        Self.elevationRange.upperBound)
        reframe()
    }

    /// Stands back far enough for the board to suit the shape of the view.
    ///
    /// The site widens its lens on a tall screen; here the lens stays put and
    /// the camera moves, so a phone and an iPad see the same perspective rather
    /// than the phone seeing a fish-eye.
    ///
    /// What has to fit is the board's footprint as the camera sees it, and not
    /// all of it: on a tall screen the far corners are allowed outside the
    /// frame, because a board that fits entirely into a phone is a board nobody
    /// can see. Past a point, standing further back stops helping and only
    /// shrinks it, so the distance is capped and a phone simply crops.
    public mutating func fit(aspect: Float) {
        self.aspect = aspect
        reframe()
    }

    /// Pinching sets how close the viewer wants to be, relative to the framing.
    public mutating func pinch(to value: Float) {
        zoom = min(max(value, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
        reframe()
    }

    private mutating func reframe() {
        // How far the board is allowed to reach across the frame. A tall screen
        // may crop its far corners a little — a board that fits entirely into a
        // phone is a board nobody can see — and a wide one has no reason to.
        let allowed: Float = aspect > 1.15 ? 0.96 : 1.12

        // Solved rather than estimated. The distance a turned board needs is
        // not a formula worth deriving: perspective makes the near corner
        // project far larger than the far one, the camera aims above the board
        // rather than at it, and the answer changes with every one of azimuth,
        // elevation, field of view and aspect. Twenty-four halvings of the
        // range settle it to a millimetre, and it runs once per turn.
        var tooClose = Self.distanceRange.lowerBound
        var farEnough = Self.distanceRange.upperBound
        for _ in 0..<24 {
            let middle = (tooClose + farEnough) / 2
            if reach(at: middle) > allowed { tooClose = middle } else { farEnough = middle }
        }

        distance = min(max(farEnough * zoom, Self.distanceRange.lowerBound),
                       Self.distanceRange.upperBound)
    }

    /// How far the outermost corner of the board reaches across the frame,
    /// where 1 is the edge of it.
    private func reach(at distance: Float) -> Float {
        let eye = target + SIMD3(
            cosf(elevation) * sinf(azimuth) * distance,
            sinf(elevation) * distance,
            cosf(elevation) * cosf(azimuth) * distance
        )
        let forward = simd_normalize(target - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3<Float>(0, 1, 0)))
        let up = simd_cross(right, forward)

        let halfVertical = tanf(Self.fieldOfView * .pi / 360)
        let halfHorizontal = halfVertical * aspect

        var worst: Float = 0
        for x in [Float(-4.55), 4.55] {
            for z in [Float(-4.55), 4.55] {
                let v = SIMD3<Float>(x, 0, z) - eye
                let depth = simd_dot(v, forward)
                guard depth > 0.01 else { return .greatestFiniteMagnitude }
                worst = max(worst, abs(simd_dot(v, right)) / (depth * halfHorizontal))
                worst = max(worst, abs(simd_dot(v, up)) / (depth * halfVertical))
            }
        }
        return worst
    }

    /// The lens, which never changes: moving the camera keeps a phone and an
    /// iPad seeing the same perspective, where widening the lens would give the
    /// phone a fish-eye.
    static let fieldOfView: Float = 52

    /// The eye position, with a whisper of handheld float.
    public func eye(clock: TimeInterval) -> SIMD3<Float> {
        let sway: Float = 0.055
        let drift = SIMD3<Float>(
            sinf(Float(clock) * 0.42) * sway,
            sinf(Float(clock) * 0.31 + 1.2) * sway * 0.7,
            0
        )
        return target + SIMD3(
            cosf(elevation) * sinf(azimuth) * distance,
            sinf(elevation) * distance,
            cosf(elevation) * cosf(azimuth) * distance
        ) + drift
    }
}

/// The first screen: a board playing famous games to itself.
///
/// One move at a time, waiting for the pieces to settle before starting the
/// clock on the next — so a slow machine gets a slower game rather than a
/// pile-up.
@MainActor
public final class TitleSequence: SceneDriver {
    public let stage: Stage
    public var camera = OrbitCamera()

    /// Called whenever a new game starts, so the screen can caption it.
    public var onGame: ((ShowGame) -> Void)?

    public private(set) var game: ShowGame

    private let games: [ShowGame]
    private var gameIndex = 0
    private var plyIndex = 0
    private var wait: Float
    private var clock: TimeInterval = 0

    /// Slow enough to follow a move, fast enough that a whole game fits inside
    /// the attention a first screen gets.
    private static let betweenMoves: Float = 0.72
    private static let firstMoveDelay: Float = 2.4
    private static let afterMate: Float = 4.6

    public init(quality: SceneQuality = .high, style: PieceStyle = .plain,
                games: [ShowGame] = ShowGames.all) {
        self.stage = Stage(quality: quality, style: style)
        self.games = games.isEmpty ? ShowGames.all : games
        self.game = self.games[0]
        self.wait = Self.firstMoveDelay
    }

    /// One frame. `delta` is already clamped by the caller: a frame that took
    /// a second — a backgrounded app, a stalled main thread — must not teleport
    /// the pieces through their animation.
    public func advance(delta: Float) {
        clock += TimeInterval(delta)

        stage.board.update(delta: delta)
        stage.followPlay(clock: clock)
        place()

        guard stage.board.isIdle else { return }

        wait -= delta
        guard wait <= 0 else { return }

        let current = games[gameIndex]
        if plyIndex >= current.plies.count {
            // Let the mate stand for a moment before clearing the board.
            gameIndex = (gameIndex + 1) % games.count
            plyIndex = 0
            stage.board.reset()
            wait = Self.firstMoveDelay
            game = games[gameIndex]
            onGame?(game)
            return
        }

        stage.board.play(current.plies[plyIndex])
        plyIndex += 1
        wait = plyIndex >= current.plies.count ? Self.afterMate : Self.betweenMoves
    }

    /// Puts the camera where the orbit says it should be.
    public func place() {
        let eye = camera.eye(clock: clock)
        stage.cameraNode.position = SCNVector3(eye.x, eye.y, eye.z)
        stage.cameraNode.look(
            at: SCNVector3(camera.target.x, camera.target.y, camera.target.z),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
    }

    /// Starts again from the first game. Used when the screen comes back after
    /// having been away long enough that carrying on mid-game reads as a bug.
    public func restart() {
        gameIndex = 0
        plyIndex = 0
        stage.board.reset()
        wait = Self.firstMoveDelay
        game = games[0]
        onGame?(game)
    }
}
