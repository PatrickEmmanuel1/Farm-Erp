import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/repository/farm_operations_repository.dart';
import '../../data/repository/machinery_repository.dart';
import '../../data/user_facing_error.dart';
import 'farm_feature.dart';

class FarmFeatureScreen extends StatefulWidget {
  const FarmFeatureScreen({
    required this.feature,
    required this.repository,
    required this.farmId,
    this.openCreateOnLoad = false,
    this.machineryRepository,
    this.actorProfileId,
    super.key,
  });

  final FarmFeature feature;
  final FarmOperationsRepository repository;
  final String farmId;
  final bool openCreateOnLoad;
  final MachineryRepository? machineryRepository;
  final String? actorProfileId;

  @override
  State<FarmFeatureScreen> createState() => _FarmFeatureScreenState();
}

class _FarmFeatureScreenState extends State<FarmFeatureScreen> {
  static const _uuid = Uuid();
  late Future<List<Map<String, dynamic>>> _rows;
  String? _error;
  String _query = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _rows = _loadRows();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openForm();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadRows() {
    return widget.repository.fetchRows(
      widget.feature.table,
      farmId: widget.feature.showFarmId ? widget.farmId : null,
      orderBy: widget.feature.orderBy,
      excludeDeleted: widget.feature.excludeDeleted,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _rows = _loadRows();
    });
    try {
      await _rows;
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    }
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final values = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FarmFeatureForm(
        feature: widget.feature,
        repository: widget.repository,
        farmId: widget.farmId,
        initialRow: row,
      ),
    );
    if (values == null || !mounted) return;

    try {
      if (row == null) {
        await widget.repository.insert(widget.feature.table, {
          widget.feature.idColumn: _uuid.v4(),
          if (widget.feature.showFarmId && widget.farmId.isNotEmpty)
            'farm_id': widget.farmId,
          ...values,
        });
      } else {
        final id = row[widget.feature.idColumn]?.toString();
        if (id == null || id.isEmpty) {
          throw StateError('This record is missing its identifier.');
        }
        await widget.repository.update(
          widget.feature.table,
          idColumn: widget.feature.idColumn,
          id: id,
          values: values,
        );
      }
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    }
  }

  Future<void> _deleteRow(Map<String, dynamic> row) async {
    final id = row[widget.feature.idColumn]?.toString();
    if (id == null || id.isEmpty) {
      setState(() => _error = 'This record is missing its identifier.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.feature.title.toLowerCase()}?'),
        content:
            const Text('This record will be removed from the active list.'),
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

    try {
      if (widget.feature.softDelete) {
        await widget.repository.softDelete(
          widget.feature.table,
          idColumn: widget.feature.idColumn,
          id: id,
        );
      } else {
        await widget.repository.deleteRow(
          widget.feature.table,
          idColumn: widget.feature.idColumn,
          id: id,
        );
      }
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    }
  }

  Future<void> _showDetails(Map<String, dynamic> row) async {
    final titleField = widget.feature.fields.firstOrNull?.column;
    final title = row[titleField]?.toString().trim();
    final entries = row.entries
        .where(
          (entry) => entry.value != null && entry.value.toString().isNotEmpty,
        )
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title?.isNotEmpty == true ? title! : widget.feature.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      for (final entry in entries)
                        ListTile(
                          dense: true,
                          title: Text(_labelFor(entry.key)),
                          subtitle: SelectableText(entry.value.toString()),
                        ),
                    ],
                  ),
                ),
                if (!widget.feature.readOnly &&
                    (widget.feature.canEditExisting ||
                        widget.feature.canDelete ||
                        _canChangeMachineryLifecycle(row))) ...[
                  if (_canChangeMachineryLifecycle(row))
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _changeMachineryLifecycle(row);
                      },
                      icon: const Icon(Icons.block_outlined),
                      label: Text(
                        widget.feature.table == 'machinery_usage'
                            ? 'Void usage record'
                            : 'Cancel maintenance',
                      ),
                    ),
                  if (widget.feature.canEditExisting)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openForm(row);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit record'),
                    ),
                  if (widget.feature.canDelete)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteRow(row);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete record'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(String column) => column
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Future<void> _changeMachineryLifecycle(Map<String, dynamic> row) async {
    final repository = widget.machineryRepository;
    final actorId = widget.actorProfileId;
    if (repository == null || actorId == null || actorId.isEmpty) return;
    final isUsage = widget.feature.table == 'machinery_usage';
    final recordId = row[isUsage ? 'usage_id' : 'maintenance_id']?.toString();
    if (recordId == null || recordId.isEmpty) {
      setState(() => _error = 'This record is missing its identifier.');
      return;
    }
    final reason = await _reasonDialog(
      title: isUsage ? 'Void usage record' : 'Cancel maintenance record',
      label: isUsage ? 'Reason for voiding' : 'Reason for cancellation',
    );
    if (reason == null || !mounted) return;
    try {
      if (isUsage) {
        await repository.voidMachineryUsage(
          usageId: recordId,
          voidedBy: actorId,
          reason: reason,
        );
      } else {
        await repository.cancelMaintenance(
          maintenanceId: recordId,
          cancelledBy: actorId,
          reason: reason,
        );
      }
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    }
  }

  Future<String?> _reasonDialog({
    required String title,
    required String label,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            minLines: 2,
            maxLines: 4,
            validator: (value) => value?.trim().isNotEmpty == true
                ? null
                : 'A reason is required.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep record'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  bool _canChangeMachineryLifecycle(Map<String, dynamic> row) {
    if (widget.machineryRepository == null ||
        widget.actorProfileId?.isNotEmpty != true) {
      return false;
    }
    final table = widget.feature.table;
    final activeValue =
        row[table == 'machinery_usage' ? 'is_voided' : 'is_cancelled'];
    final isInactive =
        activeValue == true || activeValue?.toString().toLowerCase() == 'true';
    return !isInactive &&
        (table == 'machinery_usage' || table == 'machinery_maintenance');
  }

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;
    return Scaffold(
      appBar: AppBar(
        title: Text(feature.title),
        actions: [
          if (!feature.readOnly && feature.canCreate)
            IconButton(
              tooltip: 'Add ${feature.title.toLowerCase()}',
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: Column(
        children: [
          if (feature.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(feature.description!),
              ),
            ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _rows,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LoadError(
                    message: userFacingError(snapshot.error!),
                    onRetry: _refresh,
                  );
                }
                final rows = snapshot.data ?? const [];
                final statusColumn = [
                  'status',
                  'planting_status',
                  'is_active',
                  'is_deleted',
                ]
                    .where((column) => rows.any((row) => row[column] != null))
                    .firstOrNull;
                final statuses = statusColumn == null
                    ? <String>[]
                    : (rows
                        .map((row) => row[statusColumn].toString())
                        .toSet()
                        .toList()
                      ..sort());
                final query = _query.trim().toLowerCase();
                final visibleRows = rows.where((row) {
                  final matchesQuery = query.isEmpty ||
                      row.entries.any((entry) =>
                          entry.value
                              ?.toString()
                              .toLowerCase()
                              .contains(query) ??
                          false);
                  final matchesStatus = _statusFilter == 'All' ||
                      row[statusColumn]?.toString() == _statusFilter;
                  return matchesQuery && matchesStatus;
                }).toList();
                if (rows.isEmpty) {
                  return _EmptyFeature(
                    title: feature.title,
                    canCreate: !feature.readOnly && feature.canCreate,
                    onCreate: () => _openForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          labelText: 'Search ${feature.title.toLowerCase()}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      if (statuses.length > 1) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final value in ['All', ...statuses])
                              ChoiceChip(
                                label: Text(value),
                                selected: _statusFilter == value,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = value),
                              ),
                          ],
                        ),
                      ],
                      if (visibleRows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                              child: Text('No records match these filters.')),
                        ),
                      for (final row in visibleRows)
                        Builder(builder: (context) {
                          final titleField = feature.fields.firstOrNull?.column;
                          final title = row[titleField]?.toString().trim();
                          final subtitle = feature.fields
                              .skip(1)
                              .map((field) {
                                final value = row[field.column]?.toString();
                                return value == null || value.isEmpty
                                    ? null
                                    : '${field.label}: $value';
                              })
                              .whereType<String>()
                              .take(2)
                              .join(' · ');
                          return Card(
                            child: ListTile(
                              title: Text(
                                title?.isNotEmpty == true
                                    ? title!
                                    : feature.title,
                              ),
                              subtitle:
                                  subtitle.isEmpty ? null : Text(subtitle),
                              trailing: feature.readOnly ||
                                      (!feature.canEditExisting &&
                                          !feature.canDelete)
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (action) {
                                        if (action == 'edit' &&
                                            feature.canEditExisting) {
                                          _openForm(row);
                                        }
                                        if (action == 'delete' &&
                                            feature.canDelete) {
                                          _deleteRow(row);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (feature.canEditExisting)
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                        if (feature.canDelete)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                      ],
                                    ),
                              onTap: () => _showDetails(row),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmFeatureForm extends StatefulWidget {
  const _FarmFeatureForm({
    required this.feature,
    required this.repository,
    required this.farmId,
    this.initialRow,
  });

  final FarmFeature feature;
  final FarmOperationsRepository repository;
  final String farmId;
  final Map<String, dynamic>? initialRow;

  @override
  State<_FarmFeatureForm> createState() => _FarmFeatureFormState();
}

class _FarmFeatureFormState extends State<_FarmFeatureForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _options = <String, List<Map<String, dynamic>>>{};
  final _selectedOptions = <String, String?>{};
  bool _loadingOptions = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in widget.feature.fields) {
      final value = widget.initialRow?[field.column]?.toString() ??
          field.initialValue ??
          '';
      _controllers[field.column] = TextEditingController(text: value);
      if (field.kind == FarmFieldKind.choice) {
        _selectedOptions[field.column] = value.isEmpty ? null : value;
      }
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      for (final field in widget.feature.fields) {
        if (field.referenceTable == null) continue;
        final referenceTable = field.referenceTable!;
        final rows = switch (referenceTable) {
          'worker_profile' ||
          'supervisor_profile' =>
            await widget.repository.fetchEmployeeProfileRows(
              referenceTable,
              widget.farmId,
            ),
          _ => await widget.repository.fetchReferenceRows(
              referenceTable,
              farmId: field.referenceFarmScoped ? widget.farmId : null,
              labelColumn: field.referenceLabelColumn,
            ),
        };
        _options[field.column] = rows;
      }
    } catch (error) {
      _error = userFacingError(error);
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(FarmField field) async {
    final current = DateTime.tryParse(_controllers[field.column]!.text);
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      _controllers[field.column]!.text =
          '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final values = <String, dynamic>{};
    for (final field in widget.feature.fields) {
      final text = field.kind == FarmFieldKind.choice
          ? _selectedOptions[field.column]
          : _controllers[field.column]!.text.trim();
      if (text == null || text.isEmpty) continue;
      if (field.kind == FarmFieldKind.number) {
        final parsed = num.tryParse(text);
        if (parsed == null) {
          setState(() {
            _saving = false;
            _error = '${field.label} must be a number.';
          });
          return;
        }
        values[field.column] = parsed;
      } else if (field.kind == FarmFieldKind.boolean) {
        if (text != 'true' && text != 'false') {
          setState(() {
            _saving = false;
            _error = '${field.label} must be true or false.';
          });
          return;
        }
        values[field.column] = text == 'true';
      } else {
        values[field.column] = text;
      }
    }
    Navigator.of(context).pop(values);
  }

  Widget _buildCropField(FarmField field) {
    final fieldName = field.column;
    final label = switch (fieldName) {
      'name' => 'Crop Name *',
      'scientific_name' => 'Scientific Name (Optional)',
      'description' => 'Additional Notes (Optional)',
      _ => field.label,
    };

    final icon = switch (fieldName) {
      'name' => Icons.spa_outlined,
      'scientific_name' => Icons.science_outlined,
      'description' => Icons.sticky_note_2_outlined,
      _ => Icons.edit_note_outlined,
    };

    final controller = _controllers[fieldName]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: field.kind == FarmFieldKind.number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        minLines: field.kind == FarmFieldKind.multiline ? 3 : 1,
        maxLines: field.kind == FarmFieldKind.multiline ? 5 : 1,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (field.required && text.isEmpty) {
            return 'Enter ${field.label.toLowerCase()}.';
          }
          if (field.kind == FarmFieldKind.number &&
              text.isNotEmpty &&
              num.tryParse(text) == null) {
            return 'Enter a valid number.';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF0E7A5A)),
          hintText: label,
          hintStyle: const TextStyle(
            color: Color(0xFF4B584F),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCED6CD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCED6CD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0E7A5A), width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialRow != null;
    final isCropCreate = widget.feature.table == 'crop' && !editing;

    if (isCropCreate) {
      return Container(
        color: const Color(0xFFF5F5F3),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F3),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF0E7A5A),
                elevation: 0,
                toolbarHeight: 110,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Expanded(
                        child: Text(
                          'Add Crop',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_loadingOptions)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ...widget.feature.fields.map(_buildCropField),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0E7A5A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Crop',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${editing ? 'Edit' : 'Add'} ${widget.feature.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (_loadingOptions)
                  const LinearProgressIndicator()
                else ...[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  for (final field in widget.feature.fields) ...[
                    _buildField(field),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(editing ? 'Save changes' : 'Create'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(FarmField field) {
    final options = _options[field.column];
    if (field.kind == FarmFieldKind.boolean) {
      return DropdownButtonFormField<bool>(
        initialValue: _controllers[field.column]!.text == 'true'
            ? true
            : _controllers[field.column]!.text == 'false'
                ? false
                : null,
        decoration: InputDecoration(labelText: field.label),
        items: const [
          DropdownMenuItem(value: true, child: Text('Yes')),
          DropdownMenuItem(value: false, child: Text('No')),
        ],
        onChanged: (value) {
          _controllers[field.column]!.text = value?.toString() ?? '';
          setState(() {});
        },
      );
    }
    if (field.kind == FarmFieldKind.choice) {
      final entries = options == null
          ? (field.options ?? const []).map((value) => (value, value)).toList()
          : options
              .map(
                (row) => (
                  row[field.referenceIdColumn]?.toString() ?? '',
                  row[field.referenceLabelColumn]?.toString() ?? '',
                ),
              )
              .where((entry) => entry.$1.isNotEmpty)
              .toList();
      return DropdownButtonFormField<String>(
        initialValue: _selectedOptions[field.column],
        decoration: InputDecoration(labelText: field.label),
        items: entries
            .map(
              (entry) => DropdownMenuItem(
                value: entry.$1,
                child: Text(entry.$2),
              ),
            )
            .toList(),
        validator: field.required
            ? (value) =>
                value == null ? 'Select ${field.label.toLowerCase()}.' : null
            : null,
        onChanged: (value) =>
            setState(() => _selectedOptions[field.column] = value),
      );
    }
    if (field.kind == FarmFieldKind.date) {
      return TextFormField(
        controller: _controllers[field.column],
        readOnly: true,
        decoration: InputDecoration(
          labelText: field.label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => _pickDate(field),
        validator: field.required
            ? (value) => (value?.trim().isNotEmpty ?? false)
                ? null
                : 'Enter ${field.label.toLowerCase()}.'
            : null,
      );
    }
    return TextFormField(
      controller: _controllers[field.column],
      decoration: InputDecoration(labelText: field.label),
      keyboardType: field.kind == FarmFieldKind.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      minLines: field.kind == FarmFieldKind.multiline ? 3 : 1,
      maxLines: field.kind == FarmFieldKind.multiline ? 5 : 1,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (field.required && text.isEmpty) {
          return 'Enter ${field.label.toLowerCase()}.';
        }
        if (field.kind == FarmFieldKind.number &&
            text.isNotEmpty &&
            num.tryParse(text) == null) {
          return 'Enter a valid number.';
        }
        return null;
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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

class _EmptyFeature extends StatelessWidget {
  const _EmptyFeature({
    required this.title,
    required this.canCreate,
    required this.onCreate,
  });

  final String title;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.agriculture_outlined, size: 48),
              const SizedBox(height: 12),
              Text('No $title found.'),
              if (canCreate) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: Text('Add $title'),
                ),
              ],
            ],
          ),
        ),
      );
}
