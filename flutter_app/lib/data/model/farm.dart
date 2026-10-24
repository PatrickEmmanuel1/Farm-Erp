import 'model_parsing.dart';

class Farm {
  const Farm({
    this.farmId,
    required this.name,
    required this.totalSize,
    required this.unit,
    required this.county,
    this.soilType,
    this.soilHealth,
    this.soilPh,
    this.subCounty,
    this.accountId,
    this.supervisorId,
    this.workerId,
    this.countyId,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String? farmId;
  final String name;
  final double totalSize;
  final String unit;
  final String county;
  final String? soilType;
  final String? soilHealth;
  final double? soilPh;
  final String? subCounty;
  final String? accountId;
  final String? supervisorId;
  final String? workerId;
  final int? countyId;
  final String? createdAt;
  final String? updatedAt;
  final bool isDeleted;

  factory Farm.fromJson(JsonRow json) => Farm(
        farmId: stringValue(json, 'farm_id'),
        name: stringValue(json, 'name') ?? '',
        totalSize: doubleValue(json, 'total_size') ?? 0,
        unit: stringValue(json, 'unit') ?? 'Acres',
        county: stringValue(json, 'county') ?? '',
        soilType: stringValue(json, 'soil_type'),
        soilHealth: stringValue(json, 'soil_health'),
        soilPh: doubleValue(json, 'soil_ph'),
        subCounty: stringValue(json, 'sub_county'),
        accountId: stringValue(json, 'account_id'),
        supervisorId: stringValue(json, 'supervisor_id'),
        workerId: stringValue(json, 'worker_id'),
        countyId: intValue(json, 'county_id'),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
        isDeleted: boolValue(json, 'is_deleted'),
      );

  JsonRow toJson() => {
        if (farmId != null) 'farm_id': farmId,
        'name': name,
        'total_size': totalSize,
        'unit': unit,
        'county': county,
        if (soilType != null) 'soil_type': soilType,
        if (soilHealth != null) 'soil_health': soilHealth,
        if (soilPh != null) 'soil_ph': soilPh,
        if (subCounty != null) 'sub_county': subCounty,
        if (accountId != null) 'account_id': accountId,
        if (supervisorId != null) 'supervisor_id': supervisorId,
        if (workerId != null) 'worker_id': workerId,
        if (countyId != null) 'county_id': countyId,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };
}

class Division {
  const Division({
    this.divisionId,
    required this.farmId,
    required this.name,
    required this.size,
    this.soilPh,
    this.soilHealth,
    this.units,
    this.workerId,
    this.supervisorId,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String? divisionId;
  final String farmId;
  final String name;
  final double size;
  final double? soilPh;
  final String? soilHealth;
  final String? units;
  final String? workerId;
  final String? supervisorId;
  final String? createdAt;
  final String? updatedAt;
  final bool isDeleted;

  factory Division.fromJson(JsonRow json) => Division(
        divisionId: stringValue(json, 'division_id'),
        farmId: stringValue(json, 'farm_id') ?? '',
        name: stringValue(json, 'name') ?? '',
        size: doubleValue(json, 'size') ?? 0,
        soilPh: doubleValue(json, 'soil_ph'),
        soilHealth: stringValue(json, 'soil_health'),
        units: stringValue(json, 'units'),
        workerId: stringValue(json, 'worker_id'),
        supervisorId: stringValue(json, 'supervisor_id'),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
        isDeleted: boolValue(json, 'is_deleted'),
      );

  JsonRow toJson() => {
        if (divisionId != null) 'division_id': divisionId,
        'farm_id': farmId,
        'name': name,
        'size': size,
        if (soilPh != null) 'soil_ph': soilPh,
        if (soilHealth != null) 'soil_health': soilHealth,
        if (units != null) 'units': units,
        if (workerId != null) 'worker_id': workerId,
        if (supervisorId != null) 'supervisor_id': supervisorId,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };
}
