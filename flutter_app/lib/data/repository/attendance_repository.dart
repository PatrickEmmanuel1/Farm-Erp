import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/attendance.dart';
import '../model/model_parsing.dart';
import 'employee_repository.dart';

class AttendanceRepository {
  AttendanceRepository(
    this._client, {
    EmployeeRepository? employeeRepository,
  }) : _employeeRepository = employeeRepository ?? EmployeeRepository(_client);

  final SupabaseClient _client;
  final EmployeeRepository _employeeRepository;

  Future<String?> resolveMyProfileId() async {
    return (await _resolveMyProfile())?.profileId;
  }

  Future<_AttendanceProfile?> _resolveMyProfile() async {
    final accountId = _client.auth.currentUser?.id;
    if (accountId == null) return null;
    for (final entry in const [
      ('worker_profile', 'worker_profile_id'),
      ('supervisor_profile', 'supervisor_profile_id'),
    ]) {
      final row = await _client
          .from(entry.$1)
          .select(entry.$2)
          .eq('account_id', accountId)
          .limit(1)
          .maybeSingle();
      final id = row == null ? null : stringValue(row, entry.$2);
      if (id != null && id.isNotEmpty) {
        return _AttendanceProfile(
          profileId: id,
          isSupervisor: entry.$1 == 'supervisor_profile',
        );
      }
    }
    return null;
  }

  Future<List<AttendanceDisplay>> getAttendanceForDate(
    String farmId,
    String workDate, {
    bool includeAccountDetails = true,
  }) async {
    final records = await _client
        .from('attendance')
        .select()
        .eq('farm_id', farmId)
        .eq('work_date', workDate)
        .order('created_at', ascending: false);
    final byProfile = <String, AttendanceRecord>{};
    for (final row in List<JsonRow>.from(records)) {
      final record = AttendanceRecord.fromJson(row);
      byProfile[record.profileId] = record;
    }
    final employees = await _employeeRepository.getEmployeesForFarm(
      farmId,
      includeAccountDetails: includeAccountDetails,
    );
    return employees
        .map(
          (employee) => AttendanceDisplay(
            record: byProfile[employee.profileId],
            workerProfileId: employee.profileId,
            workerName: employee.fullName,
            employeeNumber: employee.employeeNumber,
            phoneNumber: employee.phoneNumber,
            role: employee.role,
          ),
        )
        .toList();
  }

  Future<AttendanceRecord?> getMyAttendanceForDate(
    String farmId,
    String workDate,
    String workerProfileId, {
    bool isSupervisor = false,
  }) async {
    final row = await _client
        .from('attendance')
        .select()
        .eq('farm_id', farmId)
        .eq('work_date', workDate)
        .eq(
          isSupervisor ? 'supervisor_id' : 'worker_profile_id',
          workerProfileId,
        )
        .maybeSingle();
    return row == null
        ? null
        : AttendanceRecord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<AttendanceRecord>> getMyAttendanceHistory(String farmId) async {
    final profile = await _resolveMyProfile();
    if (profile == null) return const [];
    final rows = await _client
        .from('attendance')
        .select()
        .eq('farm_id', farmId)
        .eq(
          profile.isSupervisor ? 'supervisor_id' : 'worker_profile_id',
          profile.profileId,
        )
        .order('work_date', ascending: false);
    return List<JsonRow>.from(rows).map(AttendanceRecord.fromJson).toList();
  }

  Future<AttendanceRecord> markAttendance({
    required String farmId,
    required String workerProfileId,
    required String workDate,
    required String status,
    bool isSupervisor = false,
    String? notes,
  }) async {
    const statuses = {'present', 'late', 'absent', 'on_leave'};
    final normalized = status.toLowerCase().replaceAll(' ', '_');
    if (!statuses.contains(normalized)) {
      throw ArgumentError.value(
          status, 'status', 'Unsupported attendance status.');
    }
    final row = await _client
        .from('attendance')
        .upsert({
          'farm_id': farmId,
          if (isSupervisor)
            'supervisor_id': workerProfileId
          else
            'worker_profile_id': workerProfileId,
          'work_date': workDate,
          'status': normalized,
          if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
          if (_client.auth.currentUser?.id != null)
            'recorded_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return AttendanceRecord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<AttendanceRecord> clockInSelf(String farmId) async {
    final profile = await _resolveMyProfile();
    if (profile == null) throw StateError('Employee profile not found.');
    return clockIn(
      farmId: farmId,
      workerProfileId: profile.profileId,
      isSupervisor: profile.isSupervisor,
    );
  }

  Future<AttendanceRecord> clockIn({
    required String farmId,
    required String workerProfileId,
    bool isSupervisor = false,
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final workDate = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final row = await _client
        .from('attendance')
        .upsert({
          'farm_id': farmId,
          if (isSupervisor)
            'supervisor_id': workerProfileId
          else
            'worker_profile_id': workerProfileId,
          'work_date': workDate,
          'check_in': now.toIso8601String(),
          'status': 'present',
          if (_client.auth.currentUser?.id != null)
            'recorded_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return AttendanceRecord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<AttendanceRecord> clockOut(String attendanceId) async {
    final row = await _client
        .from('attendance')
        .update({'check_out': DateTime.now().toIso8601String()})
        .eq('attendance_id', attendanceId)
        .select()
        .single();
    return AttendanceRecord.fromJson(Map<String, dynamic>.from(row));
  }
}

class _AttendanceProfile {
  const _AttendanceProfile({
    required this.profileId,
    required this.isSupervisor,
  });

  final String profileId;
  final bool isSupervisor;
}
