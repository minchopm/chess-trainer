import ChessCore
import SceneKit

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// How good the machine is expected to be at this.
public enum SceneQuality: Sendable {
    case high, low

    var shadowMapSize: Int { self == .high ? 2048 : 1024 }
    var textureSize: Int { self == .high ? 1024 : 512 }
    var dustBirthRate: CGFloat { self == .high ? 90 : 36 }
    var segments: Int { self == .high ? 48 : 28 }
}

/// The room the board stands in: a floor, a plinth, three lights and the dust
/// between them.
///
/// Ported from the site's title sequence. The numbers are the site's numbers
/// wherever the two renderers agree on what a number means — geometry,
/// positions, colours, roughness — and re-graded by eye where they do not.
/// three.js lights are in candela and fall off with the square of the
/// distance; SceneKit's are in lumens and do not, so the intensities here are
/// matched to the picture rather than to the source.
@MainActor
public final class Stage {
    public let scene = SCNScene()
    public let board: PlayingBoard
    public let cameraNode = SCNNode()

    private let key = SCNNode()
    /// A light that travels with the move. It is the cheapest way to make a
    /// board full of identical objects tell you where to look.
    private let practical = SCNNode()
    private let quality: SceneQuality
    private let playable: Bool

    /// `playable` is the same room with the theatrics turned down.
    ///
    /// A title sequence wants a hot specular on the wood and a light that
    /// chases the move, because there is nothing to do but look at it. A board
    /// somebody is playing on wants to be read: the same board, a wider and
    /// softer highlight, and no light wandering across the squares while you
    /// are trying to count them.
    public init(quality: SceneQuality = .high, style: PieceStyle = .plain, playable: Bool = false) {
        self.quality = quality
        self.playable = playable
        self.board = PlayingBoard(quality: quality, style: style)

        buildEnvironment()
        buildFloor()
        buildBoard()
        scene.rootNode.addChildNode(board.node)
        buildLights()
        buildDust()
        buildCamera()
    }

    /// Moves the light that follows the play. Called once a frame.
    public func followPlay(clock: TimeInterval) {
        let focus = board.focus
        practical.position = SCNVector3(focus.x, focus.y, focus.z)

        // The key light breathes, very slightly. A perfectly steady light reads
        // as a render; a moving one reads as a room.
        guard !playable else { return }
        key.light?.intensity = 1150 + CGFloat(sin(clock * 0.7)) * 60
    }

    // MARK: - Construction

    private func buildEnvironment() {
        scene.background.contents = Colour.ink
        scene.lightingEnvironment.contents = BoardSurface.environment() as Any
        // A tenth, not a quarter. This gradient is bright across the whole
        // upper hemisphere, so the same number that suits a room map here is
        // several times the fill light — enough to flatten the key light's
        // contrast into an evenly lit board.
        scene.lightingEnvironment.intensity = 0.72

        // The same colour the camera clears to, so the floor's far edge and the
        // empty frame above it are the same nothing.
        scene.fogColor = Colour.ink
        scene.fogStartDistance = 16
        scene.fogEndDistance = 44
        scene.fogDensityExponent = 1.4
    }

