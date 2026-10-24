import 'package:flutter/material.dart';

import '../../data/model/machinery.dart';
import '../../data/model/farm_user.dart';
import '../../data/repository/farm_operations_repository.dart';
import '../../data/repository/machinery_repository.dart';
import '../../data/user_facing_error.dart';
import '../common/farm_feature.dart';
import '../common/farm_feature_screen.dart';
import '../common/farm_features.dart';

class MachineryScreen extends StatefulWidget {
  const MachineryScreen({
    required this.user,
    required this.operationsRepository,
    required this.machineryRepository,
    super.key,
  });

  final FarmUser user;
  final FarmOperationsRepository operationsRepository;
  final MachineryRepository machineryRepository;

  @override
  State<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<MachineryScreen> {
  int _selectedTab = 0;
  late Future<List<Machinery>> _machinery;
  late Future<_MaintenanceData> _maintenance;

  String get _farmId => widget.user.farmId ?? widget.user.farm?.id ?? '';
  bool get _canManage => widget.user.role.toLowerCase() == 'manager';

  @override
  void initState() {
    super.initState();
    _machinery = widget.machineryRepository.getMachineryForFarm(_farmId);
    _maintenance = _loadMaintenance();
  }

  Future<_MaintenanceData> _loadMaintenance() async {
    final results = await Future.wait([
      widget.machineryRepository.getAllMaintenanceForFarm(_farmId),
      widget.machineryRepository.getMachineryForFarm(_farmId),
    ]);
    final machines = results[1] as List<Machinery>;
    return _MaintenanceData(
      results[0] as List<MachineryMaintenance>,
      {
        for (final machine in machines)
          if (machine.machineryId != null) machine.machineryId!: machine.name,
      },
    );
  }

  Future<void> _refreshMachinery() async {
    setState(
      () => _machinery = widget.machineryRepository.getMachineryForFarm(_farmId),
    );
    try {
      await _machinery;
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _refreshMaintenance() async {
    setState(() => _maintenance = _loadMaintenance());
    try {
      await _maintenance;
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFacingError(error))),
    );
  }

  Future<void> _openFeature(FarmFeature feature) async {
    final displayFeature = _canManage
        ? feature
        : FarmFeature(
            title: feature.title,
            table: feature.table,
            idColumn: feature.idColumn,
            fields: feature.fields,
            orderBy: feature.orderBy,
            readOnly: true,
            canCreate: false,
            canEditExisting: false,
            canDelete: false,
            showFarmId: feature.showFarmId,
            excludeDeleted: feature.excludeDeleted,
            softDelete: feature.softDelete,
            description: feature.description,
          );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FarmFeatureScreen(
          feature: displayFeature,
          repository: widget.operationsRepository,
          farmId: _farmId,
          machineryRepository: widget.machineryRepository,
          actorProfileId: widget.user.profileId,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshMachinery();
    await _refreshMaintenance();
  }

  Future<void> _showMachineryDetails(Machinery machine) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(machine.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(machine.machineryType),
              const SizedBox(height: 16),
              _DetailRow(label: 'Condition', value: machine.condition),
              _DetailRow(label: 'Status', value: machine.status),
              if (machine.brand?.isNotEmpty == true)
                _DetailRow(label: 'Brand', value: machine.brand!),
              if (machine.model?.isNotEmpty == true)
                _DetailRow(label: 'Model', value: machine.model!),
              if (_canManage) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openFeature(machineryFeature);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Manage machinery'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Machinery',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage farm machinery',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'usage') _openFeature(machineryUsageFeature);
              if (value == 'maintenance') {
                setState(() => _selectedTab = 1);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'usage', child: Text('Usage history')),
              PopupMenuItem(value: 'maintenance', child: Text('Maintenance')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Row(
            children: [
              _MachineryTab(
                icon: Icons.agriculture_outlined,
                label: 'All Machinery',
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _MachineryTab(
                icon: Icons.build_outlined,
                label: 'Maintenance',
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildMachineryList() : _buildMaintenanceList(),
    );
  }

  Widget _buildMachineryList() {
    return FutureBuilder<List<Machinery>>(
      future: _machinery,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadError(
            error: snapshot.error!,
            onRetry: _refreshMachinery,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }
        final machines = snapshot.data ?? const <Machinery>[];
        return RefreshIndicator(
          onRefresh: _refreshMachinery,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              _CountSummary(
                icon: Icons.agriculture,
                count: machines.length,
                label: 'Total machinery',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Farm Machinery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_canManage)
                    OutlinedButton.icon(
                      onPressed: () => _openFeature(machineryFeature),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (machines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No machinery recorded yet.'),
                ),
              for (final machine in machines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MachineryCard(
                    machine: machine,
                    onTap: () => _showMachineryDetails(machine),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceList() {
    return FutureBuilder<_MaintenanceData>(
      future: _maintenance,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadError(
            error: snapshot.error!,
            onRetry: _refreshMaintenance,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refreshMaintenance,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              _CountSummary(
                icon: Icons.build,
                count: data.records.length,
                label: 'Maintenance records',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Maintenance History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_canManage)
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openFeature(machineryMaintenanceFeature),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No maintenance recorded yet.'),
                ),
              for (final record in data.records)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MaintenanceCard(
                    record: record,
                    machineName:
                        data.machineNames[record.machineryId] ?? 'Machinery',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MaintenanceData {
  const _MaintenanceData(this.records, this.machineNames);

  final List<MachineryMaintenance> records;
  final Map<String, String> machineNames;
}

class _MachineryTab extends StatelessWidget {
  const _MachineryTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF1B5E20) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: selected
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFF6E7068),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF6E7068),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountSummary extends StatelessWidget {
  const _CountSummary({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EAE5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF65483E),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF65483E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MachineryCard extends StatelessWidget {
  const _MachineryCard({required this.machine, required this.onTap});

  final Machinery machine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5EAE5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      size: 22,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF65483E),
                          ),
                        ),
                        Text(
                          machine.machineryType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF65483E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.build,
                    size: 16,
                    color: Color(0xFF1B5E20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Condition\n${machine.condition}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF65483E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.record,
    required this.machineName,
  });

  final MachineryMaintenance record;
  final String machineName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EAE5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.build_circle_outlined, color: Color(0xFF1B5E20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(machineName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${record.maintenanceType} · ${record.maintenanceDate}'),
                Text(record.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(userFacingError(error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
