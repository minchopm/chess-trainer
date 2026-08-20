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
    public var distance: Float = 19.5
    public var target = SIMD3<Float>(0, 1.15, 0)

    public init(azimuth: Float = -0.72, elevation: Float = 0.66,
                distance: Float = 19.5, target: SIMD3<Float> = SIMD3(0, 1.15, 0)) {
        self.azimuth = azimuth
        self.elevation = elevation
        self.distance = distance
        self.target = target
    }

    /// Low enough to keep the board a board, high enough not to fall under it.
    public static let elevationRange: ClosedRange<Float> = 0.06...1.32
    public static let distanceRange: ClosedRange<Float> = 7.5...32

    public mutating func turn(by deltaAzimuth: Float, and deltaElevation: Float) {
        azimuth += deltaAzimuth
        elevation = min(max(elevation + deltaElevation, Self.elevationRange.lowerBound),
                        Self.elevationRange.upperBound)
    }

    /// Stands back far enough for the board to suit the shape of the view.
    ///
    /// The site widens its lens on a tall screen; here the lens stays put and
    /// the camera moves, so a phone and an iPad see the same perspective rather
    /// than the phone seeing a fish-eye.
    ///
    /// What has to fit is not the board's eight squares but its footprint as
    /// the camera sees it — turned forty degrees, a nine-unit board is nearly
    /// thirteen across — and not all of that: the far corners are allowed
    /// outside the frame, because a board that fits entirely inside a tall
    /// narrow screen is a board nobody can see. Past a point, standing further
    /// back stops helping and only shrinks it, so the distance is capped and a
    /// phone simply crops.
    public mutating func fit(aspect: Float, fieldOfView: Float = 52, limit: Float = 20) {
        let half = tanf(fieldOfView * .pi / 360)
        // How much of the footprint has to be inside the frame. On a tall
        // screen the far corners are allowed out — a board that fits entirely
        // into a phone is a board nobody can see — but on a wide one there is
        // room for all of it and something beside it, so it is given margin
        // instead of being cropped.
        let margin: Float = aspect > 1.15 ? 1.05 : 0.9
        let spread = 4.55 * (abs(cosf(azimuth)) + abs(sinf(azimuth))) * margin
        let horizontal = spread / (half * min(1, aspect))
        let vertical = (spread * sinf(elevation) + 2.2) / half
        zoom(to: min(max(horizontal, vertical), limit))
    }

    public mutating func zoom(to value: Float) {
        distance = min(max(value, Self.distanceRange.lowerBound), Self.distanceRange.upperBound)
    }

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
