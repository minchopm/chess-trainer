package com.artesoft.brasspawn.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.BuildConfig
import com.artesoft.brasspawn.data.Settings
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.online.OnlineModel

/** A switch in the house style: brass when on. */
@Composable
fun Toggle(title: String, on: Boolean, note: String? = null, onChange: (Boolean) -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(role = Role.Switch) { onChange(!on) }.padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Body(title, size = 15)
            if (note != null) Body(note, size = 12, color = Theatre.ivoryFaint)
        }
        Spacer(Modifier.width(12.dp))
        val shape = RoundedCornerShape(50)
        Box(
            Modifier.size(width = 48.dp, height = 28.dp).clip(shape)
                .background(if (on) Theatre.brassDeep else Theatre.ink2)
                .border(1.dp, if (on) Theatre.brass else Theatre.rule, shape)
                .padding(3.dp),
            contentAlignment = if (on) Alignment.CenterEnd else Alignment.CenterStart,
        ) { Box(Modifier.size(20.dp).clip(RoundedCornerShape(50)).background(if (on) Theatre.brassHot else Theatre.ivoryDim)) }
    }
}

@Composable
fun SettingsScreen(navigator: Navigator) {
    val context = LocalContext.current
    val settings = remember { Settings.shared(context) }
    val online = remember { OnlineModel.shared(context) }
    var deleting by remember { mutableStateOf(false) }

    Screen(title = t("settings.settings", "Settings"), onBack = navigator::back) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Panel(Modifier.fillMaxWidth()) {
                Label(t("settings.pieces", "Pieces"))
                Spacer(Modifier.height(10.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    val names = mapOf(
                        "black" to t("appearance.pieces.ebony", "Ivory & ebony"),
                        "claret" to t("appearance.pieces.claret", "Ivory & claret"),
                        "emerald" to t("appearance.pieces.emerald", "Ivory & emerald"),
                        "sapphire" to t("appearance.pieces.sapphire", "Ivory & sapphire"),
                    )
                    for (set in Settings.darkSets) {
                        val chosen = settings.darkSet == set
                        val shape = RoundedCornerShape(12.dp)
                        Box(
                            Modifier.weight(1f).clip(shape)
                                .background(if (chosen) Theatre.brassGlow else Theatre.ink2)
                                .border(1.dp, if (chosen) Theatre.brass else Theatre.rule, shape)
                                .clickable(role = Role.RadioButton) { settings.chooseDarkSet(set) }
                                .semantics { contentDescription = names.getValue(set) }
                                .padding(6.dp),
                            contentAlignment = Alignment.Center,
                        ) { rememberArt("pieces/$set-knight.png")?.let { Image(it, null, Modifier.size(54.dp)) } }
                    }
                }
                Spacer(Modifier.height(8.dp))
                Toggle(t("settings.showFilesAndRanks", "Show files and ranks"), settings.coordinates, onChange = settings::chooseCoordinates)
                Toggle(t("settings.soundsOn", "Play sounds"), settings.sounds, onChange = settings::chooseSounds)
            }

            Panel(Modifier.fillMaxWidth()) {
                Label(t("settings.online", "Online play"))
                Spacer(Modifier.height(10.dp))
                if (online.account.isEmpty()) {
                    Body(t("settings.android.notSignedIn", "Open Play online to choose a nickname."), size = 13, color = Theatre.ivoryDim)
                } else {
                    var name by rememberSaveable(online.alias) { mutableStateOf(online.alias) }
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        TextInput(name, { name = it.take(20) }, t("settings.android.nickname", "Nickname"), Modifier.weight(1f))
                        ChipButton(t("settings.android.save", "Save"), enabled = name.trim().length >= 3 && name.trim() != online.alias) {
                            online.chooseNickname(name)
                        }
                    }
                    Spacer(Modifier.height(14.dp))
                    ChipButton(t("online.android.deleteAccount", "Delete online account")) { deleting = true }
                    Spacer(Modifier.height(6.dp))
                    Body(t("online.android.deleteAccountNote", "Removes your nickname, ratings and friends from the game service. It cannot be undone."), size = 12, color = Theatre.ivoryFaint)
                }
            }

            ChipButton(t("settings.about", "About & licence"), Modifier.fillMaxWidth(), icon = "doc.text") { navigator.open(Destination.ABOUT) }
        }
    }

    if (deleting) {
        ConfirmDialog(
            title = t("online.android.deleteAccount", "Delete online account"),
            message = t("online.android.deleteAccountNote", "Removes your nickname, ratings and friends from the game service. It cannot be undone."),
            confirm = t("online.android.delete", "Delete"), dismiss = t("common.cancel", "Cancel"),
            onConfirm = { deleting = false; online.deleteAccount() }, onDismiss = { deleting = false },
        )
    }
}

