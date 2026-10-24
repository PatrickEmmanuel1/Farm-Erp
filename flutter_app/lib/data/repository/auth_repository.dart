import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/farm_user.dart';
import '../model/farm_account.dart';
import '../user_facing_error.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<FarmUser?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadFarmUser(user);
  }

  Future<FarmAccount?> getMyAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return null;
    final row = await _client
        .from('account')
        .select()
        .eq('account_id', userId)
        .maybeSingle();
    return row == null
        ? null
        : FarmAccount.fromJson(Map<String, dynamic>.from(row));
  }

  Future<String?> getMyRole() async => (await getMyAccount())?.role;

  Future<String?> currentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return (await _loadFarmUser(user)).role;
  }

  Future<bool> hasFarmAccess(String farmId) async {
    final user = _client.auth.currentUser;
    if (user == null || farmId.isEmpty) return false;
    final profileMatches = await Future.wait([
      _client
          .from('worker_profile')
          .select('worker_profile_id')
          .eq('account_id', user.id)
          .eq('farm_id', farmId)
          .limit(1),
      _client
          .from('supervisor_profile')
          .select('supervisor_profile_id')
          .eq('account_id', user.id)
          .eq('farm_id', farmId)
          .limit(1),
    ]);
    if (profileMatches.any((rows) => rows.isNotEmpty)) return true;
    return await _client
        .from('farm')
        .select('farm_id')
        .eq('account_id', user.id)
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .limit(1)
        .then((rows) => rows.isNotEmpty);
  }

  Future<bool> isFarmManager(String farmId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || farmId.isEmpty) return false;
    final rows = await _client
        .from('farm')
        .select('farm_id')
        .eq('account_id', userId)
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<bool> isFarmSupervisor(String farmId) =>
      _hasEmployeeProfile('supervisor_profile', farmId);

  Future<bool> isFarmWorker(String farmId) =>
      _hasEmployeeProfile('worker_profile', farmId);

  Future<bool> _hasEmployeeProfile(String table, String farmId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || farmId.isEmpty) return false;
    final rows = await _client
        .from(table)
        .select()
        .eq('account_id', userId)
        .eq('farm_id', farmId)
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<FarmUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign in did not return a user.');
    }
    return _loadFarmUser(user);
  }

  Future<FarmUser?> signUpManager({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = fullName.trim();
    final cleanPhone = phoneNumber.trim();
    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'full_name': cleanName,
        if (cleanPhone.isNotEmpty) 'phone_number': cleanPhone,
        'role': 'Manager',
      },
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign up did not return a user.');
    }
    if (response.session == null) return null;

    Object? rpcError;
    try {
      await _client.rpc(
        'create_account',
        params: {
          'p_full_name': cleanName,
          'p_email': cleanEmail,
          if (cleanPhone.isNotEmpty) 'p_phone_number': cleanPhone,
          'p_role': 'Manager',
        },
      );
    } catch (error) {
      rpcError = error;
    }

    try {
      await _client.from('account').upsert(
        {
          'account_id': user.id,
          'full_name': cleanName,
          'email': cleanEmail,
          if (cleanPhone.isNotEmpty) 'phone_number': cleanPhone,
        },
        onConflict: 'account_id',
      );
      final managerProfile = await _client
          .from('manager_profile')
          .select('account_id')
          .eq('account_id', user.id)
          .limit(1)
          .maybeSingle();
      if (managerProfile == null) {
        await _client.from('manager_profile').insert({
          'manager_profile_id': _uuid.v4(),
          'account_id': user.id,
        });
      }
    } catch (accountError) {
      final fallbackMessage = userFacingError(accountError, signingUp: true);
      final rpcMessage = rpcError == null
          ? ''
          : ' Account setup RPC: ${userFacingError(rpcError)}';
      throw StateError(
        'The account was created, but its profile could not be saved. '
        '$fallbackMessage$rpcMessage',
      );
    }

    return _loadFarmUser(user);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> updateUserProfile({
    required String accountId,
    required String fullName,
    String? phoneNumber,
  }) async {
    if (fullName.trim().isEmpty) {
      throw ArgumentError.value(fullName, 'fullName', 'Name cannot be empty.');
    }
    await _client.from('account').update({
      'full_name': fullName.trim(),
      'phone_number':
          phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
    }).eq('account_id', accountId);
  }

  String errorMessage(Object error, {bool signingUp = false}) =>
      userFacingError(error, signingUp: signingUp);

  Future<FarmUser> _loadFarmUser(User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AuthException('The signed-in account has no email address.');
    }

    final account =
        await _client.from('account').select().eq('email', email).maybeSingle();
    final accountId = (account?['account_id'] as String?) ?? user.id;

    final supervisor = await _client
        .from('supervisor_profile')
        .select('supervisor_profile_id, farm_id')
        .eq('account_id', accountId)
        .limit(1)
        .maybeSingle();
    final worker = supervisor == null
        ? await _client
            .from('worker_profile')
            .select('worker_profile_id, farm_id')
            .eq('account_id', accountId)
            .limit(1)
            .maybeSingle()
        : null;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final role = supervisor != null
        ? 'Supervisor'
        : worker != null
            ? 'Worker'
            : (account?['role'] as String?) ??
                (metadata['role'] as String?) ??
                'Manager';

    final employeeProfile = supervisor ?? worker;
    var farmId = employeeProfile?['farm_id'] as String?;
    FarmSummary? farm;
    if (role.toLowerCase() == 'manager') {
      final row = await _client
          .from('farm')
          .select()
          .eq('account_id', accountId)
          .eq('is_deleted', false)
          .limit(1)
          .maybeSingle();
      if (row != null) {
        farmId = row['farm_id'] as String;
        farm = FarmSummary(
          id: row['farm_id'] as String,
          name: row['name'] as String,
          county: row['county'] as String,
          size: (row['total_size'] as num).toDouble(),
          unit: row['unit'] as String,
        );
      }
    } else if (farmId != null && farmId.isNotEmpty) {
      final row = await _client
          .from('farm')
          .select()
          .eq('farm_id', farmId)
          .eq('is_deleted', false)
          .limit(1)
          .maybeSingle();
      if (row != null) {
        farm = FarmSummary(
          id: row['farm_id'] as String,
          name: row['name'] as String,
          county: row['county'] as String,
          size: (row['total_size'] as num).toDouble(),
          unit: row['unit'] as String,
        );
      }
    }

    final fallbackName = email.split('@').first;
    return FarmUser(
      id: accountId,
      fullName: (account?['full_name'] as String?) ??
          (metadata['full_name'] as String?) ??
          fallbackName,
      email: email,
      role: role,
      profileId: employeeProfile == null
          ? null
          : employeeProfile['supervisor_profile_id'] as String? ??
              employeeProfile['worker_profile_id'] as String?,
      farmId: farmId,
      phoneNumber: (account?['phone_number'] as String?) ??
          (metadata['phone_number'] as String?),
      farm: farm,
    );
  }
}
