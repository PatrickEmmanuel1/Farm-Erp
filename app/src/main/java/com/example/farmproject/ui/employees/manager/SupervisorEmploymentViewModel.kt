package com.example.farmproject.ui.employees.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.SupervisorDetailsInput
import com.example.farmproject.data.model.SupervisorDetailsRow
import com.example.farmproject.data.repository.EmployeeRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SupervisorEmploymentState(
    val isLoading: Boolean = true,
    val details: SupervisorDetailsRow? = null,
    val loadError: String? = null,
    val isSaving: Boolean = false,
    val saveError: String? = null
)

class SupervisorEmploymentViewModel(
    private val repository: EmployeeRepository = EmployeeRepository()
) : ViewModel() {

    private val _state = MutableStateFlow(SupervisorEmploymentState())
    val state: StateFlow<SupervisorEmploymentState> = _state.asStateFlow()

    fun load(profileId: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, loadError = null) }
            repository.getSupervisorEmploymentDetails(profileId).fold(
                onSuccess = { details ->
                    _state.update { it.copy(isLoading = false, details = details) }
                },
                onFailure = { e ->
                    _state.update {
                        it.copy(
                            isLoading = false,
                            loadError = e.message ?: "Could not load employment details."
                        )
                    }
                }
            )
        }
    }

    fun save(profileId: String, input: SupervisorDetailsInput) {
        if (_state.value.isSaving) return
        viewModelScope.launch {
            _state.update { it.copy(isSaving = true, saveError = null) }
            repository.saveSupervisorDetails(profileId, input).fold(
                onSuccess = { row ->
                    _state.update { it.copy(isSaving = false, details = row) }
                },
                onFailure = { e ->
                    _state.update {
                        it.copy(isSaving = false, saveError = e.message ?: "Could not save details.")
                    }
                }
            )
        }
    }

    fun clearSaveError() {
        _state.update { it.copy(saveError = null) }
    }
}
