import 'package:flutter/material.dart';

import '../../../data/repository/employee_repository.dart';
import '../../../data/repository/farm_activity_repository.dart';
import '../../../data/model/farm_user.dart';
import '../../../data/user_facing_error.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({
    required this.user,
    required this.activitiesRepository,
    required this.employeesRepository,
    required this.onSignOut,
    super.key,
  });
  final FarmUser user;
  final FarmActivityRepository activitiesRepository;
  final EmployeeRepository employeesRepository;
  final Future<void> Function() onSignOut;

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  late Future<(int, int)> _summary;

  String get _farmId => widget.user.farmId ?? widget.user.farm?.id ?? '';

  @override
  void initState() {
    super.initState();
    _summary = _loadSummary();
  }

  Future<(int, int)> _loadSummary() async {
    final activityRows =
        await widget.activitiesRepository.getFarmActivitiesForFarm(_farmId);
    final workers = await widget.employeesRepository.getWorkersForFarm(_farmId);
    final supervisorId = widget.user.profileId;
    final activities = activityRows.where((row) {
      final status = row.safeStatus.toLowerCase();
      final assigned = row.supervisorProfileId;
      return (supervisorId == null ||
              assigned == null ||
              assigned == supervisorId) &&
          status != 'completed' &&
          status != 'done' &&
          status != 'finished';
    }).length;
    return (activities, workers.length);
  }

  Future<void> _refresh() async {
    setState(() => _summary = _loadSummary());
    await _summary;
  }

  Future<void> _signOut() async {
    try {
      await widget.onSignOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MyFarm'),
            Text('Supervisor Portal', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Welcome back, ${widget.user.fullName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text('Here is your supervision overview for today.'),
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Icon(Icons.supervisor_account, size: 36),
                title: Text('Field operations'),
                subtitle: Text(
                  'Monitor workers, activities, and daily field attendance.',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Quick summary',
                style: Theme.of(context).textTheme.titleLarge),
            FutureBuilder<(int, int)>(
              future: _summary,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text(userFacingError(snapshot.error!)),
                      TextButton(
                          onPressed: _refresh, child: const Text('Retry')),
                    ],
                  );
                }
                final counts = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.assignment_outlined,
                        title: 'Active activities',
                        value: counts.$1.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.groups_outlined,
                        title: 'Team workers',
                        value: counts.$2.toString(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
