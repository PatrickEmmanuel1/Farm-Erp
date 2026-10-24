import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/model_parsing.dart';
import '../model/storage.dart';

class StorageRepository {
  StorageRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<StoredProduce>> getStorageForFarm(String farmId) async {
    final rows = await _client
        .from('stored_produce')
        .select()
        .eq('farm_id', farmId)
        .order('date_stored', ascending: false);
    return List<JsonRow>.from(rows).map(StoredProduce.fromJson).toList();
  }

  Future<List<StorageFacility>> getFacilitiesForFarm(String farmId) async {
    final rows = await _client
        .from('storage_facility')
        .select()
        .eq('farm_id', farmId)
        .eq('is_active', true)
        .order('name');
    return List<JsonRow>.from(rows).map(StorageFacility.fromJson).toList();
  }

  Future<StorageFacility> createFacility(StorageFacility facility) async {
    final row = await _client
        .from('storage_facility')
        .insert({
          ...facility.toJson(),
          'facility_id': facility.facilityId ?? _uuid.v4(),
        })
        .select()
        .single();
    return StorageFacility.fromJson(Map<String, dynamic>.from(row));
  }

  Future<StoredProduce> addStoredProduce(StoredProduce produce) async {
    final row = await _client
        .from('stored_produce')
        .insert({
          ...produce.toJson(),
          'storage_id': produce.storageId ?? _uuid.v4(),
        })
        .select()
        .single();
    return StoredProduce.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteStoredProduce(String storageId) async {
    await _client.from('stored_produce').delete().eq('storage_id', storageId);
  }

  Future<void> setFacilityActive(
    String facilityId, {
    required bool isActive,
  }) async {
    await _client
        .from('storage_facility')
        .update({'is_active': isActive}).eq('facility_id', facilityId);
  }
}
