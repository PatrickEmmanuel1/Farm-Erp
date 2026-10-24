import 'package:flutter/material.dart';

import '../../data/model/crop.dart';
import '../../data/model/farm.dart';
import '../../data/repository/crop_repository.dart';
import '../../data/repository/division_repository.dart';
import '../../data/user_facing_error.dart';

class DivisionsScreen extends StatefulWidget {
  const DivisionsScreen({
    required this.farmId,
    required this.divisionRepository,
    required this.cropRepository,
    super.key,
  });

  final String farmId;
  final DivisionRepository divisionRepository;
  final CropRepository cropRepository;

  @override
  State<DivisionsScreen> createState() => _DivisionsScreenState();
}

class _DivisionsScreenState extends State<DivisionsScreen> {
  static const _background = Color(0xFFFAF6F0);
  static const _green = Color(0xFF1B5E20);

  late Future<_DivisionData> _data;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_DivisionData> _loadData() async {
    final result = await Future.wait([
      widget.divisionRepository.getDivisionsForFarm(widget.farmId),
      widget.cropRepository.getAssignedCropsByDivision(widget.farmId),
      widget.cropRepository.getCropCatalog(),
    ]);
    return _DivisionData(
      result[0] as List<Division>,
      result[1] as Map<String, List<String>>,
      result[2] as List<Crop>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _data = _loadData());
    await _data;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFacingError(error))),
    );
  }

  Future<void> _addDivision() async {
    final division = await showDialog<_DivisionInput>(
      context: context,
      builder: (context) => const _AddDivisionDialog(),
    );
    if (division == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.divisionRepository.createDivision(
        farmId: widget.farmId,
        name: division.name,
        size: division.size,
        units: division.units,
        soilPh: division.soilPh,
        soilHealth: division.soilHealth,
      );
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDivision(Division division) async {
    final id = division.divisionId;
    if (id == null || id.isEmpty) {
      _showError(StateError('This division is missing its identifier.'));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete division?'),
        content: Text('Remove ${division.name} from this farm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.divisionRepository.deleteDivision(id);
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignCrops(
    Division division,
    List<Crop> catalog,
  ) async {
    final divisionId = division.divisionId;
    if (divisionId == null || divisionId.isEmpty) {
      _showError(StateError('This division is missing its identifier.'));
      return;
    }
    final cropIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => _AssignCropsDialog(
        divisionName: division.name,
        availableCrops: catalog,
      ),
    );
    if (cropIds == null || cropIds.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      for (final cropId in cropIds) {
        await widget.cropRepository.assignCropToDivision(
          cropId: cropId,
          farmId: widget.farmId,
          divisionId: divisionId,
        );
      }
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Divisions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                'Manage farm partitions & field sections',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'refresh') _refresh();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              ],
            ),
          ],
        ),
        body: FutureBuilder<_DivisionData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userFacingError(snapshot.error!),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final data = snapshot.data!;
            final area = data.divisions.fold<double>(
              0,
              (total, division) => total + division.size,
            );
            final units = data.divisions
                .map((division) => division.units?.trim())
                .firstWhere(
                  (value) => value != null && value.isNotEmpty,
                  orElse: () => 'units',
                );
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                children: [
                  _DivisionSummary(
                    count: data.divisions.length,
                    totalArea: area,
                    units: units ?? 'units',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Farm Partitions',
                          style: TextStyle(
                            color: Color(0xFF25211F),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _addDivision,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF573D35),
                          side: const BorderSide(color: Color(0xFFD6C8D9)),
                          minimumSize: const Size(112, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text(
                          'Add Division',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (data.divisions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'No farm divisions created yet. Add a division to partition your farm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF705C55),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final division in data.divisions)
                      _DivisionCard(
                        division: division,
                        assignedCrops:
                            data.assignedCrops[division.divisionId] ?? const [],
                        onAssign: _busy
                            ? null
                            : () => _assignCrops(division, data.crops),
                        onDelete:
                            _busy ? null : () => _deleteDivision(division),
                      ),
                ],
              ),
            );
          },
        ),
      );
}

class _DivisionData {
  const _DivisionData(this.divisions, this.assignedCrops, this.crops);

  final List<Division> divisions;
  final Map<String, List<String>> assignedCrops;
  final List<Crop> crops;
}

class _DivisionInput {
  const _DivisionInput({
    required this.name,
    required this.size,
    required this.units,
    this.soilPh,
    this.soilHealth,
  });

  final String name;
  final double size;
  final String units;
  final double? soilPh;
  final String? soilHealth;
}

class _DivisionSummary extends StatelessWidget {
  const _DivisionSummary({
    required this.count,
    required this.totalArea,
    required this.units,
  });

