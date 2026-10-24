import 'package:flutter/material.dart';

import '../../../data/model/farm_user.dart';
import '../../../data/model/farm_activity.dart';
import '../../../data/repository/farm_activity_repository.dart';
import '../../../data/user_facing_error.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({
    required this.user,
    required this.activitiesRepository,
    required this.onSignOut,
    super.key,
  });
  final FarmUser user;
  final FarmActivityRepository activitiesRepository;
  final Future<void> Function() onSignOut;

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  late Future<List<FarmActivityDisplay>> _tasks;

  String get _farmId => widget.user.farmId ?? widget.user.farm?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tasks = _loadTasks();
  }

  Future<List<FarmActivityDisplay>> _loadTasks() async {
    final profileId = widget.user.profileId;
    if (profileId == null || profileId.isEmpty) return const [];
    final rows = await widget.activitiesRepository.getAssignedActivityDisplays(
      farmId: _farmId,
      profileId: profileId,
      isWorker: true,
    );
    return rows.where((row) {
      final status = row.activity.safeStatus.toLowerCase();
      return status != 'completed' &&
          status != 'done' &&
          status != 'finished' &&
          status != 'closed';
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() => _tasks = _loadTasks());
    await _tasks;
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
            Text('Employee Portal', style: TextStyle(fontSize: 12)),
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
            const Text('Here are your assigned farm tasks for today.'),
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Icon(Icons.person_outline, size: 36),
                title: Text('Daily tasks'),
                subtitle: Text(
                  'Perform assigned farm activities and report completion.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Assigned tasks',
                style: Theme.of(context).textTheme.titleLarge),
            FutureBuilder<List<FarmActivityDisplay>>(
              future: _tasks,
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
                final tasks = snapshot.data ?? const [];
                if (tasks.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No active tasks assigned to you right now.'),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final task in tasks)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.assignment_outlined),
                          title: Text(
                            task.displayTitle,
                          ),
                          subtitle: Text(
                            '${task.activity.safeActivityDate} · '
                            '${task.activity.safeStatus}',
                          ),
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
