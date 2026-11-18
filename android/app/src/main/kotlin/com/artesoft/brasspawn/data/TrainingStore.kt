package com.artesoft.brasspawn.data

import android.content.Context
import android.util.AtomicFile
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.artesoft.brasspawn.training.ContentLibrary
import com.artesoft.brasspawn.training.TrainingProgress
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException

/**
 * The library and the player's progress: the one holder of both, as `AppModel`
 * is on iOS.
 *
 * The five libraries are read out of the APK once, off the main thread — the
 * tactics alone are three and a half megabytes — and kept for the life of the
 * process. Progress is one JSON file in the app's own directory, in the shape
 * the iPhone app writes, read when the store is made and written again after
 * every change.
 *
 * Everything a screen reads is Compose state, so a screen that shows a rating
 * shows the new one the moment a puzzle is recorded. Change progress from the
 * main thread, through [update].
 */
class TrainingStore private constructor(context: Context) {
    private val assets = context.assets
    private val file = File(context.filesDir, FILE_NAME)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    var library by mutableStateOf(ContentLibrary())
        private set

    /**
     * False until the data files have been read. Screens need it to tell "no
     * puzzles in this build" from "the puzzles have not arrived yet", which
     * look the same from an empty list.
     */
    var isLibraryLoaded by mutableStateOf(false)
        private set

    var progress by mutableStateOf(load())
        private set

    /** What is waiting to be written. Only the latest matters: each is the whole file. */
    private val pending = Channel<TrainingProgress>(Channel.CONFLATED)

    init {
        scope.launch {
            library = withContext(Dispatchers.Default) {
                ContentLibrary.load { name ->
                    try {
                        assets.open("data/$name").buffered()
                    } catch (_: IOException) {
                        null
                    }
                }
            }
            isLibraryLoaded = true
        }
        // One writer, so two saves can never interleave and the last one asked for is the last one written.
        scope.launch(Dispatchers.IO) {
            for (snapshot in pending) write(snapshot)
        }
    }

    /**
     * Change the progress and save it: `store.update { it.record(...) }`. The
     * progress is a value, so the change is whatever the function hands back.
     */
    fun update(change: (TrainingProgress) -> TrainingProgress) {
        val next = change(progress)
        if (next == progress) return
        progress = next
        pending.trySend(next)
    }

    fun resetProgress() {
        progress = TrainingProgress()
        pending.trySend(progress)
    }

    /**
     * The file as it stands, or a fresh start. A file that cannot be read as
     * progress — cut short, or not JSON at all — is set aside rather than
     * left to fail every launch, and rather than deleted: it is somebody's
     * history, and one copy of it is kept beside the new file.
     */
    private fun load(): TrainingProgress {
        val store = AtomicFile(file)
        val text = try {
            // AtomicFile puts back the last complete file if a write was cut short.
            store.readFully().toString(Charsets.UTF_8)
        } catch (_: IOException) {
            return TrainingProgress()
        }
        TrainingProgress.decodeOrNull(text)?.let { return it }
        Log.w(TAG, "progress.json could not be read; starting afresh and keeping it as $CORRUPT_NAME")
        runCatching {
            val aside = File(file.parentFile, CORRUPT_NAME)
            aside.delete()
            if (!file.renameTo(aside)) file.delete()
        }
        return TrainingProgress()
    }

    /** Written whole to a new file and renamed over the old one, so a crash mid-write costs nothing. */
    private fun write(snapshot: TrainingProgress) {
        val store = AtomicFile(file)
        val text = try {
            snapshot.encode()
        } catch (failure: Exception) {
            Log.w(TAG, "progress could not be encoded", failure)
            return
        }
        var stream: java.io.FileOutputStream? = null
        try {
            stream = store.startWrite()
            stream.write(text.toByteArray(Charsets.UTF_8))
            store.finishWrite(stream)
        } catch (failure: IOException) {
            stream?.let(store::failWrite)
            Log.w(TAG, "progress could not be saved", failure)
        }
    }

    companion object {
        private const val TAG = "BrassPawn"
        private const val FILE_NAME = "progress.json"
        private const val CORRUPT_NAME = "progress.corrupt.json"

        @Volatile private var instance: TrainingStore? = null

        fun shared(context: Context): TrainingStore =
            instance ?: synchronized(this) { instance ?: TrainingStore(context.applicationContext).also { instance = it } }
    }
}
