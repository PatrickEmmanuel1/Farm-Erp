package com.example.farmproject.ui.dashboard.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.repository.CropRepository
import com.example.farmproject.data.repository.DivisionRepository
import com.example.farmproject.data.repository.EmployeeRepository
import com.example.farmproject.data.repository.FarmActivityRepository
import com.example.farmproject.data.repository.FarmRepository
import com.example.farmproject.data.repository.InventoryRepository
import com.example.farmproject.data.repository.MachineryRepository
import com.example.farmproject.data.session.CurrentSession
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface DashboardUiState {
    data object Loading : DashboardUiState
    data class Success(
        val farmName: String,
        val totalFarmSize: Double,
        val farmUnit: String,
        val totalCrops: Int,
        val totalDivisions: Int,
        val pendingActivities: Int,
        val totalWorkers: Int,
        val totalInventory: Int,
        val totalMachinery: Int,
        val recentActivities: List<String>
    ) : DashboardUiState
    data class Error(val message: String) : DashboardUiState
}

class DashboardViewModel(
    private val farmRepository: FarmRepository = FarmRepository(),
    private val divisionRepository: DivisionRepository = DivisionRepository(),
    private val cropRepository: CropRepository = CropRepository(),
    private val employeeRepository: EmployeeRepository = EmployeeRepository(),
    private val farmActivityRepository: FarmActivityRepository = FarmActivityRepository(),
    private val inventoryRepository: InventoryRepository = InventoryRepository(),
    private val machineryRepository: MachineryRepository = MachineryRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<DashboardUiState>(DashboardUiState.Loading)
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        loadDashboardData()
    }

    fun loadDashboardData() {
        viewModelScope.launch {
            _uiState.value = DashboardUiState.Loading
            try {
                val userId = CurrentSession.userId ?: ""
                var farmId = CurrentSession.farmId

                coroutineScope {
                    val farmDeferred = async { farmRepository.getFarmById(farmId) ?: farmRepository.getFarmForUser(userId) }
                    val farm = farmDeferred.await()
                    if (farm?.farmId != null && farm.farmId.isNotBlank()) {
                        farmId = farm.farmId
                        CurrentSession.farmId = farm.farmId
                    }

                    val divisionsDeferred = async { divisionRepository.getDivisionsForFarm(farmId) }
                    val cropsCatalogDeferred = async { cropRepository.getCropCatalog() }
                    val plantingsDeferred = async { cropRepository.getCropPlantingsForFarm(farmId) }
                    val workersDeferred = async { employeeRepository.getWorkersForFarm(farmId) }
                    val supervisorsDeferred = async { employeeRepository.getSupervisorsForFarm(farmId) }
                    val inventoryDeferred = async { inventoryRepository.getInventoryForFarm(farmId) }
                    val machineryDeferred = async { machineryRepository.getMachineryForFarm(farmId) }
                    val activitiesDeferred = async { farmActivityRepository.getFarmActivitiesForFarm(farmId) }

                    val divisions = divisionsDeferred.await()
                    val cropsCatalog = cropsCatalogDeferred.await()
                    val plantings = plantingsDeferred.await()
                    val workers = workersDeferred.await()
                    val supervisors = supervisorsDeferred.await()
                    val inventory = inventoryDeferred.await()
                    val machinery = machineryDeferred.await()
                    val activities = activitiesDeferred.await()

                    val farmName = farm?.name?.ifBlank { null } ?: "Mountain View Farm"
                    val farmSize = farm?.totalSize ?: plantings.sumOf { it.planting.areaPlanted ?: 0.0 }
                    val farmUnit = farm?.unit?.ifBlank { null } ?: "Acres"

                    val cropsCount = cropsCatalog.size
                    val divisionsCount = divisions.size
                    val totalEmployeesCount = workers.size + supervisors.size
                    val inventoryCount = inventory.size
                    val machineryCount = machinery.size
                    val pendingCount = activities.count { display ->
                        val st = display.activity.safeStatus
                        val isInProgress = st.equals("In Progress", ignoreCase = true) ||
                                st.equals("in_progress", ignoreCase = true) ||
                                st.equals("in progress", ignoreCase = true) ||
                                st.equals("in-progress", ignoreCase = true) ||
                                st.equals("ongoing", ignoreCase = true)
                        val isCompleted = st.equals("Completed", ignoreCase = true) ||
                                st.equals("completed", ignoreCase = true) ||
                                st.equals("done", ignoreCase = true) ||
                                st.equals("finished", ignoreCase = true) ||
                                st.equals("closed", ignoreCase = true)
                        !isInProgress && !isCompleted
                    }

                    val rawActivities = activities
                        .filter { display ->
                            val name = display.activityTypeName
                            !name.contains("current_user_role", ignoreCase = true) &&
                            !name.contains("Authentication", ignoreCase = true) &&
                            !name.contains("delete_", ignoreCase = true)
                        }
                        .take(5)
                        .map { display ->
                            val typeName = display.activityTypeName.take(30)
                            val location = display.divisionName ?: "Farm"
                            "$typeName recorded for $location"
                        }

                    val defaultActivities = listOf(
                        "Farm created ($farmName)",
                        "Fertilizer issued to Division A",
                        "Maize planting recorded",
                        "Worker attendance updated"
                    )

                    _uiState.value = DashboardUiState.Success(
                        farmName = farmName,
                        totalFarmSize = farmSize,
                        farmUnit = farmUnit,
                        totalCrops = cropsCount,
                        totalDivisions = divisionsCount,
                        pendingActivities = pendingCount,
                        totalWorkers = totalEmployeesCount,
                        totalInventory = inventoryCount,
                        totalMachinery = machineryCount,
                        recentActivities = if (rawActivities.isEmpty()) defaultActivities else rawActivities
                    )
                }
            } catch (e: Exception) {
                _uiState.value = DashboardUiState.Error(e.message ?: "Failed to load dashboard data")
            }
        }
    }
}
