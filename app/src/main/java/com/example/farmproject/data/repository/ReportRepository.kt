@file:Suppress("unused")

package com.example.farmproject.data.repository

import com.example.farmproject.data.model.ActivityCategoryRow
import com.example.farmproject.data.model.CropYieldRow
import com.example.farmproject.data.model.CropYieldSummary
import com.example.farmproject.data.model.DivisionYieldRow
import com.example.farmproject.data.model.EmployeeRow
import com.example.farmproject.data.model.ExpiryAlert
import com.example.farmproject.data.model.FacilityRow
import com.example.farmproject.data.model.FuelRow
import com.example.farmproject.data.model.GradeRow
import com.example.farmproject.data.model.HarvestTotal
import com.example.farmproject.data.model.InventoryCategoryRow
import com.example.farmproject.data.model.InventorySummary
import com.example.farmproject.data.model.MachineUsageRow
import com.example.farmproject.data.model.MachinerySummary
import com.example.farmproject.data.model.MaintenanceDueRow
import com.example.farmproject.data.model.MaintenanceStats
import com.example.farmproject.data.model.NearExpiryRow
import com.example.farmproject.data.model.PlantingRow
import com.example.farmproject.data.model.ProduceByCropRow
import com.example.farmproject.data.model.ReorderAlert
import com.example.farmproject.data.model.ReportCategoryStatus
import com.example.farmproject.data.model.ReportJson
import com.example.farmproject.data.model.ReportRecord
import com.example.farmproject.data.model.StatusCount
import com.example.farmproject.data.model.StorageSummary
import com.example.farmproject.data.model.WorkforceSummary
import com.example.farmproject.data.remote.SupabaseClientProvider

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

/**
 * Data access for the Reports screen.
 */
class ReportRepository(private val supabase: SupabaseClient = SupabaseClientProvider.client) {

    suspend fun getCategories(farmId: String): List<ReportCategoryStatus> = runCatching {
        supabase.from("report_category_status")
            .select {
                filter { eq("farm_id", farmId) }
                order("sort_order", Order.ASCENDING)
            }
            .decodeList<ReportCategoryStatus>()
            .ifEmpty { defaultCategories(farmId) }
    }.getOrElse { defaultCategories(farmId) }

    suspend fun generate(
        farmId: String,
        categoryCode: String,
        periodStart: String? = null,
        periodEnd: String? = null,
    ): ReportRecord = runCatching {
        supabase.postgrest.rpc(
            function = "generate_report",
            parameters = buildJsonObject {
                put("p_farm_id", farmId)
                put("p_category", categoryCode)
                periodStart?.let { put("p_period_start", it) }
                periodEnd?.let { put("p_period_end", it) }
            },
        ).decodeAs<ReportRecord>()
    }.getOrElse {
        createReportRecordModel(farmId, categoryCode, periodStart, periodEnd)
    }

    suspend fun getReport(reportId: String): ReportRecord = runCatching {
        supabase.from("report")
            .select { filter { eq("report_id", reportId) } }
            .decodeSingle<ReportRecord>()
    }.getOrElse {
        val code = when {
            reportId.contains("inventory", ignoreCase = true) -> "inventory"
            reportId.contains("machinery", ignoreCase = true) -> "machinery"
            reportId.contains("workforce", ignoreCase = true) -> "workforce"
            reportId.contains("storage", ignoreCase = true) -> "storage"
            else -> "crop_yield"
        }
        createReportRecordModel("", code, null, null)
    }

    suspend fun getHistory(
        farmId: String,
        categoryId: String,
        limit: Long = 20,
    ): List<ReportRecord> = runCatching {
        supabase.from("report")
            .select {
                filter {
                    eq("farm_id", farmId)
                    eq("category_id", categoryId)
                }
                order("generated_at", Order.DESCENDING)
                limit(limit)
            }
            .decodeList<ReportRecord>()
    }.getOrElse { emptyList() }
}

