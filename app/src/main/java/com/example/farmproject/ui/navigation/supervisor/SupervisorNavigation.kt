package com.example.farmproject.ui.navigation.supervisor

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Forum
import androidx.compose.material.icons.filled.Inventory
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.PrecisionManufacturing
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavBackStackEntry
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.farmproject.data.model.InventoryCategory
import com.example.farmproject.data.repository.ChatRepository
import com.example.farmproject.ui.activities.manager.FarmActivitiesUiState
import com.example.farmproject.ui.activities.manager.FarmActivitiesViewModel
import com.example.farmproject.ui.activities.manager.ManagerAddFarmActivityScreen
import com.example.farmproject.ui.activities.manager.ManagerEditFarmActivityScreen
import com.example.farmproject.ui.activities.manager.ManagerFarmActivitiesScreen
import com.example.farmproject.ui.activities.manager.ManagerFarmActivityDetailsScreen
import com.example.farmproject.ui.activities.supervisor.SupervisorFarmActivitiesScreen
import com.example.farmproject.ui.attendance.supervisor.SupervisorAttendanceScreen
import com.example.farmproject.ui.chat.ChatRoutes
import com.example.farmproject.ui.chat.chatGraph
import com.example.farmproject.ui.dashboard.supervisor.SupervisorDashboardScreen
import com.example.farmproject.ui.inventory.manager.InventoryUiState
import com.example.farmproject.ui.inventory.manager.InventoryViewModel
import com.example.farmproject.ui.inventory.manager.ManagerAddInventoryScreen
import com.example.farmproject.ui.inventory.manager.ManagerInventoryCategoryItemsScreen
import com.example.farmproject.ui.inventory.manager.ManagerInventoryDetailsScreen
import com.example.farmproject.ui.inventory.manager.ManagerInventoryScreen
import com.example.farmproject.ui.machinery.manager.MachineryDetailUiState
import com.example.farmproject.ui.machinery.manager.MachineryViewModel
import com.example.farmproject.ui.machinery.manager.ManagerAddMachineryScreen
import com.example.farmproject.ui.machinery.manager.ManagerMachineryDetailsScreen
import com.example.farmproject.ui.machinery.manager.ManagerMachineryInUseScreen
import com.example.farmproject.ui.machinery.manager.ManagerMachineryMaintenanceScreen
import com.example.farmproject.ui.machinery.manager.ManagerMachineryScreen
import com.example.farmproject.ui.more.supervisor.SupervisorMoreScreen
import com.example.farmproject.ui.notifications.manager.ManagerNotificationsScreen
import com.example.farmproject.ui.notifications.manager.NotificationViewModel
import com.example.farmproject.ui.notifications.supervisor.SupervisorNotificationsScreen
import com.example.farmproject.ui.settings.supervisor.SupervisorProfileScreen
import com.example.farmproject.ui.settings.supervisor.SupervisorSettingsScreen
import java.util.Locale

private sealed class SupervisorTab(
    val route: String,
    val title: String,
    val icon: ImageVector
) {
    data object Dashboard : SupervisorTab(
        route = "supervisor_tab_dashboard",
        title = "Dashboard",
        icon = Icons.Default.Dashboard
    )

    data object Messages : SupervisorTab(
        route = ChatRoutes.LIST,
        title = "Messages",
        icon = Icons.Default.Forum
    )

    data object Settings : SupervisorTab(
        route = SupervisorRoutes.SETTINGS,
        title = "Settings",
        icon = Icons.Default.Settings
    )

    data object More : SupervisorTab(
        route = "supervisor_tab_more",
        title = "More",
        icon = Icons.Default.Menu
    )
}

private object SupervisorRoutes {
    const val SETTINGS = "supervisor_settings"
    const val PROFILE = "supervisor_profile"
    const val NOTIFICATIONS = "supervisor_notifications"
    const val ACTIVITIES = "supervisor_tab_activities"
    const val INVENTORY = "supervisor_tab_inventory"
    const val MACHINERY = "supervisor_tab_machinery"
    const val ADD_FARM_ACTIVITY = "supervisor_add_farm_activity"
    const val EDIT_FARM_ACTIVITY = "supervisor_edit_farm_activity/{activityId}"
    const val FARM_ACTIVITY_DETAILS = "supervisor_farm_activity_details/{activityId}"
    const val INVENTORY_DETAILS = "supervisor_inventory_details/{itemId}"
    const val ADD_INVENTORY = "supervisor_add_inventory?category={categoryName}"
    const val MACHINERY_DETAILS = "supervisor_machinery_details/{machineryId}"
    const val ADD_MACHINERY = "supervisor_add_machinery"
    const val MACHINERY_IN_USE = "supervisor_machinery_in_use"
    const val MACHINERY_MAINTENANCE = "supervisor_machinery_maintenance"
    const val ATTENDANCE = "supervisor_attendance"
}

