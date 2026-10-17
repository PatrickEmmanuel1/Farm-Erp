package com.example.farmproject.ui.crops.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.CropPlantingDisplay
import com.example.farmproject.data.repository.CropHarvestDisplay
import com.example.farmproject.data.repository.CropRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface YieldUiState {
    data object Loading : YieldUiState
    data class Success(
        val harvests: List<CropHarvestDisplay>,
        val activePlantings: List<CropPlantingDisplay>
    ) : YieldUiState
    data class Error(val message: String) : YieldUiState
}

sealed interface YieldSaveState {
    data object Idle : YieldSaveState
    data object Saving : YieldSaveState
    data object Saved : YieldSaveState
    data class Error(val message: String) : YieldSaveState
}

class YieldViewModel(
    private val repository: CropRepository = CropRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<YieldUiState>(YieldUiState.Loading)
    val uiState: StateFlow<YieldUiState> = _uiState.asStateFlow()

    private val _saveState = MutableStateFlow<YieldSaveState>(YieldSaveState.Idle)
    val saveState: StateFlow<YieldSaveState> = _saveState.asStateFlow()

    init {
        loadYieldData()
    }

    fun loadYieldData() {
        viewModelScope.launch {
            _uiState.value = YieldUiState.Loading
            try {
                val farmId = CurrentSession.farmId
                val harvests = repository.getCropHarvestsForFarm(farmId)
                val plantings = repository.getCropPlantingsForFarm(farmId)

                _uiState.value = YieldUiState.Success(
                    harvests = harvests,
                    activePlantings = plantings
                )
            } catch (e: Exception) {
                _uiState.value = YieldUiState.Error(e.message ?: "Failed to load yield records")
            }
        }
    }

    fun recordYield(
        plantingId: String,
        divisionId: String,
        harvestDate: String,
        quantityHarvested: Double,
        quantityUnit: String,
        qualityGrade: String?,
        notes: String?
    ) {
        viewModelScope.launch {
            _saveState.value = YieldSaveState.Saving
            val result = repository.recordCropHarvest(
                plantingId = plantingId,
                divisionId = divisionId,
                harvestDate = harvestDate,
                quantityHarvested = quantityHarvested,
                quantityUnit = quantityUnit,
                qualityGrade = qualityGrade,
                notes = notes
            )
            result.fold(
                onSuccess = {
                    _saveState.value = YieldSaveState.Saved
                    loadYieldData()
                },
                onFailure = { error ->
                    _saveState.value = YieldSaveState.Error(error.message ?: "Failed to record yield")
                }
            )
        }
    }

    fun resetSaveState() {
        _saveState.value = YieldSaveState.Idle
    }
}
