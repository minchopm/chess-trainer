package com.artesoft.brasspawn.ui.training

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.artesoft.brasspawn.data.TrainingStore
import com.artesoft.brasspawn.data.t
import com.artesoft.brasspawn.match.TimeControl
import com.artesoft.brasspawn.training.RatedPool
import com.artesoft.brasspawn.training.Themes
import com.artesoft.brasspawn.training.TrainingMode
import com.artesoft.brasspawn.training.TrainingProgress
import com.artesoft.brasspawn.ui.Body
import com.artesoft.brasspawn.ui.BrassIcon
import com.artesoft.brasspawn.ui.ConfirmDialog
import com.artesoft.brasspawn.ui.Label
import com.artesoft.brasspawn.ui.LocalFaces
import com.artesoft.brasspawn.ui.Navigator
import com.artesoft.brasspawn.ui.Panel
import com.artesoft.brasspawn.ui.Screen
import com.artesoft.brasspawn.ui.Theatre

private data class Milestone(val elo: Int, val nameKey: String, val defaultName: String) {
    val label: String get() = t(nameKey, defaultName)
}

private val ratingMilestones = listOf(
    Milestone(1400, "play.casual", "Casual"),
    Milestone(1800, "play.club", "Club"),
    Milestone(2100, "play.strongClub", "Strong club"),
    Milestone(2400, "play.expert", "Expert"),
    Milestone(2700, "play.master", "Master"),
)

@Composable
fun ProgressScreen(navigator: Navigator) {
    val context = LocalContext.current
    val store = remember { TrainingStore.shared(context) }
    val progress = store.progress
    val library = store.library
    var confirmsReset by remember { mutableStateOf(false) }

    Screen(title = t("progress.progress", "Progress"), onBack = navigator::back) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                Modifier.widthIn(max = 560.dp).fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                WhereYouAreSection(progress)
                TodayAndStreakSection(progress)
                WeakSpotsSection(progress)
                EngineAndOnlineSection(progress)
                LibrarySection(
                    puzzles = library.puzzles.size,
                    exercises = library.exercises.size,
                    drills = library.drills.size,
                )

                ResetProgressButton { confirmsReset = true }
            }
        }
    }

    if (confirmsReset) {
        ConfirmDialog(
            title = t("progress.resetAllProgress", "Reset all progress"),
            message = t("progress.android.resetMessage", "Your ratings, records and history will be cleared."),
            confirm = t("progress.resetAllProgress", "Reset all progress"),
            dismiss = t("progress.stay", "Stay"),
            onConfirm = {
                confirmsReset = false
                store.resetProgress()
            },
            onDismiss = { confirmsReset = false },
        )
    }
}

@Composable
private fun WhereYouAreSection(progress: TrainingProgress) {
    val overall = progress.overallRating
    ProgressSection(t("progress.whereYouAre", "Where you are")) {
        Row(
            Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column {
                Label(t("progress.overall", "Overall"), size = 10, color = Theatre.brass)
                BasicText(overall.toString(), style = LocalFaces.current.display(42, FontWeight.SemiBold))
            }
            MilestoneSummary(overall)
        }

        Spacer(Modifier.height(10.dp))
        MilestoneBar(overall)
        Spacer(Modifier.height(14.dp))

        DisciplineRow(
            icon = "target",
            title = t("progress.tactics", "Tactics"),
            rating = progress.rating(TrainingMode.TACTICS),
            games = progress.gamesPlayed(RatedPool.Training(TrainingMode.TACTICS)),
        )
        DisciplineRow(
            icon = "square.grid.3x3.middle.filled",
            title = t("progress.positional", "Positional"),
            rating = progress.rating(TrainingMode.POSITIONAL),
            games = progress.gamesPlayed(RatedPool.Training(TrainingMode.POSITIONAL)),
        )
        DisciplineRow(
            icon = "flag.checkered",
            title = t("progress.endgames", "Endgames"),
            rating = progress.rating(TrainingMode.ENDGAME),
            games = progress.gamesPlayed(RatedPool.Training(TrainingMode.ENDGAME)),
        )

        Spacer(Modifier.height(8.dp))
        Body(
            t(
                "progress.puzzleRatingsRunAFew",
                "Puzzle ratings run a few hundred points above over-the-board ratings — treat them as a measure of progress against yourself."
            ),
            size = 12,
            color = Theatre.ivoryFaint,
        )
    }
}

