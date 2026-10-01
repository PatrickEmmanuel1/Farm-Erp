package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Farm(
    @SerialName("farm_id") val farmId: String? = null,
    val name: String,
    @SerialName("total_size") val totalSize: Double,
    val unit: String,
    @SerialName("soil_type") val soilType: String? = null,
    @SerialName("soil_health") val soilHealth: String? = null,
    @SerialName("soil_ph") val soilPh: Double? = null,
    val county: String,
    @SerialName("sub_county") val subCounty: String? = null,
    @SerialName("account_id") val accountId: String? = null,
    @SerialName("supervisor_id") val supervisorId: String? = null,
    @SerialName("worker_id") val workerId: String? = null,
    @SerialName("county_id") val countyId: Long? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("is_deleted") val isDeleted: Boolean = false
)

@Serializable
data class Division(
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("farm_id") val farmId: String,
    val name: String,
    val size: Double,
    @SerialName("soil_ph") val soilPh: Double? = null,
    @SerialName("soil_health") val soilHealth: String? = null,
    val units: String? = null,
    @SerialName("worker_id") val workerId: String? = null,
    @SerialName("supervisor_id") val supervisorId: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("is_deleted") val isDeleted: Boolean = false
)
