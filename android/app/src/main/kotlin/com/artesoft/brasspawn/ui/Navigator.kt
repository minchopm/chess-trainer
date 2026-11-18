package com.artesoft.brasspawn.ui

import androidx.compose.runtime.mutableStateListOf

/** Where in the app the player is. */
enum class Destination { MENU, PLAY, ONLINE, TACTICS, POSITIONAL, ENDGAMES, PROGRESS, SETTINGS, ABOUT }

/** The stack of screens. The first is always the menu. */
class Navigator {
    private val stack = mutableStateListOf(Destination.MENU)

    val current: Destination get() = stack.last()
    val canGoBack: Boolean get() = stack.size > 1

    fun open(destination: Destination) {
        if (stack.last() != destination) stack.add(destination)
    }

    fun back() {
        if (stack.size > 1) stack.removeAt(stack.lastIndex)
    }

    /** Straight to a screen from outside — an invitation link — over the menu alone. */
    fun reset(to: Destination) {
        stack.clear()
        stack.add(Destination.MENU)
        if (to != Destination.MENU) stack.add(to)
    }
}
