package com.artesoft.brasspawn.chess

/**
 * Zobrist hashing, used to detect threefold repetition.
 *
 * The tables are filled from a fixed seed rather than a system random source:
 * a stored game must hash the same way in the next launch, or repetition
 * detection would silently stop working across sessions.
 *
 * The values are the same 64 bits the Swift tables hold; they are kept in a
 * signed `Long` here, which changes how they print and nothing else.
 */
internal object Zobrist {
    val pieces: Array<LongArray> = run {
        val generator = SplitMix64(0x9E3779B97F4A7C15uL.toLong())
        Array(12) { LongArray(64) { generator.next() } }
    }

    val castling: LongArray = run {
        val generator = SplitMix64(0xBF58476D1CE4E5B9uL.toLong())
        LongArray(16) { generator.next() }
    }

    val enPassantFile: LongArray = run {
        val generator = SplitMix64(0x94D049BB133111EBuL.toLong())
        LongArray(8) { generator.next() }
    }

    val sideToMove: Long = SplitMix64(0x2545F4914F6CDD1DL).next()

    fun index(piece: Piece): Int = piece.color.ordinal * 6 + piece.kind.ordinal
}

/**
 * Small, fast, fully specified PRNG. Chosen over a system random source
 * precisely because it is reproducible.
 */
internal class SplitMix64(seed: Long) {
    private var state: Long = seed

    fun next(): Long {
        state += 0x9E3779B97F4A7C15uL.toLong()
        var z = state
        z = (z xor (z ushr 30)) * 0xBF58476D1CE4E5B9uL.toLong()
        z = (z xor (z ushr 27)) * 0x94D049BB133111EBuL.toLong()
        return z xor (z ushr 31)
    }
}
