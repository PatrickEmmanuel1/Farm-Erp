package com.example.farmproject.ui.navigation.supervisor

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Agriculture
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Inventory
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.PrecisionManufacturing
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.farmproject.ui.dashboard.manager.ManagerDashboardScreen
import com.example.farmproject.ui.activities.manager.ManagerFarmActivitiesScreen
import com.example.farmproject.ui.crops.manager.ManagerAddCropScreen
import com.example.farmproject.ui.employees.manager.ManagerEmployeesScreen
import com.example.farmproject.ui.crops.manager.ManagerCropDetailsScreen
import com.example.farmproject.ui.crops.manager.ManagerCropsScreen
import com.example.farmproject.ui.inventory.manager.ManagerAddInventoryScreen
import com.example.farmproject.ui.inventory.manager.ManagerInventoryDetailsScreen
import com.example.farmproject.ui.inventory.manager.ManagerInventoryScreen
import com.example.farmproject.ui.machinery.manager.ManagerAddMachineryScreen
import com.example.farmproject.ui.machinery.manager.ManagerMachineryDetailsScreen
import com.example.farmproject.ui.machinery.manager.ManagerMachineryScreen
import com.example.farmproject.ui.more.manager.ManagerMoreScreen

private sealed class ManagerTab(
    val route: String,
    val title: String,
    val icon: ImageVector
) {

    data object Dashboard : ManagerTab(
        route = "manager_dashboard",
        title = "Dashboard",
        icon = Icons.Default.Dashboard
    )

    data object Crops : ManagerTab(
        route = "manager_crops",
        title = "Crops",
        icon = Icons.Default.Agriculture
    )

    data object Inventory : ManagerTab(
        route = "manager_inventory",
        title = "Inventory",
        icon = Icons.Default.Inventory
    )

    data object Machinery : ManagerTab(
        route = "manager_machinery",
        title = "Machinery",
        icon = Icons.Default.PrecisionManufacturing
    )

    data object More : ManagerTab(
        route = "manager_more",
        title = "More",
        icon = Icons.Default.Menu
    )
}

private object ManagerRoutes {
    const val MACHINERY_DETAILS = "manager_machinery_details"
    const val ADD_MACHINERY = "manager_add_machinery"
    const val ADD_INVENTORY = "manager_add_inventory"
    const val INVENTORY_DETAILS = "manager_inventory_details"
    const val ADD_CROP = "manager_add_crop"
    const val CROP_DETAILS = "manager_crop_details"
    const val FARM_ACTIVITIES = "manager_farm_activities"
    const val EMPLOYEES = "manager_employees"
}

@Composable
fun ManagerNavigation() {

    val navController = rememberNavController()

    val tabs = listOf(
        ManagerTab.Dashboard,
        ManagerTab.Crops,
        ManagerTab.Inventory,
        ManagerTab.Machinery,
        ManagerTab.More
    )

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {

            NavigationBar {

                tabs.forEach { tab ->

                    NavigationBarItem(
                        selected = currentRoute == tab.route,

                        onClick = {
                            navController.navigate(tab.route) {

                                popUpTo(
                                    ManagerTab.Dashboard.route
                                ) {
                                    saveState = true
                                }

                                launchSingleTop = true
                                restoreState = true
                            }
                        },

                        icon = {
                            Icon(
                                imageVector = tab.icon,
                                contentDescription = tab.title
                            )
                        },

                        label = {
                            Text(tab.title)
                        }
                    )
                }
            }
        }
    ) { innerPadding ->

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {

            NavHost(
                navController = navController,
                startDestination = ManagerTab.Dashboard.route
            ) {

                composable(ManagerTab.Dashboard.route) {
                    ManagerDashboardScreen()
                }

                composable(ManagerTab.Crops.route) {
                    ManagerCropsScreen(
                        onAddClick = {
                            navController.navigate(
                                ManagerRoutes.ADD_CROP
                            )
                        },
                        onCropClick = {
                            navController.navigate(
                                ManagerRoutes.CROP_DETAILS
                            )
                        }
                    )
                }

                // Add Crop screen
                composable(ManagerRoutes.ADD_CROP) {
                    ManagerAddCropScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onSaveClick = { _, _, _ ->
                            navController.popBackStack()
                        }
                    )
                }

                // Crop details screen
                composable(ManagerRoutes.CROP_DETAILS) {
                    ManagerCropDetailsScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onEditClick = {
                            // No edit flow yet.
                        },
                        onDeleteClick = {
                            // No backend yet — just return to the list for now.
                            navController.popBackStack()
                        }
                    )
                }

                composable(ManagerTab.Inventory.route) {
                    ManagerInventoryScreen(
                        onAddClick = {
                            navController.navigate(
                                ManagerRoutes.ADD_INVENTORY
                            )
                        },
                        onCategoryClick = { category ->
                            navController.navigate(
                                "manager_inventory_category/${category.name}"
                            )
                        }
                    )
                }

                // Add Inventory screen
                composable(ManagerRoutes.ADD_INVENTORY) {
                    ManagerAddInventoryScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onSaveClick = { _, _, _, _, _, _, _ ->
                            // No backend yet — just return to the list for now.
                            navController.popBackStack()
                        }
                    )
                }

                // Inventory details screen
                composable(ManagerRoutes.INVENTORY_DETAILS) {
                    ManagerInventoryDetailsScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onEditClick = {
                            // No edit flow yet.
                        },
                        onDeleteClick = {
                            // No backend yet — just return to the list for now.
                            navController.popBackStack()
                        }
                    )
                }

                // Machinery screen
                composable(ManagerTab.Machinery.route) {
                    ManagerMachineryScreen(
                        onMachineryClick = {
                            navController.navigate(
                                ManagerRoutes.MACHINERY_DETAILS
                            )
                        },
                        onAddMachineryClick = {
                            navController.navigate(
                                ManagerRoutes.ADD_MACHINERY
                            )
                        }
                    )
                }

                // Machinery details screen
                composable(ManagerRoutes.MACHINERY_DETAILS) {
                    ManagerMachineryDetailsScreen(
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }
                // Add Machinery screen
                composable(ManagerRoutes.ADD_MACHINERY) {
                    ManagerAddMachineryScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onSaveClick = { _, _, _, _, _, _ ->
                            navController.popBackStack()
                        }
                    )
                }
                composable(ManagerTab.More.route) {
                    ManagerMoreScreen(
                        onFarmActivitiesClick = {
                            navController.navigate(
                                ManagerRoutes.FARM_ACTIVITIES
                            )
                        },
                        onEmployeesClick = {
                            navController.navigate(
                                ManagerRoutes.EMPLOYEES
                            )
                        }
                    )
                }

                // Farm Activities screen
                composable(ManagerRoutes.FARM_ACTIVITIES) {
                    ManagerFarmActivitiesScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onAddClick = {
                            // No add-activity screen yet.
                        },
                        onActivityClick = {
                            // No activity details screen yet.
                        }
                    )
                }

                // Employees screen (Supervisors + Workers tabs)
                composable(ManagerRoutes.EMPLOYEES) {
                    ManagerEmployeesScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onAddSupervisorClick = {
                            // No add-supervisor screen yet.
                        },
                        onAddWorkerClick = {
                            // No add-worker screen yet.
                        },
                        onSupervisorClick = {
                            // No supervisor details screen yet.
                        },
                        onWorkerClick = {
                            // No worker details screen yet.
                        }
                    )
                }
            }
        }
    }
}