package com.example.farmproject.data.model

import kotlinx.serialization.Serializable

@Serializable
data class EmployeeDisplay(
    val profileId: String,
    val accountId: String? = null,
    val farmId: String? = null,
    val fullName: String,
    val email: String? = null,
    val phoneNumber: String? = null,
    val employeeNumber: String? = null
)
