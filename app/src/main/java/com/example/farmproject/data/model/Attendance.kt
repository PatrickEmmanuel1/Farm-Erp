package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class AttendanceRecord(
    @SerialName("attendance_id") val attendanceId: String? = null,
    @SerialName("farm_id") val farmId: String,
    @SerialName("worker_profile_id") val workerProfileId: String,
    @SerialName("work_date") val workDate: String,
    @SerialName("check_in") val checkIn: String? = null,
    @SerialName("check_out") val checkOut: String? = null,
    val status: String = "present",
    val notes: String? = null,
    @SerialName("recorded_by") val recordedBy: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("supervisor_id") val supervisorId: String? = null
) {
    val displayStatus: String
        get() = when (status.lowercase()) {
            "late" -> "Late"
            "absent" -> "Absent"
            "on_leave", "on leave" -> "On Leave"
            else -> "Present"
        }
}

@Serializable
data class AttendanceDisplay(
    val record: AttendanceRecord?,
    val workerProfileId: String,
    val workerName: String,
    val employeeNumber: String? = null,
    val phoneNumber: String? = null,
    val role: String = "Worker"
) {
    val currentStatus: String
        get() = record?.displayStatus ?: "Not Marked"

    val isMarked: Boolean
        get() = record != null
}
