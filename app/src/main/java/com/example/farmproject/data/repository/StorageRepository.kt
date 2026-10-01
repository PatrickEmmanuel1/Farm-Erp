package com.example.farmproject.data.repository

import com.example.farmproject.data.model.StoredProduce
import com.example.farmproject.data.remote.SupabaseClientProvider
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order

class StorageRepository(
    private val client: SupabaseClient = SupabaseClientProvider.client
) {
    suspend fun getStorageForFarm(farmId: String): List<StoredProduce> {
        return client.from("stored_produce")
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
    }
}
