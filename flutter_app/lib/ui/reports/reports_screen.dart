import 'package:flutter/material.dart';

import '../../data/model/model_parsing.dart';
import '../../data/model/report.dart';
import '../../data/repository/report_repository.dart';
import '../../data/user_facing_error.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    required this.farmId,
    required this.repository,
    super.key,
  });

  final String farmId;
  final ReportRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<ReportCategoryStatus>> _categories;
  String? _selectedCode;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categories = widget.repository.getCategories(widget.farmId);
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _categories = widget.repository.getCategories(widget.farmId);
    });
    await _categories;
  }

  Future<void> _generate(ReportCategoryStatus category) async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final report = await widget.repository.generate(
        farmId: widget.farmId,
        categoryCode: category.code,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReportDetailsScreen(
            report: report,
            category: category,
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _openHistory(ReportCategoryStatus category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportHistoryScreen(
          farmId: widget.farmId,
          category: category,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          actions: [
            IconButton(
              tooltip: 'Refresh reports',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<ReportCategoryStatus>>(
          future: _categories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorPanel(
                message: userFacingError(snapshot.error!),
                onRetry: _refresh,
              );
            }
            final categories = snapshot.data ?? const [];
            if (categories.isEmpty) {
              return const Center(
                child:
                    Text('No report categories are configured for this farm.'),
              );
            }
            final selected = categories.where(
              (category) => category.code == _selectedCode,
            );
            final category =
                selected.isNotEmpty ? selected.first : categories.first;
            if (_selectedCode != category.code) _selectedCode = category.code;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Generate a farm report',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category.code,
                  decoration:
                      const InputDecoration(labelText: 'Report category'),
                  items: [
                    for (final item in categories)
                      DropdownMenuItem(
                        value: item.code,
                        child: Text(item.name),
                      ),
                  ],
                  onChanged: _generating
                      ? null
                      : (value) => setState(() => _selectedCode = value),
                ),
                const SizedBox(height: 8),
                Text(category.description),
                if (category.lastGeneratedAt != null)
                  Text('Last generated: ${category.lastGeneratedAt}'),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _generating ? null : () => _generate(category),
                  icon: const Icon(Icons.assessment_outlined),
                  label: Text(_generating ? 'Generating…' : 'Generate report'),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Report history'),
                    subtitle: Text(
                        'Browse saved ${category.name.toLowerCase()} reports.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openHistory(category),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({
    required this.farmId,
    required this.category,
    required this.repository,
    super.key,
  });

  final String farmId;
  final ReportCategoryStatus category;
  final ReportRepository repository;

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late Future<List<ReportRecord>> _reports;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reports = _load();
  }

  Future<List<ReportRecord>> _load() => widget.repository.getHistory(
        farmId: widget.farmId,
        categoryId: widget.category.categoryId,
        limit: 100,
      );

  Future<void> _refresh() async {
    setState(() => _reports = _load());
    await _reports;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.category.name} history')),
        body: FutureBuilder<List<ReportRecord>>(
          future: _reports,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorPanel(
                message: userFacingError(snapshot.error!),
                onRetry: _refresh,
              );
            }
            final reports = (snapshot.data ?? const []).where((report) {
              final query = _query.trim().toLowerCase();
              return query.isEmpty ||
                  report.generatedAt.toLowerCase().contains(query) ||
                  (report.periodStart?.toLowerCase().contains(query) ??
                      false) ||
                  (report.periodEnd?.toLowerCase().contains(query) ?? false) ||
                  report.status.toLowerCase().contains(query);
            }).toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Filter by date or status',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 8),
                  if (reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          Center(child: Text('No reports match this filter.')),
                    ),
                  for (final report in reports)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(_formatDate(report.generatedAt)),
                        subtitle: Text(
                          '${report.status}'
                          '${report.periodStart == null ? '' : ' · ${report.periodStart}'}'
                          '${report.periodEnd == null ? '' : ' to ${report.periodEnd}'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportDetailsScreen(
                              report: report,
                              category: widget.category,
                            ),
                          ),
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

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({
    required this.report,
    required this.category,
    super.key,
  });

  final ReportRecord report;
  final ReportCategoryStatus category;

  @override
  Widget build(BuildContext context) {
    final summary = ReportSummary.fromJson(category.code, report.summary);
    final metrics = _reportMetrics(summary);
    final breakdown = _reportBreakdown(summary);
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: Text('Generated ${_formatDate(report.generatedAt)}'),
              subtitle: Text(
                '${report.status} · ${_periodLabel(report)}',
              ),
            ),
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Key metrics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final metric in metrics)
              Card(
                child: ListTile(
                  title: Text(metric.$1),
                  trailing: Text(
                    metric.$2,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
          ],
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _ReportBars(rows: breakdown),
          ],
          if (report.summary.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child:
                  Center(child: Text('This report contains no summary data.')),
            ),
        ],
      ),
    );
  }
}

