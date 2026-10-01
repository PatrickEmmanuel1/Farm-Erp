package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class MachineryMaintenance(
    @SerialName("maintenance_id") val maintenanceId: String? = null,
    @SerialName("machinery_id") val machineryId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("maintenance_date") val maintenanceDate: String,
    @SerialName("maintenance_type") val maintenanceType: String,
    val description: String,
    val cost: Double? = null,
    @SerialName("service_provider") val serviceProvider: String? = null,
    @SerialName("parts_replaced") val partsReplaced: String? = null,
    @SerialName("next_maintenance_date") val nextMaintenanceDate: String? = null,
    @SerialName("hour_meter_reading") val hourMeterReading: Double? = null,
    @SerialName("condition_after") val conditionAfter: String? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("is_cancelled") val isCancelled: Boolean = false,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("cancelled_by") val cancelledBy: String? = null,
    @SerialName("cancellation_reason") val cancellationReason: String? = null
)
