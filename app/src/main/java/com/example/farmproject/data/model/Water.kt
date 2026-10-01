package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Water(
    @SerialName("water_id") val waterId: String? = null,
    @SerialName("farm_id") val farmId: String,
    @SerialName("source_name") val sourceName: String,
    @SerialName("available_quantity") val availableQuantity: Double,
    val unit: String,
    @SerialName("reorder_level") val reorderLevel: Double? = null,
    val description: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("is_deleted") val isDeleted: Boolean = false
)
