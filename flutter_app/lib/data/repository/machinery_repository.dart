import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/machinery.dart';
import '../model/model_parsing.dart';

class MachineryRepository {
  MachineryRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<Machinery>> getMachineryForFarm(String farmId) async {
    final rows = await _client
        .from('machinery')
        .select()
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .order('name');
    return List<JsonRow>.from(rows).map(Machinery.fromJson).toList();
  }

  Future<Machinery?> getMachineryById(String machineryId) async {
    final row = await _client
        .from('machinery')
        .select()
        .eq('machinery_id', machineryId)
        .maybeSingle();
    return row == null
        ? null
        : Machinery.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Machinery> insertMachinery(Machinery machinery) async {
    final row = await _client
        .from('machinery')
        .insert({
          ...machinery.toJson(),
          'machinery_id': machinery.machineryId ?? _uuid.v4(),
        })
        .select()
        .single();
    return Machinery.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Machinery> updateMachinery(Machinery machinery) async {
    final id = machinery.machineryId;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Machinery ID is required for updates.');
    }
    final row = await _client
        .from('machinery')
        .update(machinery.toJson()..remove('machinery_id'))
        .eq('machinery_id', id)
        .select()
        .single();
    return Machinery.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteMachinery(String machineryId) async {
    await _client
        .from('machinery')
        .update(const {'is_deleted': true}).eq('machinery_id', machineryId);
  }

  Future<List<MachineryUsage>> getUsageHistory(String machineryId) async {
    final rows = await _client
        .from('machinery_usage')
        .select()
        .eq('machinery_id', machineryId)
        .eq('is_voided', false)
        .order('usage_date', ascending: false);
    return List<JsonRow>.from(rows).map(MachineryUsage.fromJson).toList();
  }

  Future<MachineryUsage> logMachineryUsage(MachineryUsage usage) async {
    final row = await _client
        .from('machinery_usage')
        .insert({
          ...usage.toJson(),
          'usage_id': usage.usageId ?? _uuid.v4(),
        })
        .select()
        .single();
    return MachineryUsage.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> voidMachineryUsage({
    required String usageId,
    required String voidedBy,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A void reason is required.');
    }
    await _client.from('machinery_usage').update({
      'is_voided': true,
      'voided_at': DateTime.now().toIso8601String(),
      'voided_by': voidedBy,
      'void_reason': reason.trim(),
    }).eq('usage_id', usageId);
  }

  Future<List<MachineryMaintenance>> getMaintenanceHistory(
    String machineryId,
  ) async {
    final rows = await _client
        .from('machinery_maintenance')
        .select()
        .eq('machinery_id', machineryId)
        .eq('is_cancelled', false)
        .order('maintenance_date', ascending: false);
    return List<JsonRow>.from(rows).map(MachineryMaintenance.fromJson).toList();
  }

  Future<MachineryMaintenance> logMaintenance(
    MachineryMaintenance maintenance,
  ) async {
    final row = await _client
        .from('machinery_maintenance')
        .insert({
          ...maintenance.toJson(),
          'maintenance_id': maintenance.maintenanceId ?? _uuid.v4(),
        })
        .select()
        .single();
    return MachineryMaintenance.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> cancelMaintenance({
    required String maintenanceId,
    required String cancelledBy,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A cancellation reason is required.');
    }
    await _client.from('machinery_maintenance').update({
      'is_cancelled': true,
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancelled_by': cancelledBy,
      'cancellation_reason': reason.trim(),
    }).eq('maintenance_id', maintenanceId);
  }

  Future<List<MachineryMaintenance>> getAllMaintenanceForFarm(
    String farmId,
  ) async {
    final machineRows = await _client
        .from('machinery')
        .select('machinery_id')
        .eq('farm_id', farmId)
        .eq('is_deleted', false);
    final ids = List<JsonRow>.from(machineRows)
        .map((row) => stringValue(row, 'machinery_id'))
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('machinery_maintenance')
        .select()
        .inFilter('machinery_id', ids)
        .eq('is_cancelled', false)
        .order('maintenance_date', ascending: false);
    return List<JsonRow>.from(rows).map(MachineryMaintenance.fromJson).toList();
  }

  Future<List<MachineryUsage>> getAllUsageForFarm(String farmId) async {
    final machineRows = await _client
        .from('machinery')
        .select('machinery_id')
        .eq('farm_id', farmId)
        .eq('is_deleted', false);
    final ids = List<JsonRow>.from(machineRows)
        .map((row) => stringValue(row, 'machinery_id'))
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('machinery_usage')
        .select()
        .inFilter('machinery_id', ids)
        .eq('is_voided', false)
        .order('usage_date', ascending: false);
    return List<JsonRow>.from(rows).map(MachineryUsage.fromJson).toList();
  }
}