    private func buildFloor() {
        let floor = SCNPlane(width: 200, height: 200)
        let material = floor.firstMaterial!
        material.lightingModel = .physicallyBased
        material.diffuse.contents = Colour.make(0x02030A)
        material.roughness.contents = 0.95
        material.metalness.contents = 0.0

        material.isDoubleSided = false
        let node = SCNNode(geometry: floor)
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, -0.26, 0)
        scene.rootNode.addChildNode(node)
    }

    public static let surfaceName = "board-surface"

    private func buildBoard() {
        let top = SCNBox(width: 8, height: 0.02, length: 8, chamferRadius: 0)
        let surface = top.firstMaterial!
        surface.lightingModel = .physicallyBased
        surface.diffuse.contents = BoardSurface.texture(size: quality.textureSize) as Any
        surface.roughness.contents = BoardSurface.roughness() as Any
        surface.metalness.contents = 0.0
        surface.clearCoat.contents = playable ? 0.22 : 0.55
        surface.clearCoatRoughness.contents = playable ? 0.4 : 0.22

        let surfaceNode = SCNNode(geometry: top)
        surfaceNode.name = Stage.surfaceName
        surfaceNode.position = SCNVector3(0, -0.014, 0)
        scene.rootNode.addChildNode(surfaceNode)

        // The plinth the board sits on, in the same ebony as the black pieces.
        let plinth = SCNBox(width: 9.1, height: 0.25, length: 9.1, chamferRadius: 0.02)
        let stone = plinth.firstMaterial!
        stone.lightingModel = .physicallyBased
        stone.diffuse.contents = Colour.make(0x0E1017)
        stone.roughness.contents = 0.34
        stone.metalness.contents = 0.12
        stone.clearCoat.contents = 0.7
        stone.clearCoatRoughness.contents = 0.25

        let plinthNode = SCNNode(geometry: plinth)
        plinthNode.position = SCNVector3(0, -0.146, 0)
        scene.rootNode.addChildNode(plinthNode)
    }

    private func buildLights() {
        // The key: a single hard warm source, high and behind the black king,
        // so the pieces throw their shadows down the board toward the viewer.
        let keyLight = SCNLight()
        keyLight.type = .spot
        keyLight.color = Colour.make(0xFFCF94)
        keyLight.intensity = playable ? 950 : 1150
        keyLight.spotInnerAngle = 22
        keyLight.spotOuterAngle = 52
        keyLight.castsShadow = true
        keyLight.shadowMode = .deferred
        keyLight.shadowMapSize = CGSize(width: quality.shadowMapSize, height: quality.shadowMapSize)
        keyLight.shadowSampleCount = quality == .high ? 16 : 4
        keyLight.shadowRadius = 3
        keyLight.shadowBias = 2.4
        keyLight.shadowColor = Colour.shadow
        keyLight.zNear = 1
        keyLight.zFar = 30
        key.light = keyLight
        key.position = SCNVector3(6.5, 8.5, -5.0)
        key.look(at: SCNVector3(0.8, 0, -1.2))
        scene.rootNode.addChildNode(key)

        // The rim: cold, low, from the far side. It is what keeps the black
        // pieces from disappearing into a black room.
        let rimLight = SCNLight()
        rimLight.type = .spot
        rimLight.color = Colour.make(0x7C93B8)
        rimLight.intensity = 240
        rimLight.spotInnerAngle = 30
        rimLight.spotOuterAngle = 78
        let rim = SCNNode()
        rim.light = rimLight
        rim.position = SCNVector3(-8.5, 3.2, -6.0)
        rim.look(at: SCNVector3(0, 0.3, 0))
        scene.rootNode.addChildNode(rim)

        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = Colour.make(0x8EA6CC)
        fillLight.intensity = 165
        let fill = SCNNode()
        fill.light = fillLight
        fill.position = SCNVector3(-3, 4, 8)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)

        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = Colour.make(0x141B2C)
        ambientLight.intensity = playable ? 300 : 200
        let ambient = SCNNode()
        ambient.light = ambientLight
        scene.rootNode.addChildNode(ambient)

        let travelling = SCNLight()
        travelling.type = .omni
        travelling.color = Colour.make(0xFFC27A)
        travelling.intensity = playable ? 0 : 14
        travelling.attenuationStartDistance = 0.4
        travelling.attenuationEndDistance = 1.9
        practical.light = travelling
        practical.position = SCNVector3(0, 0.45, 0)
        scene.rootNode.addChildNode(practical)
    }

    private func buildDust() {
        guard let image = BoardSurface.dust() else { return }
        let system = SCNParticleSystem()
        system.particleImage = image
        system.birthRate = quality.dustBirthRate
        system.particleLifeSpan = 26
        system.particleLifeSpanVariation = 10
        system.particleSize = 0.011
        system.particleSizeVariation = 0.007
        system.particleColor = Colour.make(0xF3E2C0, alpha: 0.34)
        system.particleColorVariation = SCNVector4(0.02, 0.02, 0.04, 0.1)
        system.blendMode = .additive
        system.isLightingEnabled = false
        system.emitterShape = SCNBox(width: 20, height: 7, length: 20, chamferRadius: 0)
        system.birthLocation = .volume
        system.emittingDirection = SCNVector3(0, 1, 0)
        system.spreadingAngle = 22
        system.particleVelocity = 0.11
        system.particleVelocityVariation = 0.09
        system.acceleration = SCNVector3(0, 0.004, 0)
        system.isAffectedByGravity = false
        system.particleBounce = 0
        system.speedFactor = 1
        system.warmupDuration = 12
        system.imageSequenceAnimationMode = .repeat

        let node = SCNNode()
        node.position = SCNVector3(0, 3.4, 0)
        node.addParticleSystem(system)
        scene.rootNode.addChildNode(node)
    }

    private func buildCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 52
        camera.projectionDirection = .vertical
        camera.zNear = 0.1
        camera.zFar = 120
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = -0.55
        // A sheen on the brass, not a glow stick.
        camera.bloomIntensity = 0.34
        camera.bloomThreshold = 0.93
        camera.bloomBlurRadius = 11
        camera.motionBlurIntensity = 0
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
    }

    /// Opens the bloom up as the shot widens, the way the site does.
    public func setBloom(_ amount: CGFloat) {
        cameraNode.camera?.bloomIntensity = amount
    }
}

/// Colours, made once, in a form SceneKit takes on either platform.
enum Colour {
    #if canImport(UIKit)
    typealias Native = UIColor
    #else
    typealias Native = NSColor
    #endif

    static func make(_ hex: UInt32, alpha: CGFloat = 1) -> Native {
        Native(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    static let ink = make(0x05060A)
    static let shadow = make(0x000000, alpha: 0.72)
}
