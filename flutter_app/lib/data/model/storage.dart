import 'model_parsing.dart';

class StorageFacility {
  const StorageFacility({
    this.facilityId,
    required this.farmId,
    this.divisionId,
    required this.name,
    this.facilityType = 'store',
    required this.capacityKg,
    this.condition = 'good',
    this.locationNote,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String? facilityId;
  final String farmId;
  final String? divisionId;
  final String name;
  final String facilityType;
  final double capacityKg;
  final String condition;
  final String? locationNote;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  String get displayType => switch (facilityType.toLowerCase()) {
        'cold_room' => 'Cold Room',
        'silo' => 'Silo',
        'granary' => 'Granary',
        'shed' => 'Shed',
        _ => 'General Store',
      };

  String get displayCondition => switch (condition.toLowerCase()) {
        'needs_repair' => 'Needs Repair',
        'fair' => 'Fair',
        'poor' => 'Poor',
        _ => 'Good',
      };

  factory StorageFacility.fromJson(JsonRow json) => StorageFacility(
        facilityId: stringValue(json, 'facility_id'),
        farmId: stringValue(json, 'farm_id') ?? '',
        divisionId: stringValue(json, 'division_id'),
        name: stringValue(json, 'name') ?? '',
        facilityType: stringValue(json, 'facility_type') ?? 'store',
        capacityKg: doubleValue(json, 'capacity_kg') ?? 0,
        condition: stringValue(json, 'condition') ?? 'good',
        locationNote: stringValue(json, 'location_note'),
        isActive: boolValue(json, 'is_active', fallback: true),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
      );

  JsonRow toJson() => {
        if (facilityId != null) 'facility_id': facilityId,
        'farm_id': farmId,
        if (divisionId != null) 'division_id': divisionId,
        'name': name,
        'facility_type': facilityType,
        'capacity_kg': capacityKg,
        'condition': condition,
        if (locationNote != null) 'location_note': locationNote,
        'is_active': isActive,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

class StoredProduce {
  const StoredProduce({
    this.storageId,
    required this.farmId,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.location,
    required this.dateStored,
    required this.condition,
    this.needsAttention = false,
    this.isDeleted = false,
  });

  final String? storageId;
  final String farmId;
  final String cropName;
  final double quantity;
  final String unit;
  final String location;
  final String dateStored;
  final String condition;
  final bool needsAttention;
  final bool isDeleted;

  factory StoredProduce.fromJson(JsonRow json) => StoredProduce(
        storageId: stringValue(json, 'storage_id'),
        farmId: stringValue(json, 'farm_id') ?? '',
        cropName: stringValue(json, 'crop_name') ?? '',
        quantity: doubleValue(json, 'quantity') ?? 0,
        unit: stringValue(json, 'unit') ?? '',
        location: stringValue(json, 'location') ?? '',
        dateStored: stringValue(json, 'date_stored') ?? '',
        condition: stringValue(json, 'condition') ?? '',
        needsAttention: boolValue(json, 'needs_attention'),
        isDeleted: boolValue(json, 'is_deleted'),
      );

  JsonRow toJson() => {
        if (storageId != null) 'storage_id': storageId,
        'farm_id': farmId,
        'crop_name': cropName,
        'quantity': quantity,
        'unit': unit,
        'location': location,
        'date_stored': dateStored,
        'condition': condition,
        'needs_attention': needsAttention,
      };
}
