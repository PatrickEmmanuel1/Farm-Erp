package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class CreateEmployeeRequest(
    @SerialName("full_name") val fullName: String,
    val email: String,
    @SerialName("phone_number") val phoneNumber: String? = null,
    @SerialName("employee_number") val employeeNumber: String? = null,
    @SerialName("farm_id") val farmId: String,
    val password: String? = null
)
