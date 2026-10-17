package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class AppNotification(
    @SerialName("notification_id") val id: String,
    @SerialName("farm_id") val farmId: String,
    val type: String,                       // LOW_INVENTORY | MAINTENANCE_DUE
    val title: String,
    val body: String,
    @SerialName("is_read") val isRead: Boolean,
    @SerialName("created_at") val createdAt: String
)
