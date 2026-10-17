package com.example.farmproject.data.repository

import com.example.farmproject.data.model.Crop
import com.example.farmproject.data.model.CropHarvest
import com.example.farmproject.data.model.CropPlanting
import com.example.farmproject.data.model.CropPlantingDisplay
import com.example.farmproject.data.model.Division
import com.example.farmproject.data.remote.SupabaseClientProvider
import com.example.farmproject.data.session.CurrentSession
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.time.LocalDate
import java.util.UUID

@Serializable
internal data class CropNameLookup(
    @SerialName("crop_id") val cropId: String,
    val name: String
)

@Serializable
internal data class DivisionNameLookup(
    @SerialName("division_id") val divisionId: String,
    val name: String
)

class CropRepository(
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

    private suspend fun resolveCropId(input: String): String {
        val cleanInput = input.trim()
        if (cleanInput.isBlank()) return UUID.randomUUID().toString()
        if (cleanInput.isValidUuid()) return cleanInput

        val existing = try {
            client.from("crop")
                .select {
                    filter {
                        ilike("name", cleanInput)
                        eq("is_deleted", false)
                    }
                }
                .decodeList<CropNameLookup>()
                .firstOrNull()
        } catch (_: Exception) {
            null
        }

        if (existing != null) return existing.cropId

        val newCropId = UUID.randomUUID().toString()
        return try {
            val inserted = client.from("crop")
                .insert(
                    Crop(
                        cropId = newCropId,
                        name = cleanInput,
                        description = null
                    )
                ) {
                    select()
                }
                .decodeSingle<Crop>()
            inserted.cropId ?: newCropId
        } catch (_: Exception) {
            newCropId
        }
    }

    private suspend fun resolveDivisionId(farmId: String, input: String): String {
        val cleanInput = input.trim()
        if (cleanInput.isBlank()) return UUID.randomUUID().toString()
        if (cleanInput.isValidUuid()) return cleanInput

        val existing = try {
            client.from("division")
                .select {
                    filter {
                        if (farmId.isNotBlank()) {
                            eq("farm_id", farmId)
                        }
                        ilike("name", cleanInput)
                        eq("is_deleted", false)
                    }
                }
                .decodeList<DivisionNameLookup>()
                .firstOrNull()
        } catch (_: Exception) {
            null
        }

        if (existing != null) return existing.divisionId

        val newDivisionId = UUID.randomUUID().toString()
        return try {
            val inserted = client.from("division")
                .insert(
                    Division(
                        divisionId = newDivisionId,
                        farmId = farmId,
                        name = cleanInput,
                        size = 1.0
                    )
                ) {
                    select()
                }
                .decodeSingle<Division>()
            inserted.divisionId ?: newDivisionId
        } catch (_: Exception) {
            newDivisionId
        }
    }

    suspend fun createCrop(
        name: String,
        scientificName: String? = null,
        description: String? = null
    ): Result<Crop> {
        val trimmedName = name.trim()
        if (trimmedName.isBlank()) {
            return Result.failure(Exception("Crop name cannot be empty."))
        }

        val newCropId = UUID.randomUUID().toString()
        val sName = scientificName?.trim()?.ifBlank { null }
        val desc = description?.trim()?.ifBlank { null }

        val newCrop = Crop(
            cropId = newCropId,
            name = trimmedName,
            scientificName = sName,
            description = desc ?: ""
        )

        val payload1 = buildJsonObject {
            put("crop_id", newCropId)
            put("name", trimmedName)
            if (!sName.isNullOrBlank()) put("scientific_name", sName)
            put("description", desc ?: "")
        }

        val payload2 = buildJsonObject {
            put("crop_id", newCropId)
            put("name", trimmedName)
            if (!sName.isNullOrBlank()) put("scientific_name", sName)
        }

        return try {
            try {
                client.from("crop").insert(payload1)
            } catch (_: Exception) {
                try {
                    client.from("crop").insert(payload2)
                } catch (_: Exception) {
                    client.from("crop").insert(newCrop)
                }
            }
            Result.success(newCrop)
        } catch (e: Exception) {
            Result.failure(Exception(e.message ?: "Failed to create crop."))
        }
    }

    suspend fun assignCropToDivision(
        cropId: String,
        divisionId: String
    ): Result<CropPlanting> {
        val farmId = CurrentSession.ensureFarmId(client)
        val todayDate = try {
            LocalDate.now().toString()
        } catch (_: Exception) {
            "2026-03-30"
        }

        val planting = CropPlanting(
            plantingId = UUID.randomUUID().toString(),
            cropId = cropId,
            farmId = farmId,
            divisionId = divisionId,
            plantingDate = todayDate,
            areaUnit = "Acres",
            plantingStatus = "Active"
        )

        return try {
            client.from("crop_planting").insert(planting)
            Result.success(planting)
        } catch (e: Exception) {
            Result.failure(Exception(e.message ?: "Failed to assign crop to division."))
        }
    }

    suspend fun getAssignedCropsByDivision(farmId: String): Map<String, List<String>> {
        val plantings = getCropPlantingsForFarm(farmId)
        return plantings.groupBy { it.planting.divisionId }
            .mapValues { entry -> entry.value.map { it.cropName }.distinct() }
    }

    suspend fun getCropCatalog(): List<Crop> {
        return try {
            client.from("crop")
                .select {
                    filter {
                        eq("is_deleted", false)
                    }
                }
                .decodeList<Crop>()
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun deleteCrop(cropId: String) {
        try {
            client.from("crop")
                .update(mapOf("is_deleted" to true)) {
                    filter {
                        eq("crop_id", cropId)
                    }
                }
        } catch (_: Exception) {}
    }

    suspend fun getCropPlantingsForFarm(farmId: String): List<CropPlantingDisplay> {
        val validFarmId = if (farmId.isValidUuid()) farmId else CurrentSession.ensureFarmId(client)

        val plantings = try {
            client.from("crop_planting")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) {
                            eq("farm_id", validFarmId)
                        }
                        eq("is_deleted", false)
                    }
                }
                .decodeList<CropPlanting>()
        } catch (_: Exception) {
            emptyList()
        }

        if (plantings.isEmpty()) return emptyList()

        val cropIds = plantings.map { it.cropId }.filter { it.isValidUuid() }.distinct()
        val divisionIds = plantings.map { it.divisionId }.filter { it.isValidUuid() }.distinct()

        val cropNames = try {
            if (cropIds.isEmpty()) emptyMap() else {
                client.from("crop")
                    .select(columns = Columns.list("crop_id", "name")) {
                        filter {
                            isIn("crop_id", cropIds)
                        }
                    }
                    .decodeList<CropNameLookup>()
                    .associate { it.cropId to it.name }
            }
        } catch (_: Exception) {
            emptyMap()
        }

        val divisionNames = try {
            if (divisionIds.isEmpty()) emptyMap() else {
                client.from("division")
                    .select(columns = Columns.list("division_id", "name")) {
                        filter {
                            isIn("division_id", divisionIds)
                        }
                    }
                    .decodeList<DivisionNameLookup>()
                    .associate { it.divisionId to it.name }
            }
        } catch (_: Exception) {
            emptyMap()
        }

        return plantings.map { planting ->
            CropPlantingDisplay(
                planting = planting,
                cropName = cropNames[planting.cropId] ?: planting.cropId,
                divisionName = divisionNames[planting.divisionId] ?: planting.divisionId
            )
        }
    }

    suspend fun getCropPlantingById(plantingId: String): CropPlanting? {
        return try {
            client.from("crop_planting")
                .select {
                    filter {
                        eq("planting_id", plantingId)
                    }
                }
                .decodeSingleOrNull<CropPlanting>()
        } catch (_: Exception) {
            null
        }
    }

    suspend fun insertCropPlanting(planting: CropPlanting): CropPlanting {
        val resolvedFarmId = if (planting.farmId.isValidUuid()) planting.farmId else CurrentSession.ensureFarmId(client)
        val finalCropName = planting.cropId.ifBlank { "Maize" }
        val finalDivisionName = planting.divisionId.ifBlank { "Division A" }
        val resolvedCropId = resolveCropId(finalCropName)
        val resolvedDivisionId = resolveDivisionId(resolvedFarmId, finalDivisionName)

        val todayDate = try {
            LocalDate.now().toString()
        } catch (_: Exception) {
            "2026-03-30"
        }

        val cleanDate = planting.plantingDate.trim().ifBlank { todayDate }

        val cleanPlanting = planting.copy(
            plantingId = planting.plantingId ?: UUID.randomUUID().toString(),
            farmId = resolvedFarmId,
            cropId = resolvedCropId,
            divisionId = resolvedDivisionId,
            plantingDate = cleanDate
        )

        return try {
            client.from("crop_planting")
                .insert(cleanPlanting) {
                    select()
                }
                .decodeSingle<CropPlanting>()
        } catch (_: Exception) {
            try {
                client.from("crop_planting").insert(cleanPlanting)
                cleanPlanting
            } catch (inner: Exception) {
                throw inner
            }
        }
    }

    suspend fun updateCropPlanting(planting: CropPlanting): CropPlanting {
        val id = requireNotNull(planting.plantingId) {
            "Cannot update a CropPlanting with no plantingId"
        }

        return client.from("crop_planting")
            .update(planting) {
                filter {
                    eq("planting_id", id)
                }
                select()
            }
            .decodeSingle<CropPlanting>()
    }

    suspend fun deleteCropPlanting(plantingId: String) {
        try {
            client.from("crop_planting")
                .update(mapOf("is_deleted" to true)) {
                    filter {
                        eq("planting_id", plantingId)
                    }
                }
        } catch (_: Exception) {}
    }

    suspend fun getCropHarvestsForFarm(farmId: String): List<CropHarvestDisplay> {
        val validFarmId = if (farmId.isNotBlank()) farmId else CurrentSession.ensureFarmId(client)

        val rawHarvests = try {
            client.from("crop_harvest")
                .select {
                    filter {
                        if (validFarmId.isNotBlank()) eq("farm_id", validFarmId)
                    }
                    order("harvest_date", Order.DESCENDING)
                }
                .decodeList<CropHarvest>()
        } catch (_: Exception) {
            emptyList()
        }

        if (rawHarvests.isEmpty()) return emptyList()

        val plantings = getCropPlantingsForFarm(validFarmId)
        val plantingMap = plantings.associateBy { it.planting.plantingId }

        return rawHarvests.map { h ->
            val pDisplay = plantingMap[h.plantingId]
            CropHarvestDisplay(
                harvest = h,
                cropName = pDisplay?.cropName ?: "Harvested Crop",
                divisionName = pDisplay?.divisionName ?: "Division"
            )
        }
    }

    suspend fun recordCropHarvest(
        plantingId: String,
        divisionId: String,
        harvestDate: String,
        quantityHarvested: Double,
        quantityUnit: String,
        qualityGrade: String?,
        notes: String?
    ): Result<CropHarvest> {
        val farmId = CurrentSession.ensureFarmId(client)
        val hId = UUID.randomUUID().toString()

        val harvest = CropHarvest(
            harvestId = hId,
            plantingId = plantingId,
            farmId = farmId,
            divisionId = divisionId,
            harvestDate = harvestDate.ifBlank { "2026-03-30" },
            quantityHarvested = quantityHarvested,
            quantityUnit = quantityUnit,
            qualityGrade = qualityGrade?.ifBlank { null },
            quantity = quantityHarvested,
            unit = quantityUnit,
            notes = notes?.ifBlank { null }
        )

        val payload = buildJsonObject {
            put("harvest_id", hId)
            put("planting_id", plantingId)
            put("farm_id", farmId)
            put("division_id", divisionId)
            put("harvest_date", harvestDate.ifBlank { "2026-03-30" })
            put("quantity_harvested", quantityHarvested)
            put("quantity_unit", quantityUnit)
            if (!qualityGrade.isNullOrBlank()) put("quality_grade", qualityGrade)
            put("quantity", quantityHarvested)
            put("unit", quantityUnit)
            if (!notes.isNullOrBlank()) put("notes", notes)
        }

        return try {
            try {
                client.from("crop_harvest").insert(payload)
            } catch (_: Exception) {
                client.from("crop_harvest").insert(harvest)
            }
            Result.success(harvest)
        } catch (e: Exception) {
            Result.failure(Exception(e.message ?: "Failed to record crop harvest."))
        }
    }
}

data class CropHarvestDisplay(
    val harvest: CropHarvest,
    val cropName: String,
    val divisionName: String
)
