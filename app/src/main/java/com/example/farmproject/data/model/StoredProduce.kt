package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class StoredProduce(
    @SerialName("storage_id") val storageId: String? = null,
    @SerialName("farm_id") val farmId: String,
    @SerialName("crop_name") val cropName: String,
    val quantity: Double,
    val unit: String,
    val location: String,
    @SerialName("date_stored") val dateStored: String,
    val condition: String,
    @SerialName("needs_attention") val needsAttention: Boolean = false,
    @SerialName("is_deleted") val isDeleted: Boolean = false
)
