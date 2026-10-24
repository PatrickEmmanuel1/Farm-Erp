import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/farm_operations_repository.dart';
import '../../data/repository/farm_repositories.dart';
import '../activities/assigned_activities_screen.dart';
import '../common/farm_feature_screen.dart';
import '../common/farm_features.dart';
import '../dashboard/manager/manager_dashboard_screen.dart';
import '../dashboard/supervisor/supervisor_dashboard_screen.dart';
import '../dashboard/worker/worker_dashboard_screen.dart';
import '../divisions/divisions_screen.dart';
import '../employees/employees_screen.dart';
import '../machinery/machinery_screen.dart';
import '../more/more_features_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/profile_settings_screen.dart';
import '../storage/storage_screen.dart';

enum FarmRole { manager, supervisor, worker }

class RoleNavigationShell extends StatefulWidget {
  const RoleNavigationShell({
    required this.role,
    required this.user,
    required this.repositories,
    required this.onSignOut,
    this.onUserUpdated,
    super.key,
  });

  final FarmRole role;
  final FarmUser user;
  final FarmRepositories repositories;

  FarmOperationsRepository get repository => repositories.operations;
  final Future<void> Function() onSignOut;
  final ValueChanged<FarmUser>? onUserUpdated;

  @override
  State<RoleNavigationShell> createState() => _RoleNavigationShellState();
}

