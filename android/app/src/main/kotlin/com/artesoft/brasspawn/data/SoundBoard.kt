package com.artesoft.brasspawn.data

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import com.artesoft.brasspawn.chess.Move
import com.artesoft.brasspawn.chess.Position

/**
 * The sounds of a move, the same six recordings as the iOS app: a piece set
 * down, a capture, castling, a promotion, check, and the end of the game.
 */
class SoundBoard private constructor(context: Context) {
    private val settings = Settings.shared(context)
    private val pool = SoundPool.Builder()
        .setMaxStreams(3)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()
    private val sounds: Map<String, Int> = listOf("move", "capture", "castle", "promote", "check", "gameEnd").mapNotNull { name ->
        runCatching { context.assets.openFd("sounds/$name.wav").use { name to pool.load(it, 1) } }.getOrNull()
    }.toMap()

    /** The sound of `move`, having led to `resulting`. One sound: the most telling one. */
    fun play(move: Move, captured: Boolean, resulting: Position) {
        if (!settings.sounds) return
        val name = when {
            resulting.isCheckmate || resulting.isDraw -> "gameEnd"
            resulting.isCheck -> "check"
            move.promotion != null -> "promote"
            move.isCastle -> "castle"
            captured || move.isCapture -> "capture"
            else -> "move"
        }
        sounds[name]?.let { pool.play(it, 1f, 1f, 1, 0, 1f) }
    }

    fun gameEnd() {
        if (settings.sounds) sounds["gameEnd"]?.let { pool.play(it, 1f, 1f, 1, 0, 1f) }
    }

    companion object {
        @Volatile private var instance: SoundBoard? = null
        fun shared(context: Context): SoundBoard =
            instance ?: synchronized(this) { instance ?: SoundBoard(context.applicationContext).also { instance = it } }
    }
}
