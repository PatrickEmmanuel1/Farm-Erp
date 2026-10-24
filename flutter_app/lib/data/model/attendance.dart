import 'model_parsing.dart';

class AttendanceRecord {
  const AttendanceRecord({
    this.attendanceId,
    required this.farmId,
    required this.workerProfileId,
    required this.workDate,
    this.checkIn,
    this.checkOut,
    this.status = 'present',
    this.notes,
    this.recordedBy,
    this.createdAt,
    this.supervisorId,
  });

  final String? attendanceId;
  final String farmId;
  final String workerProfileId;
  final String workDate;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? notes;
  final String? recordedBy;
  final String? createdAt;
  final String? supervisorId;

  String get displayStatus => switch (status.toLowerCase()) {
        'late' => 'Late',
        'absent' => 'Absent',
        'on_leave' || 'on leave' => 'On Leave',
        _ => 'Present',
      };

  String get profileId => supervisorId ?? workerProfileId;

  factory AttendanceRecord.fromJson(JsonRow json) => AttendanceRecord(
        attendanceId: stringValue(json, 'attendance_id'),
        farmId: stringValue(json, 'farm_id') ?? '',
        workerProfileId: stringValue(json, 'worker_profile_id') ?? '',
        workDate: stringValue(json, 'work_date') ?? '',
        checkIn: stringValue(json, 'check_in'),
        checkOut: stringValue(json, 'check_out'),
        status: stringValue(json, 'status') ?? 'present',
        notes: stringValue(json, 'notes'),
        recordedBy: stringValue(json, 'recorded_by'),
        createdAt: stringValue(json, 'created_at'),
        supervisorId: stringValue(json, 'supervisor_id'),
      );

  JsonRow toJson() => {
        if (attendanceId != null) 'attendance_id': attendanceId,
        'farm_id': farmId,
        if (workerProfileId.isNotEmpty) 'worker_profile_id': workerProfileId,
        'work_date': workDate,
        if (checkIn != null) 'check_in': checkIn,
        if (checkOut != null) 'check_out': checkOut,
        'status': status,
        if (notes != null) 'notes': notes,
        if (recordedBy != null) 'recorded_by': recordedBy,
        if (createdAt != null) 'created_at': createdAt,
        if (supervisorId != null) 'supervisor_id': supervisorId,
      };
}

class AttendanceDisplay {
  const AttendanceDisplay({
    this.record,
    required this.workerProfileId,
    required this.workerName,
    this.employeeNumber,
    this.phoneNumber,
    this.role = 'Worker',
  });

  final AttendanceRecord? record;
  final String workerProfileId;
  final String workerName;
  final String? employeeNumber;
  final String? phoneNumber;
  final String role;

  String get currentStatus => record?.displayStatus ?? 'Not Marked';
  bool get isMarked => record != null;
}
