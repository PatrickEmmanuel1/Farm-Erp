import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_flutter/data/model/farm_user.dart';
import 'package:farm_flutter/data/model/farm_activity.dart';
import 'package:farm_flutter/data/model/farm_employee.dart';
import 'package:farm_flutter/data/model/storage.dart';
import 'package:farm_flutter/data/repository/farm_operations_repository.dart';
import 'package:farm_flutter/data/repository/farm_repositories.dart';
import 'package:farm_flutter/data/repository/employee_repository.dart';
import 'package:farm_flutter/data/repository/farm_activity_repository.dart';
import 'package:farm_flutter/data/repository/storage_repository.dart';
import 'package:farm_flutter/ui/activities/assigned_activities_screen.dart';
import 'package:farm_flutter/ui/dashboard/role_home_screen.dart';
import 'package:farm_flutter/ui/employees/employees_screen.dart';
import 'package:farm_flutter/ui/splash/configuration_error_app.dart';
import 'package:farm_flutter/ui/storage/storage_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('explains how to configure Supabase', (tester) async {
    await tester.pumpWidget(const ConfigurationErrorApp());

    expect(find.textContaining('Supabase is not configured.'), findsOneWidget);
    expect(find.textContaining('--dart-define=SUPABASE_URL='), findsOneWidget);
  });

  testWidgets('routes each account to its role dashboard', (tester) async {
    final client = _testClient();
    final repository = _FakeFarmOperationsRepository(client);
    for (final role in ['Manager', 'Supervisor', 'Worker']) {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleHomeScreen(
            user: FarmUser(
              id: 'account-id',
              fullName: 'Alex Farm',
              email: 'alex@example.com',
              role: role,
              farm: role == 'Manager'
                  ? const FarmSummary(
                      id: 'farm-id',
                      name: 'Green Farm',
                      county: 'Nairobi',
                      size: 20,
                      unit: 'Acres',
                    )
                  : null,
            ),
            repositories: FarmRepositories(
              client,
              operations: repository,
              activities: _FakeFarmActivityRepository(client),
              employees: _FakeEmployeeRepository(client),
            ),
            onSignOut: () async {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      if (role == 'Manager') {
        expect(find.text('Welcome back,'), findsOneWidget);
        expect(find.text('Farm Overview'), findsOneWidget);
      } else if (role == 'Worker') {
        expect(find.text('Employee Portal'), findsOneWidget);
      } else {
        expect(find.text('$role Portal'), findsOneWidget);
      }
    }
  });

  testWidgets('shows farm tasks in status tabs', (tester) async {
    final repository = _FakeFarmActivityRepository(
      _testClient(),
      activities: const [
        FarmActivityDisplay(
          activity: FarmActivity(
            activityId: 'activity-id',
            activityTypeId: 'type-id',
            farmId: 'farm-id',
            activityName: 'Weeding',
            activityDate: '2026-10-18',
            status: 'Pending',
          ),
          activityTypeName: 'Weeding',
          assignedToName: 'Owen reagan',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AssignedActivitiesScreen(
          user: const FarmUser(
            id: 'manager-id',
            fullName: 'Farm Manager',
            email: 'manager@example.com',
            role: 'Manager',
          ),
          farmId: 'farm-id',
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Farm Activities'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsOneWidget);
    expect(find.text('Weeding'), findsNWidgets(2));
    expect(find.text('Owen reagan'), findsOneWidget);
    expect(find.text('Begin activity'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    await tester.tap(find.text('Completed').first);
    await tester.pumpAndSettle();
    expect(find.text('No Completed tasks yet.'), findsOneWidget);
    expect(find.text('Begin activity'), findsNothing);
  });

  testWidgets('manager dashboard Add Crop opens the crop form', (tester) async {
    final client = _testClient();
    await tester.pumpWidget(
      MaterialApp(
        home: RoleHomeScreen(
          user: const FarmUser(
            id: 'manager-id',
            fullName: 'Farm Manager',
            email: 'manager@example.com',
            role: 'Manager',
            farm: FarmSummary(
              id: 'farm-id',
              name: 'Green Farm',
              county: 'Nairobi',
              size: 20,
              unit: 'Acres',
            ),
          ),
          repositories: FarmRepositories(
            client,
            operations: _FakeFarmOperationsRepository(client),
            activities: _FakeFarmActivityRepository(client),
            employees: _FakeEmployeeRepository(client),
          ),
          onSignOut: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Crop'));
    await tester.pumpAndSettle();

    expect(find.text('Add Crops'), findsOneWidget);
    expect(find.text('Crop Name *'), findsOneWidget);
  });

  testWidgets('storage screen switches between produce and facilities',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StorageScreen(
          farmId: 'farm-id',
          repository: _FakeStorageRepository(
            _testClient(),
            produce: const [
              StoredProduce(
                storageId: 'produce-id',
                farmId: 'farm-id',
                cropName: 'Maize',
                quantity: 20,
                unit: 'kg',
                location: 'North store',
                dateStored: '2026-10-18',
                condition: 'Good',
              ),
            ],
            facilities: const [
              StorageFacility(
                facilityId: 'facility-id',
                farmId: 'farm-id',
                name: 'North store',
                facilityType: 'store',
                capacityKg: 500,
              ),
            ],
          ),
          canManage: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('1 batches in 1 facilities'), findsOneWidget);
    expect(find.text('Maize'), findsOneWidget);
    expect(find.text('Add Produce'), findsOneWidget);

    await tester.tap(find.text('Storage Facilities (1)'));
    await tester.pumpAndSettle();

    expect(find.text('North store'), findsOneWidget);
    expect(find.text('Add Facility'), findsOneWidget);
  });

  testWidgets('settings shows profile, farm, and notifications options',
      (tester) async {
    final client = _testClient();
    await tester.pumpWidget(
      MaterialApp(
        home: RoleHomeScreen(
          user: const FarmUser(
            id: 'manager-id',
            fullName: 'Farm Manager',
            email: 'manager@example.com',
            role: 'Manager',
            farm: FarmSummary(
              id: 'farm-id',
              name: 'Green Farm',
              county: 'Nairobi',
              size: 20,
              unit: 'Acres',
            ),
          ),
          repositories: FarmRepositories(
            client,
            operations: _FakeFarmOperationsRepository(client),
            activities: _FakeFarmActivityRepository(client),
            employees: _FakeEmployeeRepository(client),
          ),
          onSignOut: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    expect(find.text('Farm management options'), findsOneWidget);
    for (var attempt = 0;
        attempt < 4 && find.text('Settings').evaluate().isEmpty;
        attempt++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account & Preferences'), findsOneWidget);
    expect(find.text('Manager Profile'), findsOneWidget);
    expect(find.text('Farm Details'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('employees screen separates supervisors and workers',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmployeesScreen(
          farmId: 'farm-id',
          repository: _FakeEmployeeRepository(
            _testClient(),
            employees: const [
              FarmEmployee(
                profileId: 'supervisor-id',
                accountId: 'supervisor-account',
                fullName: 'Owen reagan',
                role: 'Supervisor',
                employeeNumber: 'sup001',
                email: 'owen13@gmail.com',
                phoneNumber: '0712345687',
              ),
              FarmEmployee(
                profileId: 'worker-id',
                accountId: 'worker-account',
                fullName: 'Steve oti',
                role: 'Worker',
                email: 'otienop450@gmail.com',
                phoneNumber: '+254 792 261179',
              ),
            ],
          ),
          canManage: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Manage supervisors and workers'), findsOneWidget);
    expect(find.text('Total supervisors'), findsOneWidget);
    expect(find.text('Owen reagan'), findsOneWidget);
    expect(find.text('sup001'), findsOneWidget);
    expect(find.text('Steve oti'), findsNothing);
    expect(find.text('Add another supervisor'), findsOneWidget);

    await tester.tap(find.text('Workers'));
    await tester.pumpAndSettle();
    expect(find.text('Total workers'), findsOneWidget);
    expect(find.text('Steve oti'), findsOneWidget);
    expect(find.text('Owen reagan'), findsNothing);
    expect(find.text('Add another worker'), findsOneWidget);
  });
}

class _FakeFarmOperationsRepository extends FarmOperationsRepository {
  _FakeFarmOperationsRepository(super._client);

  @override
  Future<FarmDashboardSummary> loadDashboardSummary(String farmId) async =>
      const FarmDashboardSummary(
        totalCrops: 0,
        totalDivisions: 0,
        pendingActivities: 0,
        totalWorkers: 0,
        totalEmployees: 0,
        totalInventory: 0,
        totalMachinery: 0,
        totalStorage: 0,
      );

  @override
  Future<List<Map<String, dynamic>>> fetchRows(
    String table, {
    String? farmId,
    String? orderBy,
    bool excludeDeleted = true,
  }) async =>
      const [];
}

class _FakeFarmActivityRepository extends FarmActivityRepository {
  _FakeFarmActivityRepository(
    super._client, {
    this.activities = const [],
  });

  final List<FarmActivityDisplay> activities;

  @override
  Future<List<FarmActivity>> getFarmActivitiesForFarm(String farmId) async =>
      const [];

  @override
  Future<List<FarmActivityDisplay>> getFarmActivityDisplays(
    String farmId,
  ) async =>
      activities;
}

class _FakeEmployeeRepository extends EmployeeRepository {
  _FakeEmployeeRepository(
    super._client, {
    this.employees = const [],
  });

  final List<FarmEmployee> employees;

  @override
  Future<List<FarmEmployee>> getWorkersForFarm(String farmId) async => const [];

  @override
  Future<List<FarmEmployee>> getEmployeesForFarm(
    String farmId, {
    bool includeAccountDetails = true,
  }) async =>
      employees;
}

class _FakeStorageRepository extends StorageRepository {
  _FakeStorageRepository(
    super._client, {
    this.produce = const [],
    this.facilities = const [],
  });

  final List<StoredProduce> produce;
  final List<StorageFacility> facilities;

  @override
  Future<List<StoredProduce>> getStorageForFarm(String farmId) async => produce;

  @override
  Future<List<StorageFacility>> getFacilitiesForFarm(String farmId) async =>
      facilities;
}

SupabaseClient _testClient() => SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