@Composable
private inline fun <reified VM : ViewModel> sharedViewModel(
    navController: NavHostController,
    route: String,
    backStackEntry: NavBackStackEntry
): VM {
    val parentEntry = remember(backStackEntry) {
        try {
            navController.getBackStackEntry(route)
        } catch (_: Exception) {
            backStackEntry
        }
    }
    return viewModel(parentEntry)
}

@Composable
fun SupervisorNavigation(
    onLogout: () -> Unit = {}
) {
    val navController = rememberNavController()
    val chatRepository = remember { ChatRepository() }

    val tabs = listOf(
        SupervisorTab.Dashboard,
        SupervisorTab.Messages,
        SupervisorTab.Settings,
        SupervisorTab.More
    )

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    val formRoutes = setOf(
        SupervisorRoutes.ADD_INVENTORY,
        SupervisorRoutes.ADD_FARM_ACTIVITY,
        SupervisorRoutes.EDIT_FARM_ACTIVITY,
        SupervisorRoutes.ADD_MACHINERY,
        SupervisorRoutes.PROFILE
    )

    val isFormScreen = currentRoute in formRoutes || currentRoute?.startsWith("supervisor_add_inventory") == true

    fun navigateToTab(route: String) {
        navController.navigate(route) {
            popUpTo(navController.graph.findStartDestination().id) {
                saveState = true
            }
            launchSingleTop = true
            restoreState = true
        }
    }

    Scaffold(
        bottomBar = {
            if (!isFormScreen) {
                NavigationBar {
                    tabs.forEach { tab ->
                        NavigationBarItem(
                            selected = currentRoute == tab.route,
                            onClick = { navigateToTab(tab.route) },
                            icon = {
                                Icon(
                                    imageVector = tab.icon,
                                    contentDescription = tab.title
                                )
                            },
                            label = { Text(tab.title) }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = SupervisorTab.Dashboard.route,
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // 1. DASHBOARD
            composable(SupervisorTab.Dashboard.route) {
                SupervisorDashboardScreen(
                    onActivitiesClick = { navController.navigate(SupervisorRoutes.ACTIVITIES) },
                    onInventoryClick = { navController.navigate(SupervisorRoutes.INVENTORY) },
                    onMachineryClick = { navController.navigate(SupervisorRoutes.MACHINERY) },
                    onAttendanceClick = { navController.navigate(SupervisorRoutes.ATTENDANCE) },
                    onLogoutClick = onLogout
                )
            }

            // 2. ACTIVITIES
            composable(SupervisorRoutes.ACTIVITIES) {
                val viewModel: FarmActivitiesViewModel = viewModel()
                SupervisorFarmActivitiesScreen(
                    viewModel = viewModel,
                    onBackClick = { navigateToTab(SupervisorTab.Dashboard.route) },
                    onActivityClick = { activityId ->
                        navController.navigate("supervisor_farm_activity_details/$activityId")
                    }
                )
            }

            composable(SupervisorRoutes.ADD_FARM_ACTIVITY) { backStackEntry ->
                val viewModel: FarmActivitiesViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.ACTIVITIES,
                    backStackEntry = backStackEntry
                )
                val formOptions by viewModel.formOptions.collectAsStateWithLifecycle()

                ManagerAddFarmActivityScreen(
                    viewModel = viewModel,
                    activityTypes = formOptions.activityTypeNames,
                    divisions = formOptions.divisions,
                    machineryList = formOptions.machinery,
                    workers = formOptions.workers,
                    supervisors = formOptions.supervisors,
                    onBackClick = { navController.popBackStack() },
                    onSaveClick = { activityTypeName, activityName, dueDate, notes, assignedRole, workerProfileId, supervisorProfileId, divisionId, quantity, quantityUnit, equipmentNeeded ->
                        viewModel.addActivity(
                            activityTypeName = activityTypeName,
                            activityName = activityName,
                            activityDate = dueDate,
                            status = "Pending",
                            notes = notes,
                            assignedRole = assignedRole,
                            workerProfileId = workerProfileId,
                            supervisorProfileId = supervisorProfileId,
                            divisionId = divisionId,
                            quantity = quantity,
                            quantityUnit = quantityUnit,
                            equipmentNeeded = equipmentNeeded
                        )
                    }
                )
            }

            composable(
                route = SupervisorRoutes.FARM_ACTIVITY_DETAILS,
                arguments = listOf(navArgument("activityId") { type = NavType.StringType })
            ) { backStackEntry ->
                val activityId = backStackEntry.arguments?.getString("activityId").orEmpty()
                val viewModel: FarmActivitiesViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.ACTIVITIES,
                    backStackEntry = backStackEntry
                )

                val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                val formOptions by viewModel.formOptions.collectAsStateWithLifecycle()

                val display = (uiState as? FarmActivitiesUiState.Success)?.activities
                    ?.find { it.activity.activityId == activityId }

                val status = display?.activity?.status ?: "Pending"

                val durationText = if (display?.activity != null) {
                    val act = display.activity
                    if (act.durationHours != null && act.durationHours > 0) {
                        val hrs = act.durationHours
                        if (hrs == 1.0) "1.0 hr" else String.format(Locale.US, "%.1f hrs", hrs)
                    } else "1.0 hr"
                } else "1.0 hr"

                ManagerFarmActivityDetailsScreen(
                    title = display?.displayTitle ?: "Unknown activity",
                    type = display?.activityTypeName ?: "",
                    assignedTo = display?.assignedToName ?: "Unassigned",
                    dueDate = display?.activity?.safeActivityDate ?: "",
                    durationText = durationText,
                    status = status,
                    isOverdue = status.equals("Overdue", ignoreCase = true),
                    notes = display?.activity?.notes ?: "No additional notes recorded for this activity.",
                    quantity = display?.activity?.quantity,
                    quantityUnit = display?.activity?.quantityUnit,
                    equipmentNeeded = display?.activity?.equipmentNeeded,
                    workers = formOptions.workers,
                    supervisors = formOptions.supervisors,
                    onBackClick = { navController.popBackStack() },
                    onStartClick = { viewModel.startActivity(activityId) },
                    onCompleteClick = { viewModel.completeActivity(activityId) },
                    onAssignSave = { isSupervisor, profileId -> viewModel.assignActivity(activityId, isSupervisor, profileId) },
                    onEditClick = { navController.navigate("supervisor_edit_farm_activity/$activityId") },
                    onDeleteClick = {
                        viewModel.deleteActivity(activityId)
                        navController.popBackStack()
                    }
                )
            }

            composable(
                route = SupervisorRoutes.EDIT_FARM_ACTIVITY,
                arguments = listOf(navArgument("activityId") { type = NavType.StringType })
            ) { backStackEntry ->
                val activityId = backStackEntry.arguments?.getString("activityId").orEmpty()
                val viewModel: FarmActivitiesViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.ACTIVITIES,
                    backStackEntry = backStackEntry
                )

                val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                val formOptions by viewModel.formOptions.collectAsStateWithLifecycle()

                val display = (uiState as? FarmActivitiesUiState.Success)?.activities
                    ?.find { it.activity.activityId == activityId }

                ManagerEditFarmActivityScreen(
                    activityId = activityId,
                    initialType = display?.activityTypeName.orEmpty(),
                    initialName = display?.activity?.activityName.orEmpty(),
                    initialDueDate = display?.activity?.safeActivityDate.orEmpty(),
                    initialNotes = display?.activity?.notes.orEmpty(),
                    initialRole = display?.assignedToName.orEmpty(),
                    initialWorkerProfileId = display?.activity?.workerProfileId,
                    initialSupervisorProfileId = display?.activity?.supervisorProfileId,
                    initialDivisionId = display?.activity?.divisionId,
                    initialQuantity = display?.activity?.quantity,
                    initialQuantityUnit = display?.activity?.quantityUnit,
                    initialEquipmentNeeded = display?.activity?.equipmentNeeded,
                    viewModel = viewModel,
                    activityTypes = formOptions.activityTypeNames,
                    divisions = formOptions.divisions,
                    machineryList = formOptions.machinery,
                    workers = formOptions.workers,
                    supervisors = formOptions.supervisors,
                    onBackClick = { navController.popBackStack() },
                    onSaveClick = { activityTypeName, activityName, dueDate, notes, assignedRole, workerProfileId, supervisorProfileId, divisionId, quantity, quantityUnit, equipmentNeeded ->
                        viewModel.updateActivity(
                            activityId = activityId,
                            activityTypeName = activityTypeName,
                            activityName = activityName,
                            activityDate = dueDate,
                            notes = notes,
                            assignedRole = assignedRole,
                            workerProfileId = workerProfileId,
                            supervisorProfileId = supervisorProfileId,
                            divisionId = divisionId,
                            quantity = quantity,
                            quantityUnit = quantityUnit,
                            equipmentNeeded = equipmentNeeded
                        )
                    }
                )
            }

            // 3. INVENTORY
            composable(SupervisorRoutes.INVENTORY) {
                val viewModel: InventoryViewModel = viewModel()
                ManagerInventoryScreen(
                    viewModel = viewModel,
                    onBackClick = { navigateToTab(SupervisorTab.Dashboard.route) },
                    onCategoryClick = { category ->
                        navController.navigate("supervisor_inventory_category/${category.name}")
                    }
                )
            }

            composable(
                route = "supervisor_inventory_category/{categoryName}",
                arguments = listOf(navArgument("categoryName") { type = NavType.StringType })
            ) { backStackEntry ->
                val categoryName = backStackEntry.arguments?.getString("categoryName").orEmpty()
                val category = InventoryCategory.entries.find { it.name == categoryName } ?: InventoryCategory.FERTILIZER
                val viewModel: InventoryViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.INVENTORY,
                    backStackEntry = backStackEntry
                )

                ManagerInventoryCategoryItemsScreen(
                    category = category,
                    viewModel = viewModel,
                    onBackClick = { navController.popBackStack() },
                    onAddClick = { navController.navigate("supervisor_add_inventory?category=${category.name}") },
                    onItemClick = { itemId -> navController.navigate("supervisor_inventory_details/$itemId") }
                )
            }

            composable(
                route = "supervisor_add_inventory?category={categoryName}",
                arguments = listOf(navArgument("categoryName") { type = NavType.StringType; nullable = true; defaultValue = "Fertilizer" })
            ) { backStackEntry ->
                val categoryName = backStackEntry.arguments?.getString("categoryName") ?: "Fertilizer"
                val viewModel: InventoryViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.INVENTORY,
                    backStackEntry = backStackEntry
                )

                ManagerAddInventoryScreen(
                    initialCategory = categoryName,
                    onBackClick = { navController.popBackStack() },
                    onSaveClick = { category, name, subtype, quantity, unit, reorderLevel, description ->
                        viewModel.addInventoryItem(category, name, subtype, quantity, unit, reorderLevel, description)
                        navController.popBackStack()
                    }
                )
            }

            composable(
                route = SupervisorRoutes.INVENTORY_DETAILS,
                arguments = listOf(navArgument("itemId") { type = NavType.StringType })
            ) { backStackEntry ->
                val itemId = backStackEntry.arguments?.getString("itemId").orEmpty()
                val viewModel: InventoryViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.INVENTORY,
                    backStackEntry = backStackEntry
                )

                val uiState by viewModel.uiState.collectAsStateWithLifecycle()
                val item = (uiState as? InventoryUiState.Success)?.items?.find { it.id == itemId }

                ManagerInventoryDetailsScreen(
                    itemName = item?.name ?: "Unknown item",
                    category = item?.category?.displayName ?: "",
                    quantity = item?.quantity?.toString() ?: "0",
                    unit = item?.unit ?: "",
                    reorderLevel = item?.reorderLevel?.toString() ?: "Not set",
                    isLowStock = item?.isLowStock ?: false,
                    notes = item?.description ?: "No additional notes recorded for this item.",
                    onBackClick = { navController.popBackStack() },
                    onDeleteClick = {
                        item?.let { viewModel.deleteInventoryItem(it.category, it.id) }
                        navController.popBackStack()
                    }
                )
            }

            // 4. MACHINERY
            composable(SupervisorRoutes.MACHINERY) {
                val viewModel: MachineryViewModel = viewModel()
                ManagerMachineryScreen(
                    viewModel = viewModel,
                    onBackClick = { navigateToTab(SupervisorTab.Dashboard.route) },
                    onMachineryClick = { machineryId -> navController.navigate("supervisor_machinery_details/$machineryId") },
                    onAddMachineryClick = { navController.navigate(SupervisorRoutes.ADD_MACHINERY) }
                )
            }

            composable(
                route = SupervisorRoutes.MACHINERY_DETAILS,
                arguments = listOf(navArgument("machineryId") { type = NavType.StringType })
            ) { backStackEntry ->
                val machineryId = backStackEntry.arguments?.getString("machineryId").orEmpty()
                val viewModel: MachineryViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.MACHINERY,
                    backStackEntry = backStackEntry
                )

                LaunchedEffect(machineryId) { viewModel.loadMachineryDetail(machineryId) }

                val detailState by viewModel.detailState.collectAsStateWithLifecycle()
                val success = detailState as? MachineryDetailUiState.Success

                val purchaseCostFormatted = success?.machinery?.purchaseCost?.let {
                    String.format(Locale.US, "KES %,.2f", it)
                } ?: ""

                ManagerMachineryDetailsScreen(
                    machineName = success?.machinery?.name ?: "Loading...",
                    machineType = success?.machinery?.machineryType ?: "",
                    status = success?.machinery?.status ?: "",
                    condition = success?.machinery?.condition ?: "",
                    location = success?.machinery?.location ?: "Not set",
                    purchaseDate = success?.machinery?.purchaseDate.orEmpty(),
                    purchaseCost = purchaseCostFormatted,
                    rawPurchaseCost = success?.machinery?.purchaseCost?.toString().orEmpty(),
                    totalHoursUsed = success?.let { "${it.totalHoursUsed} hrs" } ?: "0 hrs",
                    totalFuelUsed = success?.let { "${it.totalFuelUsed} litres" } ?: "0 litres",
                    lastMaintenance = success?.lastMaintenanceDate ?: "No maintenance recorded",
                    nextMaintenance = success?.nextMaintenanceDate ?: "Not scheduled",
                    onBackClick = { navController.popBackStack() },
                    onEditSave = { name, purchaseDate, purchaseCost ->
                        viewModel.updateMachineryDetails(machineryId, name, purchaseDate, purchaseCost)
                    },
                    onDeleteClick = {
                        viewModel.deleteMachinery(machineryId)
                        navController.popBackStack()
                    },
                    onUsageHistoryClick = { navController.navigate(SupervisorRoutes.MACHINERY_IN_USE) },
                    onMaintenanceHistoryClick = { navController.navigate(SupervisorRoutes.MACHINERY_MAINTENANCE) },
                    onRecordUsageSave = { hrs, fuel, date, notes ->
                        viewModel.recordUsage(machineryId, hrs, fuel, date, notes)
                    }
                )
            }

            composable(SupervisorRoutes.ADD_MACHINERY) { backStackEntry ->
                val viewModel: MachineryViewModel = sharedViewModel(
                    navController = navController,
                    route = SupervisorRoutes.MACHINERY,
                    backStackEntry = backStackEntry
                )

                ManagerAddMachineryScreen(
                    viewModel = viewModel,
                    onBackClick = { navController.popBackStack() },
                    onSaveClick = { name, machineryType, model, serialNumber, purchaseDate, condition ->
                        viewModel.addMachinery(name, machineryType, model, serialNumber, purchaseDate, condition)
                    }
                )
            }

            composable(SupervisorRoutes.MACHINERY_IN_USE) {
                ManagerMachineryInUseScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }

            composable(SupervisorRoutes.MACHINERY_MAINTENANCE) {
                ManagerMachineryMaintenanceScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }

            // 5. MORE
            composable(SupervisorTab.More.route) {
                SupervisorMoreScreen(
                    onBackClick = { navigateToTab(SupervisorTab.Dashboard.route) },
                    onAttendanceClick = { navController.navigate(SupervisorRoutes.ATTENDANCE) },
                    onProfileClick = { navController.navigate(SupervisorRoutes.PROFILE) },
                    onSettingsClick = { navController.navigate(SupervisorRoutes.SETTINGS) },
                    onLogoutClick = onLogout
                )
            }

            composable(SupervisorRoutes.ATTENDANCE) {
                SupervisorAttendanceScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }

            // SETTINGS
            composable(SupervisorRoutes.SETTINGS) {
                SupervisorSettingsScreen(
                    onBackClick = { navController.popBackStack() },
                    onProfileClick = { navController.navigate(SupervisorRoutes.PROFILE) },
                    onNotificationsClick = { navController.navigate(SupervisorRoutes.NOTIFICATIONS) }
                )
            }

            // PROFILE
            composable(SupervisorRoutes.PROFILE) {
                SupervisorProfileScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }

            // NOTIFICATIONS
            composable(SupervisorRoutes.NOTIFICATIONS) {
                val viewModel: NotificationViewModel = viewModel()
                SupervisorNotificationsScreen(
                    viewModel = viewModel,
                    onBackClick = { navController.popBackStack() }
                )
            }

            chatGraph(navController, chatRepository)
        }
    }
}
