@file:Suppress("unused")

package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Tolerant JSON config used to decode report summaries. */
val ReportJson = Json {
    ignoreUnknownKeys = true
    coerceInputValues = true
    isLenient = true
}

// ---------------------------------------------------------------------
// Rows from the report_category_status view (one card on the screen)
// ---------------------------------------------------------------------
@Serializable
data class ReportCategoryStatus(
    @SerialName("farm_id") val farmId: String,
    @SerialName("category_id") val categoryId: String,
    val code: String,                       // crop_yield, inventory, machinery, workforce, storage
    val name: String,
    val description: String,
    val icon: String? = null,
    @SerialName("sort_order") val sortOrder: Int = 0,
    @SerialName("last_report_id") val lastReportId: String? = null,
    @SerialName("last_generated_at") val lastGeneratedAt: String? = null,
)

/** A row from the report table (also what generate_report returns). */
@Serializable
data class ReportRecord(
    @SerialName("report_id") val reportId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("category_id") val categoryId: String,
    @SerialName("generated_by") val generatedBy: String? = null,
    @SerialName("period_start") val periodStart: String? = null,   // yyyy-MM-dd
    @SerialName("period_end") val periodEnd: String? = null,
    val status: String = "completed",
    val summary: JsonObject = JsonObject(emptyMap()),
    @SerialName("file_url") val fileUrl: String? = null,
    @SerialName("generated_at") val generatedAt: String,
)

/** "Last generated: 12 Sep 2026" / "Not generated yet" */
fun ReportCategoryStatus.lastGeneratedLabel(zone: ZoneId = ZoneId.of("Africa/Nairobi")): String {
    val iso = lastGeneratedAt ?: return "Not generated yet"
    return runCatching {
        val formatted = OffsetDateTime.parse(iso)
            .atZoneSameInstant(zone)
            .format(DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH))
        "Last generated: $formatted"
    }.getOrDefault("Not generated yet")
}

// ---------------------------------------------------------------------
// Typed summaries (mirror the jsonb built by the SQL functions)
// ---------------------------------------------------------------------
sealed interface ReportSummary

// ----- Crop Yield -----
@Serializable data class StatusCount(val status: String = "unknown", val plantings: Int = 0)
@Serializable data class HarvestTotal(val unit: String? = null, val quantity: Double = 0.0, val harvests: Int = 0)
@Serializable data class CropYieldRow(
    @SerialName("crop_name") val cropName: String? = null,
    val unit: String? = null,
    val plantings: Int = 0,
    val harvested: Double = 0.0,
)
@Serializable data class DivisionYieldRow(
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("division_name") val divisionName: String? = null,
    val unit: String? = null,
    val plantings: Int = 0,
    val harvested: Double = 0.0,
)
@Serializable data class GradeRow(val grade: String = "ungraded", val unit: String? = null, val quantity: Double = 0.0)
@Serializable data class PlantingRow(
    @SerialName("planting_id") val plantingId: String,
    @SerialName("crop_name") val cropName: String? = null,
    @SerialName("division_name") val divisionName: String? = null,
    @SerialName("planting_date") val plantingDate: String? = null,
    @SerialName("planting_status") val plantingStatus: String? = null,
    @SerialName("area_planted") val areaPlanted: Double? = null,
    @SerialName("area_unit") val areaUnit: String? = null,
    @SerialName("expected_first_harvest_date") val expectedFirstHarvestDate: String? = null,
    val unit: String? = null,
    val harvested: Double = 0.0,
    val harvests: Int = 0,
    @SerialName("target_qty") val targetQty: Double? = null,
    @SerialName("target_achieved_pct") val targetAchievedPct: Double? = null,
)
@Serializable
data class CropYieldSummary(
    @SerialName("total_plantings") val totalPlantings: Int = 0,
    @SerialName("plantings_by_status") val plantingsByStatus: List<StatusCount> = emptyList(),
    @SerialName("harvest_totals") val harvestTotals: List<HarvestTotal> = emptyList(),
    @SerialName("by_crop") val byCrop: List<CropYieldRow> = emptyList(),
    @SerialName("by_division") val byDivision: List<DivisionYieldRow> = emptyList(),
    @SerialName("by_quality_grade") val byQualityGrade: List<GradeRow> = emptyList(),
    val plantings: List<PlantingRow> = emptyList(),
) : ReportSummary