  final int count;
  final double totalArea;
  final String units;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EAE5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F2E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.grid_on,
                color: Color(0xFF1B5E20),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Partition(s)',
                  style: const TextStyle(
                    color: Color(0xFF563D36),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Total partitioned area: ${_formatArea(totalArea)} $units',
                  style: const TextStyle(
                    color: Color(0xFF705C55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _DivisionCard extends StatelessWidget {
  const _DivisionCard({
    required this.division,
    required this.assignedCrops,
    required this.onAssign,
    required this.onDelete,
  });

  final Division division;
  final List<String> assignedCrops;
  final VoidCallback? onAssign;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EAE5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F2E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.landscape,
                    color: Color(0xFF1B5E20),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        division.name,
                        style: const TextStyle(
                          color: Color(0xFF563D36),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Size: ${_formatArea(division.size)} ${division.units ?? 'Acres'}',
                        style: const TextStyle(
                          color: Color(0xFF705C55),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete division',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete,
                    color: Color(0xFFB3261E),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.agriculture,
                  color: Color(0xFF1B5E20),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    assignedCrops.isEmpty
                        ? 'No crop assigned yet'
                        : 'Crops: ${assignedCrops.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: assignedCrops.isEmpty
                          ? const Color(0xFF705C55)
                          : const Color(0xFF3D312D),
                      fontSize: 9,
                      fontWeight: assignedCrops.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: onAssign,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF573D35),
                    side: const BorderSide(color: Color(0xFFD6C8D9)),
                    minimumSize: const Size(88, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'Assign Crop',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
            if (division.soilPh != null ||
                division.soilHealth?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (division.soilPh != null) ...[
                      const Icon(
                        Icons.science_outlined,
                        color: Color(0xFF1B5E20),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'pH: ${division.soilPh}',
                        style: const TextStyle(
                          color: Color(0xFF3D312D),
                          fontSize: 9,
                        ),
                      ),
                    ],
                    if (division.soilPh != null &&
                        division.soilHealth?.isNotEmpty == true)
                      const SizedBox(width: 14),
                    if (division.soilHealth?.isNotEmpty == true)
                      Text(
                        'Soil: ${division.soilHealth}',
                        style: const TextStyle(
                          color: Color(0xFF3D312D),
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _AssignCropsDialog extends StatefulWidget {
  const _AssignCropsDialog({
    required this.divisionName,
    required this.availableCrops,
  });

  final String divisionName;
  final List<Crop> availableCrops;

  @override
  State<_AssignCropsDialog> createState() => _AssignCropsDialogState();
}

class _AssignCropsDialogState extends State<_AssignCropsDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Assign Crop to ${widget.divisionName}'),
        content: widget.availableCrops.isEmpty
            ? const Text(
                'No registered crops found. Add crops in the Crops screen first.',
              )
            : SizedBox(
                width: 360,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final crop in widget.availableCrops)
                      CheckboxListTile(
                        value: _selected.contains(crop.cropId),
                        title: Text(crop.name),
                        subtitle: crop.scientificName?.isNotEmpty == true
                            ? Text(crop.scientificName!)
                            : null,
                        onChanged: crop.cropId == null
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selected.add(crop.cropId!);
                                  } else {
                                    _selected.remove(crop.cropId);
                                  }
                                });
                              },
                      ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (widget.availableCrops.isNotEmpty)
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected.toList()),
              child: const Text('Assign'),
            ),
        ],
      );
}

class _AddDivisionDialog extends StatefulWidget {
  const _AddDivisionDialog();

  @override
  State<_AddDivisionDialog> createState() => _AddDivisionDialogState();
}

class _AddDivisionDialogState extends State<_AddDivisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _units = TextEditingController(text: 'Acres');
  final _soilPh = TextEditingController();
  final _soilHealth = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    _units.dispose();
    _soilPh.dispose();
    _soilHealth.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _DivisionInput(
        name: _name.text.trim(),
        size: double.parse(_size.text.trim()),
        units: _units.text.trim(),
        soilPh: double.tryParse(_soilPh.text.trim()),
        soilHealth:
            _soilHealth.text.trim().isEmpty ? null : _soilHealth.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add Division'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Division name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a division name.'
                      : null,
                ),
                TextFormField(
                  controller: _size,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Size'),
                  validator: (value) {
                    final size = double.tryParse(value?.trim() ?? '');
                    return size == null || size <= 0
                        ? 'Enter a size greater than zero.'
                        : null;
                  },
                ),
                TextFormField(
                  controller: _units,
                  decoration: const InputDecoration(labelText: 'Size unit'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a size unit.'
                      : null,
                ),
                TextFormField(
                  controller: _soilPh,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Soil pH'),
                  validator: (value) => value == null ||
                          value.trim().isEmpty ||
                          double.tryParse(value.trim()) != null
                      ? null
                      : 'Enter a valid soil pH.',
                ),
                TextFormField(
                  controller: _soilHealth,
                  decoration: const InputDecoration(labelText: 'Soil health'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      );
}

String _formatArea(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';
