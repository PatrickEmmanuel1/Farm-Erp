package com.example.farmproject.ui.attendance.manager

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.farmproject.data.model.AttendanceDisplay
import com.example.farmproject.ui.attendance.AttendanceUiState
import com.example.farmproject.ui.attendance.AttendanceViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerAttendanceScreen(
    viewModel: AttendanceViewModel = viewModel(),
    onBackClick: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    var searchQuery by remember { mutableStateOf("") }
    var selectedRoleFilter by remember { mutableStateOf("All") } // "All", "Workers", "Supervisors"

    Scaffold(
        topBar = {
            TopAppBar(
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                title = {
                    Column {
                        Text(
                            text = "Attendance Records",
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Daily attendance for supervisors and workers",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (val state = uiState) {
                is AttendanceUiState.Loading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }

                is AttendanceUiState.Error -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = state.message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadAttendance() }) {
                            Text("Retry")
                        }
                    }
                }

                is AttendanceUiState.Success -> {
                    val filteredItems = state.items.filter { display ->
                        val matchesRole = when (selectedRoleFilter) {
                            "Workers" -> display.role.equals("Worker", ignoreCase = true)
                            "Supervisors" -> display.role.equals("Supervisor", ignoreCase = true)
                            else -> true
                        }
                        val matchesSearch = searchQuery.isBlank() ||
                                display.workerName.contains(searchQuery, ignoreCase = true) ||
                                display.employeeNumber?.contains(searchQuery, ignoreCase = true) == true
                        matchesRole && matchesSearch
                    }

                    LazyColumn(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(MaterialTheme.colorScheme.background)
                            .padding(horizontal = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Date Navigator
                        item {
                            Spacer(modifier = Modifier.height(8.dp))
                            DateNavigationHeader(
                                currentDateStr = state.workDate,
                                onPreviousClick = { viewModel.selectPreviousDay() },
                                onNextClick = { viewModel.selectNextDay() }
                            )
                        }

                        // Summary Statistics Cards
                        item {
                            AttendanceSummaryRow(
                                presentCount = state.presentCount,
                                lateCount = state.lateCount,
                                absentCount = state.absentCount,
                                leaveCount = state.leaveCount
                            )
                        }

                        // Role Filter Chips & Search Field
                        item {
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    FilterChip(
                                        selected = selectedRoleFilter == "All",
                                        onClick = { selectedRoleFilter = "All" },
                                        label = { Text("All Staff") }
                                    )
                                    FilterChip(
                                        selected = selectedRoleFilter == "Workers",
                                        onClick = { selectedRoleFilter = "Workers" },
                                        label = { Text("Workers") }
                                    )
                                    FilterChip(
                                        selected = selectedRoleFilter == "Supervisors",
                                        onClick = { selectedRoleFilter = "Supervisors" },
                                        label = { Text("Supervisors") }
                                    )
                                }

                                OutlinedTextField(
                                    value = searchQuery,
                                    onValueChange = { searchQuery = it },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("Search by name or employee ID...") },
                                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = MaterialTheme.colorScheme.primary,
                                        unfocusedBorderColor = MaterialTheme.colorScheme.outlineVariant
                                    )
                                )
                            }
                        }

                        // Attendance Cards List
                        if (filteredItems.isEmpty()) {
                            item {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 32.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = if (searchQuery.isNotBlank()) "No staff matching search." else "No staff records found for this date.",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        } else {
                            items(filteredItems) { display ->
                                WorkerAttendanceCard(
                                    display = display,
                                    onMarkStatus = { status ->
                                        viewModel.markAttendance(
                                            workerProfileId = display.workerProfileId,
                                            status = status
                                        )
                                    },
                                    onClockIn = {
                                        viewModel.clockInWorker(display.workerProfileId)
                                    },
                                    onClockOut = {
                                        display.record?.attendanceId?.let { id ->
                                            viewModel.clockOutWorker(id)
                                        }
                                    }
                                )
                            }
                        }

                        item {
                            Spacer(modifier = Modifier.height(24.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun DateNavigationHeader(
    currentDateStr: String,
    onPreviousClick: () -> Unit,
    onNextClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onPreviousClick) {
                Icon(
                    imageVector = Icons.Default.ChevronLeft,
                    contentDescription = "Previous Day",
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.CalendarMonth,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = currentDateStr,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }

            IconButton(onClick = onNextClick) {
                Icon(
                    imageVector = Icons.Default.ChevronRight,
                    contentDescription = "Next Day",
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
    }
}

@Composable
private fun AttendanceSummaryRow(
    presentCount: Int,
    lateCount: Int,
    absentCount: Int,
    leaveCount: Int
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        SummaryBadgeCard(
            modifier = Modifier.weight(1f),
            label = "Present",
            count = presentCount,
            badgeColor = Color(0xFF2E7D32)
        )
        SummaryBadgeCard(
            modifier = Modifier.weight(1f),
            label = "Late",
            count = lateCount,
            badgeColor = Color(0xFFE65100)
        )
        SummaryBadgeCard(
            modifier = Modifier.weight(1f),
            label = "Absent",
            count = absentCount,
            badgeColor = Color(0xFFC62828)
        )
        SummaryBadgeCard(
            modifier = Modifier.weight(1f),
            label = "Leave",
            count = leaveCount,
            badgeColor = Color(0xFF6A1B9A)
        )
    }
}

@Composable
private fun SummaryBadgeCard(
    modifier: Modifier = Modifier,
    label: String,
    count: Int,
    badgeColor: Color
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = badgeColor.copy(alpha = 0.12f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 10.dp, horizontal = 4.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = count.toString(),
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = badgeColor
            )
            Text(
                text = label,
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = badgeColor
            )
        }
    }
}

@Composable
private fun WorkerAttendanceCard(
    display: AttendanceDisplay,
    onMarkStatus: (String) -> Unit,
    onClockIn: () -> Unit,
    onClockOut: () -> Unit
) {
    val currentStatus = display.currentStatus

    val statusBgColor = when (currentStatus.lowercase()) {
        "present" -> Color(0xFFE8F5E9)
        "late" -> Color(0xFFFFF3E0)
        "absent" -> Color(0xFFFFEBEE)
        "on leave" -> Color(0xFFF3E5F5)
        else -> MaterialTheme.colorScheme.surfaceVariant
    }

    val statusTextColor = when (currentStatus.lowercase()) {
        "present" -> Color(0xFF2E7D32)
        "late" -> Color(0xFFE65100)
        "absent" -> Color(0xFFC62828)
        "on leave" -> Color(0xFF6A1B9A)
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(42.dp)
                        .background(
                            color = MaterialTheme.colorScheme.primaryContainer,
                            shape = RoundedCornerShape(10.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = display.workerName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "${display.role} • ${display.employeeNumber ?: "Staff"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Box(
                    modifier = Modifier
                        .background(statusBgColor, shape = RoundedCornerShape(16.dp))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = currentStatus,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = statusTextColor
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Quick Mark Status Chips
            Text(
                text = "Mark Status:",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                FilterChip(
                    selected = currentStatus.equals("Present", ignoreCase = true),
                    onClick = { onMarkStatus("present") },
                    label = { Text("Present", fontSize = 11.sp) }
                )
                FilterChip(
                    selected = currentStatus.equals("Late", ignoreCase = true),
                    onClick = { onMarkStatus("late") },
                    label = { Text("Late", fontSize = 11.sp) }
                )
                FilterChip(
                    selected = currentStatus.equals("Absent", ignoreCase = true),
                    onClick = { onMarkStatus("absent") },
                    label = { Text("Absent", fontSize = 11.sp) }
                )
                FilterChip(
                    selected = currentStatus.equals("On Leave", ignoreCase = true),
                    onClick = { onMarkStatus("on_leave") },
                    label = { Text("Leave", fontSize = 11.sp) }
                )
            }

            // Clock-In / Clock-Out Info
            val checkInTime = display.record?.checkIn?.take(16)?.replace("T", " ") ?: "--:--"
            val checkOutTime = display.record?.checkOut?.take(16)?.replace("T", " ") ?: "--:--"

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "In: $checkInTime  |  Out: $checkOutTime",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                if (display.record?.checkIn == null) {
                    Button(
                        onClick = onClockIn,
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                    ) {
                        Text("Clock In", fontSize = 12.sp)
                    }
                } else if (display.record.checkOut == null) {
                    Button(
                        onClick = onClockOut,
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                    ) {
                        Text("Clock Out", fontSize = 12.sp)
                    }
                }
            }
        }
    }
}
