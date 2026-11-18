package com.artesoft.brasspawn.engine

import android.content.Context
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import java.io.File

/**
 * Stockfish 18, in process: the same sources and the same C bridge as the iOS
 * app, behind the same interface.
 *
 * A UCI engine holds exactly one position and one search, so every search
 * goes through one mutex: serialising access is a correctness requirement,
 * not an optimisation.
 */
class StockfishEngine private constructor(private val handle: Long) {
    private val gate = Mutex()

    val name: String = StockfishNative.engineInfo().substringBefore(" by ")

    suspend fun newGame() = gate.withLock {
        withContext(Dispatchers.Default) { StockfishNative.newGame(handle) }
    }

    /**
     * Search a position. Giving both a depth and a time cap means "this deep,
     * but never longer than this".
     */
    suspend fun analyse(fen: String, depth: Int = 14, movetimeMs: Int = 0, multiPV: Int = 1): Analysis =
        gate.withLock { search(fen, depth, movetimeMs, multiPV, elo = null) }

    suspend fun analyse(fen: String, budget: SearchBudget, multiPV: Int = 1): Analysis =
        analyse(fen, budget.depth, budget.movetimeMs, multiPV)

    /**
     * Pick a move at a limited strength, using Stockfish's own limiter rather
     * than a shallow search — it plays far more like a human of that rating.
     */
    suspend fun chooseMove(fen: String, elo: Int? = null, depth: Int = 12, movetimeMs: Int = 0): String? =
        gate.withLock { search(fen, depth, movetimeMs, 1, elo).bestMove }

    suspend fun chooseMove(fen: String, elo: Int?, budget: SearchBudget): String? =
        chooseMove(fen, elo, budget.depth, budget.movetimeMs)

    /** Cut the current search short. Safe to call when nothing is running. */
    fun stop() = StockfishNative.stop(handle)

    private suspend fun search(fen: String, depth: Int, movetimeMs: Int, multiPV: Int, elo: Int?): Analysis =
        withContext(Dispatchers.Default) {
            StockfishNative.setOption(handle, "MultiPV", multiPV.toString())
            if (elo != null) {
                StockfishNative.setOption(handle, "UCI_LimitStrength", "true")
                StockfishNative.setOption(handle, "UCI_Elo", elo.coerceIn(1320, 3190).toString())
            } else {
                StockfishNative.setOption(handle, "UCI_LimitStrength", "false")
            }
            if (!StockfishNative.setPosition(handle, fen)) throw EngineException("The engine rejected this position: $fen")

            val lines = HashMap<Int, EngineLine>()
            val done = CompletableDeferred<String?>()
            StockfishNative.go(handle, depth, movetimeMs, object : StockfishNative.Listener {
                override fun onInfo(
                    depth: Int, selDepth: Int, multiPV: Int, scoreCp: Int, scoreMate: Int,
                    isMate: Boolean, nodes: Long, timeMs: Long, pv: String,
                ) {
                    val moves = pv.split(' ').filter { it.isNotEmpty() }
                    if (moves.isEmpty()) return
                    val score = if (isMate) EngineScore.Mate(scoreMate) else EngineScore.Centipawns(scoreCp)
                    synchronized(lines) { lines[multiPV] = EngineLine(multiPV, depth, score, moves) }
                }

                override fun onBestMove(bestMove: String, ponder: String) {
                    done.complete(bestMove.takeUnless { it.isEmpty() || it == "(none)" })
                }
            })

            // A search that overruns its budget is stopped. Stockfish honours
            // movetime itself and this should never fire — but a player staring
            // at a board has no way to tell a long think from a hang.
            val best = try {
                withTimeout(ceilingMs(movetimeMs).toLong()) { done.await() }
            } catch (_: TimeoutCancellationException) {
                StockfishNative.stop(handle)
                done.await()
            } catch (cancelled: kotlinx.coroutines.CancellationException) {
                // The asker went away: stop, and leave the engine idle for the next one.
                StockfishNative.stop(handle)
                StockfishNative.waitForSearch(handle)
                throw cancelled
            }
            StockfishNative.waitForSearch(handle)
            if (elo != null) StockfishNative.setOption(handle, "UCI_LimitStrength", "false")
            val ordered = synchronized(lines) { lines.values.sortedBy { it.rank } }
            Analysis(ordered, best)
        }

    companion object {
        /** The longest any one search may run, whatever it was asked for. */
        private const val HARD_CEILING_MS = 10_000

        private fun ceilingMs(movetimeMs: Int): Int =
            if (movetimeMs <= 0) HARD_CEILING_MS else minOf(movetimeMs + 1_500, HARD_CEILING_MS)

        @Volatile private var shared: StockfishEngine? = null
        private val opening = Mutex()

        /**
         * The app's one engine. The first call copies the two networks out of
         * the APK — Stockfish reads them from files — which takes a few
         * seconds once, on first launch after an install or update.
         */
        suspend fun shared(context: Context, onProgress: (Float) -> Unit = {}): StockfishEngine {
            shared?.let { return it }
            return opening.withLock {
                shared ?: withContext(Dispatchers.IO) {
                    val networks = Networks.install(context.applicationContext, onProgress)
                    val handle = StockfishNative.create()
                    if (!StockfishNative.loadNetworks(handle, networks.big.path, networks.small.path)) {
                        StockfishNative.destroy(handle)
                        throw EngineException("The Stockfish neural network could not be read at ${networks.big.path}.")
                    }
                    val threads = (Runtime.getRuntime().availableProcessors() - 1).coerceIn(1, 4)
                    StockfishNative.setOption(handle, "Threads", threads.toString())
                    StockfishNative.setOption(handle, "Hash", "64")
                    StockfishEngine(handle).also { shared = it }
                }
            }
        }
    }
}

/** The two networks, as files Stockfish can open. */
internal object Networks {
    class Files(val big: File, val small: File)

    fun install(context: Context, onProgress: (Float) -> Unit): Files {
        val names = context.assets.list("networks").orEmpty().filter { it.endsWith(".nnue") }
        if (names.size < 2) throw EngineException("The engine networks are missing from this build.")
        val dir = File(context.noBackupFilesDir, "networks").apply { mkdirs() }
        // A network from an earlier build has a different name: remove it.
        dir.listFiles()?.filter { it.name !in names }?.forEach { it.delete() }

        val sizes = names.associateWith { name -> context.assets.openFd("networks/$name").use { it.length } }
        val total = sizes.values.sum().coerceAtLeast(1)
        var copied = 0L
        for (name in names) {
            val target = File(dir, name)
            val size = sizes.getValue(name)
            if (target.length() == size) {
                copied += size
                onProgress(copied.toFloat() / total)
                continue
            }
            val partial = File(dir, "$name.part")
            context.assets.open("networks/$name").use { input ->
                partial.outputStream().use { output ->
                    val buffer = ByteArray(1 shl 20)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        output.write(buffer, 0, read)
                        copied += read
                        onProgress(copied.toFloat() / total)
                    }
                }
            }
            if (!partial.renameTo(target)) throw EngineException("Could not store the engine network $name.")
        }
        val files = names.map { File(dir, it) }.sortedByDescending { it.length() }
        return Files(big = files[0], small = files[1])
    }
}
