import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/farm_operations_repository.dart';
import '../../data/repository/farm_repositories.dart';
import '../attendance/attendance_screen.dart';
import '../common/farm_feature.dart';
import '../common/farm_features.dart';
import '../common/farm_feature_screen.dart';
import '../inventory/issue_inventory_screen.dart';
import '../inventory/inventory_issuance_history_screen.dart';
import '../reports/reports_screen.dart';
import '../recommendations/manager_recommendations_screen.dart';
import '../settings/profile_settings_screen.dart';
import '../divisions/divisions_screen.dart';
import '../employees/employees_screen.dart';
import '../crops/crop_yield_screen.dart';
import '../chat/chat_screen.dart';
import '../machinery/machinery_screen.dart';
import '../storage/storage_screen.dart';

const resourceMenuEntries = [
  FeatureMenuEntry('Issue inventory', Icons.outbox_outlined,
      destination: 'inventory_issuance'),
  FeatureMenuEntry('Issuance history', Icons.history,
      destination: 'inventory_history'),
  FeatureMenuEntry('Fertilizers', Icons.eco_outlined,
      feature: fertilizersFeature),
  FeatureMenuEntry('Herbicides', Icons.grass_outlined,
      feature: herbicidesFeature),
  FeatureMenuEntry('Pesticides', Icons.pest_control_outlined,
      feature: pesticidesFeature),
  FeatureMenuEntry('Fungicides', Icons.shield_outlined,
      feature: fungicidesFeature),
  FeatureMenuEntry('Insecticides', Icons.bug_report_outlined,
      feature: insecticidesFeature),
  FeatureMenuEntry('Water', Icons.water_drop_outlined, feature: waterFeature),
];

class FeatureMenuEntry {
  const FeatureMenuEntry(
    this.title,
    this.icon, {
    this.feature,
    this.destination,
    this.roles,
  });

  final String title;
  final IconData icon;
  final FarmFeature? feature;
  final String? destination;
  final List<String>? roles;
}

class MoreFeaturesScreen extends StatelessWidget {
  const MoreFeaturesScreen({
    required this.title,
    required this.entries,
    required this.user,
    required this.repository,
    required this.repositories,
    required this.onSignOut,
    this.onUserUpdated,
    this.onOpenSettings,
    super.key,
  });

  final String title;
  final List<FeatureMenuEntry> entries;
  final FarmUser user;
  final FarmOperationsRepository repository;
  final FarmRepositories repositories;
  final Future<void> Function() onSignOut;
  final ValueChanged<FarmUser>? onUserUpdated;
  final VoidCallback? onOpenSettings;

  String get _farmId => user.farmId ?? user.farm?.id ?? '';