class _RoleNavigationShellState extends State<RoleNavigationShell> {
  int _selectedIndex = 0;
  bool _showSettings = false;
  late FarmUser _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  @override
  void didUpdateWidget(covariant RoleNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) _currentUser = widget.user;
  }

  String get _farmId => _currentUser.farmId ?? _currentUser.farm?.id ?? '';

  void _onUserUpdated(FarmUser user) {
    setState(() => _currentUser = user);
    widget.onUserUpdated?.call(user);
  }

  List<_NavigationItem> get _items => switch (widget.role) {
        FarmRole.manager => const [
            _NavigationItem('Dashboard', Icons.dashboard_outlined),
            _NavigationItem('Crops', Icons.grass_outlined),
            _NavigationItem('Activities', Icons.assignment_outlined),
            _NavigationItem('Employees', Icons.groups_outlined),
            _NavigationItem('More', Icons.menu),
          ],
        FarmRole.supervisor => const [
            _NavigationItem('Dashboard', Icons.dashboard_outlined),
            _NavigationItem('Activities', Icons.assignment_outlined),
            _NavigationItem('Resources', Icons.inventory_2_outlined),
            _NavigationItem('Machinery', Icons.agriculture_outlined),
            _NavigationItem('More', Icons.menu),
          ],
        FarmRole.worker => const [
            _NavigationItem('Dashboard', Icons.dashboard_outlined),
            _NavigationItem('Activities', Icons.assignment_outlined),
            _NavigationItem('More', Icons.menu),
          ],
      };

  Widget _dashboard() => switch (widget.role) {
        FarmRole.manager => ManagerDashboardScreen(
            user: _currentUser,
            repository: widget.repositories.operations,
            onSignOut: widget.onSignOut,
            onActivities: () => setState(() => _selectedIndex = 2),
            onEmployees: () => setState(() => _selectedIndex = 3),
            onAddCrop: _openCropForm,
            onCrops: () => setState(() => _selectedIndex = 1),
            onResources: _openResources,
            onMachinery: _openMachinery,
            onStorageProduce: _openStorageProduce,
            onReports: _openReports,
            onDivisions: _openDivisions,
          ),
        FarmRole.supervisor => SupervisorDashboardScreen(
            user: _currentUser,
            activitiesRepository: widget.repositories.activities,
            employeesRepository: widget.repositories.employees,
            onSignOut: widget.onSignOut,
          ),
        FarmRole.worker => WorkerDashboardScreen(
            user: _currentUser,
            activitiesRepository: widget.repositories.activities,
            onSignOut: widget.onSignOut,
          ),
      };

  void _openCropForm() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FarmFeatureScreen(
          feature: cropsFeature,
          repository: widget.repositories.operations,
          farmId: _farmId,
          machineryRepository: widget.repositories.machinery,
          actorProfileId: _currentUser.profileId,
          openCreateOnLoad: true,
        ),
      ),
    );
  }

  void _openResources() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MoreFeaturesScreen(
          title: 'Resources',
          entries: resourceMenuEntries,
          user: _currentUser,
          repository: widget.repository,
          repositories: widget.repositories,
          onSignOut: widget.onSignOut,
          onUserUpdated: _onUserUpdated,
        ),
      ),
    );
  }

  void _openMachinery() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MachineryScreen(
          user: _currentUser,
          operationsRepository: widget.repositories.operations,
          machineryRepository: widget.repositories.machinery,
        ),
      ),
    );
  }

  void _openStorageProduce() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StorageScreen(
          farmId: _farmId,
          repository: widget.repositories.storage,
          canManage: widget.role == FarmRole.manager,
        ),
      ),
    );
  }

  void _openDivisions() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DivisionsScreen(
          farmId: _farmId,
          divisionRepository: widget.repositories.divisions,
          cropRepository: widget.repositories.crops,
        ),
      ),
    );
  }

  void _openReports() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReportsScreen(
          farmId: _farmId,
          repository: widget.repositories.reports,
        ),
      ),
    );
  }

  Widget _selectedPage() {
    final tab = _items[_selectedIndex].label;
    if (tab == 'Dashboard') return _dashboard();
    if (tab == 'More' && _showSettings) {
      return ProfileSettingsScreen(
        user: _currentUser,
        repositories: widget.repositories,
        onSignOut: widget.onSignOut,
        onUserUpdated: _onUserUpdated,
        onBack: () => setState(() => _showSettings = false),
      );
    }
    if (tab == 'Crops' && widget.role == FarmRole.manager) {
      return FarmFeatureScreen(
        feature: cropsFeature,
        repository: widget.repositories.operations,
        farmId: _farmId,
        machineryRepository: widget.repositories.machinery,
        actorProfileId: _currentUser.profileId,
      );
    }
    if (tab == 'Activities') {
      return AssignedActivitiesScreen(
        user: _currentUser,
        repository: widget.repositories.activities,
        farmId: _farmId,
      );
    }
    if (tab == 'Employees') {
      return EmployeesScreen(
        farmId: _farmId,
        repository: widget.repositories.employees,
        canManage: widget.role == FarmRole.manager,
      );
    }
    if (tab == 'Resources') {
      return MoreFeaturesScreen(
        title: 'Resources',
        entries: resourceMenuEntries,
        user: _currentUser,
        repository: widget.repository,
        repositories: widget.repositories,
        onSignOut: widget.onSignOut,
        onUserUpdated: _onUserUpdated,
      );
    }
    if (tab == 'Machinery') {
      return MachineryScreen(
        user: _currentUser,
        operationsRepository: widget.repositories.operations,
        machineryRepository: widget.repositories.machinery,
      );
    }
    return MoreFeaturesScreen(
      title: 'More',
      entries: _moreEntries,
      user: _currentUser,
      repository: widget.repository,
      repositories: widget.repositories,
      onSignOut: widget.onSignOut,
      onUserUpdated: _onUserUpdated,
      onOpenSettings: () => setState(() => _showSettings = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _selectedPage()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() {
          _selectedIndex = index;
          _showSettings = false;
        }),
        destinations: [
          for (final item in _items)
            NavigationDestination(
              icon: Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _moreEntries = [
  FeatureMenuEntry(
    'Messages',
    Icons.chat_bubble_outline,
    destination: 'messages',
  ),
  FeatureMenuEntry(
    'Worker Attendance',
    Icons.calendar_month_outlined,
    destination: 'attendance',
  ),
  FeatureMenuEntry(
    'Resources',
    Icons.inventory_2_outlined,
    destination: 'resources',
    roles: ['manager'],
  ),
  FeatureMenuEntry(
    'Machinery',
    Icons.agriculture_outlined,
    destination: 'machinery',
    roles: ['manager'],
  ),
  FeatureMenuEntry(
    'Storage Produce',
    Icons.warehouse_outlined,
    destination: 'storage',
    roles: ['manager'],
  ),
  FeatureMenuEntry(
    'Crop Yields',
    Icons.agriculture_outlined,
    destination: 'crop_yields',
    roles: ['manager'],
  ),
  FeatureMenuEntry(
    'Reports & Summaries',
    Icons.bar_chart_outlined,
    destination: 'reports',
    roles: ['manager'],
  ),
  FeatureMenuEntry(
    'Get Tips',
    Icons.lightbulb_outline,
    destination: 'recommendations',
    roles: ['manager'],
  ),
  FeatureMenuEntry(
    'Employees',
    Icons.groups_outlined,
    destination: 'employees',
    roles: ['supervisor'],
  ),
  FeatureMenuEntry('Divisions', Icons.map_outlined,
      destination: 'divisions', roles: ['manager']),
  FeatureMenuEntry('Settings', Icons.settings_outlined, destination: 'profile'),
];