// ----- Inventory -----
@Serializable data class InventoryCategoryRow(
    val category: String,
    val items: Int = 0,
    @SerialName("low_stock") val lowStock: Int = 0,
    @SerialName("out_of_stock") val outOfStock: Int = 0,
)
@Serializable data class ReorderAlert(
    val category: String,
    @SerialName("item_id") val itemId: String,
    val name: String,
    val quantity: Double = 0.0,
    val unit: String? = null,
    @SerialName("reorder_level") val reorderLevel: Double? = null,
)
@Serializable data class ExpiryAlert(
    val category: String,
    @SerialName("item_id") val itemId: String,
    val name: String,
    val quantity: Double = 0.0,
    val unit: String? = null,
    @SerialName("expiry_date") val expiryDate: String? = null,
    @SerialName("is_expired") val isExpired: Boolean = false,
)
@Serializable data class InventoryUsageRow(
    val category: String,
    val unit: String? = null,
    @SerialName("quantity_used") val quantityUsed: Double = 0.0,
    val applications: Int = 0,
)
@Serializable data class WaterUsageRow(
    val unit: String? = null,
    @SerialName("quantity_used") val quantityUsed: Double = 0.0,
    val records: Int = 0,
)
@Serializable
data class InventorySummary(
    @SerialName("total_items") val totalItems: Int = 0,
    @SerialName("out_of_stock_count") val outOfStockCount: Int = 0,
    @SerialName("low_stock_count") val lowStockCount: Int = 0,
    @SerialName("expiring_soon_count") val expiringSoonCount: Int = 0,
    @SerialName("expired_count") val expiredCount: Int = 0,
    @SerialName("by_category") val byCategory: List<InventoryCategoryRow> = emptyList(),
    @SerialName("reorder_alerts") val reorderAlerts: List<ReorderAlert> = emptyList(),
    @SerialName("expiry_alerts") val expiryAlerts: List<ExpiryAlert> = emptyList(),
    @SerialName("usage_by_category") val usageByCategory: List<InventoryUsageRow> = emptyList(),
    @SerialName("water_usage") val waterUsage: List<WaterUsageRow> = emptyList(),
) : ReportSummary

// ----- Machinery -----
@Serializable data class FuelRow(
    @SerialName("fuel_unit") val fuelUnit: String? = null,
    @SerialName("fuel_used") val fuelUsed: Double = 0.0,
)
@Serializable data class MachineUsageRow(
    @SerialName("machinery_id") val machineryId: String,
    val sessions: Int = 0,
    @SerialName("hours_used") val hoursUsed: Double = 0.0,
    @SerialName("fuel_used") val fuelUsed: Double = 0.0,
    @SerialName("last_hour_meter") val lastHourMeter: Double? = null,
    @SerialName("latest_condition") val latestCondition: String? = null,
)
@Serializable data class MaintenanceTypeRow(
    @SerialName("maintenance_type") val maintenanceType: String? = null,
    val records: Int = 0,
    val cost: Double = 0.0,
)
@Serializable data class MaintenanceStats(
    @SerialName("records_in_period") val recordsInPeriod: Int = 0,
    @SerialName("total_cost") val totalCost: Double = 0.0,
    @SerialName("by_type") val byType: List<MaintenanceTypeRow> = emptyList(),
)
@Serializable data class MaintenanceDueRow(
    @SerialName("machinery_id") val machineryId: String,
    @SerialName("last_maintenance_type") val lastMaintenanceType: String? = null,
    @SerialName("last_maintenance_date") val lastMaintenanceDate: String? = null,
    @SerialName("next_maintenance_date") val nextMaintenanceDate: String? = null,
    @SerialName("days_until_due") val daysUntilDue: Int = 0,
    @SerialName("is_overdue") val isOverdue: Boolean = false,
)
@Serializable
data class MachinerySummary(
    @SerialName("usage_sessions") val usageSessions: Int = 0,
    @SerialName("total_hours_used") val totalHoursUsed: Double = 0.0,
    @SerialName("machines_used") val machinesUsed: Int = 0,
    @SerialName("fuel_used") val fuelUsed: List<FuelRow> = emptyList(),
    @SerialName("by_machine") val byMachine: List<MachineUsageRow> = emptyList(),
    val maintenance: MaintenanceStats = MaintenanceStats(),
    @SerialName("maintenance_due") val maintenanceDue: List<MaintenanceDueRow> = emptyList(),
) : ReportSummary

