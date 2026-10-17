package com.example.farmproject.ui.divisions.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.Crop
import com.example.farmproject.data.model.Division
import com.example.farmproject.data.repository.CropRepository
import com.example.farmproject.data.repository.DivisionRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface DivisionsUiState {
    data object Loading : DivisionsUiState
    data class Success(
        val divisions: List<Division>,
        val availableCrops: List<Crop>,
        val assignedCropsByDivision: Map<String, List<String>>
    ) : DivisionsUiState
    data class Error(val message: String) : DivisionsUiState
}

sealed interface DivisionSaveState {
    data object Idle : DivisionSaveState
    data object Saving : DivisionSaveState
    data object Saved : DivisionSaveState
    data class Error(val message: String) : DivisionSaveState
}

class DivisionsViewModel(
    private val repository: DivisionRepository = DivisionRepository(),
    private val cropRepository: CropRepository = CropRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<DivisionsUiState>(DivisionsUiState.Loading)
    val uiState: StateFlow<DivisionsUiState> = _uiState.asStateFlow()

    private val _saveState = MutableStateFlow<DivisionSaveState>(DivisionSaveState.Idle)
    val saveState: StateFlow<DivisionSaveState> = _saveState.asStateFlow()

    init {
        loadDivisions()
    }

    fun loadDivisions() {
        viewModelScope.launch {
            _uiState.value = DivisionsUiState.Loading
            try {
                val farmId = CurrentSession.farmId
                val divisions = repository.getDivisionsForFarm(farmId)
                val availableCrops = cropRepository.getCropCatalog()
                val assignedCrops = cropRepository.getAssignedCropsByDivision(farmId)

                _uiState.value = DivisionsUiState.Success(
                    divisions = divisions,
                    availableCrops = availableCrops,
                    assignedCropsByDivision = assignedCrops
                )
            } catch (e: Exception) {
                _uiState.value = DivisionsUiState.Error(e.message ?: "Failed to load farm divisions")
            }
        }
    }

    fun assignCropToDivision(cropId: String, divisionId: String) {
        viewModelScope.launch {
            try {
                cropRepository.assignCropToDivision(cropId = cropId, divisionId = divisionId)
                loadDivisions()
            } catch (e: Exception) {
                _uiState.value = DivisionsUiState.Error(e.message ?: "Failed to assign crop to division")
            }
        }
    }

    fun assignCropsToDivision(cropIds: List<String>, divisionId: String) {
        viewModelScope.launch {
            try {
                cropIds.forEach { cropId ->
                    cropRepository.assignCropToDivision(cropId = cropId, divisionId = divisionId)
                }
                loadDivisions()
            } catch (e: Exception) {
                _uiState.value = DivisionsUiState.Error(e.message ?: "Failed to assign crop to division")
            }
        }
    }

    fun addDivision(
        name: String,
        sizeText: String,
        units: String,
        soilPhText: String?,
        soilHealth: String?
    ) {
        val trimmedName = name.trim()
        val trimmedSize = sizeText.trim()

        if (trimmedName.isBlank()) {
            _saveState.value = DivisionSaveState.Error("Please enter division name.")
            return
        }

        val sizeDouble = trimmedSize.toDoubleOrNull()
        if (sizeDouble == null || sizeDouble <= 0.0) {
            _saveState.value = DivisionSaveState.Error("Please enter a valid size.")
            return
        }

        val soilPhDouble = soilPhText?.trim()?.toDoubleOrNull()

        viewModelScope.launch {
            _saveState.value = DivisionSaveState.Saving

            val result = repository.createDivision(
                name = trimmedName,
                size = sizeDouble,
                units = units,
                soilPh = soilPhDouble,
                soilHealth = soilHealth
            )

            result.fold(
                onSuccess = {
                    _saveState.value = DivisionSaveState.Saved
                    loadDivisions()
                },
                onFailure = { error ->
                    _saveState.value = DivisionSaveState.Error(error.message ?: "Failed to save division.")
                }
            )
        }
    }

    fun deleteDivision(divisionId: String) {
        viewModelScope.launch {
            try {
                repository.deleteDivision(divisionId)
                loadDivisions()
            } catch (e: Exception) {
                _uiState.value = DivisionsUiState.Error(e.message ?: "Failed to delete division")
            }
        }
    }

    fun resetSaveState() {
        _saveState.value = DivisionSaveState.Idle
    }
}
