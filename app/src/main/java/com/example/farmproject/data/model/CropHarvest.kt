package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class CropHarvest(
    @SerialName("harvest_id") val harvestId: String? = null,
    @SerialName("planting_id") val plantingId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String,
    @SerialName("harvest_date") val harvestDate: String,
    @SerialName("quantity_harvested") val quantityHarvested: Double,
    @SerialName("quantity_unit") val quantityUnit: String,
    @SerialName("quality_grade") val qualityGrade: String? = null,
    val quantity: Double? = null,
    val unit: String? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)
