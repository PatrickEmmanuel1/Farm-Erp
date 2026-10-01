package com.example.farmproject.ui.employees.manager

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun SupervisorDetailsRoute(
    profileId: String,
    onBackClick: () -> Unit,
    employeesViewModel: EmployeesViewModel = viewModel(),
    employmentViewModel: SupervisorEmploymentViewModel = viewModel()
) {
    val employeesState by employeesViewModel.uiState.collectAsStateWithLifecycle()
    val employment by employmentViewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(profileId) {
        employmentViewModel.load(profileId)
    }

    if (employeesState is EmployeesUiState.Loading) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    val employee = (employeesState as? EmployeesUiState.Success)
        ?.supervisors
        ?.firstOrNull { it.profileId == profileId }

    ManagerEmployeeDetailsScreen(
        employee = employee,
        roleLabel = "Supervisor",
        onBackClick = onBackClick,
        onUpdateSave = { name, phone, employeeNumber ->
            employee?.let {
                employeesViewModel.updateEmployee(
                    accountId = it.accountId.orEmpty(),
                    profileId = it.profileId,
                    fullName = name,
                    phoneNumber = phone,
                    employeeNumber = employeeNumber,
                    isSupervisor = true
                )
            }
        },
        onDeleteClick = {
            employeesViewModel.deleteSupervisorProfile(profileId, onDeleted = onBackClick)
        },
        showEmploymentDetails = true,
        employmentDetails = employment.details,
        isEmploymentLoading = employment.isLoading,
        employmentLoadError = employment.loadError,
        isSavingEmployment = employment.isSaving,
        employmentSaveError = employment.saveError,
        onRetryEmployment = { employmentViewModel.load(profileId) },
        onSaveEmployment = { input -> employmentViewModel.save(profileId, input) },
        onEmploymentDialogDismiss = employmentViewModel::clearSaveError
    )
}