  void _open(BuildContext context, FeatureMenuEntry entry) {
    final Widget? page;
    if (entry.feature != null) {
      final requestedFeature = entry.feature!;
      final canEdit = user.role.toLowerCase() == 'manager' ||
          (user.role.toLowerCase() == 'supervisor' &&
              {'crop_planting', 'crop_harvest'}
                  .contains(requestedFeature.table));
      final feature = canEdit
          ? requestedFeature
          : FarmFeature(
              title: requestedFeature.title,
              table: requestedFeature.table,
              idColumn: requestedFeature.idColumn,
              fields: requestedFeature.fields,
              orderBy: requestedFeature.orderBy,
              readOnly: true,
              canCreate: false,
              canEditExisting: false,
              canDelete: false,
              showFarmId: requestedFeature.showFarmId,
              excludeDeleted: requestedFeature.excludeDeleted,
              softDelete: requestedFeature.softDelete,
              description: requestedFeature.description,
            );
      page = FarmFeatureScreen(
        feature: feature,
        repository: repository,
        farmId: _farmId,
        machineryRepository: repositories.machinery,
        actorProfileId: user.profileId,
      );
    } else {
      page = switch (entry.destination) {
        'resources' => MoreFeaturesScreen(
            title: 'Resources',
            entries: resourceMenuEntries,
            user: user,
            repository: repository,
            repositories: repositories,
            onSignOut: onSignOut,
            onUserUpdated: onUserUpdated,
          ),
        'attendance' => AttendanceScreen(
            user: user,
            farmId: _farmId,
            repository: repositories.attendance,
          ),
        'employees' => EmployeesScreen(
            farmId: _farmId,
            repository: repositories.employees,
            canManage: false,
          ),
        'divisions' => DivisionsScreen(
            farmId: _farmId,
            divisionRepository: repositories.divisions,
            cropRepository: repositories.crops,
          ),
        'profile' => onOpenSettings == null
            ? ProfileSettingsScreen(
                user: user,
                repositories: repositories,
                onSignOut: onSignOut,
                onUserUpdated: onUserUpdated,
              )
            : null,
        'reports' => ReportsScreen(
            farmId: _farmId,
            repository: repositories.reports,
          ),
        'messages' => MessagesScreen(
            user: user,
            repository: repositories.chat,
          ),
        'crop_yields' => CropYieldScreen(
            farmId: _farmId,
            repository: repositories.crops,
          ),
        'machinery' => MachineryScreen(
            user: user,
            operationsRepository: repository,
            machineryRepository: repositories.machinery,
          ),
        'storage' => StorageScreen(
            farmId: _farmId,
            repository: repositories.storage,
            canManage: user.role.toLowerCase() == 'manager',
          ),
        'inventory_issuance' => IssueInventoryScreen(
            user: user,
            farmId: _farmId,
            repository: repositories.inventory,
            divisionRepository: repositories.divisions,
          ),
        'inventory_history' => InventoryIssuanceHistoryScreen(
            farmId: _farmId,
            repository: repositories.inventory,
          ),
        'recommendations' => ManagerRecommendationsScreen(
            farmId: _farmId,
            repository: repository,
          ),
        _ => null,
      };
    }
    if (entry.destination == 'profile' && onOpenSettings != null) {
      onOpenSettings!();
      return;
    }
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page!));
  }

  String _entryDescription(String title) {
    final normalized = title.trim();
    if (normalized.contains('Attendance')) {
      return 'Daily field clock-in, status & attendance logs';
    }
    if (normalized.contains('Resources')) {
      return 'Track fertilizers, chemicals, water & farm resources';
    }
    if (normalized.contains('Machinery')) {
      return 'Manage farm machinery & maintenance';
    }
    if (normalized.contains('Storage')) {
      return 'Manage harvested produce & storage locations';
    }
    if (normalized.contains('Crop')) {
      return 'Record and view crop harvest logs';
    }
    if (normalized.contains('Report')) {
      return 'View crop, inventory, machinery & workforce reports';
    }
    if (normalized.contains('Tips')) {
      return 'Crop recommendations & agronomy advice';
    }
    if (normalized.contains('Employees')) {
      return 'Manage farm staff and assignments';
    }
    if (normalized.contains('Farm')) {
      return 'Manage farm details and settings';
    }
    return 'Access this farm management option';
  }

  @override
  Widget build(BuildContext context) {
    final role = user.role.toLowerCase();
    final visibleEntries = entries
        .where((entry) => entry.roles == null || entry.roles!.contains(role))
        .toList();
    final subtitle = title == 'More'
        ? 'Farm management options'
        : 'Track fertilizers, chemicals, water & farm resources';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 26),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B4B4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: visibleEntries.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == visibleEntries.length) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: onSignOut,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4E9E4),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.logout, color: Color(0xFF9B2929)),
                              SizedBox(width: 12),
                              Text(
                                'Sign out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9B2929),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final entry = visibleEntries[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _open(context, entry),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E9E4),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F2E8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                entry.icon,
                                size: 22,
                                color: const Color(0xFF1F642F),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _entryDescription(entry.title),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF5A5A5A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: Color(0xFF666666),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