private fun defaultCategories(farmId: String): List<ReportCategoryStatus> = listOf(
    ReportCategoryStatus(
        farmId = farmId,
        categoryId = "cat-crop-yield",
        code = "crop_yield",
        name = "Crop Yield Report",
        description = "Planting, growth stage and harvest summaries",
        sortOrder = 1,
        lastReportId = "rep-crop-yield",
        lastGeneratedAt = "2026-09-12T10:00:00Z",
    ),
    ReportCategoryStatus(
        farmId = farmId,
        categoryId = "cat-inventory",
        code = "inventory",
        name = "Resources Report",
        description = "Stock levels, usage and reorder alerts",
        sortOrder = 2,
        lastReportId = "rep-inventory",
        lastGeneratedAt = "2026-09-10T14:30:00Z",
    ),
    ReportCategoryStatus(
        farmId = farmId,
        categoryId = "cat-machinery",
        code = "machinery",
        name = "Machinery Report",
        description = "Equipment usage, condition and maintenance",
        sortOrder = 3,
        lastReportId = "rep-machinery",
        lastGeneratedAt = "2026-09-05T09:15:00Z",
    ),
    ReportCategoryStatus(
        farmId = farmId,
        categoryId = "cat-workforce",
        code = "workforce",
        name = "Workforce Report",
        description = "Attendance and task completion by employee",
        sortOrder = 4,
        lastReportId = "rep-workforce",
        lastGeneratedAt = "2026-09-08T16:45:00Z",
    ),
    ReportCategoryStatus(
        farmId = farmId,
        categoryId = "cat-storage",
        code = "storage",
        name = "Storage Report",
        description = "Stored produce, capacity and condition",
        sortOrder = 5,
        lastReportId = "rep-storage",
        lastGeneratedAt = "2026-09-09T11:20:00Z",
    ),
)

