import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/employee.dart';
import '../model/farm_employee.dart';
import '../model/model_parsing.dart';
import '../remote/supabase_client_provider.dart';

class EmployeeRepository {
  EmployeeRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<FarmEmployee>> getWorkersForFarm(String farmId) =>
      _getEmployees(farmId, 'worker_profile', 'worker_profile_id', 'Worker');

  Future<List<FarmEmployee>> getSupervisorsForFarm(String farmId) =>
      _getEmployees(
        farmId,
        'supervisor_profile',
        'supervisor_profile_id',
        'Supervisor',
      );

  Future<List<FarmEmployee>> getEmployeesForFarm(
    String farmId, {
    bool includeAccountDetails = true,
  }) async {
    final employees = await Future.wait([
      _getEmployees(
        farmId,
        'worker_profile',
        'worker_profile_id',
        'Worker',
        includeAccountDetails: includeAccountDetails,
      ),
      _getEmployees(
        farmId,
        'supervisor_profile',
        'supervisor_profile_id',
        'Supervisor',
        includeAccountDetails: includeAccountDetails,
      ),
    ]);
    return [...employees[1], ...employees[0]];
  }

  Future<List<FarmEmployee>> _getEmployees(
      String farmId, String profileTable, String profileIdColumn, String role,
      {bool includeAccountDetails = true}) async {
    final profileRows = await _client
        .from(profileTable)
        .select('$profileIdColumn, account_id, employee_number')
        .eq('farm_id', farmId);
    final profiles = List<JsonRow>.from(profileRows);
    if (profiles.isEmpty) return const [];

    final accountIds = profiles
        .map((row) => stringValue(row, 'account_id'))
        .whereType<String>()
        .toSet()
        .toList();
    final accounts = includeAccountDetails
        ? await _client
            .from('account')
            .select('account_id, full_name, email, phone_number')
            .inFilter('account_id', accountIds)
        : const <JsonRow>[];
    final accountById = {
      for (final row in List<JsonRow>.from(accounts))
        stringValue(row, 'account_id')!: row,
    };
    return profiles.map((profile) {
      final accountId = stringValue(profile, 'account_id') ?? '';
      final account = accountById[accountId] ?? const <String, dynamic>{};
      return FarmEmployee(
        profileId: stringValue(profile, profileIdColumn) ?? '',
        accountId: accountId,
        fullName: stringValue(account, 'full_name') ?? role,
        role: role,
        employeeNumber: stringValue(profile, 'employee_number'),
        email: stringValue(account, 'email'),
        phoneNumber: stringValue(account, 'phone_number'),
      );
    }).toList();
  }

  Future<EmployeeDisplay?> getSupervisorEmploymentDetails(
    String profileId,
  ) async {
    final row = await _client
        .from('supervisor_profile')
        .select('supervisor_profile_id, account_id, farm_id, employee_number')
        .eq('supervisor_profile_id', profileId)
        .maybeSingle();
    if (row == null) return null;
    final profile = Map<String, dynamic>.from(row);
    final accountId = stringValue(profile, 'account_id');
    final account = accountId == null
        ? null
        : await _client
            .from('account')
            .select('full_name, email, phone_number')
            .eq('account_id', accountId)
            .maybeSingle();
    final accountRow = account == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(account);
    return EmployeeDisplay(
      profileId: stringValue(profile, 'supervisor_profile_id') ?? '',
      accountId: accountId,
      farmId: stringValue(profile, 'farm_id'),
      fullName: stringValue(accountRow, 'full_name') ?? '',
      email: stringValue(accountRow, 'email'),
      phoneNumber: stringValue(accountRow, 'phone_number'),
      employeeNumber: stringValue(profile, 'employee_number'),
    );
  }

