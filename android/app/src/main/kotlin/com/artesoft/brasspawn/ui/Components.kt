package com.artesoft.brasspawn.ui

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import java.util.concurrent.ConcurrentHashMap

/** Images that ship in the APK's assets: the brass icons, the pieces, the board's wood. */
object Art {
    private val cache = ConcurrentHashMap<String, ImageBitmap>()

    fun load(context: android.content.Context, path: String): ImageBitmap? =
        cache[path] ?: runCatching {
            context.assets.open(path).use { BitmapFactory.decodeStream(it) }.asImageBitmap()
        }.getOrNull()?.also { cache[path] = it }
}

@Composable
fun rememberArt(path: String): ImageBitmap? {
    val context = LocalContext.current.applicationContext
    return remember(path) { Art.load(context, path) }
}

/** One of the brass icons, named as the SF Symbol it stands in for on iOS. */
@Composable
fun BrassIcon(name: String, size: Dp, modifier: Modifier = Modifier) {
    val image = rememberArt("icons/$name.png")
    if (image != null) Image(image, contentDescription = null, modifier = modifier.size(size))
    else Spacer(modifier.size(size))
}

@Composable
fun Label(text: String, modifier: Modifier = Modifier, size: Int = 11, color: Color = Theatre.ivoryDim, align: TextAlign? = null) {
    BasicText(
        text.uppercase(), modifier,
        style = LocalFaces.current.label(size, color).let { if (align != null) it.copy(textAlign = align) else it },
        maxLines = 1, overflow = TextOverflow.Ellipsis,
    )
}

@Composable
fun Body(
    text: String, modifier: Modifier = Modifier, size: Int = 15, color: Color = Theatre.ivory,
    style: TextStyle? = null, maxLines: Int = Int.MAX_VALUE, align: TextAlign? = null,
) {
    val base = style ?: LocalFaces.current.body(size, color)
    BasicText(text, modifier, style = if (align != null) base.copy(textAlign = align) else base, maxLines = maxLines, overflow = TextOverflow.Ellipsis)
}

private val panelShape = RoundedCornerShape(14.dp)

/** The card everything sits on: a shade above the ground, with a hairline round it. */
@Composable
fun Panel(modifier: Modifier = Modifier, padding: PaddingValues = PaddingValues(14.dp), content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier
            .clip(panelShape)
            .background(Brush.verticalGradient(listOf(Theatre.ink4, Theatre.ink3)))
            .border(1.dp, Theatre.rule, panelShape)
            .padding(padding),
        content = content,
    )
}

/** A bordered button with a small capital label; `primary` lights it in brass. */
@Composable
fun ChipButton(
    title: String, modifier: Modifier = Modifier, primary: Boolean = false, enabled: Boolean = true,
    icon: String? = null, onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        modifier
            .heightIn(min = 44.dp)
            .alpha(if (enabled) 1f else 0.4f)
            .clip(shape)
            .background(if (primary) Theatre.brassGlow else Theatre.ink3)
            .border(1.dp, if (primary) Theatre.brass.copy(alpha = 0.7f) else Theatre.rule, shape)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (icon != null) {
            BrassIcon(icon, 18.dp)
            Spacer(Modifier.width(8.dp))
        }
        Label(title, color = if (primary) Theatre.brassHot else Theatre.ivory, size = 12)
    }
}

/** The round button at the top of every screen but the first. */
@Composable
fun BackButton(description: String, onClick: () -> Unit) {
    Box(
        Modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(Theatre.ink3)
            .border(1.dp, Theatre.rule, CircleShape)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { contentDescription = description },
        contentAlignment = Alignment.Center,
    ) { BrassIcon("chevron.left", 18.dp) }
}

/** One of a row of choices: the chosen one is lit. */
@Composable
fun Segmented(options: List<String>, selected: Int, modifier: Modifier = Modifier, onSelect: (Int) -> Unit) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        modifier
            .clip(shape)
            .background(Theatre.ink2)
            .border(1.dp, Theatre.rule, shape)
            .padding(3.dp),
    ) {
        options.forEachIndexed { index, option ->
            val chosen = index == selected
            val inner = RoundedCornerShape(8.dp)
            Box(
                Modifier
                    .weight(1f)
                    .heightIn(min = 36.dp)
                    .clip(inner)
                    .background(if (chosen) Theatre.brassGlow else Color.Transparent)
                    .then(if (chosen) Modifier.border(1.dp, Theatre.brass.copy(alpha = 0.6f), inner) else Modifier)
                    .clickable(role = Role.Tab) { onSelect(index) }
                    .padding(horizontal = 8.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Body(option, size = 13, color = if (chosen) Theatre.brassHot else Theatre.ivoryDim, maxLines = 1)
            }
        }
    }
}

