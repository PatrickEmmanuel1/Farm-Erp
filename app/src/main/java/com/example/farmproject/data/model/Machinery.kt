package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Machinery(
    @SerialName("machinery_id") val machineryId: String? = null,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    val name: String,
    @SerialName("machinery_type") val machineryType: String,
    val brand: String? = null,
    val model: String? = null,
    @SerialName("serial_number") val serialNumber: String? = null,
    @SerialName("purchase_date") val purchaseDate: String? = null,
    @SerialName("purchase_cost") val purchaseCost: Double? = null,
    val purpose: String? = null,
    val condition: String,
    val status: String,
    val location: String? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("is_deleted") val isDeleted: Boolean = false
)
