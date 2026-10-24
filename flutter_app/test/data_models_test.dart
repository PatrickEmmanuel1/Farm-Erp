import 'package:flutter_test/flutter_test.dart';
import 'package:farm_flutter/data/model/attendance.dart';
import 'package:farm_flutter/data/model/crop.dart';
import 'package:farm_flutter/data/model/farm.dart';
import 'package:farm_flutter/data/model/inventory.dart';
import 'package:farm_flutter/data/model/inventory_category.dart';
import 'package:farm_flutter/data/model/machinery.dart';
import 'package:farm_flutter/data/model/report.dart';
import 'package:farm_flutter/data/model/storage.dart';

void main() {
  test('Farm and division map database snake_case fields', () {
    final farm = Farm.fromJson({
      'farm_id': 'farm-1',
      'name': 'Green Farm',
      'total_size': 12,
      'unit': 'Acres',
      'county': 'Nakuru',
      'soil_ph': '6.4',
      'is_deleted': false,
    });

    expect(farm.farmId, 'farm-1');
    expect(farm.totalSize, 12);
    expect(farm.soilPh, 6.4);
    expect(farm.toJson()['total_size'], 12);
  });

  test('Crop planting retains profile assignments and dates', () {
    final planting = CropPlanting.fromJson({
      'planting_id': 'planting-1',
      'crop_id': 'crop-1',
      'farm_id': 'farm-1',
      'division_id': 'division-1',
      'worker_profile_id': 'worker-1',
      'planting_date': '2026-10-18',
      'area_unit': 'Acres',
      'planting_status': 'Planned',
      'number_of_seeds': '25',
    });

    expect(planting.workerProfileId, 'worker-1');
    expect(planting.numberOfSeeds, 25);
    expect(planting.toJson()['planting_date'], '2026-10-18');
  });

  test('Attendance presentation normalizes known statuses', () {
    final record = AttendanceRecord.fromJson({
      'farm_id': 'farm-1',
      'worker_profile_id': 'worker-1',
      'work_date': '2026-10-18',
      'status': 'on_leave',
    });
    expect(record.displayStatus, 'On Leave');
  });

  test('Attendance records identify supervisors without worker profile ids',
      () {
    final record = AttendanceRecord.fromJson({
      'attendance_id': 'attendance-1',
      'farm_id': 'farm-1',
      'supervisor_id': 'supervisor-1',
      'work_date': '2026-10-19',
      'status': 'present',
    });

    expect(record.workerProfileId, isEmpty);
    expect(record.profileId, 'supervisor-1');
    expect(record.toJson().containsKey('worker_profile_id'), isFalse);
    expect(record.toJson()['supervisor_id'], 'supervisor-1');
  });

  test('Stored produce maps without an is_deleted column', () {
    final produce = StoredProduce.fromJson({
      'storage_id': 'storage-1',
      'farm_id': 'farm-1',
      'crop_name': 'Maize',
      'quantity': 20,
      'unit': 'kg',
      'location': 'North store',
      'date_stored': '2026-10-18',
      'condition': 'Good',
    });

    expect(produce.isDeleted, isFalse);
    expect(produce.toJson().containsKey('is_deleted'), isFalse);
  });

  test('Water stock maps category-specific id and quantity columns', () {
    final stock = FarmStockItem.fromJson(
      {
        'water_id': 'water-1',
        'farm_id': 'farm-1',
        'source_name': 'Well',
        'available_quantity': 85,
        'unit': 'm3',
        'is_deleted': false,
      },
      category: InventoryStockCategory.water,
    );

    expect(stock.toInventoryItem().quantity, 85);
    expect(stock.toJson()['water_id'], 'water-1');
    expect(stock.schema, inventoryCategories.last);
  });

  test('Machinery usage boolean and numeric fields are decoded safely', () {
    final usage = MachineryUsage.fromJson({
      'machinery_id': 'machine-1',
      'farm_id': 'farm-1',
      'usage_date': '2026-10-18',
      'purpose': 'Irrigation',
      'hours_used': '1.5',
      'is_voided': 'false',
    });

    expect(usage.hoursUsed, 1.5);
    expect(usage.isVoided, isFalse);
    expect(usage.toJson()['hours_used'], 1.5);
  });

  test('Report summaries decode known category totals', () {
    final summary = ReportSummary.fromJson('inventory', {
      'total_items': '14',
      'low_stock_count': 3,
      'by_category': [
        {'category': 'Fertilizer', 'items': 4},
      ],
    });

    expect(summary, isA<InventorySummary>());
    final inventory = summary as InventorySummary;
    expect(inventory.totalItems, 14);
    expect(inventory.lowStockCount, 3);
    expect(inventory.byCategory.single['category'], 'Fertilizer');
  });

  test('Crop-yield report summary decodes harvest and breakdown rows', () {
    final summary = ReportSummary.fromJson('crop_yield', {
      'total_plantings': 3,
      'harvest_totals': [
        {'unit': 'kg', 'quantity': 42.5, 'harvests': 2},
      ],
      'by_crop': [
        {'crop_name': 'Maize', 'unit': 'kg', 'plantings': 2, 'harvested': 30},
      ],
      'by_division': [
        {
          'division_name': 'North',
          'unit': 'kg',
          'plantings': 1,
          'harvested': 12.5,
        },
      ],
    });

    expect(summary, isA<CropYieldSummary>());
    final yield = summary as CropYieldSummary;
    expect(yield.totalPlantings, 3);
    expect(yield.harvestTotals.single['quantity'], 42.5);
    expect(yield.byCrop.single['crop_name'], 'Maize');
    expect(yield.byDivision.single['division_name'], 'North');
  });
}
