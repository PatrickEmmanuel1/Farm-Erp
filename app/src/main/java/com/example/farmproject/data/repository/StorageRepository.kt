package com.example.farmproject.data.repository

import com.example.farmproject.data.model.StorageFacility
import com.example.farmproject.data.model.StoredProduce
import com.example.farmproject.data.remote.SupabaseClientProvider
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order

class StorageRepository(
    private val client: SupabaseClient = SupabaseClientProvider.client
) {
    suspend fun getStorageForFarm(farmId: String): List<StoredProduce> {
        return try {
            client.from("stored_produce")
                .select {
                    filter {
                        if (farmId.isNotBlank()) {
                            eq("farm_id", farmId)
                        }
                        eq("is_deleted", false)
                    }
                    order("date_stored", Order.DESCENDING)
                }
                .decodeList<StoredProduce>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getFacilitiesForFarm(farmId: String): List<StorageFacility> {
        return try {
            client.from("storage_facility")
                .select {
                    filter {
                        if (farmId.isNotBlank()) {
                            eq("farm_id", farmId)
                        }
                        eq("is_active", true)
                    }
                    order("name", Order.ASCENDING)
                }
                .decodeList<StorageFacility>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun createFacility(facility: StorageFacility): Result<StorageFacility> {
        return try {
            val created = client.from("storage_facility")
                .insert(facility) {
                    select()
                }
                .decodeSingle<StorageFacility>()
            Result.success(created)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun addStoredProduce(produce: StoredProduce): Result<StoredProduce> {
        return try {
            val created = client.from("stored_produce")
                .insert(produce) {
                    select()
                }
                .decodeSingle<StoredProduce>()
            Result.success(created)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
