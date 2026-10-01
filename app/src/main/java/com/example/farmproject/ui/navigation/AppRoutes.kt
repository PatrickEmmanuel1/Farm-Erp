package com.example.farmproject.ui.navigation

sealed class AppRoute(
    val route: String
) {

    data object Splash : AppRoute("splash")

    data object RoleSelection : AppRoute("role_selection")

    data object ManagerLogin : AppRoute("manager_login")

    data object ManagerSignUp : AppRoute("manager_signup")

    data object CreateFarm : AppRoute("create_farm")

    data object SupervisorLogin : AppRoute("supervisor_login")

    data object WorkerLogin : AppRoute("worker_login")

    data object ManagerDashboard : AppRoute("manager_dashboard")

    data object SupervisorDashboard : AppRoute("supervisor_dashboard")

    data object WorkerDashboard : AppRoute("worker_dashboard")

}
