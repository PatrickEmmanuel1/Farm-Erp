import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/farm_activity.dart';
import '../model/model_parsing.dart';

class FarmActivityRepository {
  FarmActivityRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<ActivityType>> getActivityTypes() async {
    final rows = await _client
        .from('activity_type')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<JsonRow>.from(rows).map(ActivityType.fromJson).toList();
  }

  Future<FarmActivityFormOptions> getFarmActivityFormOptions(
    String farmId,
  ) async {
    final rows = await Future.wait<dynamic>([
      getActivityTypes(),
      _client
          .from('division')
          .select('division_id, name')
          .eq('farm_id', farmId)
          .order('name'),
      _client
          .from('worker_profile')
          .select('worker_profile_id, account_id')
          .eq('farm_id', farmId),
      _client
          .from('supervisor_profile')
          .select('supervisor_profile_id, account_id')
          .eq('farm_id', farmId),
    ]);

    final activityTypes = (rows[0] as List<ActivityType>)
        .map((type) => ActivitySelectionOption(
              id: type.activityTypeId ?? '',
              label: type.name,
            ))
        .toList();

    final divisions = (rows[1] as List<JsonRow>)
        .map((row) => ActivitySelectionOption(
              id: stringValue(row, 'division_id') ?? '',
              label: stringValue(row, 'name') ?? 'Division',
            ))
        .toList();

    final workerIds = (rows[2] as List<JsonRow>)
        .map((row) => stringValue(row, 'account_id'))
        .whereType<String>()
        .toSet()
        .toList();
    final supervisorIds = (rows[3] as List<JsonRow>)
        .map((row) => stringValue(row, 'account_id'))
        .whereType<String>()
        .toSet()
        .toList();

    final accountIds = [...workerIds, ...supervisorIds];
    final accounts = accountIds.isEmpty
        ? const <JsonRow>[]
        : List<JsonRow>.from(await _client
            .from('account')
            .select('account_id, full_name')
            .inFilter('account_id', accountIds));
    final accountNames = {
      for (final row in accounts)
        stringValue(row, 'account_id')!: stringValue(row, 'full_name') ?? '',
    };

    final workers = (rows[2] as List<JsonRow>)
        .map((row) => ActivitySelectionOption(
              id: stringValue(row, 'worker_profile_id') ?? '',
              label: accountNames[stringValue(row, 'account_id')] ?? 'Worker',
            ))
        .toList();

    final supervisors = (rows[3] as List<JsonRow>)
        .map((row) => ActivitySelectionOption(
              id: stringValue(row, 'supervisor_profile_id') ?? '',
              label:
                  accountNames[stringValue(row, 'account_id')] ?? 'Supervisor',
            ))
        .toList();

    return FarmActivityFormOptions(
      activityTypes: activityTypes,
      divisions: divisions,
      workers: workers,
      supervisors: supervisors,
    );
  }

  Future<List<FarmActivity>> getFarmActivitiesForFarm(String farmId) async {
    final rows = await _client
        .from('farm_activity')
        .select()
        .eq('farm_id', farmId)
        .order('activity_date', ascending: false);
    return List<JsonRow>.from(rows).map(FarmActivity.fromJson).toList();
  }

  Future<List<FarmActivityDisplay>> getFarmActivityDisplays(
    String farmId,
  ) async {
    final activities = await getFarmActivitiesForFarm(farmId);
    return _buildFarmActivityDisplays(activities);
  }

  Future<List<FarmActivityDisplay>> getAssignedActivityDisplays({
    required String farmId,
    required String profileId,
    required bool isWorker,
  }) async {
    if (profileId.isEmpty) return const [];
    final rows = await _client
        .from('farm_activity')
        .select()
        .eq('farm_id', farmId)
        .eq(isWorker ? 'worker_profile_id' : 'supervisor_profile_id', profileId)
        .order('activity_date', ascending: false);
    return _buildFarmActivityDisplays(
      List<JsonRow>.from(rows).map(FarmActivity.fromJson).toList(),
      assignedProfileId: profileId,
      isWorker: isWorker,
    );
  }

