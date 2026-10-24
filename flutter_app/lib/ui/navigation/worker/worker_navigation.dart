import 'package:flutter/material.dart';

import '../../../data/model/farm_user.dart';
import '../../../data/repository/farm_repositories.dart';
import '../role_navigation_shell.dart';

class WorkerNavigation extends StatelessWidget {
  const WorkerNavigation({
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
  Widget build(BuildContext context) => RoleNavigationShell(
        role: FarmRole.worker,
        user: user,
        repositories: repositories,
        onSignOut: onSignOut,
        onUserUpdated: onUserUpdated,
      );
}
