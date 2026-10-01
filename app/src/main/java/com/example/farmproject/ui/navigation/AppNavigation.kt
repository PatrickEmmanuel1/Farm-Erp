package com.example.farmproject.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.farmproject.data.repository.AuthRepository
import com.example.farmproject.data.session.CurrentSession
import com.example.farmproject.ui.auth.manager.ManagerLoginScreen
import com.example.farmproject.ui.auth.manager.ManagerSignUpScreen
import com.example.farmproject.ui.auth.supervisor.SupervisorLoginScreen
import com.example.farmproject.ui.auth.worker.WorkerLoginScreen
import com.example.farmproject.ui.dashboard.supervisor.SupervisorDashboardScreen
import com.example.farmproject.ui.dashboard.worker.WorkerDashboardScreen
import com.example.farmproject.ui.farm.CreateFarmScreen
import com.example.farmproject.ui.navigation.manager.ManagerNavigation
import com.example.farmproject.ui.role.RoleSelectionScreen
import com.example.farmproject.ui.splash.SplashScreen
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.launch

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val authRepository = remember { AuthRepository() }
    val sessionStatus by authRepository.sessionStatus.collectAsState()

    // Requirement 3: Reacting when session ends (logout or session revoked)
    LaunchedEffect(sessionStatus) {
        if (sessionStatus is SessionStatus.NotAuthenticated) {
            CurrentSession.clear()
            val currentRoute = navController.currentDestination?.route
            if (currentRoute != null &&
                currentRoute != AppRoute.Splash.route &&
                currentRoute != AppRoute.RoleSelection.route &&
                currentRoute != AppRoute.ManagerLogin.route &&
                currentRoute != AppRoute.ManagerSignUp.route &&
                currentRoute != AppRoute.SupervisorLogin.route &&
                currentRoute != AppRoute.WorkerLogin.route
            ) {
                navController.navigate(AppRoute.RoleSelection.route) {
                    popUpTo(0) { inclusive = true }
                }
            }
        }
    }

    NavHost(
        navController = navController,
        startDestination = AppRoute.Splash.route
    ) {

        // --------------------------------
        // Requirement 2: Splash Screen Routing
        // --------------------------------
        composable(AppRoute.Splash.route) {
            val coroutineScope = rememberCoroutineScope()

            SplashScreen(
                onSplashFinished = {
                    coroutineScope.launch {
                        // Requirement 1: Restores session profile details + farmId
                        val isSessionActive = authRepository.restoreSession()

                        val targetRoute = if (isSessionActive) {
                            when (CurrentSession.userRole?.lowercase()) {
                                "supervisor" -> AppRoute.SupervisorDashboard.route
                                "worker" -> AppRoute.WorkerDashboard.route
                                else -> if (CurrentSession.farmId.isNotBlank()) AppRoute.ManagerDashboard.route else AppRoute.CreateFarm.route
                            }
                        } else {
                            AppRoute.RoleSelection.route
                        }

                        navController.navigate(targetRoute) {
                            popUpTo(AppRoute.Splash.route) {
                                inclusive = true
                            }
                        }
                    }
                }
            )
        }

        // --------------------------------
        // Role Selection
        // --------------------------------
        composable(AppRoute.RoleSelection.route) {
            RoleSelectionScreen(
                onManagerSelected = {
                    navController.navigate(AppRoute.ManagerLogin.route)
                },
                onSupervisorSelected = {
                    navController.navigate(AppRoute.SupervisorLogin.route)
                },
                onWorkerSelected = {
                    navController.navigate(AppRoute.WorkerLogin.route)
                }
            )
        }

        // --------------------------------
        // Manager Login
        // --------------------------------
        composable(AppRoute.ManagerLogin.route) {
            ManagerLoginScreen(
                onLoginSuccess = {
                    val targetRoute = if (CurrentSession.farmId.isNotBlank()) AppRoute.ManagerDashboard.route else AppRoute.CreateFarm.route
                    navController.navigate(targetRoute) {
                        popUpTo(AppRoute.ManagerLogin.route) {
                            inclusive = true
                        }
                    }
                },
                onSignUpClick = {
                    navController.navigate(AppRoute.ManagerSignUp.route)
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        // --------------------------------
        // Manager Sign Up
        // --------------------------------
        composable(AppRoute.ManagerSignUp.route) {
            ManagerSignUpScreen(
                onSignUpSuccess = {
                    val targetRoute = if (CurrentSession.farmId.isNotBlank()) AppRoute.ManagerDashboard.route else AppRoute.CreateFarm.route
                    navController.navigate(targetRoute) {
                        popUpTo(AppRoute.RoleSelection.route) {
                            inclusive = true
                        }
                    }
                },
                onLoginClick = {
                    navController.popBackStack()
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        // --------------------------------
        // Create Farm
        // --------------------------------
        composable(AppRoute.CreateFarm.route) {
            CreateFarmScreen(
                onFarmCreated = {
                    navController.navigate(AppRoute.ManagerDashboard.route) {
                        popUpTo(AppRoute.CreateFarm.route) {
                            inclusive = true
                        }
                    }
                }
            )
        }

        // --------------------------------
        // Manager Navigation
        // --------------------------------
        composable(AppRoute.ManagerDashboard.route) {
            val coroutineScope = rememberCoroutineScope()

            ManagerNavigation(
                onLogout = {
                    coroutineScope.launch {
                        authRepository.logout()
                    }
                }
            )
        }

        // --------------------------------
        // Supervisor Login
        // --------------------------------
        composable(AppRoute.SupervisorLogin.route) {
            SupervisorLoginScreen(
                onLoginSuccess = {
                    navController.navigate(AppRoute.SupervisorDashboard.route)
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        // --------------------------------
        // Worker Login
        // --------------------------------
        composable(AppRoute.WorkerLogin.route) {
            WorkerLoginScreen(
                onLoginSuccess = {
                    navController.navigate(AppRoute.WorkerDashboard.route)
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        // --------------------------------
        // Supervisor Dashboard
        // --------------------------------
        composable(AppRoute.SupervisorDashboard.route) {
            val coroutineScope = rememberCoroutineScope()
            SupervisorDashboardScreen(
                onLogoutClick = {
                    coroutineScope.launch {
                        authRepository.logout()
                    }
                }
            )
        }

        // --------------------------------
        // Worker Dashboard
        // --------------------------------
        composable(AppRoute.WorkerDashboard.route) {
            val coroutineScope = rememberCoroutineScope()
            WorkerDashboardScreen(
                onLogoutClick = {
                    coroutineScope.launch {
                        authRepository.logout()
                    }
                }
            )
        }
    }
}
