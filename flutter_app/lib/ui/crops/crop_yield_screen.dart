import 'package:flutter/material.dart';

import '../../data/model/crop.dart';
import '../../data/repository/crop_repository.dart';
import '../../data/user_facing_error.dart';

class CropYieldScreen extends StatefulWidget {
  const CropYieldScreen({
    required this.farmId,
    required this.repository,
    super.key,
  });

  final String farmId;
  final CropRepository repository;

  @override
  State<CropYieldScreen> createState() => _CropYieldScreenState();
}

class _YieldData {
  const _YieldData(this.harvests, this.plantings);

  final List<CropHarvestDisplay> harvests;
  final List<CropPlantingDisplay> plantings;
}

class _CropYieldScreenState extends State<CropYieldScreen> {
  late Future<_YieldData> _data;
  String _gradeFilter = 'All';
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_YieldData> _load() async {
    final results = await Future.wait([
      widget.repository.getCropHarvestsForFarm(widget.farmId),
      widget.repository.getCropPlantingsForFarm(widget.farmId),
    ]);
    return _YieldData(
      results[0] as List<CropHarvestDisplay>,
      results[1] as List<CropPlantingDisplay>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _data = _load());
    await _data;
  }

  Future<CropHarvest?> _showRecordDialog(
    List<CropPlantingDisplay> plantings,
  ) async {
    final active = plantings.where((display) {
      final status = display.planting.plantingStatus.toLowerCase();
      return !{'completed', 'harvested', 'closed', 'cancelled'}
          .contains(status);
    }).toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('There are no active plantings to harvest.')),
      );
      return null;
    }

    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final unitController = TextEditingController(
      text: active.first.planting.quantityUnit ?? 'kg',
    );
    final notesController = TextEditingController();
    String? selectedPlantingId = active.first.planting.plantingId;
    String? grade;
    final dateController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final result = await showDialog<CropHarvest>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record harvest'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedPlantingId,
                      decoration: const InputDecoration(labelText: 'Planting'),
                      items: [
                        for (final display in active)
                          if (display.planting.plantingId != null)
                            DropdownMenuItem(
                              value: display.planting.plantingId,
                              child: Text(
                                '${display.cropName} · ${display.divisionName} · '
                                '${display.planting.plantingDate}',
                              ),
                            ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedPlantingId = value),
                      validator: (value) =>
                          value == null ? 'Select a planting.' : null,
                    ),
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Harvest date (YYYY-MM-DD)',
                      ),
                      validator: (value) =>
                          DateTime.tryParse(value ?? '') == null
                              ? 'Enter a valid date.'
                              : null,
                    ),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                          labelText: 'Quantity harvested'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final parsed = double.tryParse(value?.trim() ?? '');
                        return parsed == null || parsed <= 0
                            ? 'Enter a positive quantity.'
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      validator: (value) => value?.trim().isNotEmpty == true
                          ? null
                          : 'Enter a unit.',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: grade,
                      decoration:
                          const InputDecoration(labelText: 'Quality grade'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Not rated')),
                        DropdownMenuItem(
                            value: 'Grade A', child: Text('Grade A')),
                        DropdownMenuItem(
                            value: 'Grade B', child: Text('Grade B')),
                        DropdownMenuItem(
                            value: 'Export Grade', child: Text('Export Grade')),
                        DropdownMenuItem(
                            value: 'Premium', child: Text('Premium')),
                      ],
                      onChanged: (value) => setDialogState(() => grade = value),
                    ),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final planting = active.firstWhere(
                  (entry) => entry.planting.plantingId == selectedPlantingId,
                );
                final plantingId = planting.planting.plantingId;
                if (plantingId == null) return;
                Navigator.pop(
                  context,
                  CropHarvest(
                    plantingId: plantingId,
                    farmId: widget.farmId,
                    divisionId: planting.planting.divisionId,
                    harvestDate: dateController.text.trim(),
                    quantityHarvested:
                        double.parse(quantityController.text.trim()),
                    quantityUnit: unitController.text.trim(),
                    qualityGrade: grade,
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Save harvest'),
            ),
          ],
        ),
      ),
    );
    quantityController.dispose();
    unitController.dispose();
    notesController.dispose();
    dateController.dispose();
    return result;
  }

  Future<void> _recordHarvest(List<CropPlantingDisplay> plantings) async {
    final harvest = await _showRecordDialog(plantings);
    if (harvest == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.repository.recordCropHarvest(harvest);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harvest recorded.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Crop yields & harvests'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<_YieldData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(userFacingError(snapshot.error!)),
                    TextButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              );
            }
            final data = snapshot.data!;
            final grades = data.harvests
                .map((entry) => entry.harvest.qualityGrade)
                .whereType<String>()
                .where((value) => value.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final query = _query.trim().toLowerCase();
            final harvests = data.harvests.where((entry) {
              final gradeMatches = _gradeFilter == 'All' ||
                  entry.harvest.qualityGrade == _gradeFilter;
              final queryMatches = query.isEmpty ||
                  entry.cropName.toLowerCase().contains(query) ||
                  entry.divisionName.toLowerCase().contains(query);
              return gradeMatches && queryMatches;
            }).toList();
            final totalsByUnit = <String, double>{};
            final totalsByCrop = <String, double>{};
            for (final entry in harvests) {
              final unit = entry.harvest.quantityUnit;
              totalsByUnit.update(
                  unit, (value) => value + entry.harvest.quantityHarvested,
                  ifAbsent: () => entry.harvest.quantityHarvested);
              final cropUnit = '${entry.cropName} ($unit)';
              totalsByCrop.update(
                cropUnit,
                (value) => value + entry.harvest.quantityHarvested,
                ifAbsent: () => entry.harvest.quantityHarvested,
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _YieldMetric(
                          title: 'Harvest records',
                          value: harvests.length.toString(),
                          icon: Icons.agriculture_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _YieldMetric(
                          title: 'Active plantings',
                          value: data.plantings
                              .where((entry) => !{
                                    'completed',
                                    'harvested',
                                    'closed',
                                    'cancelled',
                                  }.contains(
                                    entry.planting.plantingStatus.toLowerCase(),
                                  ))
                              .length
                              .toString(),
                          icon: Icons.spa_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final total in totalsByUnit.entries)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.scale_outlined),
                        title: Text('Harvested ${total.key}'),
                        trailing: Text(total.value.toStringAsFixed(1)),
                      ),
                    ),
                  if (totalsByCrop.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Yield by crop',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _YieldBars(values: totalsByCrop),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        _saving ? null : () => _recordHarvest(data.plantings),
                    icon: const Icon(Icons.add),
                    label: Text(_saving ? 'Saving…' : 'Record harvest'),
                  ),
                  const SizedBox(height: 20),
                  Text('Harvest log',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search crop or division',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final grade in ['All', ...grades])
                        ChoiceChip(
                          label: Text(grade),
                          selected: _gradeFilter == grade,
                          onSelected: (_) =>
                              setState(() => _gradeFilter = grade),
                        ),
                    ],
                  ),
                  if (harvests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: Text('No harvests match these filters.')),
                    ),
                  for (final entry in harvests)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.grass_outlined),
                        title: Text(entry.cropName),
                        subtitle: Text(
                          '${entry.divisionName} · ${entry.harvest.harvestDate}'
                          '${entry.harvest.qualityGrade == null ? '' : ' · ${entry.harvest.qualityGrade}'}'
                          '${entry.harvest.notes?.isNotEmpty == true ? '\n${entry.harvest.notes}' : ''}',
                        ),
                        isThreeLine: entry.harvest.notes?.isNotEmpty == true,
                        trailing: Text(
                          '${entry.harvest.quantityHarvested.toStringAsFixed(1)} '
                          '${entry.harvest.quantityUnit}',
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
}

class _YieldMetric extends StatelessWidget {
  const _YieldMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      );
}

class _YieldBars extends StatelessWidget {
  const _YieldBars({required this.values});

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values
        .fold<double>(0, (max, value) => value > max ? value : max);
    return Column(
      children: [
        for (final entry in values.entries)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text(entry.value.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: maxValue == 0 ? 0 : entry.value / maxValue,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
