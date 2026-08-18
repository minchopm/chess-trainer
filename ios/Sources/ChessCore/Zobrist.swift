/// Zobrist hashing, used to detect threefold repetition.
///
/// The tables are filled from a fixed seed rather than a system random source:
/// a stored game must hash the same way in the next launch, or repetition
/// detection would silently stop working across sessions.
enum Zobrist {
    static let pieces: [[UInt64]] = {
        var generator = SplitMix64(seed: 0x9E3779B97F4A7C15)
        return (0..<12).map { _ in (0..<64).map { _ in generator.next() } }
    }()

    static let castling: [UInt64] = {
        var generator = SplitMix64(seed: 0xBF58476D1CE4E5B9)
        return (0..<16).map { _ in generator.next() }
    }()

    static let enPassantFile: [UInt64] = {
        var generator = SplitMix64(seed: 0x94D049BB133111EB)
        return (0..<8).map { _ in generator.next() }
    }()

    static let sideToMove: UInt64 = {
        var generator = SplitMix64(seed: 0x2545F4914F6CDD1D)
        return generator.next()
    }()

    @inlinable
    static func index(_ piece: Piece) -> Int { piece.color.rawValue * 6 + piece.kind.rawValue }
}

/// Small, fast, fully specified PRNG. Chosen over `SystemRandomNumberGenerator`
/// precisely because it is reproducible.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
