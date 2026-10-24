import 'model_parsing.dart';

class ReportCategoryStatus {
  const ReportCategoryStatus({
    required this.farmId,
    required this.categoryId,
    required this.code,
    required this.name,
    required this.description,
    this.icon,
    this.sortOrder = 0,
    this.lastReportId,
    this.lastGeneratedAt,
  });

  final String farmId;
  final String categoryId;
  final String code;
  final String name;
  final String description;
  final String? icon;
  final int sortOrder;
  final String? lastReportId;
  final String? lastGeneratedAt;

  factory ReportCategoryStatus.fromJson(JsonRow json) => ReportCategoryStatus(
        farmId: stringValue(json, 'farm_id') ?? '',
        categoryId: stringValue(json, 'category_id') ?? '',
        code: stringValue(json, 'code') ?? '',
        name: stringValue(json, 'name') ?? '',
        description: stringValue(json, 'description') ?? '',
        icon: stringValue(json, 'icon'),
        sortOrder: intValue(json, 'sort_order') ?? 0,
        lastReportId: stringValue(json, 'last_report_id'),
        lastGeneratedAt: stringValue(json, 'last_generated_at'),
      );
}

class ReportRecord {
  const ReportRecord({
    required this.reportId,
    required this.farmId,
    required this.categoryId,
    this.generatedBy,
    this.periodStart,
    this.periodEnd,
    this.status = 'completed',
    this.summary = const {},
    this.fileUrl,
    required this.generatedAt,
  });

  final String reportId;
  final String farmId;
  final String categoryId;
  final String? generatedBy;
  final String? periodStart;
  final String? periodEnd;
  final String status;
  final JsonRow summary;
  final String? fileUrl;
  final String generatedAt;

  factory ReportRecord.fromJson(JsonRow json) => ReportRecord(
        reportId: stringValue(json, 'report_id') ?? '',
        farmId: stringValue(json, 'farm_id') ?? '',
        categoryId: stringValue(json, 'category_id') ?? '',
        generatedBy: stringValue(json, 'generated_by'),
        periodStart: stringValue(json, 'period_start'),
        periodEnd: stringValue(json, 'period_end'),
        status: stringValue(json, 'status') ?? 'completed',
        summary: json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : const {},
        fileUrl: stringValue(json, 'file_url'),
        generatedAt: stringValue(json, 'generated_at') ?? '',
      );
}

sealed class ReportSummary {
  const ReportSummary();

  factory ReportSummary.fromJson(String categoryCode, JsonRow json) =>
      switch (categoryCode) {
        'crop_yield' => CropYieldSummary.fromJson(json),
        'inventory' => InventorySummary.fromJson(json),
        'machinery' => MachinerySummary.fromJson(json),
        'workforce' => WorkforceSummary.fromJson(json),
        'storage' => StorageSummary.fromJson(json),
        _ => throw ArgumentError.value(
            categoryCode,
            'categoryCode',
            'Unsupported report category.',
          ),
      };