@Composable
private fun MilestoneSummary(overall: Int) {
    val reached = ratingMilestones.lastOrNull { overall >= it.elo }
    val next = ratingMilestones.firstOrNull { overall < it.elo }
    Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Label(t("progress.android.ladder", "Milestones"), size = 9, color = Theatre.ivoryFaint)
        if (reached != null) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                BrassIcon("trophy.fill", 15.dp)
                Body(
                    "${reached.label} (${reached.elo})",
                    size = 14,
                    style = LocalFaces.current.body(14, weight = FontWeight.SemiBold, color = Theatre.brassHot),
                )
            }
        }
        Body(
            if (next != null) t("progress.android.nextMilestone", "Next: %1\$@ (%2\$lld)", next.label, next.elo)
            else t("progress.android.topMilestone", "Highest rung reached"),
            size = 12,
            color = Theatre.ivoryDim,
        )
    }
}

@Composable
private fun MilestoneBar(overall: Int) {
    val floor = 1000f
    val ceiling = 2700f
    val fraction = ((overall - floor) / (ceiling - floor)).coerceIn(0.04f, 1f)
    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(7.dp)
                .clip(CircleShape)
                .background(Theatre.ink2)
                .border(0.7.dp, Theatre.rule, CircleShape),
        ) {
            Box(
                Modifier
                    .fillMaxWidth(fraction)
                    .height(7.dp)
                    .clip(CircleShape)
                    .background(Brush.horizontalGradient(listOf(Theatre.brassDeep, Theatre.brassHot))),
            )
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            for (rung in ratingMilestones) {
                val lit = overall >= rung.elo
                BasicText(
                    rung.elo.toString(),
                    style = LocalFaces.current.figures(10, if (lit) Theatre.brassHot else Theatre.ivoryFaint),
                )
            }
        }
    }
}

@Composable
private fun DisciplineRow(icon: String, title: String, rating: Int, games: Int) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        BrassIcon(icon, 20.dp)
        Spacer(Modifier.width(10.dp))
        Body(title, Modifier.weight(1f), size = 15, color = Theatre.ivory)
        if (games > 0) {
            BasicText(
                "($games)",
                style = LocalFaces.current.figures(12, Theatre.ivoryFaint),
            )
            Spacer(Modifier.width(10.dp))
        }
        BasicText(rating.toString(), style = LocalFaces.current.figures(17, Theatre.ivory))
    }
}

@Composable
private fun TodayAndStreakSection(progress: TrainingProgress) {
    val today = progress.sessionStats()
    val totalAttempted = progress.history.size
    val totalSolved = progress.history.count { it.correct }
    ProgressSection(t("progress.today", "Today")) {
        ProgressRow(t("progress.dayStreak", "Day streak"), progress.currentStreak.toString(), highlight = progress.currentStreak > 0)
        if (progress.bestStreak > 1) {
            ProgressRow(t("progress.android.bestStreak", "Best streak"), progress.bestStreak.toString())
        }
        ProgressRow(t("progress.attempted", "Attempted"), today.attempted.toString())
        ProgressRow(t("progress.solved", "Solved"), today.solved.toString())
        ProgressRow(t("progress.accuracy", "Accuracy"), "${(today.accuracy * 100).toInt()}%")

        if (totalAttempted > today.attempted) {
            Spacer(Modifier.height(6.dp))
            Box(Modifier.fillMaxWidth().height(1.dp).background(Theatre.ruleSoft))
            Spacer(Modifier.height(6.dp))
            ProgressRow(
                t("progress.android.allTime", "All time"),
                "$totalSolved / $totalAttempted",
            )
        }
    }
}

