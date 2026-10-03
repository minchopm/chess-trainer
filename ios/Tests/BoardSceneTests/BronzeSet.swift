import AppKit
import ChessCore
import SceneKit
import Testing
@testable import BoardScene

@Suite("brass and bronze set")
@MainActor
struct BronzeSet {
    @Test("rook pedestal is circular")
    func roundFoot() throws {
        let node = TurnedPieces.node(for: .rook, style: .bronze)
        var points: [SIMD3<Float>] = []
        node.enumerateHierarchy { child, _ in
            for source in child.geometry?.sources(for: .vertex) ?? [] {
                source.data.withUnsafeBytes { raw in
                    for i in 0..<source.vectorCount {
                        let offset = i * source.dataStride + source.dataOffset
                        let x = raw.loadUnaligned(fromByteOffset: offset, as: Float.self)
                        let y = raw.loadUnaligned(fromByteOffset: offset + 4, as: Float.self)
                        let z = raw.loadUnaligned(fromByteOffset: offset + 8, as: Float.self)
                        if y < 0.15 { points.append(SIMD3(x, y, z)) }
                    }
                }
            }
        }
        let radius = try #require(points.map { hypot($0.x, $0.z) }.max())
        #expect(radius > 0.3 && radius < 0.5)
        let ring = points.filter { abs(hypot($0.x, $0.z) - radius) < 0.0001 }
        let angles = Set(ring.map { Int((atan2($0.z, $0.x) * 1000).rounded()) })
        #expect(angles.count >= 48)
    }

    @Test("render", .enabled(if: ProcessInfo.processInfo.environment["RENDER_BRONZE"] != nil))
    func render() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let stage = Stage(quality: .high, style: .bronze, playable: true)
        stage.board.reset()
        var camera = OrbitCamera()
        camera.azimuth = -0.72
        camera.elevation = 0.55
        camera.fit(aspect: 1)
        let eye = camera.eye(clock: 0), up = camera.up()
        stage.cameraNode.position = SCNVector3(eye.x, eye.y, eye.z)
        stage.cameraNode.look(at: SCNVector3(camera.target.x, camera.target.y, camera.target.z),
                                  up: SCNVector3(up.x, up.y, up.z), localFront: SCNVector3(0, 0, -1))
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = stage.scene
        renderer.pointOfView = stage.cameraNode
        let image = renderer.snapshot(atTime: 0, with: NSSize(width: 1200, height: 1200),
                                      antialiasingMode: .multisampling4X)
        let data = try #require(image.tiffRepresentation)
        let rep = try #require(NSBitmapImageRep(data: data))
        let png = try #require(rep.representation(using: .png, properties: [:]))
        let path = try #require(ProcessInfo.processInfo.environment["BRONZE_PREVIEW_PATH"])
        try png.write(to: URL(fileURLWithPath: path))
    }
}
