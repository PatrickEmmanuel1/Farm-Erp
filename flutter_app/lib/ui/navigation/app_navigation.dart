import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/repository/farm_repository.dart';
import '../../data/repository/farm_repositories.dart';
import '../../data/remote/supabase_client_provider.dart';
import '../../data/user_facing_error.dart';
import '../auth/login_screen.dart';
import '../dashboard/role_home_screen.dart';
import '../farm/create_farm_screen.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  late final AuthRepository _authRepository;
  late final FarmRepository _farmRepository;
  late final FarmRepositories _repositories;
  FarmUser? _user;
  Object? _startupError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final client = SupabaseClientProvider.client;
    _authRepository = AuthRepository(client);
    _farmRepository = FarmRepository(client);
    _repositories = FarmRepositories(client);
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _loading = true;
      _startupError = null;
    });
    try {
      _user = await _authRepository.restoreSession();
    } catch (error) {
      _startupError = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSignedIn(FarmUser user) {
    setState(() {
      _user = user;
      _startupError = null;
    });
  }

  Future<void> _onSignOut() async {
    await _authRepository.signOut();
    if (mounted) setState(() => _user = null);
  }

  Future<void> _clearSession() async {
    try {
      await _authRepository.signOut();
      if (mounted) {
        setState(() {
          _startupError = null;
          _user = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _startupError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_startupError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not restore your session.'),
                const SizedBox(height: 8),
                Text(
                  userFacingError(_startupError!),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _restoreSession,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: _clearSession,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_user == null) {
      return LoginScreen(
        authRepository: _authRepository,
        onSignedIn: _onSignedIn,
      );
    }
    if (_user!.needsFarmSetup) {
      return CreateFarmScreen(
        farmRepository: _farmRepository,
        user: _user!,
        onFarmCreated: (farm) => setState(() => _user = _user!.withFarm(farm)),
        onSignOut: _onSignOut,
      );
    }
    return RoleHomeScreen(
      user: _user!,
      repositories: _repositories,
      onSignOut: _onSignOut,
      onUserUpdated: _onSignedIn,
    );
  }
}