/** The row of actions under a board: icon over a small capital label. */
@Composable
fun ActionBar(modifier: Modifier = Modifier, content: @Composable RowScope.() -> Unit) {
    Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), content = content)
}

@Composable
fun RowScope.ActionButton(title: String, icon: String, primary: Boolean = false, enabled: Boolean = true, onClick: () -> Unit) {
    val shape = RoundedCornerShape(12.dp)
    Column(
        Modifier
            .weight(1f)
            .height(62.dp)
            .alpha(if (enabled) 1f else 0.4f)
            .clip(shape)
            .background(Theatre.ink3)
            .border(1.dp, if (primary) Theatre.brass.copy(alpha = 0.7f) else Theatre.rule, shape)
            .clickable(
                enabled = enabled, role = Role.Button, onClick = onClick,
                interactionSource = remember { MutableInteractionSource() }, indication = ripple(color = Theatre.brass),
            ),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        BrassIcon(icon, 22.dp)
        Spacer(Modifier.height(5.dp))
        Label(title, size = 9, color = Theatre.ivory, modifier = Modifier.padding(horizontal = 4.dp))
    }
}

/** A screen's frame: the ground, the back button, a title, and the content under them. */
@Composable
fun Screen(
    title: String?, onBack: (() -> Unit)?, modifier: Modifier = Modifier,
    trailing: @Composable (RowScope.() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier
            .background(Theatre.ink)
            .padding(horizontal = 14.dp),
    ) {
        Row(Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            if (onBack != null) {
                BackButton(com.artesoft.brasspawn.data.t("common.back", "Back"), onBack)
                Spacer(Modifier.width(12.dp))
            }
            if (title != null) {
                BasicText(title, Modifier.weight(1f), style = LocalFaces.current.display(26), maxLines = 1, overflow = TextOverflow.Ellipsis)
            } else Spacer(Modifier.weight(1f))
            trailing?.invoke(this)
        }
        content()
    }
}

@Composable
fun BoxScope.Centered(content: @Composable () -> Unit) = Box(Modifier.align(Alignment.Center)) { content() }

/** A one-line field in the house style. */
@Composable
fun TextInput(
    value: String, onValueChange: (String) -> Unit, placeholder: String, modifier: Modifier = Modifier,
    capitalize: Boolean = false, onDone: (() -> Unit)? = null,
) {
    val shape = RoundedCornerShape(10.dp)
    androidx.compose.foundation.text.BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        textStyle = LocalFaces.current.body(16),
        cursorBrush = androidx.compose.ui.graphics.SolidColor(Theatre.brass),
        keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
            capitalization = if (capitalize) androidx.compose.ui.text.input.KeyboardCapitalization.Characters
            else androidx.compose.ui.text.input.KeyboardCapitalization.None,
            autoCorrectEnabled = false,
            imeAction = androidx.compose.ui.text.input.ImeAction.Done,
        ),
        keyboardActions = androidx.compose.foundation.text.KeyboardActions(onDone = { onDone?.invoke() }),
        modifier = modifier
            .heightIn(min = 44.dp)
            .clip(shape)
            .background(Theatre.ink2)
            .border(1.dp, Theatre.rule, shape)
            .semantics { contentDescription = placeholder },
        decorationBox = { field ->
            Box(Modifier.padding(horizontal = 12.dp, vertical = 11.dp), contentAlignment = Alignment.CenterStart) {
                if (value.isEmpty()) Body(placeholder, size = 16, color = Theatre.ivoryFaint, maxLines = 1)
                field()
            }
        },
    )
}

/** A question over the screen, with two answers. */
@Composable
fun ConfirmDialog(
    title: String, message: String, confirm: String, dismiss: String,
    onConfirm: () -> Unit, onDismiss: () -> Unit,
) {
    androidx.compose.ui.window.Dialog(onDismissRequest = onDismiss) {
        Panel(padding = PaddingValues(18.dp)) {
            BasicText(title, style = LocalFaces.current.display(24))
            Spacer(Modifier.height(8.dp))
            Body(message, size = 14, color = Theatre.ivoryDim)
            Spacer(Modifier.height(16.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ChipButton(dismiss, Modifier.weight(1f), onClick = onDismiss)
                ChipButton(confirm, Modifier.weight(1f), primary = true, onClick = onConfirm)
            }
        }
    }
}
