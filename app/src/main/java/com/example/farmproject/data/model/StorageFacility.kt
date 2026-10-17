package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class StorageFacility(
    @SerialName("facility_id") val facilityId: String? = null,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    val name: String,
    @SerialName("facility_type") val facilityType: String = "store",
    @SerialName("capacity_kg") val capacityKg: Double,
    val condition: String = "good",
    @SerialName("location_note") val locationNote: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
) {
    val displayType: String
        get() = when (facilityType.lowercase()) {
            "cold_room" -> "Cold Room"
            "silo" -> "Silo"
            "granary" -> "Granary"
            "shed" -> "Shed"
            else -> "General Store"
        }

    val displayCondition: String
        get() = when (condition.lowercase()) {
            "needs_repair" -> "Needs Repair"
            "fair" -> "Fair"
            "poor" -> "Poor"
            else -> "Good"
        }
}
