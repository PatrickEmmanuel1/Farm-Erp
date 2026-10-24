// =====================================================================
// ChatUiComponents.kt
// Small shared pieces: initials avatar, error banner (same style as the
// Attendance screen's red retry card), empty state, and date helpers.
//
// Colours come from MaterialTheme, so the screens pick up your app theme.
// Needs: Material3 1.2+, and minSdk 26 (or core library desugaring) for java.time.
// =====================================================================
package com.example.farmproject.ui.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import kotlin.time.Instant

// ---------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------
@Composable
fun InitialsAvatar(name: String, modifier: Modifier = Modifier, size: Dp = 48.dp) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primaryContainer),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = initialsOf(name),
            color = MaterialTheme.colorScheme.onPrimaryContainer,
            fontWeight = FontWeight.SemiBold,
            fontSize = (size.value * 0.36f).sp,
        )
    }
}

fun initialsOf(name: String): String {
    val parts = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
    return when (parts.size) {
        0 -> "?"
        1 -> parts[0].take(2).uppercase()
        else -> (parts.first().take(1) + parts.last().take(1)).uppercase()
    }
}

// ---------------------------------------------------------------------
// Error banner + empty state
// ---------------------------------------------------------------------
@Composable
fun ErrorBanner(message: String, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.errorContainer,
    ) {
        Row(
            modifier = Modifier.padding(start = 12.dp, end = 4.dp, top = 4.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                Icons.Default.Warning,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onErrorContainer,
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = message,
                modifier = Modifier.weight(1f),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onErrorContainer,
            )
            TextButton(onClick = onRetry) { Text("Retry") }
        }
    }
}

@Composable
fun EmptyState(title: String, subtitle: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.size(6.dp))
        Text(
            text = subtitle,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

// ---------------------------------------------------------------------
// Date / time helpers (device time zone)
// ---------------------------------------------------------------------
private val clockFormat = DateTimeFormatter.ofPattern("HH:mm")
private val weekdayFormat = DateTimeFormatter.ofPattern("EEE")
private val shortDateFormat = DateTimeFormatter.ofPattern("dd MMM")
private val longDateFormat = DateTimeFormatter.ofPattern("EEEE, d MMM yyyy")

private fun Instant.local(): ZonedDateTime =
    java.time.Instant.ofEpochMilli(toEpochMilliseconds()).atZone(ZoneId.systemDefault())

/** "14:32" - shown under each bubble. */
fun Instant.clockTime(): String = local().format(clockFormat)

fun Instant.localDate(): LocalDate = local().toLocalDate()

/** Chat list timestamp: time today, "Yesterday", weekday this week, otherwise "05 Oct". */
fun Instant.listLabel(): String {
    val zoned = local()
    val date = zoned.toLocalDate()
    val today = LocalDate.now()
    return when {
        date == today -> zoned.format(clockFormat)
        date == today.minusDays(1) -> "Yesterday"
        date.isAfter(today.minusDays(7)) -> zoned.format(weekdayFormat)
        else -> zoned.format(shortDateFormat)
    }
}

/** Date chip inside a conversation. */
fun LocalDate.dayHeader(): String {
    val today = LocalDate.now()
    return when (this) {
        today -> "Today"
        today.minusDays(1) -> "Yesterday"
        else -> format(longDateFormat)
    }
}

/** Pending messages have no server time yet, so treat them as "today". */
fun UiMessage.localDay(): LocalDate = createdAt?.localDate() ?: LocalDate.now()
