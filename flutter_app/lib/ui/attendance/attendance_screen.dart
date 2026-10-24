import 'package:flutter/material.dart';

import '../../data/model/attendance.dart';
import '../../data/model/farm_employee.dart';
import '../../data/model/farm_user.dart';
import '../../data/repository/attendance_repository.dart';
import '../../data/user_facing_error.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    required this.user,
    required this.farmId,
    required this.repository,
    super.key,
  });

  final FarmUser user;
  final String farmId;
  final AttendanceRepository repository;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceData {
  const _AttendanceData(this.employees, this.records);

  final List<FarmEmployee> employees;
  final List<AttendanceRecord> records;
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _selectedDate;
  late Future<_AttendanceData> _data;
  String? _error;
  bool _busy = false;
  String _searchQuery = '';
  String _roleFilter = 'all';

  String get _workDate => '${_selectedDate.year.toString().padLeft(4, '0')}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  bool get _isWorker => widget.user.role.toLowerCase() == 'worker';

  static const List<String> _tabs = ['All Staff', 'Workers', 'Supervisors'];
  static const List<String> _statusOptions = [
    'present',
    'late',
    'absent',
    'on_leave'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _data = _loadData();
  }

  Future<_AttendanceData> _loadData() async {
    if (_isWorker) {
      final profileId = widget.user.profileId;
      if (profileId == null || profileId.isEmpty) {
        throw StateError('Employee profile not found for the current account.');
      }
      final record = await widget.repository.getMyAttendanceForDate(
        widget.farmId,
        _workDate,
        profileId,
        isSupervisor: widget.user.role.toLowerCase() == 'supervisor',
      );
      return _AttendanceData(
        [
          FarmEmployee(
            profileId: profileId,
            accountId: widget.user.id,
            fullName: widget.user.fullName,
            role: widget.user.role,
            email: widget.user.email,
            phoneNumber: widget.user.phoneNumber,
          ),
        ],
        [if (record != null) record],
      );
    }
    final entries = await widget.repository.getAttendanceForDate(
      widget.farmId,
      _workDate,
      includeAccountDetails: widget.user.role.toLowerCase() == 'manager',
    );
    final employees = entries
        .map((entry) => FarmEmployee(
              profileId: entry.workerProfileId,
              accountId: '',
              fullName: entry.workerName,
              role: entry.role,
              employeeNumber: entry.employeeNumber,
              phoneNumber: entry.phoneNumber,
            ))
        .toList();
    return _AttendanceData(
      employees,
      entries
          .map((entry) => entry.record)
          .whereType<AttendanceRecord>()
          .toList(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _data = _loadData();
    });
    await _data;
  }

  AttendanceRecord? _recordFor(
    List<AttendanceRecord> records,
    FarmEmployee employee,
  ) {
    for (final record in records) {
      if (record.workerProfileId == employee.profileId) return record;
    }
    return null;
  }

  Future<void> _markAttendance(FarmEmployee employee, String status) async {
    await _perform(() async {
      await widget.repository.markAttendance(
        farmId: widget.farmId,
        workerProfileId: employee.profileId,
        workDate: _workDate,
        status: status,
        isSupervisor: employee.role.toLowerCase() == 'supervisor',
      );
    });
  }

  Future<void> _clockIn(FarmEmployee employee) async {
    await _perform(() async {
      await widget.repository.clockIn(
        farmId: widget.farmId,
        workerProfileId: employee.profileId,
        isSupervisor: employee.role.toLowerCase() == 'supervisor',
      );
    });
  }

  Future<void> _clockOut(AttendanceRecord attendance) async {
    final id = attendance.attendanceId;
    if (id == null || id.isEmpty) {
      setState(() => _error = 'Attendance record is missing its identifier.');
      return;
    }
    await _perform(() async {
      await widget.repository.clockOut(id);
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _roleTabValue(String role) {
    final name = role.toLowerCase();
    if (name.contains('supervisor')) return 'supervisor';
    if (name.contains('worker') || name.contains('staff')) return 'worker';
    return 'all';
  }

  Map<String, int> _summaryCounts(List<AttendanceRecord> records) {
    final counts = <String, int>{
      'present': 0,
      'late': 0,
      'absent': 0,
      'leave': 0,
    };

    for (final record in records) {
      final status = record.status.toLowerCase();
      switch (status) {
        case 'late':
          counts['late'] = (counts['late'] ?? 0) + 1;
          break;
        case 'absent':
          counts['absent'] = (counts['absent'] ?? 0) + 1;
          break;
        case 'on_leave':
          counts['leave'] = (counts['leave'] ?? 0) + 1;
          break;
        default:
          counts['present'] = (counts['present'] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<FarmEmployee> _filteredEmployees(_AttendanceData data) {
    final query = _searchQuery.trim().toLowerCase();
    return data.employees.where((employee) {
      final role = _roleTabValue(employee.role);
      final matchRole = switch (_roleFilter) {
        'worker' => role == 'worker',
        'supervisor' => role == 'supervisor',
        _ => true,
      };
      if (!matchRole) return false;
      if (query.isEmpty) return true;
      final matches =
          '${employee.fullName} ${employee.employeeNumber ?? ''} ${employee.profileId}'
              .toLowerCase();
      return matches.contains(query);
    }).toList();
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return value.trim().isEmpty
          ? 'NA'
          : value.trim().substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1).toUpperCase()}${parts.last.substring(0, 1).toUpperCase()}';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      case 'on_leave':
        return 'Leave';
      case 'present':
        return 'Present';
      default:
        return 'Not Marked';
    }
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    try {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return '--:--';
      return TimeOfDay.fromDateTime(parsed.toLocal()).format(context);
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1ED),
      body: SafeArea(
        child: FutureBuilder<_AttendanceData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    userFacingError(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data ?? const _AttendanceData([], []);
            final summary = _summaryCounts(data.records);
            final employees = _filteredEmployees(data);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 28),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attendance Records',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            const Text(
                              'Daily attendance for supervisors and workers',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6A6A6A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEBD8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() => _selectedDate = _selectedDate
                                .subtract(const Duration(days: 1)));
                            _data = _loadData();
                          },
                          icon: const Icon(Icons.chevron_left, size: 30),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2D1C),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _selectedDate =
                                _selectedDate.add(const Duration(days: 1)));
                            _data = _loadData();
                          },
                          icon: const Icon(Icons.chevron_right, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _statTile('Present', summary['present'] ?? 0,
                          const Color(0xFFE9EAE4), const Color(0xFF3B5B3A)),
                      _statTile('Late', summary['late'] ?? 0,
                          const Color(0xFFF0E6E2), const Color(0xFFB76746)),
                      _statTile('Absent', summary['absent'] ?? 0,
                          const Color(0xFFF0E7EA), const Color(0xFFC97E7E)),
                      _statTile('Leave', summary['leave'] ?? 0,
                          const Color(0xFFEDEAF7), const Color(0xFF8F7AB1)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F3F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD9D9D6)),
                    ),
                    child: Row(
                      children: List.generate(
                        _tabs.length,
                        (index) {
                          final isSelected = _roleFilter ==
                              switch (index) {
                                0 => 'all',
                                1 => 'worker',
                                _ => 'supervisor',
                              };
                          final label = _tabs[index];
                          return Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() => _roleFilter = switch (index) {
                                      0 => 'all',
                                      1 => 'worker',
                                      _ => 'supervisor',
                                    });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE9F0EA)
                                      : Colors.transparent,
                                  border: Border(
                                    right: BorderSide(
                                      color: index < _tabs.length - 1
                                          ? const Color(0xFFD9D9D6)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF245D32)
                                        : const Color(0xFF4A4A4A),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF6A6A6A)),
                      hintText: 'Search by name or employee ID...',
                      hintStyle: const TextStyle(color: Color(0xFF7D7D7D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE3E3E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE3E3E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2C7A4B), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red))),
                          TextButton(
                              onPressed: _refresh, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        final record = _recordFor(data.records, employee);
                        final statusText = _statusLabel(record?.status ?? '');
                        final selectedStatus =
                            (record?.status ?? '').toLowerCase();
                        final isClockedIn = record != null &&
                            record.checkIn != null &&
                            record.checkOut == null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE3E3E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFBCE0C8),
                                    child: Text(
                                      _initials(employee.fullName),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF234F32),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.fullName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E1E1E),
                                          ),
                                        ),
                                        Text(
                                          '${employee.role} • ${employee.employeeNumber ?? (employee.profileId.length > 5 ? employee.profileId.substring(0, 5).toUpperCase() : employee.profileId.toUpperCase())}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF787878),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F3F3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF565656),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Mark Status:',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF4D4D4D)),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final status in _statusOptions)
                                    ChoiceChip(
                                      label: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: selectedStatus == status
                                              ? Colors.white
                                              : const Color(0xFF5A5A5A),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      selected: selectedStatus == status,
                                      onSelected: _busy
                                          ? null
                                          : (_) => _markAttendance(
                                              employee,
                                              status == 'on_leave'
                                                  ? 'on_leave'
                                                  : status),
                                      selectedColor: const Color(0xFF3D8F5F),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: selectedStatus == status
                                            ? const Color(0xFF3D8F5F)
                                            : const Color(0xFFDBDBD9),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_filled,
                                            size: 15, color: Color(0xFF6B6B6B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          record == null
                                              ? '--:--'
                                              : _formatTime(record.checkIn),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF5C5C5C)),
                                        ),
                                        const SizedBox(width: 14),
                                        const Icon(Icons.exit_to_app_rounded,
                                            size: 15, color: Color(0xFF6B6B6B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          record == null
                                              ? '--:--'
                                              : _formatTime(record.checkOut),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF5C5C5C)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 110,
                                    height: 38,
                                    child: ElevatedButton(
                                      onPressed: _busy
                                          ? null
                                          : () {
                                              if (record == null ||
                                                  record.checkIn == null) {
                                                _clockIn(employee);
                                              } else if (record.checkOut ==
                                                  null) {
                                                _clockOut(record);
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1E8F57),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        isClockedIn ? 'Clock Out' : 'Clock In',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statTile(String label, int count, Color background, Color accent) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
