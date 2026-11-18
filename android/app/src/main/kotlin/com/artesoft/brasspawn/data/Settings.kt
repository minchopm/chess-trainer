package com.artesoft.brasspawn.data

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/** What the player has chosen about how the app looks and sounds. Kept on the device. */
class Settings private constructor(context: Context) {
    private val preferences = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    var sounds by mutableStateOf(preferences.getBoolean("sounds", true))
        private set
    var coordinates by mutableStateOf(preferences.getBoolean("coordinates", true))
        private set
    /** Which stain the dark side of the photographed set wears: black, claret, emerald or sapphire. */
    var darkSet by mutableStateOf(preferences.getString("darkSet", "black") ?: "black")
        private set
    var coaching by mutableStateOf(preferences.getBoolean("coaching", true))
        private set

    fun chooseSounds(on: Boolean) { sounds = on; preferences.edit().putBoolean("sounds", on).apply() }
    fun chooseCoordinates(on: Boolean) { coordinates = on; preferences.edit().putBoolean("coordinates", on).apply() }
    fun chooseDarkSet(name: String) { darkSet = name; preferences.edit().putString("darkSet", name).apply() }
    fun chooseCoaching(on: Boolean) { coaching = on; preferences.edit().putBoolean("coaching", on).apply() }

    companion object {
        val darkSets = listOf("black", "claret", "emerald", "sapphire")

        @Volatile private var instance: Settings? = null
        fun shared(context: Context): Settings =
            instance ?: synchronized(this) { instance ?: Settings(context.applicationContext).also { instance = it } }
    }
}
