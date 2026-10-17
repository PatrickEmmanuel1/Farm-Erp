package com.example.farmproject.ui.attendance.supervisor

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.farmproject.ui.attendance.SelfAttendanceScreen
import com.example.farmproject.ui.attendance.SelfAttendanceViewModel

@Composable
fun SupervisorAttendanceScreen(
    viewModel: SelfAttendanceViewModel = viewModel(),
    onBackClick: () -> Unit = {}
) {
    SelfAttendanceScreen(
        viewModel = viewModel,
        onBackClick = onBackClick
    )
}
