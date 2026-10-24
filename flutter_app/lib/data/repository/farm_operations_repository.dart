import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/farm_employee.dart';
import '../model/farm_dashboard_summary.dart';
import '../model/inventory_category.dart';

export '../model/farm_dashboard_summary.dart';

class FarmOperationsRepository {
  FarmOperationsRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<void> issueInventory({
    required InventoryCategory category,
    required String itemId,
    required String farmId,
    required String issuedBy,
    required num quantity,
    required String unit,
    required String issuanceDate,
    String? divisionId,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(
          quantity, 'quantity', 'Must be greater than 0.');
    }
    final item = await _client
        .from(category.table)
        .select()
        .eq(category.itemIdColumn, itemId)
        .eq('farm_id', farmId)
        .single();
    final available = item[category.stockColumn];
    if (available is! num) {
      throw StateError('Inventory stock quantity is not numeric.');
    }
    if (quantity > available) {
      throw StateError(
        'Only $available $unit are available for this item.',
      );
    }

    final remaining = available - quantity;
    await _client
        .from(category.table)
        .update({category.stockColumn: remaining})
        .eq(category.itemIdColumn, itemId)
        .eq('farm_id', farmId);

    final issuanceId = _uuid.v4();
    final payload = <String, dynamic>{
      category.issuanceIdColumn: issuanceId,
      category.itemIdColumn: itemId,
      'farm_id': farmId,
      if (divisionId != null && divisionId.isNotEmpty)
        'division_id': divisionId,
      'issued_by': issuedBy,
      'quantity_issued': quantity,
      'unit': unit,
      'issuance_date': issuanceDate,
      'status': 'issued',
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    try {
      await _client.from(category.issuanceTable).insert(payload);
    } catch (firstError) {
      if (divisionId == null || divisionId.isEmpty) {
        await _restoreStockAfterIssueFailure(
          category: category,
          itemId: itemId,
          farmId: farmId,
          available: available,
          issueError: firstError,
        );
        rethrow;
      }
      final withoutDivision = Map<String, dynamic>.from(payload)
        ..remove('division_id');
      try {
        await _client.from(category.issuanceTable).insert(withoutDivision);
      } catch (retryError) {
        await _restoreStockAfterIssueFailure(
          category: category,
          itemId: itemId,
          farmId: farmId,
          available: available,
          issueError: StateError('$firstError; retry: $retryError'),
        );
        rethrow;
      }
    }
  }

  Future<void> _restoreStockAfterIssueFailure({
    required InventoryCategory category,
    required String itemId,
    required String farmId,
    required num available,
    required Object issueError,
  }) async {
    try {
      await _client
          .from(category.table)
          .update({category.stockColumn: available})
          .eq(category.itemIdColumn, itemId)
          .eq('farm_id', farmId);
    } catch (restoreError) {
      throw StateError(
        'Issuance was not saved ($issueError), and inventory could not be '
        'restored ($restoreError). Verify the stock quantity before retrying.',
      );
    }
  }

  Future<List<FarmEmployee>> fetchEmployees(String farmId) async {
    final results = await Future.wait([
      _client.from('worker_profile').select().eq('farm_id', farmId),
      _client.from('supervisor_profile').select().eq('farm_id', farmId),
    ]);
    final profiles = <(Map<String, dynamic>, String, String)>[];
    for (final row in List<Map<String, dynamic>>.from(results[0])) {
      profiles.add((row, 'Worker', 'worker_profile_id'));
    }
    for (final row in List<Map<String, dynamic>>.from(results[1])) {
      profiles.add((row, 'Supervisor', 'supervisor_profile_id'));
    }
    if (profiles.isEmpty) return const [];

    final accountIds = profiles
        .map((profile) => profile.$1['account_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final accountRows = await _client
        .from('account')
        .select('account_id, full_name, email, phone_number')
        .inFilter('account_id', accountIds);
    final accounts = {
      for (final row in List<Map<String, dynamic>>.from(accountRows))
        row['account_id'] as String: row,
    };

    return profiles.map((profile) {
      final data = profile.$1;
      final accountId = data['account_id'] as String;
      final account = accounts[accountId];
      return FarmEmployee(
        profileId: data[profile.$3] as String,
        accountId: accountId,
        fullName: account?['full_name'] as String? ?? 'Unknown ${profile.$2}',
        role: profile.$2,
        employeeNumber: data['employee_number'] as String?,
        email: account?['email'] as String?,
        phoneNumber: account?['phone_number'] as String?,
      );
    }).toList();
  }

  Future<void> provisionEmployee({
    required String role,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String employeeNumber,
    required String password,
    required String farmId,
  }) async {
    final normalizedRole = role.toLowerCase();
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phoneNumber.trim();
    final cleanEmployeeNumber = employeeNumber.trim();
    if (normalizedRole == 'supervisor') {
      try {
        await _client.functions.invoke(
          'create-supervisor',
          body: {
            'full_name': cleanName,
            'email': cleanEmail,
            if (cleanPhone.isNotEmpty) 'phone_number': cleanPhone,
            if (cleanEmployeeNumber.isNotEmpty)
              'employee_number': cleanEmployeeNumber,
            'password': password,
            'farm_id': farmId,
          },
        );
        return;
      } catch (functionError) {
        try {
          await _client.rpc(
            'provision_supervisor',
            params: {
              'p_full_name': cleanName,
              'p_email': cleanEmail,
              'p_phone_number': cleanPhone,
              'p_employee_number': cleanEmployeeNumber,
              'p_farm_id': farmId,
              'p_password': password,
            },
          );
          return;
        } catch (rpcError) {
          throw StateError(
            'Could not provision supervisor. '
            'Edge Function: $functionError. RPC fallback: $rpcError',
          );
        }
      }
    }
    if (normalizedRole != 'worker') {
      throw ArgumentError.value(role, 'role', 'Unsupported employee role.');
    }
    await _client.rpc(
      'provision_worker',
      params: {
        'p_full_name': cleanName,
        'p_email': cleanEmail,
        'p_phone_number': cleanPhone,
        'p_employee_number': cleanEmployeeNumber,
        'p_farm_id': farmId,
        'p_password': password,
      },
    );
  }

  Future<void> updateEmployee(
    FarmEmployee employee, {
    required String fullName,
    required String phoneNumber,
    required String employeeNumber,
  }) async {
    await _client.from('account').update({
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
    }).eq('account_id', employee.accountId);
    final profileTable =
        employee.role == 'Supervisor' ? 'supervisor_profile' : 'worker_profile';
    final profileIdColumn = employee.role == 'Supervisor'
        ? 'supervisor_profile_id'
        : 'worker_profile_id';
    await _client.from(profileTable).update({
      'employee_number': employeeNumber.trim(),
    }).eq(profileIdColumn, employee.profileId);
  }

  Future<List<Map<String, dynamic>>> fetchAttendance(
    String farmId,
    String workDate,
  ) async {
    final rows = await _client
        .from('attendance')
        .select()
        .eq('farm_id', farmId)
        .eq('work_date', workDate)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> upsertAttendance(
    Map<String, dynamic> values,
  ) async {
    final row =
        await _client.from('attendance').upsert(values).select().single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> updateAttendance(
    String attendanceId,
    Map<String, dynamic> values,
  ) async {
    await _client
        .from('attendance')
        .update(values)
        .eq('attendance_id', attendanceId);
  }

  Future<void> updateActivityStatus(
    String activityId, {
    required bool complete,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('farm_activity').update({
      'status': complete ? 'Completed' : 'In Progress',
      if (complete) 'completed_at': now else 'started_at': now,
      if (complete) 'end_time': now else 'start_time': now,
    }).eq('activity_id', activityId);
  }

  Future<void> updateAccount(
    String accountId,
    Map<String, dynamic> values,
  ) async {
    await _client.from('account').update(values).eq('account_id', accountId);
  }

  Future<void> updateFarm(
    String farmId,
    Map<String, dynamic> values,
  ) async {
    await _client
        .from('farm')
        .update(values)
        .eq('farm_id', farmId)
        .eq('is_deleted', false);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String farmId) async {
    final rows = await _client
        .from('notification')
        .select()
        .eq('farm_id', farmId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notification')
        .update(const {'is_read': true}).eq('notification_id', notificationId);
  }

  Future<List<Map<String, dynamic>>> fetchInventoryIssuances(
    InventoryCategory category,
    String farmId,
  ) async {
    final rows = await _client
        .from(category.issuanceTable)
        .select()
        .eq('farm_id', farmId)
        .order('issuance_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markAllNotificationsRead(String farmId) async {
    await _client
        .from('notification')
        .update(const {'is_read': true})
        .eq('farm_id', farmId)
        .eq('is_read', false);
  }

  Future<void> generateReport({
    required String farmId,
    required String category,
    String? periodStart,
    String? periodEnd,
  }) async {
    await _client.rpc(
      'generate_report',
      params: {
        'p_farm_id': farmId,
        'p_category': category,
        if (periodStart != null) 'p_period_start': periodStart,
        if (periodEnd != null) 'p_period_end': periodEnd,
      },
    );
  }

  Future<FarmDashboardSummary> loadDashboardSummary(String farmId) async {
    final results = await Future.wait([
      fetchRows('crop'),
      fetchRows('division', farmId: farmId),
      fetchRows('farm_activity', farmId: farmId, excludeDeleted: false),
      fetchRows('worker_profile', farmId: farmId, excludeDeleted: false),
      fetchRows('supervisor_profile', farmId: farmId, excludeDeleted: false),
      fetchRows('fertilizers', farmId: farmId),
      fetchRows('herbicide', farmId: farmId),
      fetchRows('pesticide', farmId: farmId),
      fetchRows('fungicide', farmId: farmId),
      fetchRows('insecticide', farmId: farmId),
      fetchRows('water', farmId: farmId),
      fetchRows('machinery', farmId: farmId),
      fetchRows('storage_facility', farmId: farmId, excludeDeleted: false),
    ]);
    final activities = results[2];
    final pendingActivities = activities.where((activity) {
      final status = (activity['status'] as String? ?? '').toLowerCase();
      return !const {
        'in progress',
        'in_progress',
        'in-progress',
        'ongoing',
        'completed',
        'done',
        'finished',
        'closed',
      }.contains(status);
    }).length;

    return FarmDashboardSummary(
      totalCrops: results[0].length,
      totalDivisions: results[1].length,
      pendingActivities: pendingActivities,
      totalWorkers: results[3].length,
      totalEmployees: results[3].length + results[4].length,
      totalInventory: results[5].length +
          results[6].length +
          results[7].length +
          results[8].length +
          results[9].length +
          results[10].length,
      totalMachinery: results[11].length,
      totalStorage: results[12].length,
    );
  }

  Future<List<Map<String, dynamic>>> fetchRows(
    String table, {
    String? farmId,
    String? orderBy,
    bool excludeDeleted = true,
  }) async {
    var query = _client.from(table).select();
    if (farmId != null && farmId.isNotEmpty) {
      query = query.eq('farm_id', farmId);
    }
    if (excludeDeleted) {
      query = query.eq('is_deleted', false);
    }
    final rows = orderBy == null
        ? await query
        : await query.order(orderBy, ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> values,
  ) async {
    final rows = await _client.from(table).insert(values).select();
    return Map<String, dynamic>.from(rows.single);
  }

  Future<void> update(
    String table, {
    required String idColumn,
    required String id,
    required Map<String, dynamic> values,
  }) async {
    await _client.from(table).update(values).eq(idColumn, id);
  }

  Future<void> softDelete(
    String table, {
    required String idColumn,
    required String id,
  }) async {
    await update(
      table,
      idColumn: idColumn,
      id: id,
      values: const {'is_deleted': true},
    );
  }

  Future<void> deleteRow(
    String table, {
    required String idColumn,
    required String id,
  }) async {
    await _client.from(table).delete().eq(idColumn, id);
  }

  Future<List<Map<String, dynamic>>> fetchReferenceRows(
    String table, {
    String? farmId,
    String? labelColumn,
    bool excludeDeleted = false,
  }) async {
    var query = _client.from(table).select();
    if (farmId != null && farmId.isNotEmpty) {
      query = query.eq('farm_id', farmId);
    }
    if (excludeDeleted) {
      query = query.eq('is_deleted', false);
    }
    final rows = await query;
    final result = List<Map<String, dynamic>>.from(rows);
    if (labelColumn != null) {
      result.sort(
        (left, right) => (left[labelColumn] as String? ?? '')
            .compareTo(right[labelColumn] as String? ?? ''),
      );
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchEmployeeProfileRows(
    String table,
    String farmId,
  ) async {
    final profileIdColumn = switch (table) {
      'worker_profile' => 'worker_profile_id',
      'supervisor_profile' => 'supervisor_profile_id',
      _ =>
        throw ArgumentError.value(table, 'table', 'Unsupported profile table.'),
    };
    final profiles = await _client
        .from(table)
        .select('$profileIdColumn, account_id, employee_number')
        .eq('farm_id', farmId);
    final profileRows = List<Map<String, dynamic>>.from(profiles);
    if (profileRows.isEmpty) return const [];
    final accountIds = profileRows
        .map((row) => row['account_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final accounts = await _client
        .from('account')
        .select('account_id, full_name')
        .inFilter('account_id', accountIds);
    final names = {
      for (final account in List<Map<String, dynamic>>.from(accounts))
        account['account_id'] as String: account['full_name'] as String?,
    };
    return profileRows
        .map(
          (profile) => {
            ...profile,
            'full_name': names[profile['account_id']] ?? 'Unknown employee',
          },
        )
        .toList();
  }
}
