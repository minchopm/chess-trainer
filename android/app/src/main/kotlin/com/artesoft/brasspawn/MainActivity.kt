package com.artesoft.brasspawn

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.artesoft.brasspawn.data.Strings
import com.artesoft.brasspawn.data.TrainingStore
import com.artesoft.brasspawn.ui.BrassPawnTheme
import com.artesoft.brasspawn.ui.Destination
import com.artesoft.brasspawn.ui.MenuScreen
import com.artesoft.brasspawn.ui.Navigator
import com.artesoft.brasspawn.ui.OnlineScreen
import com.artesoft.brasspawn.ui.PendingInvitation
import com.artesoft.brasspawn.ui.PlayScreen
import com.artesoft.brasspawn.ui.SettingsScreen
import com.artesoft.brasspawn.ui.AboutScreen
import com.artesoft.brasspawn.ui.Theatre
import com.artesoft.brasspawn.ui.training.EndgameScreen
import com.artesoft.brasspawn.ui.training.PositionalScreen
import com.artesoft.brasspawn.ui.training.ProgressScreen
import com.artesoft.brasspawn.ui.training.TacticsScreen

class MainActivity : ComponentActivity() {
    private val navigator = Navigator()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The activity is made again when the language changes (per-app language included), and its
        // configuration is the one to read: the application's can lag behind it.
        Strings.load(this, resources.configuration.locales)
        // Start decoding the training libraries in the background right away.
        TrainingStore.shared(this)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT),
        )
        handle(intent)
        setContent {
            BrassPawnTheme {
                Box(Modifier.fillMaxSize().background(Theatre.ink).windowInsetsPadding(WindowInsets.safeDrawing)) {
                    Root(navigator)
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handle(intent)
    }

    /**
     * An invitation link — https://brasspawn.com/play?i=CODE — goes to the
     * lobby with its code. Debug builds can also be started on a screen:
     * `--es screen play`.
     */
    private fun handle(intent: Intent?) {
        intent?.data?.takeIf { it.host == "brasspawn.com" }?.getQueryParameter("i")?.let { code ->
            if (code.length == 6 && code.all(Char::isLetterOrDigit)) {
                PendingInvitation.code = code.uppercase()
                navigator.reset(Destination.ONLINE)
            }
            return
        }
        if (!BuildConfig.INTERNAL_TOOLS) return
        val screen = intent?.getStringExtra("screen") ?: return
        val destination = when {
            screen.equals("endgame", ignoreCase = true) -> Destination.ENDGAMES
            else -> Destination.entries.firstOrNull { it.name.equals(screen, ignoreCase = true) }
        }
        destination?.let(navigator::reset)
    }
}

@Composable
private fun Root(navigator: Navigator) {
    BackHandler(enabled = navigator.canGoBack) { navigator.back() }
    when (navigator.current) {
        Destination.MENU -> MenuScreen(navigator)
        Destination.ONLINE -> OnlineScreen(navigator)
        Destination.PLAY -> PlayScreen(navigator)
        Destination.TACTICS -> TacticsScreen(navigator)
        Destination.POSITIONAL -> PositionalScreen(navigator)
        Destination.ENDGAMES -> EndgameScreen(navigator)
        Destination.PROGRESS -> ProgressScreen(navigator)
        Destination.SETTINGS -> SettingsScreen(navigator)
        Destination.ABOUT -> AboutScreen(navigator)
    }
}
