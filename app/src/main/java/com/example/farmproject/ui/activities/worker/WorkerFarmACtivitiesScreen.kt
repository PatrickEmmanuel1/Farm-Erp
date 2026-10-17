package com.example.farmproject.ui.activities.worker

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.farmproject.data.model.FarmActivity
import com.example.farmproject.data.model.FarmActivityDisplay
import com.example.farmproject.data.session.CurrentSession
import com.example.farmproject.ui.activities.manager.FarmActivitiesUiState
import com.example.farmproject.ui.activities.manager.FarmActivitiesViewModel
import java.time.Duration
import java.time.LocalDateTime
import java.util.Locale

private fun calculateDisplayDuration(activity: FarmActivity): String {
    if (activity.durationHours != null && activity.durationHours > 0) {
        val hrs = activity.durationHours
        return if (hrs == 1.0) "1.0 hr" else String.format(Locale.US, "%.1f hrs", hrs)
    }

    val startStr = activity.startedAt ?: activity.startTime ?: activity.createdAt
    val endStr = activity.completedAt ?: activity.endTime ?: activity.updatedAt

    if (!startStr.isNullOrBlank() && !endStr.isNullOrBlank()) {
        try {
            val start = LocalDateTime.parse(startStr)
            val end = LocalDateTime.parse(endStr)
            val mins = Duration.between(start, end).toMinutes()
            if (mins > 0) {
                val hrs = mins / 60.0
                return if (hrs == 1.0) "1.0 hr" else String.format(Locale.US, "%.1f hrs", hrs)
            }
        } catch (_: Exception) {}
    }

    return "1.0 hr"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkerFarmActivitiesScreen(
    viewModel: FarmActivitiesViewModel = viewModel(),
    onBackClick: () -> Unit = {},
    onActivityClick: (String) -> Unit = {}
) {
    var selectedTab by remember { mutableIntStateOf(0) }
    val uiState by viewModel.uiState.collectAsState()

    val workerUserId = CurrentSession.userId.orEmpty()
    val workerName = CurrentSession.fullName?.trim().orEmpty()

    Scaffold(
        topBar = {
            Column {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.primary)
                        .padding(horizontal = 8.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    Column {
                        Text(
                            text = "Assigned Activities",
                            color = Color.White,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            text = "View & perform worker tasks",
                            color = Color.White.copy(alpha = 0.85f),
                            fontSize = 12.sp
                        )
                    }
                }

                TabRow(selectedTabIndex = selectedTab) {
                    Tab(
                        selected = selectedTab == 0,
                        onClick = { selectedTab = 0 },
                        text = { Text("Assigned Activities") },
                        icon = { Icon(imageVector = Icons.Default.HourglassTop, contentDescription = null) }
                    )
                    Tab(
                        selected = selectedTab == 1,
                        onClick = { selectedTab = 1 },
                        text = { Text("Completed Activities") },
                        icon = { Icon(imageVector = Icons.Default.CheckCircle, contentDescription = null) }
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (val state = uiState) {
                is FarmActivitiesUiState.Loading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }

                is FarmActivitiesUiState.Error -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = state.message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadActivities() }) {
                            Text("Retry")
                        }
                    }
                }

                is FarmActivitiesUiState.Success -> {
                    val allActivities = state.activities

                    // Filter activities assigned to worker
                    val workerActivities = allActivities.filter { display ->
                        val act = display.activity
                        (act.workerProfileId != null && act.workerProfileId == workerUserId) ||
                        (display.assignedToName != null && display.assignedToName.equals(workerName, ignoreCase = true)) ||
                        (act.method != null && act.method.contains("Worker", ignoreCase = true))
                    }

                    val filteredActivities = workerActivities.filter { display ->
                        val st = display.activity.safeStatus
                        if (selectedTab == 1) {
                            st.equals("Completed", ignoreCase = true) || st.equals("completed", ignoreCase = true)
                        } else {
                            !st.equals("Completed", ignoreCase = true) && !st.equals("completed", ignoreCase = true)
                        }
                    }

                    val tabTitle = if (selectedTab == 1) "Completed Activities" else "Assigned Activities"

                    LazyColumn(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(MaterialTheme.colorScheme.background)
                            .padding(horizontal = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        item {
                            Spacer(modifier = Modifier.height(8.dp))

                            WorkerActivitySummaryCard(
                                totalActivities = filteredActivities.size,
                                labelText = "$tabTitle count"
                            )
                        }

                        item {
                            Text(
                                text = tabTitle,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        if (filteredActivities.isEmpty()) {
                            item {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 32.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = "No $tabTitle found.",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        } else {
                            items(filteredActivities) { activityDisplay ->
                                val activityId = activityDisplay.activity.activityId.orEmpty()
                                val isPending = !activityDisplay.activity.safeStatus.equals("In Progress", ignoreCase = true) &&
                                        !activityDisplay.activity.safeStatus.equals("Completed", ignoreCase = true)

                                WorkerActivityCard(
                                    activityDisplay = activityDisplay,
                                    isCompletedTab = selectedTab == 1,
                                    onClick = {
                                        if (activityId.isNotBlank()) {
                                            onActivityClick(activityId)
                                        }
                                    },
                                    onStartClick = if (selectedTab == 0 && isPending && activityId.isNotBlank()) {
                                        { viewModel.startActivity(activityId) }
                                    } else null,
                                    onCompleteClick = if (selectedTab == 0 && !isPending && activityId.isNotBlank()) {
                                        { viewModel.completeActivity(activityId) }
                                    } else null
                                )
                            }
                        }

                        item {
                            Spacer(modifier = Modifier.height(16.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun WorkerActivitySummaryCard(
    totalActivities: Int,
    labelText: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(18.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(52.dp)
                        .background(
                            color = MaterialTheme.colorScheme.primaryContainer,
                            shape = RoundedCornerShape(14.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Assignment,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                Spacer(modifier = Modifier.size(16.dp))

                Column {
                    Text(
                        text = totalActivities.toString(),
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = labelText,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
    }
}

@Composable
private fun WorkerActivityCard(
    activityDisplay: FarmActivityDisplay,
    isCompletedTab: Boolean,
    onClick: () -> Unit,
    onStartClick: (() -> Unit)? = null,
    onCompleteClick: (() -> Unit)? = null
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .background(
                            color = MaterialTheme.colorScheme.primaryContainer,
                            shape = RoundedCornerShape(12.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Assignment,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                Spacer(modifier = Modifier.size(12.dp))

                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = activityDisplay.displayTitle,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = activityDisplay.activityTypeName,
                        style = MaterialTheme.typography.bodySmall
                    )
                }

                Box(
                    modifier = Modifier
                        .background(
                            color = MaterialTheme.colorScheme.primaryContainer,
                            shape = RoundedCornerShape(20.dp)
                        )
                        .padding(horizontal = 10.dp, vertical = 5.dp)
                ) {
                    Text(
                        text = activityDisplay.activity.safeStatus,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                WorkerActivityInfoRow(
                    icon = Icons.Default.Person,
                    label = "Assigned to",
                    value = activityDisplay.assignedToName ?: "Worker"
                )

                if (isCompletedTab) {
                    WorkerActivityInfoRow(
                        icon = Icons.Default.Schedule,
                        label = "Duration",
                        value = calculateDisplayDuration(activityDisplay.activity)
                    )
                } else {
                    WorkerActivityInfoRow(
                        icon = Icons.Default.CalendarMonth,
                        label = "Due date",
                        value = activityDisplay.activity.safeActivityDate
                    )
                }
            }

            // Begin activity button
            if (onStartClick != null) {
                Spacer(modifier = Modifier.height(12.dp))
                Button(
                    onClick = onStartClick,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF1565C0)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Begin activity",
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            // Complete task button
            if (onCompleteClick != null) {
                Spacer(modifier = Modifier.height(12.dp))
                Button(
                    onClick = onCompleteClick,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF2E7D32)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Complete task",
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun WorkerActivityInfoRow(
    icon: ImageVector,
    label: String,
    value: String
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .background(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = RoundedCornerShape(10.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.primary
            )
        }

        Spacer(modifier = Modifier.width(10.dp))

        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall
            )

            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
        }
    }
}
