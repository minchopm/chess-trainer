import ChessCore
import SceneKit
import simd

/// The board, playing.
///
/// Owns thirty-two nodes and moves them. It knows nothing about chess beyond
/// what a `Ply` tells it — which piece goes where, what it takes, and whether a
/// rook comes with it — because the legality was settled by the move generator
/// long before the scene saw the move.
///
/// Nothing is created or destroyed after construction: a taken piece shrinks
/// away and its node stays in the pool, and resetting for the next game puts
/// all thirty-two back where they started. A first screen that runs for as long
/// as somebody leaves the app open cannot afford to allocate per move.
@MainActor
public final class PlayingBoard {
    public let node = SCNNode()

    /// Where the action is, for a light to follow. Eased, not snapped.
    public private(set) var focus = SIMD3<Float>(0, 0.4, 0)

    private final class Piece {
        let node: SCNNode
        let colour: PieceColor
        let home: Square
        let homeKind: PieceKind
        var kind: PieceKind
        init(node: SCNNode, colour: PieceColor, home: Square, kind: PieceKind) {
            self.node = node; self.colour = colour; self.home = home
            self.homeKind = kind; self.kind = kind
        }
    }

    private struct Travel {
        let piece: Piece
        let from: SIMD3<Float>
        let to: SIMD3<Float>
        let span: Float
        let lift: Float
        let lit: Bool
        let promotion: PieceKind?
        var t: Float
    }

    private struct Taken {
        let piece: Piece
        let span: Float
        var t: Float
    }

    private var pool: [Piece] = []
    private var occupied: [Square: Piece] = [:]
    private var travels: [Travel] = []
    private var taken: [Taken] = []
    private var focusTarget = SIMD3<Float>(0, 0.4, 0)

    private let materials: PieceMaterials
    private var prototypes: [PieceKind: SCNNode] = [:]

    /// One square is one unit; a1 is the far corner for White.
    public static func position(of square: Square) -> SIMD3<Float> {
        SIMD3(Float(square.file) - 3.5, 0, 3.5 - Float(square.rank))
    }

    public init(quality: SceneQuality = .high) {
        self.materials = PieceMaterials()
        for kind in PieceKind.allCases {
            prototypes[kind] = TurnedPieces.node(for: kind)
        }

        for placement in Self.startingPosition() {
            let piece = Piece(
                node: clone(placement.kind), colour: placement.colour,
                home: placement.square, kind: placement.kind
            )
            node.addChildNode(piece.node)
            pool.append(piece)
        }

        reset()
    }

    /// True when every piece has finished moving.
    public var isIdle: Bool { travels.isEmpty }

    /// Puts all thirty-two back on their squares, ready for the next game.
    public func reset() {
        travels.removeAll()
        taken.removeAll()
        occupied.removeAll()

        for piece in pool {
            if piece.kind != piece.homeKind {
                replaceGeometry(of: piece, with: piece.homeKind)
            }
            piece.kind = piece.homeKind
            apply(lit: false, to: piece)
            piece.node.scale = SCNVector3(1, 1, 1)
            piece.node.isHidden = false
            // Knights face the other side; the rest are turned to match, so a
            // set looks placed rather than dropped.
            piece.node.eulerAngles = SCNVector3(0, piece.colour == .white ? Float.pi : 0, 0)
            let home = Self.position(of: piece.home)
            piece.node.position = SCNVector3(home.x, home.y, home.z)
            occupied[piece.home] = piece
        }

        focusTarget = SIMD3(0, 0.4, 0)
        focus = focusTarget
    }

    /// Starts one half-move.
    ///
    /// Silently does nothing if the board and the move list have somehow
    /// disagreed — a first screen that throws is worse than one that skips a
    /// move.
    public func play(_ ply: Ply) {
        guard let mover = occupied[ply.from] else { return }

        if let square = ply.capture, let victim = occupied[square] {
            occupied[square] = nil
            taken.append(Taken(piece: victim, span: 0.42, t: 0))
        }

        occupied[ply.from] = nil
        occupied[ply.to] = mover
        start(mover, to: ply.to, hop: ply.kind == .knight, lit: true, promotion: ply.promotion)

        if let rook = ply.rook, let castling = occupied[rook.from] {
            occupied[rook.from] = nil
            occupied[rook.to] = castling
            start(castling, to: rook.to, hop: false, lit: false, promotion: nil)
        }

        focusTarget = Self.position(of: ply.to)
        focusTarget.y = 0.45
    }

