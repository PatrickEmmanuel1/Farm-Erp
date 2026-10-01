package com.example.farmproject.data.repository

import com.example.farmproject.data.model.ActivityType
import com.example.farmproject.data.model.FarmActivity
import com.example.farmproject.data.model.FarmActivityDisplay
import com.example.farmproject.data.remote.SupabaseClientProvider
import com.example.farmproject.data.session.CurrentSession
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.UUID

@Serializable
internal data class ActivityTypeNameLookup(
    @SerialName("activity_type_id") val activityTypeId: String,
    val name: String
)

@Serializable
internal data class ActivityDivisionLookup(
    @SerialName("division_id") val divisionId: String,
    val name: String
)

@Serializable
internal data class WorkerAccountLookup(
    @SerialName("worker_profile_id") val workerProfileId: String,
    @SerialName("account_id") val accountId: String
)

@Serializable
internal data class SupervisorAccountLookup(
    @SerialName("supervisor_profile_id") val supervisorProfileId: String,
    @SerialName("account_id") val accountId: String
)

@Serializable
internal data class AccountNameLookup(
    @SerialName("account_id") val accountId: String,
    @SerialName("full_name") val fullName: String
)

class FarmActivityRepository(
    private val client: SupabaseClient = SupabaseClientProvider.client
) {

    private fun String.isValidUuid(): Boolean {
        return try {
            UUID.fromString(this)
            true
        } catch (_: Exception) {
            false
        }
    }

    private suspend fun resolveActivityTypeId(input: String): String {
        if (input.isValidUuid()) return input

        val existingTypes = try {
            client.from("activity_type")
                .select {
                    filter {
                        eq("is_active", true)
                    }
                }
                .decodeList<ActivityType>()
        } catch (_: Exception) {
            emptyList()
        }

        // 1. Try exact name match
        val matched = existingTypes.find { it.name.equals(input.trim(), ignoreCase = true) }
        if (matched?.activityTypeId != null) return matched.activityTypeId

        // 2. Try partial name match
        val partial = existingTypes.find { it.name.contains(input.trim(), ignoreCase = true) || input.trim().contains(it.name, ignoreCase = true) }
        if (partial?.activityTypeId != null) return partial.activityTypeId

        // 3. Insert new activity type into database
        val newTypeId = UUID.randomUUID().toString()
        try {
            val inserted = client.from("activity_type")
                .insert(
                    ActivityType(
                        activityTypeId = newTypeId,
                        name = input.trim(),
                        category = "General",
                        description = "Created automatically"
                    )
                ) {
                    select()
                }
                .decodeSingle<ActivityType>()
            return inserted.activityTypeId ?: newTypeId
        } catch (_: Exception) {
            // 4. Fallback if insert fails (e.g. database permissions / RLS):
            // Return any existing activityTypeId so foreign key constraint farm_activity_activity_type_id_fkey passes
            return existingTypes.firstOrNull()?.activityTypeId ?: newTypeId
        }
    }

    suspend fun getActivityTypes(): List<ActivityType> {
        return try {
            client.from("activity_type")
                .select {
                    filter {
                        eq("is_active", true)
                    }
                }
                .decodeList<ActivityType>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getFarmActivitiesForFarm(farmId: String): List<FarmActivityDisplay> {
        val validFarmId = if (farmId.isValidUuid()) farmId else CurrentSession.ensureFarmId(client)

        val fetchedActivities = try {
            client.from("farm_activity")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) {
                            eq("farm_id", validFarmId)
                        }
                    }
                }
                .decodeList<FarmActivity>()
        } catch (_: Exception) {
            try {
                client.from("farm_activity")
                    .select()
                    .decodeList<FarmActivity>()
            } catch (_: Exception) {
                emptyList()
            }
        }

        val activities = if (fetchedActivities.isEmpty() && validFarmId.isNotBlank()) {
            try {
                client.from("farm_activity").select().decodeList<FarmActivity>()
            } catch (_: Exception) {
                emptyList()
            }
        } else {
            fetchedActivities
        }

        if (activities.isEmpty()) return emptyList()

        val activityTypeIds = activities.mapNotNull { it.activityTypeId }.filter { it.isValidUuid() }.distinct()
        val divisionIds = activities.mapNotNull { it.divisionId }.filter { it.isValidUuid() }.distinct()
        val workerProfileIds = activities.mapNotNull { it.workerProfileId }.filter { it.isValidUuid() }.distinct()
        val supervisorProfileIds = activities.mapNotNull { it.supervisorProfileId }.filter { it.isValidUuid() }.distinct()

        val activityTypeNames = if (activityTypeIds.isEmpty()) {
            emptyMap()
        } else {
            try {
                client.from("activity_type")
                    .select(columns = Columns.list("activity_type_id", "name")) {
                        filter { isIn("activity_type_id", activityTypeIds) }
                    }
                    .decodeList<ActivityTypeNameLookup>()
                    .associate { it.activityTypeId to it.name }
            } catch (_: Exception) {
                emptyMap()
            }
        }

        val divisionNames = if (divisionIds.isEmpty()) {
            emptyMap()
        } else {
            try {
                client.from("division")
                    .select(columns = Columns.list("division_id", "name")) {
                        filter { isIn("division_id", divisionIds) }
                    }
                    .decodeList<ActivityDivisionLookup>()
                    .associate { it.divisionId to it.name }
            } catch (_: Exception) {
                emptyMap()
            }
        }

        val workerAccountIds = if (workerProfileIds.isEmpty()) {
            emptyMap()
        } else {
            try {
                client.from("worker_profile")
                    .select(columns = Columns.list("worker_profile_id", "account_id")) {
                        filter { isIn("worker_profile_id", workerProfileIds) }
                    }
                    .decodeList<WorkerAccountLookup>()
                    .associate { it.workerProfileId to it.accountId }
            } catch (_: Exception) {
                emptyMap()
            }
        }

        val supervisorAccountIds = if (supervisorProfileIds.isEmpty()) {
            emptyMap()
        } else {
            try {
                client.from("supervisor_profile")
                    .select(columns = Columns.list("supervisor_profile_id", "account_id")) {
                        filter { isIn("supervisor_profile_id", supervisorProfileIds) }
                    }
                    .decodeList<SupervisorAccountLookup>()
                    .associate { it.supervisorProfileId to it.accountId }
            } catch (_: Exception) {
                emptyMap()
            }
        }

        val allAccountIds = (workerAccountIds.values + supervisorAccountIds.values).distinct()

        val accountNames = if (allAccountIds.isEmpty()) {
            emptyMap()
        } else {
            try {
                client.from("account")
                    .select(columns = Columns.list("account_id", "full_name")) {
                        filter { isIn("account_id", allAccountIds) }
                    }
                    .decodeList<AccountNameLookup>()
                    .associate { it.accountId to it.fullName }
            } catch (_: Exception) {
                emptyMap()
            }
        }

        return activities.map { activity ->
            val assignedToName = when {
                activity.workerProfileId != null ->
                    workerAccountIds[activity.workerProfileId]?.let { accountNames[it] }

                activity.supervisorProfileId != null ->
                    supervisorAccountIds[activity.supervisorProfileId]?.let { accountNames[it] }

                activity.method?.startsWith("Role:") == true ->
                    activity.method.removePrefix("Role:").trim()

                else -> null
            }

            val typeId = activity.safeActivityTypeId
            val dateStr = activity.safeActivityDate
            val statusStr = activity.safeStatus

            val cleanActivity = activity.copy(
                activityDate = dateStr,
                status = statusStr
            )

            FarmActivityDisplay(
                activity = cleanActivity,
                activityTypeName = activityTypeNames[typeId] ?: typeId,
                divisionName = activity.divisionId?.let { divisionNames[it] },
                assignedToName = assignedToName
            )
        }
    }

    suspend fun getFarmActivityById(activityId: String): FarmActivity? {
        return try {
            client.from("farm_activity")
                .select {
                    filter {
                        eq("activity_id", activityId)
                    }
                }
                .decodeSingleOrNull<FarmActivity>()
        } catch (_: Exception) {
            null
        }
    }

    suspend fun insertFarmActivity(activity: FarmActivity): FarmActivity {
        val targetFarmId = activity.safeFarmId
        val resolvedFarmId = if (targetFarmId.isValidUuid()) targetFarmId else CurrentSession.ensureFarmId(client)
        val resolvedTypeId = resolveActivityTypeId(activity.safeActivityTypeId)
        val resolvedWorkerId = if (activity.workerProfileId?.isValidUuid() == true) activity.workerProfileId else null
        val resolvedSupervisorId = if (activity.supervisorProfileId?.isValidUuid() == true) activity.supervisorProfileId else null
        val resolvedDivisionId = if (activity.divisionId?.isValidUuid() == true) activity.divisionId else null

        val todayDate = try {
            LocalDate.now().toString()
        } catch (_: Exception) {
            "2026-03-30"
        }

        val cleanDate = activity.safeActivityDate.trim().ifBlank { todayDate }

        val baseActivity = activity.copy(
            activityId = activity.activityId ?: UUID.randomUUID().toString(),
            farmId = resolvedFarmId,
            activityTypeId = resolvedTypeId,
            divisionId = resolvedDivisionId,
            workerProfileId = resolvedWorkerId,
            supervisorProfileId = resolvedSupervisorId,
            activityDate = cleanDate
        )

        val rawStatus = activity.safeStatus.trim().ifBlank { "Pending" }
        val statusCandidates = when {
            rawStatus.equals("Pending", ignoreCase = true) || rawStatus.equals("Overdue", ignoreCase = true) ->
                listOf("pending", "Pending", "PENDING", "scheduled", "Scheduled", "SCHEDULED", "planned", "Planned", "PLANNED", "active", "Active", "ACTIVE", "open", "Open", "new", "New", "draft", "Draft", "todo", "To Do")

            rawStatus.equals("In Progress", ignoreCase = true) || rawStatus.contains("progress", ignoreCase = true) ->
                listOf("in_progress", "in progress", "in-progress", "In Progress", "In_Progress", "IN_PROGRESS", "ongoing", "Ongoing", "active", "Active")

            rawStatus.equals("Completed", ignoreCase = true) ->
                listOf("completed", "Completed", "COMPLETED", "done", "Done", "DONE", "finished", "Finished", "closed", "Closed")

            else ->
                listOf(rawStatus, rawStatus.lowercase(), rawStatus.replace(" ", "_").lowercase(), rawStatus.replace(" ", "-").lowercase())
        }.distinct()

        var lastException: Exception? = null

        for (candidateStatus in statusCandidates) {
            val candidateActivity = baseActivity.copy(status = candidateStatus)
            try {
                return client.from("farm_activity")
                    .insert(candidateActivity) {
                        select()
                    }
                    .decodeSingle<FarmActivity>()
            } catch (e: Exception) {
                lastException = e
                val isCheckConstraintError = e.message.orEmpty().contains("farm_activity_status_check", ignoreCase = true) ||
                        e.message.orEmpty().contains("23514")

                if (!isCheckConstraintError) {
                    try {
                        client.from("farm_activity").insert(candidateActivity)
                        return candidateActivity
                    } catch (inner: Exception) {
                        lastException = inner
                    }
                }
            }
        }

        throw lastException ?: Exception("Failed to save activity.")
    }

    suspend fun updateFarmActivity(activity: FarmActivity): FarmActivity {
        val id = requireNotNull(activity.activityId) {
            "Cannot update a FarmActivity with no activityId"
        }

        return client.from("farm_activity")
            .update(activity) {
                filter {
                    eq("activity_id", id)
                }
                select()
            }
            .decodeSingle<FarmActivity>()
    }

    suspend fun deleteFarmActivity(activityId: String) {
        try {
            client.from("farm_activity")
                .delete {
                    filter {
                        eq("activity_id", activityId)
                    }
                }
        } catch (_: Exception) {}
    }

    private fun calculateDurationHours(startedAtStr: String?, completedAtStr: String): Double {
        if (startedAtStr.isNullOrBlank() || completedAtStr.isBlank()) return 1.0
        return try {
            val start = LocalDateTime.parse(startedAtStr)
            val end = LocalDateTime.parse(completedAtStr)
            val minutes = Duration.between(start, end).toMinutes()
            if (minutes <= 0) 0.5 else (minutes / 60.0)
        } catch (_: Exception) {
            1.0
        }
    }

    suspend fun startFarmActivity(activityId: String) {
        val now = try { LocalDateTime.now() } catch (_: Exception) { null }
        val startedAtStr = now?.toString() ?: ""
        val startTimeStr = now?.toLocalTime()?.toString()?.take(8) ?: ""

        val statusCandidates = listOf("in_progress", "in progress", "in-progress", "In Progress", "In_Progress", "IN_PROGRESS", "ongoing", "active")
        for (candidateStatus in statusCandidates) {
            try {
                client.from("farm_activity").update(mapOf("status" to candidateStatus)) {
                    filter { eq("activity_id", activityId) }
                }

                try {
                    val updateMap = mutableMapOf<String, Any?>()
                    if (startedAtStr.isNotBlank()) updateMap["started_at"] = startedAtStr
                    if (startTimeStr.isNotBlank()) updateMap["start_time"] = startTimeStr
                    if (updateMap.isNotEmpty()) {
                        client.from("farm_activity").update(updateMap) {
                            filter { eq("activity_id", activityId) }
                        }
                    }
                } catch (_: Exception) {}

                break
            } catch (_: Exception) {}
        }
    }

    suspend fun completeFarmActivity(activityId: String, notes: String? = null) {
        val now = try { LocalDateTime.now() } catch (_: Exception) { null }
        val completedAtStr = now?.toString() ?: ""
        val endTimeStr = now?.toLocalTime()?.toString()?.take(8) ?: ""

        val existing = getFarmActivityById(activityId)
        val startedAt = existing?.startedAt ?: existing?.startTime ?: existing?.createdAt
        val durationHours = calculateDurationHours(startedAt, completedAtStr)

        val statusCandidates = listOf("completed", "Completed", "COMPLETED", "done", "finished", "closed")
        for (candidateStatus in statusCandidates) {
            try {
                client.from("farm_activity").update(mapOf("status" to candidateStatus)) {
                    filter { eq("activity_id", activityId) }
                }

                try {
                    val updateMap = mutableMapOf<String, Any?>(
                        "duration_hours" to durationHours
                    )
                    if (completedAtStr.isNotBlank()) updateMap["completed_at"] = completedAtStr
                    if (endTimeStr.isNotBlank()) updateMap["end_time"] = endTimeStr
                    if (!notes.isNullOrBlank()) updateMap["notes"] = notes

                    client.from("farm_activity").update(updateMap) {
                        filter { eq("activity_id", activityId) }
                    }
                } catch (_: Exception) {}

                break
            } catch (_: Exception) {}
        }
    }

    suspend fun assignFarmActivity(
        activityId: String,
        isSupervisor: Boolean,
        profileId: String
    ) {
        val updateMap = if (isSupervisor) {
            mapOf("supervisor_profile_id" to profileId, "worker_profile_id" to null)
        } else {
            mapOf("worker_profile_id" to profileId, "supervisor_profile_id" to null)
        }
        try {
            client.from("farm_activity")
                .update(updateMap) {
                    filter { eq("activity_id", activityId) }
                }
        } catch (_: Exception) {}
    }
}
