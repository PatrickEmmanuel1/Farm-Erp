import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/farm_operations_repository.dart';
import '../../data/repository/farm_repositories.dart';
import '../../data/user_facing_error.dart';
import '../farm/farm_details_screen.dart';
import '../notifications/notifications_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    required this.user,
    required this.repositories,
    required this.onSignOut,
    this.onUserUpdated,
    this.onBack,
    super.key,
  });

  final FarmUser user;
  final FarmRepositories repositories;
  final Future<void> Function() onSignOut;
  final ValueChanged<FarmUser>? onUserUpdated;
  final VoidCallback? onBack;

  Future<void> _openProfile(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _ManagerProfileScreen(
            user: user,
            onSignOut: onSignOut,
            onUserUpdated: onUserUpdated,
          ),
        ),
      );

  Future<void> _openFarmDetails(BuildContext context) async {
    final farm = user.farm;
    if (farm == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FarmDetailsScreen(
          farm: farm,
          repository: repositories.farms,
          onSaved: (updatedFarm) =>
              onUserUpdated?.call(user.withFarm(updatedFarm)),
        ),
      ),
    );
  }

  Future<void> _openNotifications(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(
            farmId: user.farmId ?? user.farm?.id ?? '',
            repository: repositories.notifications,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isManager = user.role.toLowerCase() == 'manager';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        leading: onBack == null
            ? null
            : IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Manage account & application preferences',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Account & Preferences',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          _SettingsOption(
            icon: Icons.person,
            title: isManager ? 'Manager Profile' : 'Profile',
            description: 'Update personal profile details',
            onTap: () => _openProfile(context),
          ),
          if (isManager && user.farm != null) ...[
            const SizedBox(height: 9),
            _SettingsOption(
              icon: Icons.agriculture,
              title: 'Farm Details',
              description:
                  'View & update farm configuration, size, and soil health',
              onTap: () => _openFarmDetails(context),
            ),
          ],
          const SizedBox(height: 9),
          _SettingsOption(
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Manage alerts and notification preferences',
            onTap: () => _openNotifications(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsOption extends StatelessWidget {
  const _SettingsOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFF4EAE5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F2E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1B5E20), size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF563D36),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF705C55),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF563D36),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ManagerProfileScreen extends StatefulWidget {
  const _ManagerProfileScreen({
    required this.user,
    required this.onSignOut,
    this.onUserUpdated,
  });

  final FarmUser user;
  final Future<void> Function() onSignOut;
  final ValueChanged<FarmUser>? onUserUpdated;

  @override
  State<_ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<_ManagerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _repository = FarmOperationsRepository(Supabase.instance.client);
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController =
        TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      await _repository.updateAccount(
        widget.user.id,
        {
          'full_name': _nameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
        },
      );
      final phone = _phoneController.text.trim();
      widget.onUserUpdated?.call(
        widget.user.copyWith(
          fullName: _nameController.text.trim(),
          phoneNumber: phone.isEmpty ? null : phone,
          clearPhoneNumber: phone.isEmpty,
        ),
      );
      if (mounted) setState(() => _message = 'Profile updated.');
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(widget.user.email);
      if (mounted) {
        setState(() => _message = 'Password reset instructions were sent.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Manager Profile')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.user.email,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => (value?.trim().isNotEmpty ?? false)
                        ? null
                        : 'Enter your name.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone number'),
                    keyboardType: TextInputType.phone,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Save profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _sendPasswordReset,
              child: const Text('Send password reset email'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      );
}
