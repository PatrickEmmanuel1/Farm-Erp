package com.example.farmproject.ui.farm

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.repository.FarmRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface CreateFarmState {
    data object Idle : CreateFarmState
    data object Saving : CreateFarmState
    data object Success : CreateFarmState
    data class Error(val message: String) : CreateFarmState
}

class CreateFarmViewModel(
    private val farmRepository: FarmRepository = FarmRepository()
) : ViewModel() {

    private val _saveState = MutableStateFlow<CreateFarmState>(CreateFarmState.Idle)
    val saveState: StateFlow<CreateFarmState> = _saveState.asStateFlow()

    fun createFarm(
        farmName: String,
        county: String,
        subCounty: String?,
        sizeText: String,
        unit: String
    ) {
        val trimmedName = farmName.trim()
        val trimmedCounty = county.trim()
        val trimmedSize = sizeText.trim()

        if (trimmedName.isBlank()) {
            _saveState.value = CreateFarmState.Error("Please enter your farm name.")
            return
        }

        if (trimmedCounty.isBlank()) {
            _saveState.value = CreateFarmState.Error("Please select or enter your farm county.")
            return
        }

        val sizeDouble = trimmedSize.toDoubleOrNull()
        if (sizeDouble == null || sizeDouble < 1.0 || sizeDouble > 10000.0) {
            _saveState.value = CreateFarmState.Error("Farm size must be between 1 and 10,000 $unit.")
            return
        }

        viewModelScope.launch {
            _saveState.value = CreateFarmState.Saving

            val result = farmRepository.createFarm(
                name = trimmedName,
                county = trimmedCounty,
                subCounty = subCounty,
                totalSize = sizeDouble,
                unit = unit
            )

            result.fold(
                onSuccess = {
                    _saveState.value = CreateFarmState.Success
                },
                onFailure = { error ->
                    _saveState.value = CreateFarmState.Error(error.message ?: "Failed to create farm.")
                }
            )
        }
    }

    fun resetState() {
        _saveState.value = CreateFarmState.Idle
    }
}
