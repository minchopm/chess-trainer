package com.artesoft.brasspawn.engine

/** The JNI surface over `sfbridge.h` — see `app/src/main/cpp/engine_jni.cpp`. */
internal object StockfishNative {
    init {
        System.loadLibrary("brasspawn")
    }

    /** Called from Stockfish's search thread. */
    interface Listener {
        fun onInfo(
            depth: Int, selDepth: Int, multiPV: Int, scoreCp: Int, scoreMate: Int,
            isMate: Boolean, nodes: Long, timeMs: Long, pv: String,
        )

        fun onBestMove(bestMove: String, ponder: String)
    }

    external fun engineInfo(): String
    external fun create(): Long
    external fun destroy(handle: Long)
    external fun loadNetworks(handle: Long, big: String, small: String): Boolean
    external fun setOption(handle: Long, name: String, value: String)
    external fun newGame(handle: Long)
    external fun setPosition(handle: Long, fen: String): Boolean
    external fun go(handle: Long, depth: Int, movetimeMs: Int, listener: Listener)
    external fun stop(handle: Long)
    external fun waitForSearch(handle: Long)
}
