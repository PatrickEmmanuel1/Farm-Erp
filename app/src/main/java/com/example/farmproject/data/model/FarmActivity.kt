package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class FarmActivity(
    @SerialName("activity_id") val activityId: String? = null,
    @SerialName("activity_type_id") val activityTypeId: String? = null,
    @SerialName("farm_id") val farmId: String? = null,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("planting_id") val plantingId: String? = null,
    @SerialName("worker_profile_id") val workerProfileId: String? = null,
    @SerialName("supervisor_profile_id") val supervisorProfileId: String? = null,
    @SerialName("activity_date") val activityDate: String? = null,
    @SerialName("start_time") val startTime: String? = null,
    @SerialName("end_time") val endTime: String? = null,
    @SerialName("duration_hours") val durationHours: Double? = null,
    val quantity: Double? = null,
    @SerialName("quantity_unit") val quantityUnit: String? = null,
    val method: String? = null,
    @SerialName("equipment_needed") val equipmentNeeded: String? = null,
    val notes: String? = null,
    val status: String? = null,
    @SerialName("activity_name") val activityName: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("completed_at") val completedAt: String? = null
) {
    val safeActivityTypeId: String get() = activityTypeId.orEmpty().ifBlank { "General Activity" }
    val safeFarmId: String get() = farmId.orEmpty()
    val safeActivityDate: String get() = activityDate.orEmpty().ifBlank { "2026-03-30" }
    val safeStatus: String get() = status.orEmpty().ifBlank { "Pending" }
}
