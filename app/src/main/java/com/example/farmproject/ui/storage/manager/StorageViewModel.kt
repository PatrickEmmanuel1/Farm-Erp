package com.example.farmproject.ui.storage.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.StorageFacility
import com.example.farmproject.data.model.StoredProduce
import com.example.farmproject.data.repository.StorageRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate

sealed interface StorageUiState {
    data object Loading : StorageUiState
    data class Success(
        val items: List<StoredProduce>,
        val facilities: List<StorageFacility> = emptyList()
    ) : StorageUiState
    data class Error(val message: String) : StorageUiState
}

class StorageViewModel(
    private val repository: StorageRepository = StorageRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<StorageUiState>(StorageUiState.Loading)
    val uiState: StateFlow<StorageUiState> = _uiState.asStateFlow()

    init {
        loadStorage()
    }

    fun loadStorage() {
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = StorageUiState.Loading
            try {
                val farmId = CurrentSession.farmId
                coroutineScope {
                    val produceDeferred = async { repository.getStorageForFarm(farmId) }
                    val facilitiesDeferred = async { repository.getFacilitiesForFarm(farmId) }

                    val produceItems = produceDeferred.await()
                    val facilitiesList = facilitiesDeferred.await()

                    _uiState.value = StorageUiState.Success(
                        items = produceItems,
                        facilities = facilitiesList
                    )
                }
            } catch (e: Exception) {
                _uiState.value = StorageUiState.Error(e.message ?: "Failed to load storage data")
            }
        }
    }

    fun addFacility(
        name: String,
        facilityType: String,
        capacityKg: Double,
        condition: String,
        locationNote: String?,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        viewModelScope.launch(Dispatchers.IO) {
            val facility = StorageFacility(
                farmId = CurrentSession.farmId,
                name = name.trim(),
                facilityType = facilityType,
                capacityKg = capacityKg,
                condition = condition,
                locationNote = locationNote?.trim()?.ifBlank { null }
            )
            val result = repository.createFacility(facility)
            if (result.isSuccess) {
                loadStorage()
                onSuccess()
            } else {
                onError(result.exceptionOrNull()?.message ?: "Failed to create storage facility")
            }
        }
    }

    fun addProduce(
        cropName: String,
        quantity: Double,
        unit: String,
        location: String,
        dateStored: String,
        condition: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        viewModelScope.launch(Dispatchers.IO) {
            val produce = StoredProduce(
                farmId = CurrentSession.farmId,
                cropName = cropName.trim(),
                quantity = quantity,
                unit = unit.trim(),
                location = location.trim(),
                dateStored = dateStored.ifBlank { LocalDate.now().toString() },
                condition = condition.trim().ifBlank { "Good" },
                needsAttention = condition.contains("Spoiled", ignoreCase = true) || condition.contains("Poor", ignoreCase = true)
            )
            val result = repository.addStoredProduce(produce)
            if (result.isSuccess) {
                loadStorage()
                onSuccess()
            } else {
                onError(result.exceptionOrNull()?.message ?: "Failed to record stored produce")
            }
        }
    }
}
