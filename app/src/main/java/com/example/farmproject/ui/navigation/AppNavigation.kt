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
import com.example.farmproject.ui.farm.CreateFarmScreen
import com.example.farmproject.ui.navigation.manager.ManagerNavigation
import com.example.farmproject.ui.navigation.supervisor.SupervisorNavigation
import com.example.farmproject.ui.navigation.worker.WorkerNavigation
import com.example.farmproject.ui.role.RoleSelectionScreen
import com.example.farmproject.ui.splash.SplashScreen
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.launch

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val authRepository = remember { AuthRepository() }
    val sessionStatus by authRepository.sessionStatus.collectAsState()

    LaunchedEffect(sessionStatus) {
        if (sessionStatus is SessionStatus.NotAuthenticated) {
            CurrentSession.clear()
            val currentRoute = navController.currentDestination?.route
            if (currentRoute != null &&
                currentRoute != AppRoute.Splash.route &&
                currentRoute != AppRoute.ManagerLogin.route &&
                currentRoute != AppRoute.ManagerSignUp.route
            ) {
                navController.navigate(AppRoute.ManagerLogin.route) {
                    popUpTo(0) { inclusive = true }
                }
            }
        }
    }

    NavHost(
        navController = navController,
        startDestination = AppRoute.Splash.route
    ) {
        // Splash Screen
        composable(AppRoute.Splash.route) {
            val coroutineScope = rememberCoroutineScope()

            SplashScreen(
                onSplashFinished = {
                    coroutineScope.launch {
                        val isSessionActive = authRepository.restoreSession()

                        val targetRoute = if (isSessionActive) {
                            when (CurrentSession.userRole?.lowercase()) {
                                "supervisor" -> AppRoute.SupervisorDashboard.route
                                "worker" -> AppRoute.WorkerDashboard.route
                                else -> if (CurrentSession.farmId.isNotBlank()) AppRoute.ManagerDashboard.route else AppRoute.CreateFarm.route
                            }
                        } else {
                            AppRoute.ManagerLogin.route
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

        // Legacy Role Selection (redirects directly to Unified Login Screen)
        composable(AppRoute.RoleSelection.route) {
            RoleSelectionScreen(
                onManagerSelected = { navController.navigate(AppRoute.ManagerLogin.route) },
                onSupervisorSelected = { navController.navigate(AppRoute.ManagerLogin.route) },
                onWorkerSelected = { navController.navigate(AppRoute.ManagerLogin.route) }
            )
        }

        // Unified Login Screen
        composable(AppRoute.ManagerLogin.route) {
            ManagerLoginScreen(
                onLoginSuccess = {
                    val targetRoute = when (CurrentSession.userRole?.lowercase()) {
                        "supervisor" -> AppRoute.SupervisorDashboard.route
                        "worker" -> AppRoute.WorkerDashboard.route
                        else -> if (CurrentSession.farmId.isNotBlank()) AppRoute.ManagerDashboard.route else AppRoute.CreateFarm.route
                    }
                    navController.navigate(targetRoute) {
                        popUpTo(AppRoute.ManagerLogin.route) {
                            inclusive = true
                        }
                    }
                },
                onSignUpClick = {
                    navController.navigate(AppRoute.ManagerSignUp.route)
                }
            )
        }

        composable(AppRoute.SupervisorLogin.route) {
            ManagerLoginScreen(
                onLoginSuccess = {
                    navController.navigate(AppRoute.SupervisorDashboard.route) {
                        popUpTo(AppRoute.SupervisorLogin.route) { inclusive = true }
                    }
                },
                onSignUpClick = {
                    navController.navigate(AppRoute.ManagerSignUp.route)
                }
            )
        }

        composable(AppRoute.WorkerLogin.route) {
            ManagerLoginScreen(
                onLoginSuccess = {
                    navController.navigate(AppRoute.WorkerDashboard.route) {
                        popUpTo(AppRoute.WorkerLogin.route) { inclusive = true }
                    }
                },
                onSignUpClick = {
                    navController.navigate(AppRoute.ManagerSignUp.route)
                }
            )
        }

        // Manager Sign Up
        composable(AppRoute.ManagerSignUp.route) {
            ManagerSignUpScreen(
                onSignUpSuccess = {
                    val targetRoute = if (CurrentSession.farmId.isNotBlank()) AppRoute.ManagerDashboard.route else AppRoute.CreateFarm.route
                    navController.navigate(targetRoute) {
                        popUpTo(AppRoute.ManagerLogin.route) {
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

        // Create Farm
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

        // Manager Navigation
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

        // Supervisor Navigation
        composable(AppRoute.SupervisorDashboard.route) {
            val coroutineScope = rememberCoroutineScope()

            SupervisorNavigation(
                onLogout = {
                    coroutineScope.launch {
                        authRepository.logout()
                    }
                }
            )
        }

        // Worker Navigation
        composable(AppRoute.WorkerDashboard.route) {
            val coroutineScope = rememberCoroutineScope()

            WorkerNavigation(
                onLogout = {
                    coroutineScope.launch {
                        authRepository.logout()
                    }
                }
            )
        }
    }
}
