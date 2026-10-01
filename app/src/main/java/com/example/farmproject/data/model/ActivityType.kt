package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ActivityType(
    @SerialName("activity_type_id") val activityTypeId: String? = null,
    val name: String,
    val category: String? = null,
    val description: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("created_at") val createdAt: String? = null
)

