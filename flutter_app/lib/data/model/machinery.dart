import 'model_parsing.dart';

class Machinery {
  const Machinery({
    this.machineryId,
    required this.farmId,
    this.divisionId,
    required this.name,
    required this.machineryType,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchaseCost,
    this.purpose,
    required this.condition,
    required this.status,
    this.location,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String? machineryId;
  final String farmId;
  final String? divisionId;
  final String name;
  final String machineryType;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? purchaseDate;
  final double? purchaseCost;
  final String? purpose;
  final String condition;
  final String status;
  final String? location;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final bool isDeleted;

  factory Machinery.fromJson(JsonRow json) => Machinery(
        machineryId: stringValue(json, 'machinery_id'),
        farmId: stringValue(json, 'farm_id') ?? '',
        divisionId: stringValue(json, 'division_id'),
        name: stringValue(json, 'name') ?? '',
        machineryType: stringValue(json, 'machinery_type') ?? '',
        brand: stringValue(json, 'brand'),
        model: stringValue(json, 'model'),
        serialNumber: stringValue(json, 'serial_number'),
        purchaseDate: stringValue(json, 'purchase_date'),
        purchaseCost: doubleValue(json, 'purchase_cost'),
        purpose: stringValue(json, 'purpose'),
        condition: stringValue(json, 'condition') ?? '',
        status: stringValue(json, 'status') ?? '',
        location: stringValue(json, 'location'),
        notes: stringValue(json, 'notes'),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
        isDeleted: boolValue(json, 'is_deleted'),
      );

  JsonRow toJson() => {
        if (machineryId != null) 'machinery_id': machineryId,
        'farm_id': farmId,
        if (divisionId != null) 'division_id': divisionId,
        'name': name,
        'machinery_type': machineryType,
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
        if (serialNumber != null) 'serial_number': serialNumber,
        if (purchaseDate != null) 'purchase_date': purchaseDate,
        if (purchaseCost != null) 'purchase_cost': purchaseCost,
        if (purpose != null) 'purpose': purpose,
        'condition': condition,
        'status': status,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };
}

class MachineryUsage {
  const MachineryUsage({
    this.usageId,
    required this.machineryId,
    required this.farmId,
    required this.usageDate,
    required this.purpose,
    this.divisionId,
    this.plantingId,
    this.workerProfileId,
    this.supervisorProfileId,
    this.startTime,
    this.endTime,
    this.hoursUsed,
    this.fuelUsed,
    this.fuelUnit,
    this.hourMeterReading,
    this.conditionAfter,
    this.notes,
    this.createdAt,
    this.isVoided = false,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    this.issuanceId,
  });

  final String? usageId;
  final String machineryId;
  final String farmId;
  final String? divisionId;
  final String? plantingId;
  final String? workerProfileId;
  final String? supervisorProfileId;
  final String usageDate;
  final String? startTime;
  final String? endTime;
  final double? hoursUsed;
  final String purpose;
  final double? fuelUsed;
  final String? fuelUnit;
  final double? hourMeterReading;
  final String? conditionAfter;
  final String? notes;
  final String? createdAt;
  final bool isVoided;
  final String? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final String? issuanceId;

  factory MachineryUsage.fromJson(JsonRow json) => MachineryUsage(
        usageId: stringValue(json, 'usage_id'),
        machineryId: stringValue(json, 'machinery_id') ?? '',
        farmId: stringValue(json, 'farm_id') ?? '',
        divisionId: stringValue(json, 'division_id'),
        plantingId: stringValue(json, 'planting_id'),
        workerProfileId: stringValue(json, 'worker_profile_id'),
        supervisorProfileId: stringValue(json, 'supervisor_profile_id'),
        usageDate: stringValue(json, 'usage_date') ?? '',
        startTime: stringValue(json, 'start_time'),
        endTime: stringValue(json, 'end_time'),
        hoursUsed: doubleValue(json, 'hours_used'),
        purpose: stringValue(json, 'purpose') ?? '',
        fuelUsed: doubleValue(json, 'fuel_used'),
        fuelUnit: stringValue(json, 'fuel_unit'),
        hourMeterReading: doubleValue(json, 'hour_meter_reading'),
        conditionAfter: stringValue(json, 'condition_after'),
        notes: stringValue(json, 'notes'),
        createdAt: stringValue(json, 'created_at'),
        isVoided: boolValue(json, 'is_voided'),
        voidedAt: stringValue(json, 'voided_at'),
        voidedBy: stringValue(json, 'voided_by'),
        voidReason: stringValue(json, 'void_reason'),
        issuanceId: stringValue(json, 'issuance_id'),
      );

  JsonRow toJson() => {
        if (usageId != null) 'usage_id': usageId,
        'machinery_id': machineryId,
        'farm_id': farmId,
        if (divisionId != null) 'division_id': divisionId,
        if (plantingId != null) 'planting_id': plantingId,
        if (workerProfileId != null) 'worker_profile_id': workerProfileId,
        if (supervisorProfileId != null)
          'supervisor_profile_id': supervisorProfileId,
        'usage_date': usageDate,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (hoursUsed != null) 'hours_used': hoursUsed,
        'purpose': purpose,
        if (fuelUsed != null) 'fuel_used': fuelUsed,
        if (fuelUnit != null) 'fuel_unit': fuelUnit,
        if (hourMeterReading != null) 'hour_meter_reading': hourMeterReading,
        if (conditionAfter != null) 'condition_after': conditionAfter,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'created_at': createdAt,
        'is_voided': isVoided,
        if (voidedAt != null) 'voided_at': voidedAt,
        if (voidedBy != null) 'voided_by': voidedBy,
        if (voidReason != null) 'void_reason': voidReason,
        if (issuanceId != null) 'issuance_id': issuanceId,
      };
}

class MachineryMaintenance {
  const MachineryMaintenance({
    this.maintenanceId,
    required this.machineryId,
    required this.farmId,
    required this.maintenanceDate,
    required this.maintenanceType,
    required this.description,
    this.cost,
    this.serviceProvider,
    this.partsReplaced,
    this.nextMaintenanceDate,
    this.hourMeterReading,
    this.conditionAfter,
    this.notes,
    this.createdAt,
    this.isCancelled = false,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
  });

  final String? maintenanceId;
  final String machineryId;
  final String farmId;
  final String maintenanceDate;
  final String maintenanceType;
  final String description;
  final double? cost;
  final String? serviceProvider;
  final String? partsReplaced;
  final String? nextMaintenanceDate;
  final double? hourMeterReading;
  final String? conditionAfter;
  final String? notes;
  final String? createdAt;
  final bool isCancelled;
  final String? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  factory MachineryMaintenance.fromJson(JsonRow json) => MachineryMaintenance(
        maintenanceId: stringValue(json, 'maintenance_id'),
        machineryId: stringValue(json, 'machinery_id') ?? '',
        farmId: stringValue(json, 'farm_id') ?? '',
        maintenanceDate: stringValue(json, 'maintenance_date') ?? '',
        maintenanceType: stringValue(json, 'maintenance_type') ?? '',
        description: stringValue(json, 'description') ?? '',
        cost: doubleValue(json, 'cost'),
        serviceProvider: stringValue(json, 'service_provider'),
        partsReplaced: stringValue(json, 'parts_replaced'),
        nextMaintenanceDate: stringValue(json, 'next_maintenance_date'),
        hourMeterReading: doubleValue(json, 'hour_meter_reading'),
        conditionAfter: stringValue(json, 'condition_after'),
        notes: stringValue(json, 'notes'),
        createdAt: stringValue(json, 'created_at'),
        isCancelled: boolValue(json, 'is_cancelled'),
        cancelledAt: stringValue(json, 'cancelled_at'),
        cancelledBy: stringValue(json, 'cancelled_by'),
        cancellationReason: stringValue(json, 'cancellation_reason'),
      );

  JsonRow toJson() => {
        if (maintenanceId != null) 'maintenance_id': maintenanceId,
        'machinery_id': machineryId,
        'farm_id': farmId,
        'maintenance_date': maintenanceDate,
        'maintenance_type': maintenanceType,
        'description': description,
        if (cost != null) 'cost': cost,
        if (serviceProvider != null) 'service_provider': serviceProvider,
        if (partsReplaced != null) 'parts_replaced': partsReplaced,
        if (nextMaintenanceDate != null)
          'next_maintenance_date': nextMaintenanceDate,
        if (hourMeterReading != null) 'hour_meter_reading': hourMeterReading,
        if (conditionAfter != null) 'condition_after': conditionAfter,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'created_at': createdAt,
        'is_cancelled': isCancelled,
        if (cancelledAt != null) 'cancelled_at': cancelledAt,
        if (cancelledBy != null) 'cancelled_by': cancelledBy,
        if (cancellationReason != null)
          'cancellation_reason': cancellationReason,
      };
}
