import 'package:flutter/material.dart';

import '../../../data/model/farm_user.dart';
import '../../../data/repository/farm_repositories.dart';
import '../role_navigation_shell.dart';

class SupervisorNavigation extends StatelessWidget {
  const SupervisorNavigation({
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
        role: FarmRole.supervisor,
        user: user,
        repositories: repositories,
        onSignOut: onSignOut,
        onUserUpdated: onUserUpdated,
      );
}
