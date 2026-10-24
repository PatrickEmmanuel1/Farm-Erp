import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/crop.dart';
import '../model/model_parsing.dart';

class CropRepository {
  CropRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<Crop>> getCropCatalog() async {
    final rows = await _client
        .from('crop')
        .select()
        .eq('is_deleted', false)
        .order('name');
    return List<JsonRow>.from(rows).map(Crop.fromJson).toList();
  }

  Future<Map<String, List<String>>> getAssignedCropsByDivision(
    String farmId,
  ) async {
    final plantings = await getCropPlantingsForFarm(farmId);
    final grouped = <String, Set<String>>{};
    for (final display in plantings) {
      grouped
          .putIfAbsent(display.planting.divisionId, () => <String>{})
          .add(display.cropName);
    }
    return grouped.map((divisionId, names) => MapEntry(
          divisionId,
          names.toList()..sort(),
        ));
  }

  Future<void> assignCropToDivision({
    required String cropId,
    required String farmId,
    required String divisionId,
  }) async {
    if (cropId.trim().isEmpty ||
        farmId.trim().isEmpty ||
        divisionId.trim().isEmpty) {
      throw ArgumentError('A crop, farm, and division are required.');
    }
    await insertCropPlanting(CropPlanting(
      cropId: cropId,
      farmId: farmId,
      divisionId: divisionId,
      plantingDate: DateTime.now().toIso8601String().split('T').first,
      areaUnit: 'Acres',
      plantingStatus: 'Active',
    ));
  }

  Future<Crop> createCrop({
    required String name,
    String? scientificName,
    String? description,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Crop name cannot be empty.');
    }
    final crop = Crop(
      cropId: _uuid.v4(),
      name: name.trim(),
      scientificName: _clean(scientificName),
      description: _clean(description),
    );
    final row =
        await _client.from('crop').insert(crop.toJson()).select().single();
    return Crop.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteCrop(String cropId) async {
    await _client
        .from('crop')
        .update(const {'is_deleted': true}).eq('crop_id', cropId);
  }

  Future<List<CropPlantingDisplay>> getCropPlantingsForFarm(
    String farmId,
  ) async {
    final rows = await _client
        .from('crop_planting')
        .select()
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .order('planting_date', ascending: false);
    final plantings =
        List<JsonRow>.from(rows).map(CropPlanting.fromJson).toList();
    if (plantings.isEmpty) return const [];

    final cropIds = plantings.map((row) => row.cropId).toSet().toList();
    final divisionIds = plantings.map((row) => row.divisionId).toSet().toList();
    final references = await Future.wait([
      _client.from('crop').select('crop_id, name').inFilter('crop_id', cropIds),
      _client
          .from('division')
          .select('division_id, name')
          .inFilter('division_id', divisionIds),
    ]);
    final cropNames = {
      for (final row in List<JsonRow>.from(references[0]))
        stringValue(row, 'crop_id')!: stringValue(row, 'name') ?? '',
    };
    final divisionNames = {
      for (final row in List<JsonRow>.from(references[1]))
        stringValue(row, 'division_id')!: stringValue(row, 'name') ?? '',
    };
    return plantings
        .map(
          (planting) => CropPlantingDisplay(
            planting: planting,
            cropName: cropNames[planting.cropId] ?? planting.cropId,
            divisionName:
                divisionNames[planting.divisionId] ?? planting.divisionId,
          ),
        )
        .toList();
  }

  Future<CropPlanting?> getCropPlantingById(String plantingId) async {
    final row = await _client
        .from('crop_planting')
        .select()
        .eq('planting_id', plantingId)
        .maybeSingle();
    return row == null
        ? null
        : CropPlanting.fromJson(Map<String, dynamic>.from(row));
  }

  Future<CropPlanting> insertCropPlanting(CropPlanting planting) async {
    final clean = CropPlanting(
      plantingId: planting.plantingId ?? _uuid.v4(),
      cropId: planting.cropId,
      farmId: planting.farmId,
      divisionId: planting.divisionId,
      workerProfileId: planting.workerProfileId,
      supervisorProfileId: planting.supervisorProfileId,
      managerProfileId: planting.managerProfileId,
      plantingDate: planting.plantingDate,
      plantingTime: planting.plantingTime,
      quantityPlanted: planting.quantityPlanted,
      quantityUnit: planting.quantityUnit,
      areaPlanted: planting.areaPlanted,
      areaUnit: planting.areaUnit,
      numberOfSeeds: planting.numberOfSeeds,
      notes: planting.notes,
      expectedFirstHarvestDate: planting.expectedFirstHarvestDate,
      plantingStatus: planting.plantingStatus,
    );
    final row = await _client
        .from('crop_planting')
        .insert(clean.toJson())
        .select()
        .single();
    return CropPlanting.fromJson(Map<String, dynamic>.from(row));
  }

  Future<CropPlanting> updateCropPlanting(CropPlanting planting) async {
    final id = planting.plantingId;
    if (id == null || id.isEmpty) {
      throw ArgumentError('A planting ID is required to update a planting.');
    }
    final row = await _client
        .from('crop_planting')
        .update(planting.toJson()..remove('planting_id'))
        .eq('planting_id', id)
        .select()
        .single();
    return CropPlanting.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteCropPlanting(String plantingId) async {
    await _client
        .from('crop_planting')
        .update(const {'is_deleted': true}).eq('planting_id', plantingId);
  }

  Future<List<CropHarvestDisplay>> getCropHarvestsForFarm(
    String farmId,
  ) async {
    final rows = await _client
        .from('crop_harvest')
        .select()
        .eq('farm_id', farmId)
        .order('harvest_date', ascending: false);
    final harvests =
        List<JsonRow>.from(rows).map(CropHarvest.fromJson).toList();
    if (harvests.isEmpty) return const [];
    final plantingDetails = await getCropPlantingsForFarm(farmId);
    final plantingById = {
      for (final entry in plantingDetails)
        if (entry.planting.plantingId != null)
          entry.planting.plantingId!: entry,
    };
    return harvests.map((harvest) {
      final planting = plantingById[harvest.plantingId];
      return CropHarvestDisplay(
        harvest: harvest,
        cropName: planting?.cropName ?? 'Harvested Crop',
        divisionName: planting?.divisionName ?? 'Division',
      );
    }).toList();
  }

  Future<CropHarvest> recordCropHarvest(CropHarvest harvest) async {
    final clean = CropHarvest(
      harvestId: harvest.harvestId ?? _uuid.v4(),
      plantingId: harvest.plantingId,
      farmId: harvest.farmId,
      divisionId: harvest.divisionId,
      harvestDate: harvest.harvestDate,
      quantityHarvested: harvest.quantityHarvested,
      quantityUnit: harvest.quantityUnit,
      qualityGrade: harvest.qualityGrade,
      quantity: harvest.quantity ?? harvest.quantityHarvested,
      unit: harvest.unit ?? harvest.quantityUnit,
      notes: harvest.notes,
    );
    final row = await _client
        .from('crop_harvest')
        .insert(clean.toJson())
        .select()
        .single();
    return CropHarvest.fromJson(Map<String, dynamic>.from(row));
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
