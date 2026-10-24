import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/farm_repositories.dart';
import '../navigation/manager/manager_navigation.dart';
import '../navigation/supervisor/supervisor_navigation.dart';
import '../navigation/worker/worker_navigation.dart';

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({
    required this.user,
    required this.repositories,
    required this.onSignOut,
    this.onUserUpdated,
    super.key,
  });

  final FarmUser user;
  final FarmRepositories repositories;
  final Future<void> Function() onSignOut;
  final ValueChanged<FarmUser>? onUserUpdated;

  @override
  Widget build(BuildContext context) {
    return switch (user.role.toLowerCase()) {
      'manager' => ManagerNavigation(
          user: user,
          repositories: repositories,
          onSignOut: onSignOut,
          onUserUpdated: onUserUpdated,
        ),
      'supervisor' => SupervisorNavigation(
          user: user,
          repositories: repositories,
          onSignOut: onSignOut,
          onUserUpdated: onUserUpdated,
        ),
      'worker' => WorkerNavigation(
          user: user,
          repositories: repositories,
          onSignOut: onSignOut,
          onUserUpdated: onUserUpdated,
        ),
      _ => _UnsupportedRoleScreen(role: user.role, onSignOut: onSignOut),
    };
  }
}

class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen({
    required this.role,
    required this.onSignOut,
  });

  final String role;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyFarm')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No dashboard is available for the "$role" role.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