@Composable
fun AboutScreen(navigator: Navigator) {
    val context = LocalContext.current
    var licence by remember { mutableStateOf<String?>(null) }
    fun open(url: String) = runCatching {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    Screen(title = t("about.about", "About"), onBack = { if (licence != null) licence = null else navigator.back() }) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            val shown = licence
            if (shown != null) {
                androidx.activity.compose.BackHandler { licence = null }
                Body(shown, size = 12, style = LocalFaces.current.figures(11, Theatre.ivoryDim))
                return@Column
            }
            Panel(Modifier.fillMaxWidth()) {
                BasicText(t("about.brassPawn", "Brass Pawn"), style = LocalFaces.current.display(30))
                Body(t("about.version", "Version %@", BuildConfig.VERSION_NAME), size = 13, color = Theatre.ivoryFaint)
                Spacer(Modifier.height(8.dp))
                Body(t("about.android.intro", "Tactics, positional judgement, endgame technique and coached play, with the engine running on the device itself."), size = 14, color = Theatre.ivoryDim)
            }
            Panel(Modifier.fillMaxWidth()) {
                Label(t("about.licence", "Licence"))
                Spacer(Modifier.height(6.dp))
                Body(t("about.thisApplicationIsFreeSoftware", "This application is free software, licensed under the GNU Affero General Public License version 3 or later."), size = 14)
                Spacer(Modifier.height(6.dp))
                Body(t("about.android.includes", "It includes Stockfish, which is GPLv3. Because it is linked into the app, the whole application carries AGPLv3 — and its complete source is published."), size = 13, color = Theatre.ivoryDim)
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ChipButton(t("about.gnuAgplV3", "GNU AGPL v3"), Modifier.weight(1f)) { licence = read(context, "legal/AGPL.txt") }
                    ChipButton(t("about.credits", "Credits"), Modifier.weight(1f)) { licence = read(context, "legal/NOTICE.txt") }
                }
                Spacer(Modifier.height(10.dp))
                ChipButton(t("about.android.source", "Source code"), Modifier.fillMaxWidth(), icon = "arrow.up.right") { open("https://github.com/minchopm/chess-trainer") }
            }
            Panel(Modifier.fillMaxWidth()) {
                Label(t("about.privacy", "Privacy"))
                Spacer(Modifier.height(6.dp))
                Body(t("about.android.privacy", "Apart from online play, the app collects nothing and sends nothing about you."), size = 13, color = Theatre.ivoryDim)
                Spacer(Modifier.height(8.dp))
                Body(t("about.android.online", "Online play is the exception."), size = 13, color = Theatre.ivoryDim)
                Spacer(Modifier.height(12.dp))
                ChipButton("brasspawn.com/privacy", Modifier.fillMaxWidth()) { open("https://brasspawn.com/privacy") }
            }
        }
    }
}

private fun read(context: android.content.Context, path: String): String =
    runCatching { context.assets.open(path).bufferedReader().use { it.readText() } }.getOrDefault("")
