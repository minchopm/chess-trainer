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
    /// Which board, and which room. Follows the set — see `PieceStyle.dressing`.
    private let dressing: Dressing

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
        self.dressing = style.dressing
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
        guard !playable, dressing == .theatre else { return }
        key.light?.intensity = 1150 + CGFloat(sin(clock * 0.7)) * 60
    }

    // MARK: - Construction

    private func buildEnvironment() {
        if dressing == .parlour {
            // A dim room rather than a black stage. The background is a warm
            // near-black instead of Colour.ink's blue one, and the fog is what
            // closes the table off into it — there are no walls, on purpose:
            // the camera orbits all the way round, and one lit wall behind the
            // board is a wall the player can put the camera on the wrong side
            // of. Fog and the environment map give the same reading from every
            // angle for none of the geometry.
            scene.background.contents = Colour.make(0x191310)
            scene.lightingEnvironment.contents = Parlour.environment() as Any
            scene.lightingEnvironment.intensity = 0.55
            scene.fogColor = Colour.make(0x191310)
            scene.fogStartDistance = 20
            scene.fogEndDistance = 62
            scene.fogDensityExponent = 1.2
            return
        }
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
        if dressing == .parlour { buildRoom(); buildTable(); return }
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

    /// The room, as one cylinder seen from inside.
    ///
    /// The parlour started without one, on the reasoning that the camera orbits
    /// all the way round and a wall behind the board is a wall the player can
    /// get on the wrong side of. That is true and it was still wrong: with
    /// nothing behind it, everything above the table's far edge is the
    /// background colour, and what a lit table under a black sky reads as is a
    /// diorama. It also gave the dust nothing to be seen against, so the motes
    /// came out as stars.
    ///
    /// A cylinder rather than four walls because it has no corners to notice as
    /// the board turns, and `cullMode = .front` rather than an inside-out mesh
    /// because that is one line instead of a second geometry. Unlit — the
    /// gradient already has the lamp's falloff painted into it, and lighting it
    /// for real would need the lamp to reach thirty units, at which point it is
    /// lighting the board like a floodlight.
    private func buildRoom() {
        let room = SCNCylinder(radius: 34, height: 40)
        let plaster = room.firstMaterial!
        plaster.lightingModel = .constant
        plaster.diffuse.contents = Parlour.wall() as Any
        plaster.diffuse.wrapS = .clamp
        plaster.diffuse.wrapT = .clamp
        plaster.cullMode = .front
        // The board must never be seen through the far wall, and the wall must
        // never be seen through the board.
        plaster.writesToDepthBuffer = true

        let node = SCNNode(geometry: room)
        // Sunk, so the bottom of the gradient — its warmest part — meets the
        // table rather than sitting above it in mid-air.
        node.position = SCNVector3(0, 14, 0)
        scene.rootNode.addChildNode(node)
    }

    /// The table the parlour board stands on.
    ///
    /// A box rather than a plane, because it is seen from below the level of
    /// its own top: the app lets the camera down to six hundredths of a radian
    /// above the horizon, and at that height a plane is a line. The edge and
    /// its thickness are most of what says "table" from there.
    ///
    /// Wide enough that its far edge is in the fog at any distance the camera
    /// can reach, and no wider — 200 units of table, which is what the
    /// theatre's floor is, would be a field.
    private func buildTable() {
        let table = SCNBox(width: 34, height: 0.9, length: 26, chamferRadius: 0.02)
        let wood = table.firstMaterial!
        wood.lightingModel = .physicallyBased
        wood.diffuse.contents = Parlour.planks(size: quality.textureSize) as Any
        // Tiled, so the planks come out about three units across — a third of
        // the board's width, which is what the reference's are. Mapped once
        // over thirty-four units they are seven units wide and the table reads
        // as a stage.
        wood.diffuse.wrapS = .repeat
        wood.diffuse.wrapT = .repeat
        wood.diffuse.contentsTransform = SCNMatrix4MakeScale(2.2, 1.7, 1)
        wood.roughness.contents = 0.72
        wood.metalness.contents = 0.0
        // Old wax, not varnish: enough of a sheen for the lamp to find the
        // grain, nowhere near enough to reflect the board.
        wood.clearCoat.contents = 0.12
        wood.clearCoatRoughness.contents = 0.70

        let node = SCNNode(geometry: table)
        // Its top a few thousandths under the board's underside, which sits at
        // -0.321. Level with it the two surfaces fight for the same pixels
        // along the whole join.
        node.position = SCNVector3(0, -0.775, 0)
        scene.rootNode.addChildNode(node)
    }

    /// Six materials for the frame, because a box takes six.
    ///
    /// One material would put the inlay on the sides as well, and the inlay
    /// drawn down the edge of the board is a stripe round a plinth. So the top
    /// gets the frame texture and the four sides get end grain — which is a
    /// different colour from the face of the same wood, darker and duller,
    /// exactly as a sawn edge is.
    ///
    /// The order SceneKit wants is front, right, back, left, top, bottom.
    private func frameMaterials() -> [SCNMaterial] {
        func make(_ configure: (SCNMaterial) -> Void) -> SCNMaterial {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.metalness.contents = 0.0
            configure(material)
            return material
        }

        let edge = make {
            $0.diffuse.contents = Colour.make(0x40261A)
            $0.roughness.contents = 0.58
            $0.clearCoat.contents = 0.22
            $0.clearCoatRoughness.contents = 0.46
        }
        let face = make {
            $0.diffuse.contents = Parlour.border(size: quality.textureSize) as Any
            $0.roughness.contents = 0.42
            // French polish on the frame and wax on the field, which is how a
            // board is finished: the frame is handled and the squares are
            // played on. It also keeps the frame reading as the darker, glossier
            // thing and stops it merging with the outer rank of squares.
            $0.clearCoat.contents = 0.40
            $0.clearCoatRoughness.contents = 0.24
        }
        let under = make {
            $0.diffuse.contents = Colour.make(0x2A180F)
            $0.roughness.contents = 0.86
        }
        return [edge, edge.copy() as! SCNMaterial, edge.copy() as! SCNMaterial,
                edge.copy() as! SCNMaterial, face, under]
    }

    public static let surfaceName = "board-surface"
    public static let coordinatesName = "board-coordinates"

    /// Whether the files and ranks are painted on the rim.
    ///
    /// Off until asked for, and the title sequence never asks: that board is a
    /// showcase playing famous games to itself, and nobody reads a square off
    /// it. Every board that is played on, watched or solved turns them on from
    /// the setting.
    public func setCoordinates(_ showing: Bool) {
        scene.rootNode.childNode(withName: Stage.coordinatesName, recursively: true)?
            .isHidden = !showing
    }

    private func buildBoard() {
        let top = SCNBox(width: 8, height: 0.02, length: 8, chamferRadius: 0)
        let surface = top.firstMaterial!
        surface.lightingModel = .physicallyBased
        surface.diffuse.contents = dressing == .parlour
            ? Parlour.field(size: quality.textureSize) as Any
            : BoardSurface.texture(size: quality.textureSize) as Any
        surface.roughness.contents = BoardSurface.roughness() as Any
        surface.metalness.contents = 0.0
        // Varnish, and how polished it is. On the board being played this is
        // kept low and left rough: a tight coat throws the key light back as a
        // mirror, and the squares under it go white enough that an ivory piece
        // standing on them has nothing to stand against. The title sequence
        // keeps the gloss, because there the shot is the point and nobody has
        // to find a bishop on it.
        //
        // The parlour's field is waxed either way, title sequence or not. A
        // lamp is a small source close by, so a tight coat gives it one hot
        // spot on the squares instead of the broad sheen a rig's soft box
        // gives — and a bright pool in the middle of the board is where the
        // pieces are.
        let polished = dressing == .theatre && !playable
        surface.clearCoat.contents = polished ? 0.55 : 0.10
        surface.clearCoatRoughness.contents = polished ? 0.22 : 0.68

        let surfaceNode = SCNNode(geometry: top)
        surfaceNode.name = Stage.surfaceName
        surfaceNode.position = SCNVector3(0, -0.014, 0)
        scene.rootNode.addChildNode(surfaceNode)

        // What the field is set into: an ebony plinth in the theatre, and in
        // the parlour a walnut frame — thicker, because a board on a table is
        // an object with a side to it, where a plinth on a black floor is a
        // shadow with a top.
        let deep: CGFloat = dressing == .parlour ? 0.30 : 0.25
        let plinth = SCNBox(width: 9.1, height: deep, length: 9.1, chamferRadius: 0.02)
        if dressing == .parlour {
            plinth.materials = frameMaterials()
        } else {
            let stone = plinth.firstMaterial!
            stone.lightingModel = .physicallyBased
            stone.diffuse.contents = Colour.make(0x0E1017)
            stone.roughness.contents = 0.34
            stone.metalness.contents = 0.12
            stone.clearCoat.contents = 0.7
            stone.clearCoatRoughness.contents = 0.25
        }

        let plinthNode = SCNNode(geometry: plinth)
        // Its top is at -0.021 either way, just under the field's, so the field
        // sits in the frame rather than on it.
        plinthNode.position = SCNVector3(0, -0.021 - deep / 2, 0)
        scene.rootNode.addChildNode(plinthNode)

        // The files and ranks, laid on the plinth around the squares. A plane
        // of its own rather than part of the plinth's material, so it can be
        // switched off without rebuilding the board.
        let rim = SCNPlane(width: 9.1, height: 9.1)
        let paint = rim.firstMaterial!
        let parlour = dressing == .parlour
        // Lit in the parlour, unlit in the theatre, and that is the difference
        // that matters rather than the colour. `.constant` ignores every light
        // in the scene, so the letters come out equally bright in the hot pool
        // under the lamp and in the corner the lamp does not reach — which is
        // exactly how a printed label behaves and exactly how inlaid wood does
        // not. Given the lamp to sit in, they dim with the frame around them.
        //
        // The theatre keeps `.constant` on purpose: its plinth is very nearly
        // black and its one spot comes from off-stage, so letters that took
        // that light would be legible along one edge of the board and gone
        // along the other.
        paint.lightingModel = parlour ? .physicallyBased : .constant
        paint.diffuse.contents = (parlour
            ? Parlour.letters(size: quality.textureSize)
            : BoardSurface.coordinates()) as Any
        if parlour {
            paint.roughness.contents = 0.44
            paint.metalness.contents = 0.0
        }
        paint.isDoubleSided = false
        paint.writesToDepthBuffer = false
        let rimNode = SCNNode(geometry: rim)
        rimNode.name = Stage.coordinatesName
        rimNode.eulerAngles.x = -.pi / 2
        // Just clear of the plinth's top, which is where the ivory stops — and
        // a little further clear in the parlour, where the plane is lit and so
        // has a shaded surface of its own to be confused with rather than a
        // flat colour that wins either way.
        rimNode.position = SCNVector3(0, parlour ? -0.0182 : -0.0195, 0)
        // A decal casts nothing. It is a nine-unit square lying just above the
        // frame, so left to cast it drops a shadow of the whole board onto the
        // table — where the board's own shadow happens to hide it, which is
        // luck rather than a reason. The theatre is left as it was: its plane
        // has always cast one, and this branch is not the place to find out
        // what depended on that.
        if parlour { rimNode.castsShadow = false }
        rimNode.isHidden = true
        scene.rootNode.addChildNode(rimNode)
    }

    private func buildLights() {
        if dressing == .parlour { buildLamp(); return }
        // The key: a single hard warm source, high and behind the black king,
        // so the pieces throw their shadows down the board toward the viewer.
        let keyLight = SCNLight()
        keyLight.type = .spot
        keyLight.color = Colour.make(0xFFCF94)
        keyLight.intensity = playable ? 790 : 1150
        // Wide and soft for play, narrow and dramatic for the title. A tight
        // cone puts a bright pool in the middle of the board and lets the
        // corners fall away — which is a good photograph and a bad thing to
        // play on, because the pieces at the two ends are the ones being read.
        keyLight.spotInnerAngle = playable ? 34 : 22
        keyLight.spotOuterAngle = playable ? 78 : 52
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
        // Aimed at the middle of the board for play, and off it for the title.
        // Off-centre throws the shadows down the board towards the viewer,
        // which is the shot — but it also leaves one half of the board lit and
        // the other half not, and both halves have pieces on them.
        key.look(at: playable ? SCNVector3(0, 0, -0.3) : SCNVector3(0.8, 0, -1.2))
        scene.rootNode.addChildNode(key)

        // The rim: cold, low, from the far side. It is what keeps the black
        // pieces from disappearing into a black room.
        let rimLight = SCNLight()
        rimLight.type = .spot
        rimLight.color = Colour.make(0x7C93B8)
        rimLight.intensity = playable ? 268 : 240
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
        fillLight.intensity = playable ? 215 : 165
        let fill = SCNNode()
        fill.light = fillLight
        fill.position = SCNVector3(-3, 4, 8)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)

        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = Colour.make(0x141B2C)
        // Lifted for play. It is what stops the far corners going to nothing,
        // and a black piece in a dark corner of a dark board is not a piece.
        ambientLight.intensity = playable ? 405 : 200
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

    /// The parlour's light: one lamp in the room, and what the room gives back.
    ///
    /// The theatre's rig is three lights from three directions and an ambient,
    /// and the two cold ones are what keep an ebony piece off a dark square.
    /// This has one warm source and no cold light anywhere, because a table
    /// lamp is the only thing on in the room — and it can afford to, because
    /// nothing here is black: the dark pieces are walnut and the dark squares
    /// are walnut, and both have a colour to be seen by.
    ///
    /// What replaces the two cold lights is bounce. A lamp in a room lights the
    /// ceiling and the wall and the table, and all three throw warm light back
    /// at the board from every direction at once — which is what the
    /// environment map and a generous warm ambient are standing in for. Lit
    /// with the lamp alone, the side of every piece facing away from it went to
    /// nothing, and a set half in shadow is a set you cannot read.
    private func buildLamp() {
        // The lamp: close, high and off to one side, the way it stands in the
        // reference. Close matters — its falloff across the board is most of
        // what makes the near corner warm and the far one cool, and a light
        // far enough away to be even is a light that could be anywhere.
        let lamp = SCNLight()
        lamp.type = .spot
        lamp.color = Colour.make(0xFFC98A)
        // Bright, and the fill kept well under it. This is the number the
        // shadows live on: a shadow is only the absence of this light, so what
        // decides whether a piece has one is not the shadow settings but how
        // much of the total light comes from somewhere that does not cast one.
        // At 1120 against an ambient of 430 and an environment of 0.9, the
        // lamp was under half the light on the board and every piece stood on
        // clean wood — the shadows were being drawn and then filled straight
        // back in.
        lamp.intensity = playable ? 1080 : 1220
        // A narrow inner cone, so the light falls off *across* the board rather
        // than lighting all of it evenly. A lamp three feet from a board is not
        // an even source, and the gradient from the near corner to the far one
        // is most of what says the light is in the room.
        lamp.spotInnerAngle = playable ? 32 : 26
        lamp.spotOuterAngle = playable ? 80 : 70
        lamp.castsShadow = true
        lamp.shadowMode = .deferred
        lamp.shadowMapSize = CGSize(width: quality.shadowMapSize, height: quality.shadowMapSize)
        lamp.shadowSampleCount = quality == .high ? 16 : 4
        // Softer than the theatre's, but only a little. A lampshade is a big
        // diffuser at close range, so its shadows do have a wide penumbra —
        // and taken to its logical end, a radius of five and the theatre's
        // bias of 2.4, every piece on the board lost its shadow completely.
        // The bias is what did it: it pushes the shadow away from the thing
        // casting it, and what that costs is precisely the contact shadow —
        // the dark ring where the base meets the square, which is the only
        // shadow that says the piece is standing on the board rather than
        // floating over it.
        lamp.shadowRadius = 2.6
        lamp.shadowBias = 1.1
        // Brown, not black. A shadow on wood under a warm lamp keeps the wood's
        // colour, and the theatre's near-black shadow on walnut reads as a hole
        // cut in the board.
        lamp.shadowColor = Colour.make(0x1A0E06, alpha: 0.76)
        lamp.zNear = 1
        lamp.zFar = 40
        key.light = lamp
        // Behind the board and off to the right, which is where the lamp
        // stands in the reference — and, more to the point, is the only side it
        // can stand on. A board is looked at from a player's chair, and the
        // default chair is White's at +z; a lamp on that side throws every
        // shadow away from the camera and behind the piece casting it, so the
        // set comes out looking pasted onto the squares. It cost an hour of
        // hunting through shadow bias, shadow mode and the room geometry before
        // the shadows turned out to be there all along and pointing the wrong
        // way.
        key.position = SCNVector3(8.2, 8.6, -1.2)
        key.look(at: SCNVector3(-0.8, 0, 0.2))
        scene.rootNode.addChildNode(key)

        // The room, coming back off the ceiling. Directional, and from the
        // opposite corner to the lamp — the near left, which is the side facing
        // whichever chair the board is being read from. Put behind the board
        // instead, it lights the far army's back and leaves its front, the only
        // part a player can see, as dark as the lamp left it.
        let bounce = SCNLight()
        bounce.type = .directional
        bounce.color = Colour.make(0xCBB69E)
        bounce.intensity = playable ? 200 : 165
        let ceiling = SCNNode()
        ceiling.light = bounce
        ceiling.position = SCNVector3(-5.5, 6.5, 5.5)
        ceiling.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(ceiling)

        // And off the table, which is the one that matters for the pieces: it
        // comes from below and it is what puts light under the bases and into
        // the underside of the knight's jaw.
        let table = SCNLight()
        table.type = .directional
        table.color = Colour.make(0xB98A5C)
        table.intensity = 90
        let floor = SCNNode()
        floor.light = table
        floor.position = SCNVector3(2, -3, 4)
        floor.look(at: SCNVector3(0, 0.5, 0))
        scene.rootNode.addChildNode(floor)

        let room = SCNLight()
        room.type = .ambient
        room.color = Colour.make(0x282018)
        room.intensity = playable ? 330 : 275
        let ambient = SCNNode()
        ambient.light = room
        scene.rootNode.addChildNode(ambient)

        // No travelling light. In the theatre it is what tells you where to
        // look on a board of identical objects; here the lamp already makes one
        // part of the board brighter than the rest, and a second moving pool of
        // light on top of that reads as a torch being shone about.
        practical.position = SCNVector3(0, 0.45, 0)
        scene.rootNode.addChildNode(practical)
    }

    private func buildDust() {
        guard let image = BoardSurface.dust() else { return }
        let system = SCNParticleSystem()
        system.particleImage = image
        // Half as much in the parlour. Dust reads as dust when it is caught in
        // a beam and as noise when it is not, and a lamp in a room has no beam
        // — so what the theatre's ninety motes look like here is a dirty lens.
        system.birthRate = dressing == .parlour
            ? quality.dustBirthRate * 0.45 : quality.dustBirthRate
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
        camera.fieldOfView = CGFloat(OrbitCamera.fieldOfView)
        camera.projectionDirection = .vertical
        camera.zNear = 0.1
        camera.zFar = 120
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = dressing == .parlour ? -0.30 : -0.55
        // A sheen on the brass, not a glow stick — and next to none in the
        // parlour, where there is no brass to catch it. Left at the theatre's
        // figure the lamp's hot spot on the boxwood blooms, and a bloomed
        // highlight on a wooden piece reads as plastic.
        camera.bloomIntensity = dressing == .parlour ? 0.14 : 0.34
        camera.bloomThreshold = dressing == .parlour ? 0.97 : 0.93
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
