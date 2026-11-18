package com.artesoft.brasspawn.ui

import android.content.Context
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.sp
import com.artesoft.brasspawn.data.Strings

/**
 * The house style, carried over from the iOS app and the site.
 *
 * A dark theatre: near-black ground, ivory type, one warm light. Every colour
 * is named here so the whole app can be re-graded from one place.
 */
object Theatre {
    // Ground
    val ink = Color(0xFF05060A)
    val ink2 = Color(0xFF0A0C12)
    val ink3 = Color(0xFF10131B)
    val ink4 = Color(0xFF171B26)
    val shadow = Color(0xFF000000)
    val light = Color(0xFFFFFFFF)

    // Type
    val ivory = Color(0xFFE9E4D8)
    val ivoryDim = ivory.copy(alpha = 0.66f)
    /** The faintest ivory the app writes in. */
    val ivoryFaint = ivory.copy(alpha = 0.58f)

    // The one light in the room
    val brass = Color(0xFFD6A95F)
    val brassHot = Color(0xFFF0CD8E)
    val brassDeep = Color(0xFF8A6A2F)
    val brassGlow = brass.copy(alpha = 0.18f)

    // Hairlines
    val rule = ivory.copy(alpha = 0.12f)
    val ruleSoft = ivory.copy(alpha = 0.06f)

    // Verdicts, graded to sit in the same room as the brass.
    val good = Color(0xFF7FB069)
    val warn = Color(0xFFD9A441)
    val bad = Color(0xFFC96A5B)
}

/** The three faces of the app: a display serif, the system sans, and a mono for figures. */
class Faces(context: Context) {
    private val assets = context.assets

    private fun cormorant(weight: Int, italic: Boolean = false) = Font(
        path = if (italic) "fonts/CormorantGaramond-Italic.ttf" else "fonts/CormorantGaramond.ttf",
        assetManager = assets,
        weight = FontWeight(weight),
        style = if (italic) FontStyle.Italic else FontStyle.Normal,
        variationSettings = FontVariation.Settings(FontVariation.weight(weight)),
    )

    private fun mono(weight: Int) = Font(
        path = "fonts/JetBrainsMono.ttf",
        assetManager = assets,
        weight = FontWeight(weight),
        variationSettings = FontVariation.Settings(FontVariation.weight(weight)),
    )

    val serif = FontFamily(cormorant(400), cormorant(500), cormorant(600), cormorant(400, italic = true))
    val mono = FontFamily(mono(400), mono(500), mono(700))

    /** A title: the serif, as on the title screen. */
    fun display(size: Int, weight: FontWeight = FontWeight.Medium) =
        TextStyle(fontFamily = serif, fontSize = size.sp, fontWeight = weight, color = Theatre.ivory)

    /** A small capital label: wide tracking, as on every button of the iOS app. */
    fun label(size: Int = 11, color: Color = Theatre.ivoryDim) =
        TextStyle(fontSize = size.sp, fontWeight = FontWeight.SemiBold, letterSpacing = (size * 0.16f).sp, color = color)

    fun body(size: Int = 15, color: Color = Theatre.ivory, weight: FontWeight = FontWeight.Normal) =
        TextStyle(fontSize = size.sp, fontWeight = weight, color = color, lineHeight = (size * 1.4f).sp)

    fun figures(size: Int = 13, color: Color = Theatre.ivoryDim) =
        TextStyle(fontFamily = mono, fontSize = size.sp, color = color)
}

val LocalFaces = staticCompositionLocalOf<Faces> { error("No faces: wrap the content in BrassPawnTheme") }

@Composable
fun BrassPawnTheme(content: @Composable () -> Unit) {
    val context = LocalContext.current
    val faces = remember(context) { Faces(context.applicationContext) }
    val colors = darkColorScheme(
        primary = Theatre.brass,
        onPrimary = Theatre.ink,
        secondary = Theatre.brassHot,
        background = Theatre.ink,
        onBackground = Theatre.ivory,
        surface = Theatre.ink3,
        onSurface = Theatre.ivory,
        surfaceVariant = Theatre.ink4,
        onSurfaceVariant = Theatre.ivoryDim,
        outline = Theatre.rule,
        error = Theatre.bad,
    )
    val direction = if (Strings.isRightToLeft) LayoutDirection.Rtl else LayoutDirection.Ltr
    MaterialTheme(colorScheme = colors) {
        CompositionLocalProvider(LocalFaces provides faces, LocalLayoutDirection provides direction, content = content)
    }
}