  Future<List<FarmActivityDisplay>> _buildFarmActivityDisplays(
    List<FarmActivity> activities, {
    String? assignedProfileId,
    bool? isWorker,
  }
  ) async {
    if (activities.isEmpty) return const [];
    final typeIds = activities
        .map((activity) => activity.activityTypeId)
        .whereType<String>()
        .toSet()
        .toList();
    final divisionIds = activities
        .map((activity) => activity.divisionId)
        .whereType<String>()
        .toSet()
        .toList();
    final workerIds = assignedProfileId != null
        ? (isWorker == true ? [assignedProfileId] : <String>[])
        : activities
            .map((activity) => activity.workerProfileId)
            .whereType<String>()
            .toSet()
            .toList();
    final supervisorIds = assignedProfileId != null
        ? (isWorker == false ? [assignedProfileId] : <String>[])
        : activities
            .map((activity) => activity.supervisorProfileId)
            .whereType<String>()
            .toSet()
            .toList();

    Future<List<JsonRow>> fetchByIds(
      String table,
      String idColumn,
      List<String> ids,
    ) async {
      if (ids.isEmpty) return const [];
      final rows = await _client
          .from(table)
          .select('$idColumn, name')
          .inFilter(idColumn, ids);
      return List<JsonRow>.from(rows);
    }

    final typesFuture =
        fetchByIds('activity_type', 'activity_type_id', typeIds);
    final divisionsFuture = fetchByIds('division', 'division_id', divisionIds);
    final workersFuture = _fetchProfileNames(
      'worker_profile',
      'worker_profile_id',
      workerIds,
    );
    final supervisorsFuture = _fetchProfileNames(
      'supervisor_profile',
      'supervisor_profile_id',
      supervisorIds,
    );
    final lookups = await Future.wait([
      typesFuture,
      divisionsFuture,
      workersFuture,
      supervisorsFuture,
    ]);
    final typeNames = _nameMap(lookups[0], 'activity_type_id');
    final divisionNames = _nameMap(lookups[1], 'division_id');
    final workerNames = _nameMap(lookups[2], 'worker_profile_id');
    final supervisorNames = _nameMap(lookups[3], 'supervisor_profile_id');
    return activities
        .map((activity) => FarmActivityDisplay(
              activity: activity,
              activityTypeName: typeNames[activity.activityTypeId] ??
                  activity.safeActivityTypeId,
              divisionName: divisionNames[activity.divisionId],
              assignedToName: assignedProfileId != null
                  ? null
                  : activity.workerProfileId != null
                      ? workerNames[activity.workerProfileId]
                      : supervisorNames[activity.supervisorProfileId],
            ))
        .toList();
  }

  Future<FarmActivity?> getFarmActivityById(String activityId) async {
    final row = await _client
        .from('farm_activity')
        .select()
        .eq('activity_id', activityId)
        .maybeSingle();
    return row == null
        ? null
        : FarmActivity.fromJson(Map<String, dynamic>.from(row));
  }

  Future<FarmActivity> insertFarmActivity(FarmActivity activity) async {
    if (activity.farmId?.isNotEmpty != true ||
        activity.activityTypeId?.isNotEmpty != true) {
      throw ArgumentError('Farm and activity type are required.');
    }
    final payload = activity.toJson()
      ..['activity_id'] = activity.activityId ?? _uuid.v4();
    final row =
        await _client.from('farm_activity').insert(payload).select().single();
    return FarmActivity.fromJson(Map<String, dynamic>.from(row));
  }

  Future<FarmActivity> updateFarmActivity(FarmActivity activity) async {
    final id = activity.activityId;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Activity ID is required for updates.');
    }
    final row = await _client
        .from('farm_activity')
        .update(activity.toJson()..remove('activity_id'))
        .eq('activity_id', id)
        .select()
        .single();
    return FarmActivity.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteFarmActivity(String activityId) async {
    await _client.from('farm_activity').delete().eq('activity_id', activityId);
  }

  Future<void> startFarmActivity(String activityId) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('farm_activity').update({
      'status': 'In Progress',
      'started_at': now,
      'start_time': now,
    }).eq('activity_id', activityId);
  }

  Future<void> completeFarmActivity(
    String activityId, {
    String? notes,
  }) async {
    final now = DateTime.now();
    final values = <String, dynamic>{
      'status': 'Completed',
      'completed_at': now.toIso8601String(),
      'end_time': now.toIso8601String(),
      if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
    };
    final activity = await getFarmActivityById(activityId);
    final startedAt = DateTime.tryParse(activity?.startedAt ?? '');
    if (startedAt != null) {
      values['duration_hours'] =
          now.difference(startedAt).inSeconds / Duration.secondsPerHour;
    }
    await _client
        .from('farm_activity')
        .update(values)
        .eq('activity_id', activityId);
  }

  Future<List<JsonRow>> _fetchProfileNames(
    String table,
    String profileColumn,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from(table)
        .select('$profileColumn, account_id')
        .inFilter(profileColumn, ids);
    final profiles = List<JsonRow>.from(rows);
    final accountIds = profiles
        .map((row) => stringValue(row, 'account_id'))
        .whereType<String>()
        .toSet()
        .toList();
    if (accountIds.isEmpty) return const [];
    final accountRows = await _client
        .from('account')
        .select('account_id, full_name')
        .inFilter('account_id', accountIds);
    final namesByAccount = {
      for (final row in List<JsonRow>.from(accountRows))
        stringValue(row, 'account_id')!: stringValue(row, 'full_name') ?? '',
    };
    return profiles
        .map((row) => {
              ...row,
              'name': namesByAccount[stringValue(row, 'account_id')] ?? '',
            })
        .toList();
  }

  static Map<String, String> _nameMap(
    List<JsonRow> rows,
    String idColumn,
  ) =>
      {
        for (final row in rows)
          if (stringValue(row, idColumn) != null)
            stringValue(row, idColumn)!: stringValue(row, 'name') ?? '',
      };
}
