package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class MachineryUsage(
    @SerialName("usage_id") val usageId: String? = null,
    @SerialName("machinery_id") val machineryId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("planting_id") val plantingId: String? = null,
    @SerialName("worker_profile_id") val workerProfileId: String? = null,
    @SerialName("supervisor_profile_id") val supervisorProfileId: String? = null,
    @SerialName("usage_date") val usageDate: String,
    @SerialName("start_time") val startTime: String? = null,
    @SerialName("end_time") val endTime: String? = null,
    @SerialName("hours_used") val hoursUsed: Double? = null,
    val purpose: String,
    @SerialName("fuel_used") val fuelUsed: Double? = null,
    @SerialName("fuel_unit") val fuelUnit: String? = null,
    @SerialName("hour_meter_reading") val hourMeterReading: Double? = null,
    @SerialName("condition_after") val conditionAfter: String? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("is_voided") val isVoided: Boolean = false,
    @SerialName("voided_at") val voidedAt: String? = null,
    @SerialName("voided_by") val voidedBy: String? = null,
    @SerialName("void_reason") val voidReason: String? = null,
    @SerialName("issuance_id") val issuanceId: String? = null
)
