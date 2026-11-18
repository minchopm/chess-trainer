package com.artesoft.brasspawn.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.artesoft.brasspawn.data.t

/**
 * The first screen: the title over the photograph, one large way into a game,
 * and the training modes under it — the same order as the iOS app.
 */
@Composable
fun MenuScreen(navigator: Navigator) {
    val faces = LocalFaces.current
    BoxWithConstraints(Modifier.fillMaxSize().background(Theatre.ink)) {
        val isWide = maxWidth > maxHeight && maxWidth >= 600.dp
        if (isWide) {
            val artSize = minOf(maxHeight * 0.90f, maxWidth * 0.48f, 620.dp)
            Box(Modifier.fillMaxSize()) {
                Row(
                    Modifier.fillMaxSize().padding(horizontal = 32.dp, vertical = 18.dp),
                    horizontalArrangement = Arrangement.spacedBy(32.dp, Alignment.CenterHorizontally),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(Modifier.size(artSize), contentAlignment = Alignment.Center) {
                        rememberArt("art/pawn.png")?.let { art ->
                            Image(
                                art, contentDescription = null, contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(20.dp)),
                            )
                        }
                        Box(
                            Modifier.fillMaxSize().background(
                                Brush.verticalGradient(
                                    0f to Theatre.ink.copy(alpha = 0.72f),
                                    0.18f to Color.Transparent,
                                    0.80f to Color.Transparent,
                                    1f to Theatre.ink.copy(alpha = 0.82f),
                                )
                            )
                        )
                        Box(
                            Modifier.fillMaxSize().background(
                                Brush.horizontalGradient(
                                    0f to Theatre.ink.copy(alpha = 0.72f),
                                    0.18f to Color.Transparent,
                                    0.82f to Color.Transparent,
                                    1f to Theatre.ink.copy(alpha = 0.78f),
                                )
                            )
                        )
                    }
                    Column(
                        Modifier.widthIn(max = 480.dp).weight(1f, fill = false).fillMaxHeight(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                            SettingsGearButton { navigator.open(Destination.SETTINGS) }
                        }
                        Spacer(Modifier.weight(1f))
                        BasicText(t("menu.title", "Brass Pawn"), style = faces.display(52, FontWeight.Medium).copy(textAlign = TextAlign.Center))
                        Spacer(Modifier.height(6.dp))
                        BasicText(
                            t("menu.slug", "Play · Train · Watch").uppercase(),
                            style = faces.label(12, Theatre.brass).copy(letterSpacing = 4.sp, textAlign = TextAlign.Center),
                        )
                        Spacer(Modifier.height(28.dp))
                        MenuButtonsGrid(navigator)
                        Spacer(Modifier.weight(1f))
                    }
                }
            }
        } else {
            rememberArt("art/pawn.png")?.let { art ->
                Image(
                    art, contentDescription = null, contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxWidth().aspectRatio(0.92f).align(Alignment.TopCenter).padding(top = 96.dp),
                )
            }
            // The photograph fades into the ground above and below, so the type sits on black.
            Box(
                Modifier.fillMaxSize().background(
                    Brush.verticalGradient(
                        0f to Theatre.ink, 0.16f to Theatre.ink.copy(alpha = 0.55f), 0.34f to Color.Transparent,
                        0.5f to Theatre.ink.copy(alpha = 0.35f), 0.64f to Theatre.ink,
                    )
                )
            )
            Column(
                Modifier.fillMaxSize().padding(horizontal = 18.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Row(Modifier.fillMaxWidth().padding(top = 8.dp), horizontalArrangement = Arrangement.End) {
                    SettingsGearButton { navigator.open(Destination.SETTINGS) }
                }
                BasicText(t("menu.title", "Brass Pawn"), style = faces.display(46, FontWeight.Medium).copy(textAlign = TextAlign.Center))
                Spacer(Modifier.height(6.dp))
                BasicText(
                    t("menu.slug", "Play · Train · Watch").uppercase(),
                    style = faces.label(11, Theatre.brass).copy(letterSpacing = 4.sp, textAlign = TextAlign.Center),
                )
                Spacer(Modifier.weight(1f))
                MenuButtonsGrid(navigator)
                Spacer(Modifier.height(18.dp))
            }
        }
    }
}

@Composable
private fun SettingsGearButton(onClick: () -> Unit) {
    Box(
        Modifier
            .size(44.dp).clip(CircleShape).background(Theatre.ink3.copy(alpha = 0.8f))
            .border(1.dp, Theatre.rule, CircleShape)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { contentDescription = t("settings.settings", "Settings") },
        contentAlignment = Alignment.Center,
    ) { BrassIcon("gearshape", 22.dp) }
}

@Composable
private fun MenuButtonsGrid(navigator: Navigator) {
    Column(Modifier.widthIn(max = 520.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        PlayButton { navigator.open(Destination.PLAY) }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            MenuTile(t("online.playOnline", "Play online"), "bolt.horizontal.circle", Modifier.weight(1f)) { navigator.open(Destination.ONLINE) }
            MenuTile(t("progress.tactics", "Tactics"), "target", Modifier.weight(1f)) { navigator.open(Destination.TACTICS) }
            MenuTile(t("progress.positional", "Positional"), "square.grid.3x3.middle.filled", Modifier.weight(1f)) { navigator.open(Destination.POSITIONAL) }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            MenuTile(t("progress.endgames", "Endgames"), "flag.checkered", Modifier.weight(1f)) { navigator.open(Destination.ENDGAMES) }
            MenuTile(t("progress.progress", "Progress"), "chart.line.uptrend.xyaxis", Modifier.weight(1f)) { navigator.open(Destination.PROGRESS) }
            MenuTile(t("about.about", "About"), "doc.text", Modifier.weight(1f)) { navigator.open(Destination.ABOUT) }
        }
    }
}

@Composable
private fun PlayButton(onClick: () -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Row(
        Modifier
            .fillMaxWidth().height(84.dp).clip(shape)
            .background(Brush.verticalGradient(listOf(Theatre.ink4, Theatre.ink2)))
            .border(1.dp, Theatre.brass.copy(alpha = 0.55f), shape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier.size(58.dp).clip(CircleShape).background(Theatre.ink).border(1.5.dp, Theatre.brass, CircleShape),
            contentAlignment = Alignment.Center,
        ) { BrassIcon("chess", 38.dp) }
        Spacer(Modifier.width(20.dp))
        BasicText(
            t("progress.play", "Play").uppercase(),
            style = LocalFaces.current.label(26, Theatre.ivory).copy(fontWeight = FontWeight.Medium, letterSpacing = 6.sp),
        )
    }
}

@Composable
private fun MenuTile(title: String, icon: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val shape = RoundedCornerShape(14.dp)
    Column(
        modifier
            .height(78.dp).clip(shape)
            .background(Brush.verticalGradient(listOf(Theatre.ink4, Theatre.ink2)))
            .border(1.dp, Theatre.rule, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        BrassIcon(icon, 26.dp)
        Spacer(Modifier.height(8.dp))
        Label(title, size = 10, color = Theatre.ivory, align = TextAlign.Center)
    }
}