List<(String, String)> _reportMetrics(ReportSummary summary) {
  switch (summary) {
    case CropYieldSummary value:
      final totalsByUnit = <String, double>{};
      for (final row in value.harvestTotals) {
        final unit = stringValue(row, 'unit') ?? 'units';
        final quantity = doubleValue(row, 'quantity') ?? 0;
        totalsByUnit.update(
          unit,
          (total) => total + quantity,
          ifAbsent: () => quantity,
        );
      }
      return [
        ('Total plantings', '${value.totalPlantings}'),
        for (final total in totalsByUnit.entries)
          ('Harvested (${total.key})', total.value.toStringAsFixed(1)),
        ('Crops logged', '${value.byCrop.length}'),
        ('Divisions covered', '${value.byDivision.length}'),
      ];
    case InventorySummary value:
      return [
        ('Inventory items', '${value.totalItems}'),
        ('Low stock', '${value.lowStockCount}'),
        ('Out of stock', '${value.outOfStockCount}'),
        ('Expired', '${value.expiredCount}'),
      ];
    case MachinerySummary value:
      return [
        ('Usage sessions', '${value.usageSessions}'),
        ('Hours used', value.totalHoursUsed.toStringAsFixed(1)),
        ('Machines used', '${value.machinesUsed}'),
        (
          'Maintenance records',
          '${intValue(value.maintenance, 'records_in_period') ?? 0}'
        ),
      ];
    case WorkforceSummary value:
      return [
        ('Workers', '${value.totalWorkers}'),
        ('Hours worked', value.totalHoursWorked.toStringAsFixed(1)),
        ('Activities assigned', '${value.activitiesAssigned}'),
        (
          'Completion rate',
          '${(value.overallCompletionRatePct ?? 0).toStringAsFixed(1)}%'
        ),
      ];
    case StorageSummary value:
      return [
        ('Storage facilities', '${value.facilities.length}'),
        ('Produce groups', '${value.produceByCrop.length}'),
        ('Near-expiry lots', '${value.nearExpiryLots.length}'),
      ];
  }
}

List<(String, double)> _reportBreakdown(ReportSummary summary) {
  final rows = switch (summary) {
    CropYieldSummary value => value.byCrop
        .map((row) => (
              '${stringValue(row, 'crop_name') ?? 'Crop'} '
                  '(${stringValue(row, 'unit') ?? 'units'})',
              doubleValue(row, 'harvested') ?? 0,
            ))
        .toList(),
    InventorySummary value => value.byCategory
        .map((row) => (
              stringValue(row, 'category') ?? 'Category',
              doubleValue(row, 'items') ?? 0,
            ))
        .toList(),
    MachinerySummary value => value.byMachine
        .map((row) => (
              stringValue(row, 'machine_name') ??
                  stringValue(row, 'name') ??
                  'Machine',
              doubleValue(row, 'hours_used') ?? 0,
            ))
        .toList(),
    WorkforceSummary value => value.activitiesByCategory
        .map((row) => (
              stringValue(row, 'category') ?? 'Activity',
              doubleValue(row, 'activities_completed') ??
                  doubleValue(row, 'completed') ??
                  0,
            ))
        .toList(),
    StorageSummary value => value.produceByCrop
        .map((row) => (
              stringValue(row, 'crop_name') ?? 'Crop',
              doubleValue(row, 'quantity') ??
                  doubleValue(row, 'quantity_stored') ??
                  0,
            ))
        .toList(),
  };
  return rows.where((row) => row.$2 > 0).toList();
}

String _periodLabel(ReportRecord report) {
  if (report.periodStart == null && report.periodEnd == null) return 'All time';
  return '${report.periodStart ?? 'Start'} to ${report.periodEnd ?? 'Present'}';
}

String _formatDate(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _ReportBars extends StatelessWidget {
  const _ReportBars({required this.rows});

  final List<(String, double)> rows;

  @override
  Widget build(BuildContext context) {
    final maxValue =
        rows.fold<double>(0, (max, row) => row.$2 > max ? row.$2 : max);
    return Column(
      children: [
        for (final row in rows)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(row.$1)),
                      Text(row.$2.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: maxValue == 0 ? 0 : row.$2 / maxValue,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