// ----- Workforce -----
@Serializable data class EmployeeRow(
    @SerialName("worker_profile_id") val workerProfileId: String,
    @SerialName("employee_number") val employeeNumber: String? = null,
    @SerialName("worker_name") val workerName: String? = null,
    @SerialName("days_present") val daysPresent: Int = 0,
    @SerialName("days_late") val daysLate: Int = 0,
    @SerialName("days_absent") val daysAbsent: Int = 0,
    @SerialName("days_on_leave") val daysOnLeave: Int = 0,
    @SerialName("activities_assigned") val activitiesAssigned: Int = 0,
    @SerialName("activities_completed") val activitiesCompleted: Int = 0,
    @SerialName("hours_worked") val hoursWorked: Double = 0.0,
    @SerialName("completion_rate_pct") val completionRatePct: Double? = null,
) {
    val displayName: String get() = workerName ?: employeeNumber ?: "Unnamed worker"
}
@Serializable data class ActivityCategoryRow(
    val category: String = "uncategorised",
    val activities: Int = 0,
    val hours: Double = 0.0,
)
@Serializable
data class WorkforceSummary(
    @SerialName("total_workers") val totalWorkers: Int = 0,
    @SerialName("total_hours_worked") val totalHoursWorked: Double = 0.0,
    @SerialName("activities_assigned") val activitiesAssigned: Int = 0,
    @SerialName("activities_completed") val activitiesCompleted: Int = 0,
    @SerialName("overall_completion_rate_pct") val overallCompletionRatePct: Double? = null,
    val employees: List<EmployeeRow> = emptyList(),
    @SerialName("activities_by_category") val activitiesByCategory: List<ActivityCategoryRow> = emptyList(),
) : ReportSummary

// ----- Storage -----
@Serializable data class FacilityRow(
    @SerialName("facility_id") val facilityId: String,
    val name: String,
    @SerialName("facility_type") val facilityType: String? = null,
    @SerialName("capacity_kg") val capacityKg: Double = 0.0,
    val condition: String? = null,
    @SerialName("stored_kg") val storedKg: Double = 0.0,
    @SerialName("utilisation_pct") val utilisationPct: Double = 0.0,
    @SerialName("at_risk_lots") val atRiskLots: Int = 0,
)
@Serializable data class ProduceByCropRow(
    @SerialName("crop_name") val cropName: String,
    @SerialName("stored_kg") val storedKg: Double = 0.0,
    val lots: Int = 0,
)
@Serializable data class NearExpiryRow(
    @SerialName("stock_id") val stockId: String,
    @SerialName("crop_name") val cropName: String,
    @SerialName("quantity_kg") val quantityKg: Double = 0.0,
    val condition: String? = null,
    @SerialName("expires_on") val expiresOn: String? = null,
)
@Serializable
data class StorageSummary(
    val facilities: List<FacilityRow> = emptyList(),
    @SerialName("produce_by_crop") val produceByCrop: List<ProduceByCropRow> = emptyList(),
    @SerialName("near_expiry_lots") val nearExpiryLots: List<NearExpiryRow> = emptyList(),
) : ReportSummary

/** Decode the raw jsonb summary into the right typed model for a category code. */
fun parseReportSummary(code: String, summary: JsonObject): ReportSummary? = runCatching {
    when (code) {
        "crop_yield" -> ReportJson.decodeFromJsonElement(CropYieldSummary.serializer(), summary)
        "inventory"  -> ReportJson.decodeFromJsonElement(InventorySummary.serializer(), summary)
        "machinery"  -> ReportJson.decodeFromJsonElement(MachinerySummary.serializer(), summary)
        "workforce"  -> ReportJson.decodeFromJsonElement(WorkforceSummary.serializer(), summary)
        "storage"    -> ReportJson.decodeFromJsonElement(StorageSummary.serializer(), summary)
        else -> null
    }
}.getOrNull()