  Future<SupervisorDetails?> getSupervisorDetails(String profileId) async {
    final row = await _client
        .from('supervisor_details')
        .select()
        .eq('supervisor_profile_id', profileId)
        .maybeSingle();
    return row == null
        ? null
        : SupervisorDetails.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> saveSupervisorDetails({
    required String profileId,
    required SupervisorDetailsInput details,
  }) async {
    if (details.salary < 0 || details.age < 0) {
      throw ArgumentError('Salary and age cannot be negative.');
    }
    await _client.from('supervisor_details').upsert(
          details.toJson(profileId),
          onConflict: 'supervisor_profile_id',
        );
  }

  Future<void> createWorker(CreateEmployeeRequest request) =>
      _provision('provision_worker', 'Worker', request);

  Future<void> createSupervisor(CreateEmployeeRequest request) async {
    try {
      await _client.functions.invoke(
        'create-supervisor',
        body: {
          ...request.toJson(),
          'password': request.password,
        },
      );
    } catch (functionError) {
      try {
        await _provision('provision_supervisor', 'Supervisor', request);
      } catch (rpcError) {
        throw StateError(
          'Supervisor provisioning failed. Edge Function: $functionError. '
          'RPC fallback: $rpcError',
        );
      }
    }
  }

  Future<void> _provision(
    String function,
    String role,
    CreateEmployeeRequest request,
  ) async {
    if (request.password == null || request.password!.length < 6) {
      throw ArgumentError(
          'A temporary password of at least 6 characters is required.');
    }
    final fullName = request.fullName.trim();
    final email = request.email.trim().toLowerCase();
    final params = <String, dynamic>{
      'p_full_name': fullName,
      'p_email': email,
      'p_phone_number': request.phoneNumber?.trim() ?? '',
      'p_employee_number': request.employeeNumber?.trim() ?? '',
      'p_farm_id': request.farmId,
      'p_password': request.password,
    };
    try {
      await _client.rpc(function, params: params);
    } catch (rpcError) {
      try {
        await _provisionWithIsolatedAuth(
          request: request,
          fullName: fullName,
          email: email,
          role: role,
        );
      } catch (authError) {
        throw StateError(
          '$role provisioning failed. RPC: $rpcError. '
          'Isolated auth fallback: $authError',
        );
      }
    }
  }

  Future<void> _provisionWithIsolatedAuth({
    required CreateEmployeeRequest request,
    required String fullName,
    required String email,
    required String role,
  }) async {
    final authClient = SupabaseClientProvider.createIsolatedAuthClient();
    try {
      final phoneNumber = request.phoneNumber?.trim();
      final response = await authClient.auth.signUp(
        email: email,
        password: request.password!,
        data: {
          'full_name': fullName,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phone_number': phoneNumber,
          'role': role,
        },
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Employee registration did not return an auth user.',
        );
      }

      final profileId = _uuid.v4();
      final profileTable =
          role == 'Supervisor' ? 'supervisor_profile' : 'worker_profile';
      final profileIdColumn =
          role == 'Supervisor' ? 'supervisor_profile_id' : 'worker_profile_id';
      final employeeNumber = request.employeeNumber?.trim();

      await _client.from('account').upsert(
        {
          'account_id': user.id,
          'full_name': fullName,
          'email': email,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phone_number': phoneNumber,
          'role': role,
        },
        onConflict: 'account_id',
      );
      await _client.from(profileTable).upsert(
        {
          profileIdColumn: profileId,
          'account_id': user.id,
          'farm_id': request.farmId,
          if (employeeNumber != null && employeeNumber.isNotEmpty)
            'employee_number': employeeNumber,
        },
        onConflict: profileIdColumn,
      );
    } finally {
      await authClient.dispose();
    }
  }

  Future<void> updateEmployeeNumber(
    FarmEmployee employee, {
    String? employeeNumber,
  }) async {
    final isSupervisor = employee.role.toLowerCase() == 'supervisor';
    await _client
        .from(isSupervisor ? 'supervisor_profile' : 'worker_profile')
        .update({
      'employee_number': employeeNumber?.trim().isEmpty == true
          ? null
          : employeeNumber?.trim(),
    }).eq(
      isSupervisor ? 'supervisor_profile_id' : 'worker_profile_id',
      employee.profileId,
    );
  }

  Future<void> removeEmployeeProfile(FarmEmployee employee) async {
    final isSupervisor = employee.role.toLowerCase() == 'supervisor';
    final profileTable = isSupervisor ? 'supervisor_profile' : 'worker_profile';
    final profileIdColumn =
        isSupervisor ? 'supervisor_profile_id' : 'worker_profile_id';
    final procedure =
        isSupervisor ? 'delete_supervisor_profile' : 'delete_worker_profile';

    try {
      await _client.rpc(
        procedure,
        params: {'p_profile_id': employee.profileId},
      );
    } catch (procedureError) {
      try {
        await _client
            .from(profileTable)
            .delete()
            .eq(profileIdColumn, employee.profileId);
      } catch (fallbackError) {
        throw StateError(
          'Could not remove ${employee.role.toLowerCase()} profile. '
          'RPC: $procedureError. Direct-delete fallback: $fallbackError',
        );
      }
    }
  }

  String newProfileId() => _uuid.v4();
}
