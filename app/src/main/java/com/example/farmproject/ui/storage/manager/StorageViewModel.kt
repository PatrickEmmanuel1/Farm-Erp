package com.example.farmproject.ui.storage.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.StoredProduce
import com.example.farmproject.data.repository.StorageRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface StorageUiState {
    data object Loading : StorageUiState
    data class Success(val items: List<StoredProduce>) : StorageUiState
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
        viewModelScope.launch {
            _uiState.value = StorageUiState.Loading
            try {
                val items = repository.getStorageForFarm(CurrentSession.farmId)
                _uiState.value = StorageUiState.Success(items)
            } catch (e: Exception) {
                _uiState.value = StorageUiState.Error(e.message ?: "Failed to load storage data")
            }
        }
    }
}