  static List<JsonRow> _rows(JsonRow json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

class CropYieldSummary extends ReportSummary {
  const CropYieldSummary({
    required this.totalPlantings,
    required this.plantingsByStatus,
    required this.harvestTotals,
    required this.byCrop,
    required this.byDivision,
    required this.byQualityGrade,
    required this.plantings,
  });

  final int totalPlantings;
  final List<JsonRow> plantingsByStatus;
  final List<JsonRow> harvestTotals;
  final List<JsonRow> byCrop;
  final List<JsonRow> byDivision;
  final List<JsonRow> byQualityGrade;
  final List<JsonRow> plantings;

  factory CropYieldSummary.fromJson(JsonRow json) => CropYieldSummary(
        totalPlantings: intValue(json, 'total_plantings') ?? 0,
        plantingsByStatus: ReportSummary._rows(json, 'plantings_by_status'),
        harvestTotals: ReportSummary._rows(json, 'harvest_totals'),
        byCrop: ReportSummary._rows(json, 'by_crop'),
        byDivision: ReportSummary._rows(json, 'by_division'),
        byQualityGrade: ReportSummary._rows(json, 'by_quality_grade'),
        plantings: ReportSummary._rows(json, 'plantings'),
      );
}

class InventorySummary extends ReportSummary {
  const InventorySummary({
    required this.totalItems,
    required this.outOfStockCount,
    required this.lowStockCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.byCategory,
    required this.reorderAlerts,
    required this.expiryAlerts,
    required this.usageByCategory,
    required this.waterUsage,
  });

  final int totalItems;
  final int outOfStockCount;
  final int lowStockCount;
  final int expiringSoonCount;
  final int expiredCount;
  final List<JsonRow> byCategory;
  final List<JsonRow> reorderAlerts;
  final List<JsonRow> expiryAlerts;
  final List<JsonRow> usageByCategory;
  final List<JsonRow> waterUsage;

  factory InventorySummary.fromJson(JsonRow json) => InventorySummary(
        totalItems: intValue(json, 'total_items') ?? 0,
        outOfStockCount: intValue(json, 'out_of_stock_count') ?? 0,
        lowStockCount: intValue(json, 'low_stock_count') ?? 0,
        expiringSoonCount: intValue(json, 'expiring_soon_count') ?? 0,
        expiredCount: intValue(json, 'expired_count') ?? 0,
        byCategory: ReportSummary._rows(json, 'by_category'),
        reorderAlerts: ReportSummary._rows(json, 'reorder_alerts'),
        expiryAlerts: ReportSummary._rows(json, 'expiry_alerts'),
        usageByCategory: ReportSummary._rows(json, 'usage_by_category'),
        waterUsage: ReportSummary._rows(json, 'water_usage'),
      );
}

class MachinerySummary extends ReportSummary {
  const MachinerySummary({
    required this.usageSessions,
    required this.totalHoursUsed,
    required this.machinesUsed,
    required this.fuelUsed,
    required this.byMachine,
    required this.maintenance,
    required this.maintenanceDue,
  });

  final int usageSessions;
  final double totalHoursUsed;
  final int machinesUsed;
  final List<JsonRow> fuelUsed;
  final List<JsonRow> byMachine;
  final JsonRow maintenance;
  final List<JsonRow> maintenanceDue;

  factory MachinerySummary.fromJson(JsonRow json) => MachinerySummary(
        usageSessions: intValue(json, 'usage_sessions') ?? 0,
        totalHoursUsed: doubleValue(json, 'total_hours_used') ?? 0,
        machinesUsed: intValue(json, 'machines_used') ?? 0,
        fuelUsed: ReportSummary._rows(json, 'fuel_used'),
        byMachine: ReportSummary._rows(json, 'by_machine'),
        maintenance: json['maintenance'] is Map
            ? Map<String, dynamic>.from(json['maintenance'] as Map)
            : const {},
        maintenanceDue: ReportSummary._rows(json, 'maintenance_due'),
      );
}

class WorkforceSummary extends ReportSummary {
  const WorkforceSummary({
    required this.totalWorkers,
    required this.totalHoursWorked,
    required this.activitiesAssigned,
    required this.activitiesCompleted,
    this.overallCompletionRatePct,
    required this.employees,
    required this.activitiesByCategory,
  });

  final int totalWorkers;
  final double totalHoursWorked;
  final int activitiesAssigned;
  final int activitiesCompleted;
  final double? overallCompletionRatePct;
  final List<JsonRow> employees;
  final List<JsonRow> activitiesByCategory;

  factory WorkforceSummary.fromJson(JsonRow json) => WorkforceSummary(
        totalWorkers: intValue(json, 'total_workers') ?? 0,
        totalHoursWorked: doubleValue(json, 'total_hours_worked') ?? 0,
        activitiesAssigned: intValue(json, 'activities_assigned') ?? 0,
        activitiesCompleted: intValue(json, 'activities_completed') ?? 0,
        overallCompletionRatePct:
            doubleValue(json, 'overall_completion_rate_pct'),
        employees: ReportSummary._rows(json, 'employees'),
        activitiesByCategory:
            ReportSummary._rows(json, 'activities_by_category'),
      );
}

class StorageSummary extends ReportSummary {
  const StorageSummary({
    required this.facilities,
    required this.produceByCrop,
    required this.nearExpiryLots,
  });

  final List<JsonRow> facilities;
  final List<JsonRow> produceByCrop;
  final List<JsonRow> nearExpiryLots;

  factory StorageSummary.fromJson(JsonRow json) => StorageSummary(
        facilities: ReportSummary._rows(json, 'facilities'),
        produceByCrop: ReportSummary._rows(json, 'produce_by_crop'),
        nearExpiryLots: ReportSummary._rows(json, 'near_expiry_lots'),
      );
}
