import 'model_parsing.dart';

class Crop {
  const Crop({
    this.cropId,
    required this.name,
    this.scientificName,
    this.description,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String? cropId;
  final String name;
  final String? scientificName;
  final String? description;
  final String? type;
  final String? createdAt;
  final String? updatedAt;
  final bool isDeleted;

  factory Crop.fromJson(JsonRow json) => Crop(
        cropId: stringValue(json, 'crop_id'),
        name: stringValue(json, 'name') ?? '',
        scientificName: stringValue(json, 'scientific_name'),
        description: stringValue(json, 'description'),
        type: stringValue(json, 'type'),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
        isDeleted: boolValue(json, 'is_deleted'),
      );

  JsonRow toJson() => {
        if (cropId != null) 'crop_id': cropId,
        'name': name,
        if (scientificName != null) 'scientific_name': scientificName,
        if (description != null) 'description': description,
        if (type != null) 'type': type,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };
}

class CropPlanting {
  const CropPlanting({
    this.plantingId,
    required this.cropId,
    required this.farmId,
    required this.divisionId,
    required this.plantingDate,
    required this.areaUnit,
    required this.plantingStatus,
    this.workerProfileId,
    this.supervisorProfileId,
    this.managerProfileId,
    this.plantingTime,
    this.quantityPlanted,
    this.quantityUnit,
    this.areaPlanted,
    this.numberOfSeeds,
    this.notes,
    this.expectedFirstHarvestDate,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String? plantingId;
  final String cropId;
  final String farmId;
  final String divisionId;
  final String? workerProfileId;
  final String? supervisorProfileId;
  final String? managerProfileId;
  final String plantingDate;
  final String? plantingTime;
  final double? quantityPlanted;
  final String? quantityUnit;
  final double? areaPlanted;
  final String areaUnit;
  final int? numberOfSeeds;
  final String? notes;
  final String? expectedFirstHarvestDate;
  final String plantingStatus;
  final String? createdAt;
  final String? updatedAt;
  final bool isDeleted;

  factory CropPlanting.fromJson(JsonRow json) => CropPlanting(
        plantingId: stringValue(json, 'planting_id'),
        cropId: stringValue(json, 'crop_id') ?? '',
        farmId: stringValue(json, 'farm_id') ?? '',
        divisionId: stringValue(json, 'division_id') ?? '',
        workerProfileId: stringValue(json, 'worker_profile_id'),
        supervisorProfileId: stringValue(json, 'supervisor_profile_id'),
        managerProfileId: stringValue(json, 'manager_profile_id'),
        plantingDate: stringValue(json, 'planting_date') ?? '',
        plantingTime: stringValue(json, 'planting_time'),
        quantityPlanted: doubleValue(json, 'quantity_planted'),
        quantityUnit: stringValue(json, 'quantity_unit'),
        areaPlanted: doubleValue(json, 'area_planted'),
        areaUnit: stringValue(json, 'area_unit') ?? 'Acres',
        numberOfSeeds: intValue(json, 'number_of_seeds'),
        notes: stringValue(json, 'notes'),
        expectedFirstHarvestDate:
            stringValue(json, 'expected_first_harvest_date'),
        plantingStatus: stringValue(json, 'planting_status') ?? 'Planned',
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
        isDeleted: boolValue(json, 'is_deleted'),
      );

  JsonRow toJson() => {
        if (plantingId != null) 'planting_id': plantingId,
        'crop_id': cropId,
        'farm_id': farmId,
        'division_id': divisionId,
        if (workerProfileId != null) 'worker_profile_id': workerProfileId,
        if (supervisorProfileId != null)
          'supervisor_profile_id': supervisorProfileId,
        if (managerProfileId != null) 'manager_profile_id': managerProfileId,
        'planting_date': plantingDate,
        if (plantingTime != null) 'planting_time': plantingTime,
        if (quantityPlanted != null) 'quantity_planted': quantityPlanted,
        if (quantityUnit != null) 'quantity_unit': quantityUnit,
        if (areaPlanted != null) 'area_planted': areaPlanted,
        'area_unit': areaUnit,
        if (numberOfSeeds != null) 'number_of_seeds': numberOfSeeds,
        if (notes != null) 'notes': notes,
        if (expectedFirstHarvestDate != null)
          'expected_first_harvest_date': expectedFirstHarvestDate,
        'planting_status': plantingStatus,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };
}

class CropHarvest {
  const CropHarvest({
    this.harvestId,
    required this.plantingId,
    required this.farmId,
    required this.divisionId,
    required this.harvestDate,
    required this.quantityHarvested,
    required this.quantityUnit,
    this.qualityGrade,
    this.quantity,
    this.unit,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String? harvestId;
  final String plantingId;
  final String farmId;
  final String divisionId;
  final String harvestDate;
  final double quantityHarvested;
  final String quantityUnit;
  final String? qualityGrade;
  final double? quantity;
  final String? unit;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  factory CropHarvest.fromJson(JsonRow json) => CropHarvest(
        harvestId: stringValue(json, 'harvest_id'),
        plantingId: stringValue(json, 'planting_id') ?? '',
        farmId: stringValue(json, 'farm_id') ?? '',
        divisionId: stringValue(json, 'division_id') ?? '',
        harvestDate: stringValue(json, 'harvest_date') ?? '',
        quantityHarvested: doubleValue(json, 'quantity_harvested') ?? 0,
        quantityUnit: stringValue(json, 'quantity_unit') ?? '',
        qualityGrade: stringValue(json, 'quality_grade'),
        quantity: doubleValue(json, 'quantity'),
        unit: stringValue(json, 'unit'),
        notes: stringValue(json, 'notes'),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
      );

  JsonRow toJson() => {
        if (harvestId != null) 'harvest_id': harvestId,
        'planting_id': plantingId,
        'farm_id': farmId,
        'division_id': divisionId,
        'harvest_date': harvestDate,
        'quantity_harvested': quantityHarvested,
        'quantity_unit': quantityUnit,
        if (qualityGrade != null) 'quality_grade': qualityGrade,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

class CropPlantingDisplay {
  const CropPlantingDisplay({
    required this.planting,
    required this.cropName,
    required this.divisionName,
  });

  final CropPlanting planting;
  final String cropName;
  final String divisionName;
}

class CropHarvestDisplay {
  const CropHarvestDisplay({
    required this.harvest,
    required this.cropName,
    required this.divisionName,
  });

  final CropHarvest harvest;
  final String cropName;
  final String divisionName;
}
