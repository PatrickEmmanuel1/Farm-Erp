package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Pesticide(
    @SerialName("pesticide_id") val pesticideId: String? = null,
    @SerialName("farm_id") val farmId: String,
    val name: String,
    @SerialName("active_ingredient") val activeIngredient: String? = null,
    val quantity: Double,
    val unit: String,
    @SerialName("reorder_level") val reorderLevel: Double? = null,
    val description: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("is_deleted") val isDeleted: Boolean = false
)
