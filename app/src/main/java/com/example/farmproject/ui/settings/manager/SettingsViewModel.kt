package com.example.farmproject.ui.settings.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.Farm
import com.example.farmproject.data.repository.AuthRepository
import com.example.farmproject.data.repository.FarmRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface SettingsUiState {
    data object Loading : SettingsUiState
    data class Success(
        val fullName: String,
        val email: String,
        val phoneNumber: String,
        val farmName: String,
        val farmSize: Double,
        val farmUnit: String,
        val county: String,
        val soilPh: Double?,
        val soilHealth: String?
    ) : SettingsUiState
    data class Error(val message: String) : SettingsUiState
}

sealed interface ProfileSaveState {
    data object Idle : ProfileSaveState
    data object Saving : ProfileSaveState
    data object Saved : ProfileSaveState
    data class Error(val message: String) : ProfileSaveState
}

class SettingsViewModel(
    private val authRepository: AuthRepository = AuthRepository(),
    private val farmRepository: FarmRepository = FarmRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<SettingsUiState>(SettingsUiState.Loading)
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    private val _saveState = MutableStateFlow<ProfileSaveState>(ProfileSaveState.Idle)
    val saveState: StateFlow<ProfileSaveState> = _saveState.asStateFlow()

    init {
        loadSettings()
    }

    fun loadSettings() {
        viewModelScope.launch {
            _uiState.value = SettingsUiState.Loading
            try {
                val userId = CurrentSession.userId ?: ""
                val farmId = CurrentSession.farmId

                val farm: Farm? = if (farmId.isNotBlank()) {
                    farmRepository.getFarmById(farmId)
                } else if (userId.isNotBlank()) {
                    farmRepository.getFarmForUser(userId)
                } else null

                _uiState.value = SettingsUiState.Success(
                    fullName = CurrentSession.fullName ?: "",
                    email = CurrentSession.email ?: "",
                    phoneNumber = CurrentSession.phoneNumber ?: "",
                    farmName = farm?.name ?: "Mountain View Farm",
                    farmSize = farm?.totalSize ?: 10.0,
                    farmUnit = farm?.unit ?: "Acres",
                    county = farm?.county ?: "Nairobi",
                    soilPh = farm?.soilPh,
                    soilHealth = farm?.soilHealth
                )
            } catch (e: Exception) {
                _uiState.value = SettingsUiState.Error(e.message ?: "Failed to load profile details")
            }
        }
    }

    fun saveManagerProfile(
        fullName: String,
        phoneNumber: String?
    ) {
        viewModelScope.launch {
            _saveState.value = ProfileSaveState.Saving
            try {
                val userId = CurrentSession.userId ?: ""

                if (userId.isNotBlank()) {
                    authRepository.updateUserProfile(userId, fullName, phoneNumber)
                }

                CurrentSession.updateSession(
                    userId = userId,
                    fullName = fullName,
                    email = CurrentSession.email ?: "",
                    phoneNumber = phoneNumber,
                    userRole = CurrentSession.userRole ?: "Manager",
                    farmId = CurrentSession.farmId
                )

                _saveState.value = ProfileSaveState.Saved
                loadSettings()
            } catch (e: Exception) {
                _saveState.value = ProfileSaveState.Error(e.message ?: "Failed to save profile changes")
            }
        }
    }

    fun saveFarmDetails(
        farmName: String,
        farmSize: Double,
        farmUnit: String,
        county: String,
        soilPh: Double?,
        soilHealth: String?
    ) {
        viewModelScope.launch {
            _saveState.value = ProfileSaveState.Saving
            try {
                val farmId = CurrentSession.farmId

                if (farmId.isNotBlank()) {
                    farmRepository.updateFarmDetails(
                        farmId = farmId,
                        name = farmName,
                        totalSize = farmSize,
                        unit = farmUnit,
                        county = county,
                        soilPh = soilPh,
                        soilHealth = soilHealth
                    )
                }

                _saveState.value = ProfileSaveState.Saved
                loadSettings()
            } catch (e: Exception) {
                _saveState.value = ProfileSaveState.Error(e.message ?: "Failed to save farm details")
            }
        }
    }

    fun resetSaveState() {
        _saveState.value = ProfileSaveState.Idle
    }
}
