package com.example.farmproject.data.repository

import com.example.farmproject.data.model.Crop
import com.example.farmproject.data.model.CropPlanting
import com.example.farmproject.data.model.CropPlantingDisplay
import com.example.farmproject.data.model.Division
import com.example.farmproject.data.remote.SupabaseClientProvider
import com.example.farmproject.data.session.CurrentSession
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
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
        val newCrop = Crop(
            cropId = newCropId,
            name = trimmedName,
            scientificName = scientificName?.trim()?.ifBlank { null },
            description = description?.trim()?.ifBlank { null }
        )

        return try {
            val inserted = client.from("crop")
                .insert(newCrop) {
                    select()
                }
                .decodeSingle<Crop>()
            Result.success(inserted)
        } catch (_: Exception) {
            try {
                client.from("crop").insert(newCrop)
                Result.success(newCrop)
            } catch (e: Exception) {
                Result.failure(Exception(e.message ?: "Failed to create crop."))
            }
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
}
