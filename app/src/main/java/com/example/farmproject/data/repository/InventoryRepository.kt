package com.example.farmproject.data.repository

import com.example.farmproject.data.model.Fertilizer
import com.example.farmproject.data.model.Fungicide
import com.example.farmproject.data.model.Herbicide
import com.example.farmproject.data.model.Insecticide
import com.example.farmproject.data.model.InventoryCategory
import com.example.farmproject.data.model.InventoryItem
import com.example.farmproject.data.model.Pesticide
import com.example.farmproject.data.model.StockIssuance
import com.example.farmproject.data.model.Water
import com.example.farmproject.data.model.toInventoryItem
import com.example.farmproject.data.remote.SupabaseClientProvider
import com.example.farmproject.data.session.CurrentSession
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import java.util.UUID

class InventoryRepository(
    private val client: SupabaseClient = SupabaseClientProvider.client
) {

    /**
     * Every active item across all six category tables for one farm,
     * mapped into the flat shape ManagerInventoryScreen renders. Runs
     * the six table queries concurrently rather than one after another.
     */
    suspend fun getInventoryForFarm(farmId: String): List<InventoryItem> = coroutineScope {
        val fertilizers = async { getFertilizers(farmId) }
        val herbicides = async { getHerbicides(farmId) }
        val pesticides = async { getPesticides(farmId) }
        val fungicides = async { getFungicides(farmId) }
        val insecticides = async { getInsecticides(farmId) }
        val water = async { getWater(farmId) }

        fertilizers.await().map { it.toInventoryItem() } +
                herbicides.await().map { it.toInventoryItem() } +
                pesticides.await().map { it.toInventoryItem() } +
                fungicides.await().map { it.toInventoryItem() } +
                insecticides.await().map { it.toInventoryItem() } +
                water.await().map { it.toInventoryItem() }
    }

    // ---------------------------------------------------------------
    // Per-category reads
    // ---------------------------------------------------------------

    suspend fun getFertilizers(farmId: String): List<Fertilizer> {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)
        return try {
            client.from("fertilizers")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) eq("farm_id", validFarmId)
                        eq("is_deleted", false)
                    }
                    order("name", Order.ASCENDING)
                }
                .decodeList<Fertilizer>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getHerbicides(farmId: String): List<Herbicide> {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)
        return try {
            client.from("herbicide")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) eq("farm_id", validFarmId)
                        eq("is_deleted", false)
                    }
                    order("name", Order.ASCENDING)
                }
                .decodeList<Herbicide>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getPesticides(farmId: String): List<Pesticide> {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)
        return try {
            client.from("pesticide")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) eq("farm_id", validFarmId)
                        eq("is_deleted", false)
                    }
                    order("name", Order.ASCENDING)
                }
                .decodeList<Pesticide>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getFungicides(farmId: String): List<Fungicide> {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)
        return try {
            client.from("fungicide")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) eq("farm_id", validFarmId)
                        eq("is_deleted", false)
                    }
                    order("name", Order.ASCENDING)
                }
                .decodeList<Fungicide>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getInsecticides(farmId: String): List<Insecticide> {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)
        return try {
            client.from("insecticide")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) eq("farm_id", validFarmId)
                        eq("is_deleted", false)
                    }
                    order("name", Order.ASCENDING)
                }
                .decodeList<Insecticide>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getWater(farmId: String): List<Water> {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)
        return try {
            client.from("water")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) eq("farm_id", validFarmId)
                        eq("is_deleted", false)
                    }
                    order("source_name", Order.ASCENDING)
                }
                .decodeList<Water>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    // ---------------------------------------------------------------
    // Inserts
    // ---------------------------------------------------------------

    suspend fun insertFertilizer(item: Fertilizer): Fertilizer {
        val farmId = if (item.farmId.isNotBlank()) item.farmId else CurrentSession.ensureFarmId(client)
        val clean = item.copy(
            fertilizerId = item.fertilizerId ?: UUID.randomUUID().toString(),
            farmId = farmId
        )
        return try {
            client.from("fertilizers").insert(clean) { select() }.decodeSingle<Fertilizer>()
        } catch (_: Exception) {
            client.from("fertilizers").insert(clean)
            clean
        }
    }

    suspend fun insertHerbicide(item: Herbicide): Herbicide {
        val farmId = if (item.farmId.isNotBlank()) item.farmId else CurrentSession.ensureFarmId(client)
        val clean = item.copy(
            herbicideId = item.herbicideId ?: UUID.randomUUID().toString(),
            farmId = farmId
        )
        return try {
            client.from("herbicide").insert(clean) { select() }.decodeSingle<Herbicide>()
        } catch (_: Exception) {
            client.from("herbicide").insert(clean)
            clean
        }
    }

    suspend fun insertPesticide(item: Pesticide): Pesticide {
        val farmId = if (item.farmId.isNotBlank()) item.farmId else CurrentSession.ensureFarmId(client)
        val clean = item.copy(
            pesticideId = item.pesticideId ?: UUID.randomUUID().toString(),
            farmId = farmId
        )
        return try {
            client.from("pesticide").insert(clean) { select() }.decodeSingle<Pesticide>()
        } catch (_: Exception) {
            client.from("pesticide").insert(clean)
            clean
        }
    }

    suspend fun insertFungicide(item: Fungicide): Fungicide {
        val farmId = if (item.farmId.isNotBlank()) item.farmId else CurrentSession.ensureFarmId(client)
        val clean = item.copy(
            fungicideId = item.fungicideId ?: UUID.randomUUID().toString(),
            farmId = farmId
        )
        return try {
            client.from("fungicide").insert(clean) { select() }.decodeSingle<Fungicide>()
        } catch (_: Exception) {
            client.from("fungicide").insert(clean)
            clean
        }
    }

    suspend fun insertInsecticide(item: Insecticide): Insecticide {
        val farmId = if (item.farmId.isNotBlank()) item.farmId else CurrentSession.ensureFarmId(client)
        val clean = item.copy(
            insecticideId = item.insecticideId ?: UUID.randomUUID().toString(),
            farmId = farmId
        )
        return try {
            client.from("insecticide").insert(clean) { select() }.decodeSingle<Insecticide>()
        } catch (_: Exception) {
            client.from("insecticide").insert(clean)
            clean
        }
    }

    suspend fun insertWater(item: Water): Water {
        val farmId = if (item.farmId.isNotBlank()) item.farmId else CurrentSession.ensureFarmId(client)
        val clean = item.copy(
            waterId = item.waterId ?: UUID.randomUUID().toString(),
            farmId = farmId
        )
        return try {
            client.from("water").insert(clean) { select() }.decodeSingle<Water>()
        } catch (_: Exception) {
            client.from("water").insert(clean)
            clean
        }
    }

    // ---------------------------------------------------------------
    // Deletes (Soft delete via is_deleted = true)
    // ---------------------------------------------------------------

    suspend fun deleteFertilizer(id: String) = softDelete("fertilizers", "fertilizer_id", id)
    suspend fun deleteHerbicide(id: String) = softDelete("herbicide", "herbicide_id", id)
    suspend fun deletePesticide(id: String) = softDelete("pesticide", "pesticide_id", id)
    suspend fun deleteFungicide(id: String) = softDelete("fungicide", "fungicide_id", id)
    suspend fun deleteInsecticide(id: String) = softDelete("insecticide", "insecticide_id", id)
    suspend fun deleteWater(id: String) = softDelete("water", "water_id", id)

    private suspend fun softDelete(table: String, idColumn: String, idValue: String) {
        try {
            client.from(table)
                .update(mapOf("is_deleted" to true)) {
                    filter {
                        eq(idColumn, idValue)
                    }
                }
        } catch (_: Exception) {}
    }

    // ---------------------------------------------------------------
    // Stock Issuances (Per-category and Global tables)
    // ---------------------------------------------------------------

    suspend fun issueStockItem(
        category: InventoryCategory,
        itemId: String,
        quantityIssued: Double,
        issuedTo: String,
        issueDate: String,
        notes: String?
    ): Result<Unit> {
        return try {
            val farmId = CurrentSession.ensureFarmId(client)

            val table = when (category) {
                InventoryCategory.FERTILIZER -> "fertilizers"
                InventoryCategory.HERBICIDE -> "herbicide"
                InventoryCategory.PESTICIDE -> "pesticide"
                InventoryCategory.FUNGICIDE -> "fungicide"
                InventoryCategory.INSECTICIDE -> "insecticide"
                InventoryCategory.WATER -> "water"
            }
            val idColumn = when (category) {
                InventoryCategory.FERTILIZER -> "fertilizer_id"
                InventoryCategory.HERBICIDE -> "herbicide_id"
                InventoryCategory.PESTICIDE -> "pesticide_id"
                InventoryCategory.FUNGICIDE -> "fungicide_id"
                InventoryCategory.INSECTICIDE -> "insecticide_id"
                InventoryCategory.WATER -> "water_id"
            }

            // 1. Fetch current item details
            val items = getInventoryForFarm(farmId)
            val item = items.find { it.id == itemId }

            // 2. Update stock quantity in category table
            if (item != null) {
                val newQuantity = (item.quantity - quantityIssued).coerceAtLeast(0.0)
                try {
                    val updateMap = if (category == InventoryCategory.WATER) {
                        mapOf("available_quantity" to newQuantity)
                    } else {
                        mapOf("quantity" to newQuantity)
                    }
                    client.from(table).update(updateMap) {
                        filter { eq(idColumn, itemId) }
                    }
                } catch (_: Exception) {}
            }

            // 3. Insert record into category-specific issuance table and global stock_issuance
            val issuanceId = UUID.randomUUID().toString()
            val itemName = item?.name ?: "Stock Item"
            val itemUnit = item?.unit ?: "units"
            val dateStr = issueDate.trim().ifBlank { "2026-03-30" }

            val categoryTables = when (category) {
                InventoryCategory.FERTILIZER -> listOf("fertilizer_issuance", "fertilizers_issuance", "stock_issuance")
                InventoryCategory.HERBICIDE -> listOf("herbicide_issuance", "herbicides_issuance", "stock_issuance")
                InventoryCategory.PESTICIDE -> listOf("pesticide_issuance", "pesticides_issuance", "stock_issuance")
                InventoryCategory.FUNGICIDE -> listOf("fungicide_issuance", "fungicides_issuance", "stock_issuance")
                InventoryCategory.INSECTICIDE -> listOf("insecticide_issuance", "insecticides_issuance", "stock_issuance")
                InventoryCategory.WATER -> listOf("water_issuance", "waters_issuance", "stock_issuance")
            }

            val payloadWithFarm = buildJsonObject {
                put("issuance_id", issuanceId)
                put("item_id", itemId)
                put(idColumn, itemId)
                put("category", category.name)
                put("item_name", itemName)
                put("name", itemName)
                put("quantity_issued", quantityIssued)
                put("quantity", quantityIssued)
                put("unit", itemUnit)
                put("issued_to", issuedTo)
                put("issue_date", dateStr)
                put("issuance_date", dateStr)
                if (!notes.isNullOrBlank()) put("notes", notes)
                if (farmId.isNotBlank()) put("farm_id", farmId)
            }

            val payloadNoFarm = buildJsonObject {
                put("issuance_id", issuanceId)
                put("item_id", itemId)
                put(idColumn, itemId)
                put("category", category.name)
                put("item_name", itemName)
                put("name", itemName)
                put("quantity_issued", quantityIssued)
                put("quantity", quantityIssued)
                put("unit", itemUnit)
                put("issued_to", issuedTo)
                put("issue_date", dateStr)
                put("issuance_date", dateStr)
                if (!notes.isNullOrBlank()) put("notes", notes)
            }

            for (targetTable in categoryTables) {
                try {
                    client.from(targetTable).insert(payloadWithFarm)
                } catch (_: Exception) {
                    try {
                        client.from(targetTable).insert(payloadNoFarm)
                    } catch (_: Exception) {}
                }
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun fetchIssuancesFromTable(
        tableName: String,
        category: InventoryCategory,
        farmId: String
    ): List<StockIssuance> {
        return try {
            val rawList = try {
                client.from(tableName)
                    .select {
                        filter {
                            if (farmId.isNotBlank()) eq("farm_id", farmId)
                        }
                    }
                    .decodeList<JsonObject>()
            } catch (_: Exception) {
                client.from(tableName).select().decodeList<JsonObject>()
            }

            val idColumn = when (category) {
                InventoryCategory.FERTILIZER -> "fertilizer_id"
                InventoryCategory.HERBICIDE -> "herbicide_id"
                InventoryCategory.PESTICIDE -> "pesticide_id"
                InventoryCategory.FUNGICIDE -> "fungicide_id"
                InventoryCategory.INSECTICIDE -> "insecticide_id"
                InventoryCategory.WATER -> "water_id"
            }

            rawList.mapNotNull { json ->
                try {
                    val issuanceId = json["issuance_id"]?.jsonPrimitive?.contentOrNull
                        ?: json["id"]?.jsonPrimitive?.contentOrNull
                        ?: UUID.randomUUID().toString()

                    val itemId = json["item_id"]?.jsonPrimitive?.contentOrNull
                        ?: json[idColumn]?.jsonPrimitive?.contentOrNull
                        ?: ""

                    val itemName = json["item_name"]?.jsonPrimitive?.contentOrNull
                        ?: json["name"]?.jsonPrimitive?.contentOrNull
                        ?: "Stock Item"

                    val qty = json["quantity_issued"]?.jsonPrimitive?.doubleOrNull
                        ?: json["quantity"]?.jsonPrimitive?.doubleOrNull
                        ?: 0.0

                    val unit = json["unit"]?.jsonPrimitive?.contentOrNull ?: "units"
                    val issuedTo = json["issued_to"]?.jsonPrimitive?.contentOrNull ?: "Field"
                    val issueDate = json["issue_date"]?.jsonPrimitive?.contentOrNull
                        ?: json["issuance_date"]?.jsonPrimitive?.contentOrNull
                        ?: "2026-03-30"

                    val notes = json["notes"]?.jsonPrimitive?.contentOrNull

                    StockIssuance(
                        issuanceId = issuanceId,
                        itemId = itemId,
                        category = category.name,
                        itemName = itemName,
                        quantityIssued = qty,
                        unit = unit,
                        issuedTo = issuedTo,
                        issueDate = issueDate,
                        notes = notes,
                        farmId = farmId
                    )
                } catch (_: Exception) {
                    null
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getStockIssuancesForFarm(farmId: String): List<StockIssuance> = coroutineScope {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)

        val fertList = async { fetchIssuancesFromTable("fertilizer_issuance", InventoryCategory.FERTILIZER, validFarmId) }
        val herbList = async { fetchIssuancesFromTable("herbicide_issuance", InventoryCategory.HERBICIDE, validFarmId) }
        val pestList = async { fetchIssuancesFromTable("pesticide_issuance", InventoryCategory.PESTICIDE, validFarmId) }
        val fungList = async { fetchIssuancesFromTable("fungicide_issuance", InventoryCategory.FUNGICIDE, validFarmId) }
        val insecList = async { fetchIssuancesFromTable("insecticide_issuance", InventoryCategory.INSECTICIDE, validFarmId) }
        val waterList = async { fetchIssuancesFromTable("water_issuance", InventoryCategory.WATER, validFarmId) }
        val globalList = async { fetchIssuancesFromTable("stock_issuance", InventoryCategory.FERTILIZER, validFarmId) }

        val combined = fertList.await() + herbList.await() + pestList.await() +
                fungList.await() + insecList.await() + waterList.await() + globalList.await()

        combined.distinctBy { it.safeIssuanceId }
    }
}
