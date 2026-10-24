import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/farm.dart';
import '../model/model_parsing.dart';

class DivisionRepository {
  DivisionRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<Division>> getDivisionsForFarm(String farmId) async {
    final rows = await _client
        .from('division')
        .select()
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .order('name');
    return List<JsonRow>.from(rows).map(Division.fromJson).toList();
  }

  Future<Division> createDivision({
    required String farmId,
    required String name,
    required double size,
    String units = 'Acres',
    double? soilPh,
    String? soilHealth,
  }) async {
    if (farmId.isEmpty || name.trim().isEmpty || size <= 0) {
      throw ArgumentError(
          'A farm, division name, and positive size are required.');
    }
    final division = Division(
      divisionId: _uuid.v4(),
      farmId: farmId,
      name: name.trim(),
      size: size,
      units: units.trim().isEmpty ? 'Acres' : units.trim(),
      soilPh: soilPh,
      soilHealth:
          soilHealth?.trim().isEmpty == true ? null : soilHealth?.trim(),
    );
    final row = await _client
        .from('division')
        .insert(division.toJson())
        .select()
        .single();
    return Division.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteDivision(String divisionId) async {
    await _client
        .from('division')
        .update(const {'is_deleted': true}).eq('division_id', divisionId);
  }
}