@Composable
private fun WeakSpotsSection(progress: TrainingProgress) {
    val weak = progress.weakestThemes().ifEmpty { progress.weakestThemes(limit = 5, minimumSeen = 1) }
    if (weak.isEmpty()) return
    val targeted = progress.trainingTargets().map { it.name }.toSet()

    ProgressSection(t("progress.weakSpots", "Weak spots")) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            for (theme in weak) {
                val pct = (theme.record.accuracy * 100).toInt()
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Row(
                        Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Row(
                            Modifier.weight(1f),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            Body(Themes.readable(theme.name), size = 14, color = Theatre.ivory, maxLines = 1)
                            if (theme.name in targeted) {
                                Box(
                                    Modifier
                                        .clip(CircleShape)
                                        .background(Theatre.brassGlow)
                                        .border(0.6.dp, Theatre.brass.copy(alpha = 0.5f), CircleShape)
                                        .padding(horizontal = 7.dp, vertical = 2.dp),
                                ) {
                                    Label(t("progress.android.targeting", "Targeting"), size = 8, color = Theatre.brassHot)
                                }
                            }
                        }
                        Spacer(Modifier.width(8.dp))
                        BasicText(
                            t("progress.themeAccuracy", "%lld%% of %lld", pct, theme.record.seen),
                            style = LocalFaces.current.figures(12, Theatre.ivoryDim),
                        )
                    }
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .height(4.dp)
                            .clip(CircleShape)
                            .background(Theatre.ink2),
                    ) {
                        Box(
                            Modifier
                                .fillMaxWidth(theme.record.accuracy.toFloat().coerceIn(0.03f, 1f))
                                .height(4.dp)
                                .clip(CircleShape)
                                .background(
                                    when {
                                        theme.record.accuracy >= 0.75 -> Theatre.good
                                        theme.record.accuracy >= 0.5 -> Theatre.warn
                                        else -> Theatre.bad
                                    }
                                ),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun EngineAndOnlineSection(progress: TrainingProgress) {
    val engineGames = progress.gamesPlayed(RatedPool.Engine)
    if (engineGames > 0) {
        ProgressSection(t("progress.engine", "Engine")) {
            ProgressRow(t("progress.engine", "Engine"), progress.rating(RatedPool.Engine).toString())
            Spacer(Modifier.height(4.dp))
            Body(
                t(
                    "progress.everyPoolIsRatedApart",
                    "Each of these is rated on its own. Solving with a clock running is a different skill from solving with all afternoon, and beating a bot whose strength you chose is a different measure again."
                ),
                size = 12,
                color = Theatre.ivoryFaint,
            )
        }
    }

    val playedClocks = TimeControl.entries.filter { progress.gamesPlayed(RatedPool.Online(it.minutes)) > 0 }
    if (playedClocks.isNotEmpty()) {
        ProgressSection(t("progress.online", "Online")) {
            for (control in playedClocks) {
                ProgressRow(
                    "${control.label} · ${control.displayName}",
                    progress.rating(RatedPool.Online(control.minutes)).toString(),
                )
            }
            ProgressRow(
                t("progress.record", "Record"),
                "${progress.onlineWins}W · ${progress.onlineLosses}L · ${progress.onlineDraws}D",
            )
            Spacer(Modifier.height(4.dp))
            Body(
                t(
                    "progress.onlineRatingIsKeptApart",
                    "Online rating is kept apart from the training ratings: it measures you against the people you play, not against a library. Each clock is rated on its own — three minutes and thirty are different games."
                ),
                size = 12,
                color = Theatre.ivoryFaint,
            )
        }
    }
}

@Composable
private fun LibrarySection(puzzles: Int, exercises: Int, drills: Int) {
    ProgressSection(t("progress.library", "Library")) {
        ProgressRow(t("progress.tacticsPuzzles", "Tactics puzzles"), puzzles.toString())
        ProgressRow(t("progress.positional", "Positional"), exercises.toString())
        ProgressRow(t("progress.endgames", "Endgames"), drills.toString())
    }
}

@Composable
private fun ProgressSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Label(title, size = 10, color = Theatre.brass)
            Box(Modifier.weight(1f).height(1.dp).background(Theatre.rule))
        }
        Panel(Modifier.fillMaxWidth(), content = content)
    }
}

@Composable
private fun ProgressRow(title: String, value: String, highlight: Boolean = false) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Body(title, Modifier.weight(1f), size = 14, color = Theatre.ivory)
        Spacer(Modifier.width(12.dp))
        BasicText(
            value,
            style = LocalFaces.current.figures(15, if (highlight) Theatre.brassHot else Theatre.ivoryDim),
        )
    }
}

@Composable
private fun ResetProgressButton(onClick: () -> Unit) {
    val shape = RoundedCornerShape(12.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Theatre.ink3)
            .border(1.dp, Theatre.bad.copy(alpha = 0.45f), shape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Body(t("progress.resetAllProgress", "Reset all progress"), Modifier.weight(1f), size = 14, color = Theatre.bad)
        BrassIcon("trash", 18.dp)
    }
}
