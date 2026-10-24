import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/farm_user.dart';
import '../model/farm.dart';
import '../model/model_parsing.dart';

class FarmRepository {
  FarmRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<String>> getCounties() async {
    final rows =
        await _client.from('county').select('county_name').order('county_name');
    return List<JsonRow>.from(rows)
        .map((row) => stringValue(row, 'county_name'))
        .whereType<String>()
        .toList();
  }

  Future<Farm?> getFarmById(String farmId) async {
    if (farmId.trim().isEmpty) return null;
    final row = await _client
        .from('farm')
        .select()
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .maybeSingle();
    return row == null ? null : Farm.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Farm?> getFarmForUser([String? accountId]) async {
    final ownerId = accountId ?? _client.auth.currentUser?.id;
    if (ownerId == null || ownerId.isEmpty) return null;
    final row = await _client
        .from('farm')
        .select()
        .eq('account_id', ownerId)
        .eq('is_deleted', false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Farm.fromJson(Map<String, dynamic>.from(row));
  }

  Future<FarmSummary> createFarm({
    required String accountId,
    required String name,
    required String county,
    required String subCounty,
    required double size,
    required String unit,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Farm name cannot be empty.');
    }
    if (size <= 0) {
      throw ArgumentError.value(
          size, 'size', 'Farm size must be greater than 0.');
    }
    final row = <String, dynamic>{
      'farm_id': _uuid.v4(),
      'name': name.trim(),
      'county': county.trim(),
      'total_size': size,
      'unit': unit.trim().isEmpty ? 'Acres' : unit.trim(),
      'account_id': accountId,
      if (subCounty.trim().isNotEmpty) 'sub_county': subCounty.trim(),
    };
    await _client.from('farm').insert(row);

    return FarmSummary(
      id: row['farm_id'] as String,
      name: row['name'] as String,
      county: row['county'] as String,
      size: size,
      unit: row['unit'] as String,
    );
  }

  Future<void> updateFarmDetails({
    required String farmId,
    required String name,
    required double totalSize,
    required String unit,
    String? county,
    double? soilPh,
    String? soilHealth,
  }) async {
    if (farmId.trim().isEmpty) {
      throw ArgumentError.value(farmId, 'farmId', 'Farm ID cannot be empty.');
    }
    if (name.trim().isEmpty || totalSize <= 0) {
      throw ArgumentError('A farm name and positive farm size are required.');
    }
    final values = <String, dynamic>{
      'name': name.trim(),
      'total_size': totalSize,
      'unit': unit.trim().isEmpty ? 'Acres' : unit.trim(),
      if (county?.trim().isNotEmpty == true) 'county': county!.trim(),
      if (soilPh != null) 'soil_ph': soilPh,
      if (soilHealth?.trim().isNotEmpty == true)
        'soil_health': soilHealth!.trim(),
    };
    await _client
        .from('farm')
        .update(values)
        .eq('farm_id', farmId)
        .eq('is_deleted', false);
  }
}