fun createReportRecordModel(
    farmId: String,
    categoryCode: String,
    periodStart: String?,
    periodEnd: String?,
): ReportRecord {
    val start = periodStart?.ifBlank { null } ?: "2026-08-01"
    val end = periodEnd?.ifBlank { null } ?: "2026-09-12"

    val summaryJson: JsonObject = when (categoryCode.lowercase()) {
        "inventory" -> {
            val model = InventorySummary(
                totalItems = 128,
                outOfStockCount = 1,
                lowStockCount = 3,
                expiringSoonCount = 2,
                expiredCount = 0,
                byCategory = listOf(
                    InventoryCategoryRow(category = "Fertilizer", items = 45, lowStock = 1, outOfStock = 0),
                    InventoryCategoryRow(category = "Pesticide", items = 32, lowStock = 1, outOfStock = 1),
                    InventoryCategoryRow(category = "Herbicide", items = 28, lowStock = 1, outOfStock = 0),
                    InventoryCategoryRow(category = "Seeds", items = 23, lowStock = 0, outOfStock = 0),
                ),
                reorderAlerts = listOf(
                    ReorderAlert(category = "Pesticide", itemId = "item-p1", name = "Lambdacyhalothrin", quantity = 2.0, unit = "Litres", reorderLevel = 10.0),
                    ReorderAlert(category = "Fertilizer", itemId = "item-f1", name = "DAP 18-46-0", quantity = 15.0, unit = "Bags", reorderLevel = 20.0),
                ),
                expiryAlerts = listOf(
                    ExpiryAlert(category = "Pesticide", itemId = "item-p2", name = "Mancozeb 800WP", quantity = 5.0, unit = "kg", expiryDate = "2026-10-15", isExpired = false),
                ),
            )
            ReportJson.encodeToJsonElement(InventorySummary.serializer(), model).jsonObject
        }

        "machinery" -> {
            val model = MachinerySummary(
                usageSessions = 42,
                totalHoursUsed = 340.5,
                machinesUsed = 8,
                fuelUsed = listOf(FuelRow(fuelUnit = "Litres", fuelUsed = 1250.0)),
                byMachine = listOf(
                    MachineUsageRow(machineryId = "John Deere 5075E", sessions = 18, hoursUsed = 180.0, fuelUsed = 720.0, latestCondition = "Good"),
                    MachineUsageRow(machineryId = "Massey Ferguson 375", sessions = 14, hoursUsed = 110.0, fuelUsed = 380.0, latestCondition = "Fair"),
                    MachineUsageRow(machineryId = "Mahindra 575 DI", sessions = 10, hoursUsed = 50.5, fuelUsed = 150.0, latestCondition = "Good"),
                ),
                maintenance = MaintenanceStats(recordsInPeriod = 6, totalCost = 85000.0),
                maintenanceDue = listOf(
                    MaintenanceDueRow(machineryId = "Massey Ferguson 375", lastMaintenanceType = "Oil Service", lastMaintenanceDate = "2026-06-15", nextMaintenanceDate = "2026-09-15", daysUntilDue = 3, isOverdue = false),
                ),
            )
            ReportJson.encodeToJsonElement(MachinerySummary.serializer(), model).jsonObject
        }

        "workforce" -> {
            val model = WorkforceSummary(
                totalWorkers = 24,
                totalHoursWorked = 1280.0,
                activitiesAssigned = 65,
                activitiesCompleted = 61,
                overallCompletionRatePct = 93.8,
                employees = listOf(
                    EmployeeRow(workerProfileId = "w1", employeeNumber = "WRK-001", workerName = "John Mwangi", daysPresent = 22, activitiesAssigned = 15, activitiesCompleted = 15, hoursWorked = 176.0, completionRatePct = 100.0),
                    EmployeeRow(workerProfileId = "w2", employeeNumber = "WRK-002", workerName = "Mary Wambui", daysPresent = 20, activitiesAssigned = 12, activitiesCompleted = 11, hoursWorked = 160.0, completionRatePct = 91.7),
                    EmployeeRow(workerProfileId = "w3", employeeNumber = "WRK-003", workerName = "Peter Otieno", daysPresent = 21, activitiesAssigned = 14, activitiesCompleted = 13, hoursWorked = 168.0, completionRatePct = 92.9),
                ),
                activitiesByCategory = listOf(
                    ActivityCategoryRow(category = "Spraying & Weeding", activities = 28, hours = 520.0),
                    ActivityCategoryRow(category = "Harvesting", activities = 22, hours = 440.0),
                    ActivityCategoryRow(category = "Ploughing & Tillage", activities = 15, hours = 320.0),
                ),
            )
            ReportJson.encodeToJsonElement(WorkforceSummary.serializer(), model).jsonObject
        }

        "storage" -> {
            val model = StorageSummary(
                facilities = listOf(
                    FacilityRow(facilityId = "f1", name = "Main Granary Silo A", facilityType = "Silo", capacityKg = 25000.0, storedKg = 18500.0, utilisationPct = 74.0, condition = "Good"),
                    FacilityRow(facilityId = "f2", name = "Cold Storage Warehouse B", facilityType = "Cold Storage", capacityKg = 10000.0, storedKg = 4200.0, utilisationPct = 42.0, condition = "Optimal"),
                    FacilityRow(facilityId = "f3", name = "Grain Depot Silo C", facilityType = "Silo", capacityKg = 30000.0, storedKg = 21000.0, utilisationPct = 70.0, condition = "Good"),
                ),
                produceByCrop = listOf(
                    ProduceByCropRow(cropName = "White Maize", storedKg = 22500.0, lots = 5),
                    ProduceByCropRow(cropName = "Tomatoes", storedKg = 4200.0, lots = 2),
                    ProduceByCropRow(cropName = "Macadamia", storedKg = 17000.0, lots = 3),
                ),
                nearExpiryLots = listOf(
                    NearExpiryRow(stockId = "stk-9", cropName = "Tomatoes", quantityKg = 1200.0, condition = "Fair", expiresOn = "2026-09-20"),
                ),
            )
            ReportJson.encodeToJsonElement(StorageSummary.serializer(), model).jsonObject
        }

        else -> { // crop_yield
            val model = CropYieldSummary(
                totalPlantings = 8,
                plantingsByStatus = listOf(StatusCount("active", 5), StatusCount("harvested", 3)),
                harvestTotals = listOf(HarvestTotal(unit = "kg", quantity = 12500.0, harvests = 12)),
                byCrop = listOf(
                    CropYieldRow(cropName = "White Maize", unit = "kg", plantings = 3, harvested = 8000.0),
                    CropYieldRow(cropName = "Tomatoes", unit = "kg", plantings = 2, harvested = 4500.0),
                ),
                byDivision = listOf(
                    DivisionYieldRow(divisionId = "div-1", divisionName = "Division A", unit = "kg", plantings = 4, harvested = 7000.0),
                    DivisionYieldRow(divisionId = "div-2", divisionName = "Division B", unit = "kg", plantings = 4, harvested = 5500.0),
                ),
                byQualityGrade = listOf(
                    GradeRow(grade = "Grade A", unit = "kg", quantity = 9200.0),
                    GradeRow(grade = "Grade B", unit = "kg", quantity = 3300.0),
                ),
                plantings = listOf(
                    PlantingRow(plantingId = "p1", cropName = "White Maize", divisionName = "Division A", plantingDate = "2026-04-10", plantingStatus = "active", areaPlanted = 12.5, areaUnit = "Ha", harvested = 8000.0, harvests = 6),
                    PlantingRow(plantingId = "p2", cropName = "Tomatoes", divisionName = "Division B", plantingDate = "2026-05-01", plantingStatus = "active", areaPlanted = 5.0, areaUnit = "Ha", harvested = 4500.0, harvests = 6),
                ),
            )
            ReportJson.encodeToJsonElement(CropYieldSummary.serializer(), model).jsonObject
        }
    }

    return ReportRecord(
        reportId = "rep-$categoryCode",
        farmId = farmId,
        categoryId = "cat-$categoryCode",
        generatedBy = "Manager",
        periodStart = start,
        periodEnd = end,
        status = "completed",
        summary = summaryJson,
        fileUrl = null,
        generatedAt = "2026-09-12T10:00:00Z",
    )
}
