@file:OptIn(ExperimentalLayoutApi::class)

package com.artesoft.brasspawn.ui.training

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.ui.Body
import com.artesoft.brasspawn.ui.BrassIcon
import com.artesoft.brasspawn.ui.Label
import com.artesoft.brasspawn.ui.LocalFaces
import com.artesoft.brasspawn.ui.Panel
import com.artesoft.brasspawn.ui.Theatre
import kotlin.math.abs

enum class FeedbackTone {
    CORRECT, PARTIAL, WRONG, NEUTRAL;

    val color: Color
        get() = when (this) {
            CORRECT -> Theatre.good
            PARTIAL -> Theatre.warn
            WRONG -> Theatre.bad
            NEUTRAL -> Theatre.ivoryDim
        }
}

/**
 * The shared frame of every training mode: the board and its two player rows,
 * the scrollable coach/prompt cards, and the action bar anchored at the foot.
 *
 * In portrait the board sits on top, sized so the cards and controls remain
 * reachable below it; in landscape or wide tablet windows the reading column
 * stands beside the board.
 */
@Composable
fun TrainingLayout(
    modifier: Modifier = Modifier,
    board: @Composable (Dp) -> Unit,
    panel: @Composable ColumnScope.() -> Unit,
    controls: @Composable () -> Unit,
) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        val isWide = maxWidth > maxHeight && maxWidth >= 600.dp
        if (isWide) {
            val side = minOf(maxHeight - 68.dp, (maxWidth - 340.dp).coerceAtLeast(240.dp), 560.dp)
            Row(
                Modifier.fillMaxSize().padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.Top,
            ) {
                Box(Modifier.width(side)) {
                    board(side)
                }
                Column(
                    Modifier.widthIn(max = 520.dp).weight(1f, fill = false).fillMaxHeight(),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Column(
                        Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                        content = panel,
                    )
                    controls()
                }
            }
        } else {
            val boardWidth = minOf(maxWidth, 520.dp, (maxHeight - 236.dp).coerceAtLeast(220.dp))
            Column(
                Modifier.fillMaxSize().padding(bottom = 10.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(Modifier.width(boardWidth)) {
                    board(boardWidth)
                }
                Spacer(Modifier.height(10.dp))
                Column(
                    Modifier
                        .widthIn(max = 560.dp)
                        .weight(1f)
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    content = panel,
                )
                Spacer(Modifier.height(10.dp))
                Box(Modifier.widthIn(max = 560.dp).fillMaxWidth()) {
                    controls()
                }
            }
        }
    }
}

/** Small uppercase brass pills that wrap cleanly onto new lines when needed. */
@Composable
fun TagRow(tags: List<String>, modifier: Modifier = Modifier) {
    if (tags.isEmpty()) return
    FlowRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        for (tag in tags) {
            Box(
                Modifier
                    .clip(CircleShape)
                    .background(Theatre.brass.copy(alpha = 0.10f))
                    .border(0.7.dp, Theatre.brass.copy(alpha = 0.28f), CircleShape)
                    .padding(horizontal = 9.dp, vertical = 4.dp),
            ) {
                Label(tag, size = 9, color = Theatre.brassHot)
            }
        }
    }
}

/** A card marked along its leading edge with a verdict colour. */
@Composable
fun VerdictCard(
    tone: FeedbackTone,
    title: String,
    lines: List<String> = emptyList(),
    modifier: Modifier = Modifier,
    extra: (@Composable ColumnScope.() -> Unit)? = null,
) {
    Panel(modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
            Box(
                Modifier
                    .width(3.dp)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(2.dp))
                    .background(tone.color),
            )
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Body(
                    title,
                    size = 16,
                    style = LocalFaces.current.body(16, weight = FontWeight.SemiBold, color = Theatre.ivory),
                )
                for (line in lines) {
                    Body(line, size = 13, color = Theatre.ivoryDim)
                }
                extra?.invoke(this)
            }
        }
    }
}

/** Shown while a JSON library is decoding on the background thread, or if absent. */
@Composable
fun LibraryNotice(isLoaded: Boolean, what: String) {
    Panel(Modifier.fillMaxWidth()) {
        Body(
            if (!isLoaded) t("common.loading", "Loading %@…", what)
            else t("common.nothingBundled", "No %@ bundled", what),
            color = Theatre.ivoryDim,
        )
    }
}

/** Formats "1200 → 1232 (+32)" in the monospaced figure face. */
@Composable
fun RatingDeltaRow(before: Int, after: Int) {
    val delta = after - before
    val sign = if (delta >= 0) "+" else "−"
    val tone = when {
        delta > 0 -> Theatre.good
        delta < 0 -> Theatre.bad
        else -> Theatre.ivoryDim
    }
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Label(t("progress.rating", "Rating"), size = 9, color = Theatre.ivoryFaint)
        BasicText(
            "$before → $after ($sign${abs(delta)})",
            style = LocalFaces.current.figures(13, tone),
        )
    }
}

/**
 * Full-screen dimmed theatre backdrop for wrong-move interruptions and puzzle
 * completions. Drawn in-tree rather than in a separate window so the dimmed
 * board remains visible behind it.
 */
@Composable
fun TrainingModal(
    tint: Color = Theatre.brassHot,
    onBackdropTap: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val panelShape = RoundedCornerShape(18.dp)
    Box(
        Modifier
            .fillMaxSize()
            .background(Theatre.shadow.copy(alpha = 0.84f))
            .background(
                Brush.radialGradient(
                    colors = listOf(Theatre.brassGlow.copy(alpha = 0.14f), Color.Transparent),
                    radius = 680f,
                )
            )
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) { onBackdropTap?.invoke() }
            .padding(horizontal = 20.dp, vertical = 24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            Modifier
                .widthIn(max = 420.dp)
                .fillMaxWidth()
                .clip(panelShape)
                .background(Brush.verticalGradient(listOf(Theatre.ink4, Theatre.ink2)))
                .background(
                    Brush.radialGradient(
                        colors = listOf(tint.copy(alpha = 0.14f), Color.Transparent),
                        radius = 480f,
                    )
                )
                .border(1.dp, tint.copy(alpha = 0.55f), panelShape)
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) {}
                .padding(PaddingValues(20.dp)),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            content = content,
        )
    }
}

/** A modal action button whose text scales/ellipsizes gracefully in long locales. */
@Composable
fun ModalButton(
    title: String,
    modifier: Modifier = Modifier,
    primary: Boolean = false,
    enabled: Boolean = true,
    icon: String? = null,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        modifier
            .heightIn(min = 44.dp)
            .alpha(if (enabled) 1f else 0.4f)
            .clip(shape)
            .background(if (primary) Theatre.brassGlow else Theatre.ink3)
            .border(1.dp, if (primary) Theatre.brass.copy(alpha = 0.75f) else Theatre.rule, shape)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (icon != null) {
            BrassIcon(icon, 17.dp)
            Spacer(Modifier.width(8.dp))
        }
        BasicText(
            title.uppercase(),
            style = LocalFaces.current.label(11, if (primary) Theatre.brassHot else Theatre.ivory)
                .copy(textAlign = TextAlign.Center),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
