package com.example.farmproject.ui.machinery.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.Machinery
import com.example.farmproject.data.model.MachineryUsage
import com.example.farmproject.data.repository.MachineryRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

sealed interface MachineryUiState {
    data object Loading : MachineryUiState
    data class Success(val machinery: List<Machinery>) : MachineryUiState
    data class Error(val message: String) : MachineryUiState
}

sealed interface MachinerySaveState {
    data object Idle : MachinerySaveState
    data object Saving : MachinerySaveState
    data object Saved : MachinerySaveState
    data class Error(val message: String) : MachinerySaveState
}

/**
 * Hours used / fuel used / last & next maintenance aren't columns on
 * machinery — they're derived from machinery_usage (summed) and the
 * most recent machinery_maintenance row. This is what
 * ManagerMachineryDetailsScreen's "Machine Overview" and "Maintenance"
 * sections actually need.
 */
sealed interface MachineryDetailUiState {
    data object Loading : MachineryDetailUiState
    data class Success(
        val machinery: Machinery,
        val totalHoursUsed: Double,
        val totalFuelUsed: Double,
        val lastMaintenanceDate: String?,
        val nextMaintenanceDate: String?
    ) : MachineryDetailUiState
    data object NotFound : MachineryDetailUiState
    data class Error(val message: String) : MachineryDetailUiState
}

class MachineryViewModel(
    private val repository: MachineryRepository = MachineryRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<MachineryUiState>(MachineryUiState.Loading)
    val uiState: StateFlow<MachineryUiState> = _uiState.asStateFlow()

    private val _saveState = MutableStateFlow<MachinerySaveState>(MachinerySaveState.Idle)
    val saveState: StateFlow<MachinerySaveState> = _saveState.asStateFlow()

    private val _detailState = MutableStateFlow<MachineryDetailUiState>(MachineryDetailUiState.Loading)
    val detailState: StateFlow<MachineryDetailUiState> = _detailState.asStateFlow()

    init {
        loadMachinery()
    }

    fun loadMachinery() {
        viewModelScope.launch {
            _uiState.value = MachineryUiState.Loading
            try {
                val machinery = repository.getMachineryForFarm(CurrentSession.farmId)
                _uiState.value = MachineryUiState.Success(machinery)
            } catch (e: Exception) {
                _uiState.value = MachineryUiState.Error(e.message ?: "Failed to load machinery")
            }
        }
    }

    /**
     * ManagerAddMachineryScreen's Hour Meter and Fuel Type fields have
     * no home here — those belong on a machinery_usage row (an actual
     * usage session), not the static machine record, so they're not
     * parameters. status defaults to "Active" since the screen doesn't
     * collect it; brand/purchaseCost/purpose/location aren't collected
     * either and stay null until that screen grows to cover them.
     */
    fun addMachinery(
        name: String,
        machineryType: String,
        model: String?,
        serialNumber: String?,
        purchaseDate: String?,
        condition: String
    ) {
        viewModelScope.launch {
            _saveState.value = MachinerySaveState.Saving
            try {
                repository.insertMachinery(
                    Machinery(
                        farmId = CurrentSession.farmId,
                        name = name,
                        machineryType = machineryType,
                        model = model,
                        serialNumber = serialNumber,
                        purchaseDate = purchaseDate,
                        condition = condition,
                        status = "Available"
                    )
                )
                _saveState.value = MachinerySaveState.Saved
                loadMachinery()
            } catch (e: Exception) {
                _saveState.value = MachinerySaveState.Error(e.message ?: "Failed to save machinery")
            }
        }
    }

    fun deleteMachinery(machineryId: String) {
        viewModelScope.launch {
            try {
                repository.deleteMachinery(machineryId)
                loadMachinery()
            } catch (e: Exception) {
                _uiState.value = MachineryUiState.Error(e.message ?: "Failed to delete machinery")
            }
        }
    }

    fun updateMachineryDetails(
        machineryId: String,
        name: String,
        purchaseDate: String?,
        purchaseCost: Double?
    ) {
        viewModelScope.launch {
            try {
                val existing = repository.getMachineryById(machineryId)
                if (existing != null) {
                    val updated = existing.copy(
                        name = name,
                        purchaseDate = purchaseDate,
                        purchaseCost = purchaseCost
                    )
                    repository.updateMachinery(updated)
                    loadMachineryDetail(machineryId)
                    loadMachinery()
                }
            } catch (e: Exception) {
                _saveState.value = MachinerySaveState.Error(e.message ?: "Failed to update machinery")
            }
        }
    }

    fun recordUsage(
        machineryId: String,
        hoursUsed: Double,
        fuelUsed: Double?,
        date: String,
        notes: String?
    ) {
        viewModelScope.launch {
            try {
                val farmId = CurrentSession.farmId
                val newUsage = MachineryUsage(
                    usageId = UUID.randomUUID().toString(),
                    machineryId = machineryId,
                    farmId = farmId,
                    usageDate = date.ifBlank { "2026-03-30" },
                    hoursUsed = hoursUsed,
                    fuelUsed = fuelUsed,
                    purpose = notes?.ifBlank { null } ?: "Field Operation",
                    notes = notes
                )
                repository.logMachineryUsage(newUsage)
                loadMachineryDetail(machineryId)
            } catch (e: Exception) {
                _saveState.value = MachinerySaveState.Error(e.message ?: "Failed to record usage")
            }
        }
    }

    /**
     * Looks the machine up fresh (rather than from the already-loaded
     * list) since Details also needs its usage/maintenance history,
     * which the list screen never fetches.
     */
    fun loadMachineryDetail(machineryId: String) {
        viewModelScope.launch {
            _detailState.value = MachineryDetailUiState.Loading
            try {
                val machinery = repository.getMachineryById(machineryId)

                if (machinery == null) {
                    _detailState.value = MachineryDetailUiState.NotFound
                    return@launch
                }

                val usage = repository.getUsageHistory(machineryId)
                val maintenance = repository.getMaintenanceHistory(machineryId)

                val totalHoursUsed = usage.sumOf { it.hoursUsed ?: 0.0 }
                val totalFuelUsed = usage.sumOf { it.fuelUsed ?: 0.0 }

                // ISO date strings (yyyy-MM-dd) sort correctly as plain text.
                val mostRecentMaintenance = maintenance.maxByOrNull { it.maintenanceDate }

                _detailState.value = MachineryDetailUiState.Success(
                    machinery = machinery,
                    totalHoursUsed = totalHoursUsed,
                    totalFuelUsed = totalFuelUsed,
                    lastMaintenanceDate = mostRecentMaintenance?.maintenanceDate,
                    nextMaintenanceDate = mostRecentMaintenance?.nextMaintenanceDate
                )
            } catch (e: Exception) {
                _detailState.value = MachineryDetailUiState.Error(
                    e.message ?: "Failed to load machinery details"
                )
            }
        }
    }

    fun resetSaveState() {
        _saveState.value = MachinerySaveState.Idle
    }
}