import 'package:flutter/material.dart';

import '../../../data/model/farm_user.dart';
import '../../../data/repository/farm_operations_repository.dart';
import '../../../data/user_facing_error.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({
    required this.user,
    required this.repository,
    required this.onSignOut,
    required this.onActivities,
    required this.onEmployees,
    required this.onAddCrop,
    required this.onCrops,
    required this.onResources,
    required this.onMachinery,
    required this.onStorageProduce,
    required this.onReports,
    required this.onDivisions,
    super.key,
  });

  final FarmUser user;
  final FarmOperationsRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback onActivities;
  final VoidCallback onEmployees;
  final VoidCallback onAddCrop;
  final VoidCallback onCrops;
  final VoidCallback onResources;
  final VoidCallback onMachinery;
  final VoidCallback onStorageProduce;
  final VoidCallback onReports;
  final VoidCallback onDivisions;

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  late Future<FarmDashboardSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.repository.loadDashboardSummary(_farmId);
  }

  String get _farmId => widget.user.farmId ?? widget.user.farm?.id ?? '';

  Future<void> _refresh() async {
    setState(() => _summary = widget.repository.loadDashboardSummary(_farmId));
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

  String _farmSize(double size) =>
      size == size.roundToDouble() ? size.toInt().toString() : size.toString();

  @override
  Widget build(BuildContext context) {
    final farm = widget.user.farm;
    final firstName = widget.user.fullName.trim().split(RegExp(r'\s+')).first;
    final initial = firstName.isEmpty ? '?' : firstName[0].toUpperCase();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F0),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6E7068),
                        ),
                      ),
                      Text(
                        firstName,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D1A),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Account options',
                  onSelected: (value) {
                    if (value == 'sign_out') _signOut();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'sign_out',
                      child: Text('Sign out'),
                    ),
                  ],
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<FarmDashboardSummary>(
              future: _summary,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _SummaryError(
                    message: userFacingError(snapshot.error!),
                    onRetry: _refresh,
                  );
                }
                final summary = snapshot.data;
                return _OverviewCard(
                  farmName: farm?.name ?? 'My farm',
                  farmSize: farm == null ? '--' : _farmSize(farm.size),
                  farmUnit: farm?.unit ?? '',
                  divisions: summary?.totalDivisions,
                  pending: summary?.pendingActivities,
                  onDivisions: widget.onDivisions,
                  onActivities: widget.onActivities,
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D1A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickAction(
                  icon: Icons.add,
                  label: 'Add Crop',
                  onTap: widget.onAddCrop,
                ),
                _QuickAction(
                  icon: Icons.format_list_bulleted,
                  label: 'Log Activity',
                  onTap: widget.onActivities,
                ),
                _QuickAction(
                  icon: Icons.person_add_alt_1,
                  label: 'Add Worker',
                  onTap: widget.onEmployees,
                ),
                _QuickAction(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  onTap: widget.onReports,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Farm Operations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D1A),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<FarmDashboardSummary>(
              future: _summary,
              builder: (context, snapshot) {
                final summary = snapshot.data;
                if (summary == null) {
                  if (snapshot.hasError) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _OperationCard(
                            icon: Icons.spa,
                            iconBackground: const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF2E7D32),
                            value: summary.totalCrops,
                            label: 'Crops',
                            onTap: widget.onCrops,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OperationCard(
                            icon: Icons.groups,
                            iconBackground: const Color(0xFFE3F2FD),
                            iconColor: const Color(0xFF1976D2),
                            value: summary.totalWorkers,
                            label: 'Workers',
                            onTap: widget.onEmployees,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _OperationCard(
                            icon: Icons.inventory_2,
                            iconBackground: const Color(0xFFFFF8E1),
                            iconColor: const Color(0xFFF57F17),
                            value: summary.totalInventory,
                            label: 'Total Resources',
                            onTap: widget.onResources,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OperationCard(
                            icon: Icons.precision_manufacturing,
                            iconBackground: const Color(0xFFFBE9E7),
                            iconColor: const Color(0xFFE64A19),
                            value: summary.totalMachinery,
                            label: 'Total Machinery',
                            onTap: widget.onMachinery,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StorageCard(
                      value: summary.totalStorage,
                      onTap: widget.onStorageProduce,
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.farmName,
    required this.farmSize,
    required this.farmUnit,
    required this.divisions,
    required this.pending,
    required this.onDivisions,
    required this.onActivities,
  });

  final String farmName;
  final String farmSize;
  final String farmUnit;
  final int? divisions;
  final int? pending;
  final VoidCallback onDivisions;
  final VoidCallback onActivities;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF277A3C), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terrain, size: 18, color: Color(0xFFA5D6A7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  farmName.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA5D6A7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Farm Overview',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(value: farmSize, label: farmUnit),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewStat(
                  value: divisions?.toString() ?? '—',
                  label: 'Divisions',
                  onTap: onDivisions,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewStat(
                  value: pending?.toString() ?? '—',
                  label: 'Pending',
                  onTap: onActivities,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1B5E20), size: 25),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C312D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8E7E1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF9E9E9E),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1A),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6E7068),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warehouse,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1A),
                      ),
                    ),
                    const Text(
                      'Storage Produce',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6E7068),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
