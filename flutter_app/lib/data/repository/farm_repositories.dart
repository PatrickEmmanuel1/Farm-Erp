import 'package:supabase_flutter/supabase_flutter.dart';

import 'attendance_repository.dart';
import 'auth_repository.dart';
import 'chat_repository.dart';
import 'crop_repository.dart';
import 'division_repository.dart';
import 'employee_repository.dart';
import 'farm_activity_repository.dart';
import 'farm_operations_repository.dart';
import 'farm_repository.dart';
import 'inventory_repository.dart';
import 'machinery_repository.dart';
import 'notification_repository.dart';
import 'report_repository.dart';
import 'storage_repository.dart';

class FarmRepositories {
  FarmRepositories(
    SupabaseClient client, {
    FarmOperationsRepository? operations,
    FarmActivityRepository? activities,
    EmployeeRepository? employees,
  })  : auth = AuthRepository(client),
        chat = ChatRepository(client),
        farms = FarmRepository(client),
        divisions = DivisionRepository(client),
        crops = CropRepository(client),
        activities = activities ?? FarmActivityRepository(client),
        employees = employees ?? EmployeeRepository(client),
        attendance = AttendanceRepository(client),
        inventory = InventoryRepository(client),
        machinery = MachineryRepository(client),
        storage = StorageRepository(client),
        notifications = NotificationRepository(client),
        reports = ReportRepository(client),
        operations = operations ?? FarmOperationsRepository(client);

  final AuthRepository auth;
  final ChatRepository chat;
  final FarmRepository farms;
  final DivisionRepository divisions;
  final CropRepository crops;
  final FarmActivityRepository activities;
  final EmployeeRepository employees;
  final AttendanceRepository attendance;
  final InventoryRepository inventory;
  final MachineryRepository machinery;
  final StorageRepository storage;
  final NotificationRepository notifications;
  final ReportRepository reports;

  /// Temporary adapter for screens still using dynamic generic CRUD.
  final FarmOperationsRepository operations;
}