    public func update(delta: Float) {
        for index in travels.indices.reversed() {
            travels[index].t += delta
            let travel = travels[index]
            let k = min(1, travel.t / travel.span)
            let e = Self.easeInOut(k)

            var place = simd_mix(travel.from, travel.to, SIMD3(repeating: e))
            // A knight is the only piece that goes over things, so it is the
            // only one that leaves the board by more than a lift-and-place.
            place.y = sinf(.pi * k) * travel.lift
            travel.piece.node.position = SCNVector3(place.x, place.y, place.z)

            if k >= 1 {
                travel.piece.node.position = SCNVector3(travel.to.x, travel.to.y, travel.to.z)
                if travel.lit { apply(lit: false, to: travel.piece) }
                if let promotion = travel.promotion {
                    replaceGeometry(of: travel.piece, with: promotion)
                    travel.piece.kind = promotion
                    apply(lit: false, to: travel.piece)
                }
                travels.remove(at: index)
            }
        }

        for index in taken.indices.reversed() {
            taken[index].t += delta
            let take = taken[index]
            let k = min(1, take.t / take.span)

            // Lifted off the board and away, rather than sunk through it: a
            // piece disappearing downwards reads as a bug from a low camera.
            let scale = 1 - Self.easeIn(k)
            take.piece.node.scale = SCNVector3(scale, scale, scale)
            take.piece.node.position.y = SCNFloat(k * 0.35)
            take.piece.node.eulerAngles.y += SCNFloat(delta * 2.4)

            if k >= 1 {
                take.piece.node.isHidden = true
                take.piece.node.scale = SCNVector3(1, 1, 1)
                taken.remove(at: index)
            }
        }

        // The focus lags the move, so the light arrives with the piece rather
        // than ahead of it.
        focus = simd_mix(focus, focusTarget, SIMD3(repeating: min(1, delta * 2.6)))
    }

    // MARK: - Private

    private func start(_ piece: Piece, to square: Square, hop: Bool, lit: Bool, promotion: PieceKind?) {
        if lit { apply(lit: true, to: piece) }
        let from = piece.node.position
        travels.append(Travel(
            piece: piece,
            from: SIMD3(Float(from.x), Float(from.y), Float(from.z)),
            to: Self.position(of: square),
            span: hop ? 0.62 : 0.5,
            lift: hop ? 0.85 : 0.16,
            lit: lit,
            promotion: promotion,
            t: 0
        ))
    }

    private func clone(_ kind: PieceKind) -> SCNNode {
        // A clone shares its geometry with the prototype, so thirty-two pieces
        // are six meshes.
        prototypes[kind]!.clone()
    }

    private func replaceGeometry(of piece: Piece, with kind: PieceKind) {
        for child in piece.node.childNodes { child.removeFromParentNode() }
        for child in clone(kind).childNodes { piece.node.addChildNode(child) }
    }

    private func apply(lit: Bool, to piece: Piece) {
        let material = materials.material(for: piece.colour, lit: lit)
        for child in piece.node.childNodes {
            child.geometry?.materials = [material]
        }
    }

    private struct Placement {
        let square: Square
        let kind: PieceKind
        let colour: PieceColor
    }

    private static func startingPosition() -> [Placement] {
        let back: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        var out: [Placement] = []
        for file in 0..<8 {
            out.append(Placement(square: Square(file: file, rank: 0), kind: back[file], colour: .white))
            out.append(Placement(square: Square(file: file, rank: 1), kind: .pawn, colour: .white))
            out.append(Placement(square: Square(file: file, rank: 6), kind: .pawn, colour: .black))
            out.append(Placement(square: Square(file: file, rank: 7), kind: back[file], colour: .black))
        }
        return out
    }

    private static func easeInOut(_ t: Float) -> Float {
        t < 0.5 ? 4 * t * t * t : 1 - powf(-2 * t + 2, 3) / 2
    }

    private static func easeIn(_ t: Float) -> Float { t * t * t }
}

/// The two sets, and the warmed version each wears while it is moving.
///
/// Not a different piece in gold — the same piece, catching the light, which is
/// what a hand lifting it off the board would actually look like.
@MainActor
final class PieceMaterials {
    private let ivory = SCNMaterial()
    private let ebony = SCNMaterial()
    private let ivoryLit = SCNMaterial()
    private let ebonyLit = SCNMaterial()

    init() {
        for material in [ivory, ivoryLit] {
            material.lightingModel = .physicallyBased
            material.diffuse.contents = Colour.make(0xE6DFCD)
            material.roughness.contents = 0.36
            material.metalness.contents = 0.0
            material.clearCoat.contents = 0.55
            material.clearCoatRoughness.contents = 0.3
        }
        for material in [ebony, ebonyLit] {
            material.lightingModel = .physicallyBased
            material.diffuse.contents = Colour.make(0x11131A)
            material.roughness.contents = 0.3
            material.metalness.contents = 0.08
            material.clearCoat.contents = 0.75
            material.clearCoatRoughness.contents = 0.18
        }
        ivoryLit.emission.contents = Colour.make(0xD6A95F)
        ivoryLit.emission.intensity = 0.3
        ebonyLit.emission.contents = Colour.make(0xD6A95F)
        ebonyLit.emission.intensity = 0.55
    }

    func material(for colour: PieceColor, lit: Bool) -> SCNMaterial {
        if colour == .white { return lit ? ivoryLit : ivory }
        return lit ? ebonyLit : ebony
    }
}

#if os(macOS)
typealias SCNFloat = CGFloat
#else
typealias SCNFloat = Float
#endif
