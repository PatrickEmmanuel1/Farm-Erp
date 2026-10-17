package com.example.farmproject.data.repository

import com.example.farmproject.data.model.AttendanceDisplay
import com.example.farmproject.data.model.AttendanceRecord
import com.example.farmproject.data.remote.SupabaseClientProvider
import com.example.farmproject.data.session.CurrentSession
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import java.time.LocalDate
import java.time.OffsetDateTime

class AttendanceRepository(
    private val client: SupabaseClient = SupabaseClientProvider.client,
    private val employeeRepository: EmployeeRepository = EmployeeRepository(client)
) {

    suspend fun resolveMyProfileId(): String? {
        val currentUserId = CurrentSession.userId ?: client.auth.currentUserOrNull()?.id ?: return null
        return try {
            val workerRow = client.from("worker_profile")
                .select { filter { eq("account_id", currentUserId) } }
                .decodeList<JsonObject>()
                .firstOrNull()
            val workerId = workerRow?.get("worker_profile_id")?.jsonPrimitive?.content
            if (!workerId.isNullOrBlank()) return workerId

            val supervisorRow = client.from("supervisor_profile")
                .select { filter { eq("account_id", currentUserId) } }
                .decodeList<JsonObject>()
                .firstOrNull()
            supervisorRow?.get("supervisor_profile_id")?.jsonPrimitive?.content
        } catch (_: Exception) {
            null
        }
    }

    suspend fun getAttendanceForDate(farmId: String, workDate: String): List<AttendanceDisplay> {
        val targetFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.farmId

        val existingRecords = try {
            client.from("attendance")
                .select {
                    filter {
                        if (targetFarmId.isNotBlank()) {
                            eq("farm_id", targetFarmId)
                        }
                        eq("work_date", workDate)
                    }
                    order("created_at", Order.DESCENDING)
                }
                .decodeList<AttendanceRecord>()
        } catch (_: Exception) {
            emptyList()
        }

        val recordsByProfile = existingRecords.associateBy { it.workerProfileId }

        val workers = employeeRepository.getWorkersForFarm(targetFarmId).map { worker ->
            AttendanceDisplay(
                record = recordsByProfile[worker.profileId],
                workerProfileId = worker.profileId,
                workerName = worker.fullName,
                employeeNumber = worker.employeeNumber,
                phoneNumber = worker.phoneNumber,
                role = "Worker"
            )
        }

        val supervisors = employeeRepository.getSupervisorsForFarm(targetFarmId).map { supervisor ->
            AttendanceDisplay(
                record = recordsByProfile[supervisor.profileId],
                workerProfileId = supervisor.profileId,
                workerName = supervisor.fullName,
                employeeNumber = supervisor.employeeNumber,
                phoneNumber = supervisor.phoneNumber,
                role = "Supervisor"
            )
        }

        return (supervisors + workers)
    }

    suspend fun getMyAttendanceHistory(farmId: String): List<AttendanceRecord> {
        val myProfileId = resolveMyProfileId() ?: return emptyList()
        val targetFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.farmId

        return try {
            client.from("attendance")
                .select {
                    filter {
                        if (targetFarmId.isNotBlank()) {
                            eq("farm_id", targetFarmId)
                        }
                        eq("worker_profile_id", myProfileId)
                    }
                    order("work_date", Order.DESCENDING)
                }
                .decodeList<AttendanceRecord>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun clockInSelf(farmId: String): Result<AttendanceRecord> {
        val myProfileId = resolveMyProfileId()
            ?: return Result.failure(Exception("Employee profile not found for current user"))
        return clockIn(farmId = farmId, workerProfileId = myProfileId)
    }

    suspend fun markAttendance(
        farmId: String,
        workerProfileId: String,
        workDate: String,
        status: String,
        notes: String? = null
    ): Result<AttendanceRecord> {
        return try {
            val targetFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.farmId
            val recordedBy = CurrentSession.userId

            val validStatus = when (status.lowercase()) {
                "late" -> "late"
                "absent" -> "absent"
                "on_leave", "on leave" -> "on_leave"
                else -> "present"
            }

            val payload = buildJsonObject {
                put("farm_id", targetFarmId)
                put("worker_profile_id", workerProfileId)
                put("work_date", workDate)
                put("status", validStatus)
                if (!notes.isNullOrBlank()) put("notes", notes.trim())
                if (!recordedBy.isNullOrBlank()) put("recorded_by", recordedBy)
            }

            val upserted = client.from("attendance")
                .upsert(payload) {
                    select()
                }
                .decodeSingle<AttendanceRecord>()

            Result.success(upserted)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun clockIn(
        farmId: String,
        workerProfileId: String,
        workDate: String = LocalDate.now().toString()
    ): Result<AttendanceRecord> {
        return try {
            val nowIso = OffsetDateTime.now().toString()
            val targetFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.farmId

            val payload = buildJsonObject {
                put("farm_id", targetFarmId)
                put("worker_profile_id", workerProfileId)
                put("work_date", workDate)
                put("check_in", nowIso)
                put("status", "present")
                if (!CurrentSession.userId.isNullOrBlank()) put("recorded_by", CurrentSession.userId)
            }

            val record = client.from("attendance")
                .upsert(payload) {
                    select()
                }
                .decodeSingle<AttendanceRecord>()

            Result.success(record)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun clockOut(
        attendanceId: String
    ): Result<AttendanceRecord> {
        return try {
            val nowIso = OffsetDateTime.now().toString()
            val payload = buildJsonObject {
                put("check_out", nowIso)
            }

            val updated = client.from("attendance")
                .update(payload) {
                    filter {
                        eq("attendance_id", attendanceId)
                    }
                    select()
                }
                .decodeSingle<AttendanceRecord>()

            Result.success(updated)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
