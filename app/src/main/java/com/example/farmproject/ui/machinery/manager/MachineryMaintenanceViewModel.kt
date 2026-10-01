package com.example.farmproject.ui.machinery.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.Machinery
import com.example.farmproject.data.model.MachineryMaintenance
import com.example.farmproject.data.repository.MachineryRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

sealed interface MachineryMaintenanceUiState {
    data object Loading : MachineryMaintenanceUiState
    data class Success(
        val maintenanceLogs: List<MachineryMaintenance>,
        val machineryList: List<Machinery>
    ) : MachineryMaintenanceUiState
    data class Error(val message: String) : MachineryMaintenanceUiState
}

class MachineryMaintenanceViewModel(
    private val repository: MachineryRepository = MachineryRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<MachineryMaintenanceUiState>(MachineryMaintenanceUiState.Loading)
    val uiState: StateFlow<MachineryMaintenanceUiState> = _uiState.asStateFlow()

    init {
        loadMaintenanceData()
    }

    fun loadMaintenanceData() {
        viewModelScope.launch {
            _uiState.value = MachineryMaintenanceUiState.Loading
            try {
                val farmId = CurrentSession.farmId
                val machineryList = repository.getMachineryForFarm(farmId)
                val maintenanceLogs = repository.getAllMaintenanceForFarm(farmId)

                _uiState.value = MachineryMaintenanceUiState.Success(
                    maintenanceLogs = maintenanceLogs,
                    machineryList = machineryList
                )
            } catch (e: Exception) {
                _uiState.value = MachineryMaintenanceUiState.Error(e.message ?: "Failed to load maintenance data")
            }
        }
    }

    fun recordMaintenance(
        machineryId: String,
        maintenanceType: String,
        date: String,
        cost: Double?,
        notes: String?
    ) {
        viewModelScope.launch {
            try {
                val farmId = CurrentSession.farmId
                val newMaintenance = MachineryMaintenance(
                    maintenanceId = UUID.randomUUID().toString(),
                    machineryId = machineryId,
                    farmId = farmId,
                    maintenanceType = maintenanceType,
                    maintenanceDate = date.ifBlank { "2026-03-30" },
                    description = notes?.ifBlank { null } ?: maintenanceType,
                    cost = cost,
                    notes = notes
                )
                repository.logMaintenance(newMaintenance)
                loadMaintenanceData()
            } catch (e: Exception) {
                _uiState.value = MachineryMaintenanceUiState.Error(e.message ?: "Failed to record maintenance")
            }
        }
    }
}
