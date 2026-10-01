package com.example.farmproject.data.repository

import android.util.Log
import com.example.farmproject.data.model.Farm
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
import java.util.UUID
import kotlin.coroutines.cancellation.CancellationException

class FarmRepository(
    private val client: SupabaseClient = SupabaseClientProvider.client
) {

    private suspend fun signedInUserId(): String? {
        client.auth.awaitInitialization()
        val authId = client.auth.currentUserOrNull()?.id
            ?: client.auth.currentSessionOrNull()?.user?.id
        if (!authId.isNullOrBlank()) return authId
        return CurrentSession.userId?.takeIf { it.isNotBlank() }
    }

    suspend fun getCounties(): List<String> {
        return try {
            client.from("county")
                .select { order("county_name", Order.ASCENDING) }
                .decodeList<JsonObject>()
                .mapNotNull { it["county_name"]?.jsonPrimitive?.content }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("Farm", "Error loading counties: ${e.message}", e)
            emptyList()
        }
    }

    suspend fun getFarmById(farmId: String): Farm? {
        if (farmId.isBlank()) return null
        return try {
            client.from("farm")
                .select {
                    filter {
                        eq("farm_id", farmId)
                        eq("is_deleted", false)
                    }
                }
                .decodeList<Farm>()
                .firstOrNull()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("Farm", "Error getting farm by ID: ${e.message}", e)
            null
        }
    }

    /** The signed-in manager's own farm. The userId parameter is kept only so existing callers compile. */
    @Suppress("UNUSED_PARAMETER")
    suspend fun getFarmForUser(userId: String = ""): Farm? {
        val authUserId = signedInUserId() ?: return null
        return try {
            client.from("farm")
                .select {
                    filter {
                        eq("account_id", authUserId)
                        eq("is_deleted", false)
                    }
                }
                .decodeList<Farm>()
                .firstOrNull()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("Farm", "Error getting farm for user: ${e.message}", e)
            null
        }
    }

    /**
     * Managers only: if CurrentSession.farmId is empty (fresh install, restored
     * session), load it from the manager's farm. Call after login and after restoreSession().
     */
    suspend fun ensureFarmInSession() {
        if (CurrentSession.farmId.isNotBlank()) return
        if (!CurrentSession.userRole.equals("Manager", ignoreCase = true)) return
        getFarmForUser()?.farmId?.let { CurrentSession.farmId = it }
    }

    suspend fun createFarm(
        name: String,
        county: String,
        subCounty: String?,
        totalSize: Double,
        unit: String
    ): Result<Farm> {
        val authUserId = signedInUserId()
            ?: return Result.failure(Exception("Your session has expired. Please log in again."))

        val newFarm = Farm(
            farmId = UUID.randomUUID().toString(),
            name = name.trim(),
            county = county.trim(),
            subCounty = subCounty?.trim()?.ifBlank { null },
            totalSize = totalSize,
            unit = unit.ifBlank { "Acres" },
            accountId = authUserId
        )

        return try {
            // No select() on the insert, so the farm_select policy is not evaluated here
            client.from("farm").insert(newFarm)

            // Only reached if the insert really succeeded
            newFarm.farmId?.let { CurrentSession.farmId = it }
            Result.success(newFarm)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("Farm", "Failed to create farm: ${e.message}", e)
            Result.failure(Exception(e.message ?: "Failed to create farm. Please try again."))
        }
    }

    suspend fun updateFarmDetails(
        farmId: String,
        name: String,
        totalSize: Double,
        unit: String,
        county: String? = null,
        soilPh: Double? = null,
        soilHealth: String? = null
    ): Result<Unit> {
        return try {
            if (farmId.isNotBlank()) {
                val updateJsonObject = buildJsonObject {
                    put("name", name.trim())
                    put("total_size", totalSize)
                    put("unit", unit.ifBlank { "Acres" })
                    if (!county.isNullOrBlank()) put("county", county.trim())
                    if (soilPh != null) put("soil_ph", soilPh)
                    if (!soilHealth.isNullOrBlank()) put("soil_health", soilHealth.trim())
                }
                client.from("farm")
                    .update(updateJsonObject) {
                        filter { eq("farm_id", farmId) }
                    }
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e("Farm", "Failed to update farm details: ${e.message}", e)
            Result.failure(e)
        }
    }
}