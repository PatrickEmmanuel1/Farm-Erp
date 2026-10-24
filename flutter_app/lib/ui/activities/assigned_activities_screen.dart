import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/model/farm_activity.dart';
import '../../data/model/farm_user.dart';
import '../../data/repository/farm_activity_repository.dart';
import '../../data/user_facing_error.dart';

class AssignedActivitiesScreen extends StatefulWidget {
  const AssignedActivitiesScreen({
    required this.user,
    required this.farmId,
    required this.repository,
    super.key,
  });

  final FarmUser user;
  final String farmId;
  final FarmActivityRepository repository;

  @override
  State<AssignedActivitiesScreen> createState() =>
      _AssignedActivitiesScreenState();
}

class _AssignedActivitiesScreenState extends State<AssignedActivitiesScreen> {
  static const _backgroundColor = Color(0xFFFAF6F0);
  static const _cardColor = Color(0xFFF4EAE5);
  static const _greenColor = Color(0xFF287A34);

  late Future<List<FarmActivityDisplay>> _activities;
  bool _busy = false;
  String _statusFilter = 'Pending';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _activities = _loadActivities();
  }

  Future<List<FarmActivityDisplay>> _loadActivities() async {
    if (widget.user.role.toLowerCase() == 'manager') {
      return widget.repository.getFarmActivityDisplays(widget.farmId);
    }
    final profileId = widget.user.profileId;
    if (profileId == null || profileId.isEmpty) return const [];
    return widget.repository.getAssignedActivityDisplays(
      farmId: widget.farmId,
      profileId: profileId,
      isWorker: widget.user.role.toLowerCase() == 'worker',
    );
  }

  Future<void> _refresh() async {
    setState(() => _activities = _loadActivities());
    await _activities;
  }

  Future<void> _changeStatus(
    FarmActivityDisplay display, {
    required bool complete,
  }) async {
    final id = display.activity.activityId;
    if (id == null || id.isEmpty) return;
    setState(() => _busy = true);
    try {
      if (complete) {
        await widget.repository.completeFarmActivity(id);
      } else {
        await widget.repository.startFarmActivity(id);
      }
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAddActivityForm() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => _AddFarmActivitySheet(
        farmId: widget.farmId,
        repository: widget.repository,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final selectedType = result['activity_type_id'] as String?;
      if (selectedType == null || selectedType.isEmpty) {
        throw StateError('Select an activity type.');
      }
      await widget.repository.insertFarmActivity(FarmActivity(
        activityId: Uuid().v4(),
        farmId: widget.farmId,
        activityTypeId: selectedType,
        activityName: result['activity_name'] as String?,
        workerProfileId: result['worker_profile_id'] as String?,
        supervisorProfileId: result['supervisor_profile_id'] as String?,
        divisionId: result['division_id'] as String?,
        activityDate: result['activity_date'] as String?,
        quantity: result['quantity'] as double?,
        quantityUnit: result['quantity_unit'] as String?,
        equipmentNeeded: result['equipment_needed'] as String?,
        status: 'Pending',
        notes: result['notes'] as String?,
      ));
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm activity added.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    }
  }

  Future<void> _showDetails(FarmActivityDisplay display) async {
    final activity = display.activity;
    final normalized = activity.safeStatus.toLowerCase();
    final isComplete = {
      'completed',
      'done',
      'finished',
      'closed',
    }.contains(normalized);
    final isInProgress = {
      'in progress',
      'in_progress',
      'in-progress',
      'ongoing',
    }.contains(normalized);
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
              Text(
                display.displayTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Status: ${activity.safeStatus}'),
              Text('Date: ${activity.safeActivityDate}'),
              if (display.assignedToName != null)
                Text('Assigned to: ${display.assignedToName}'),
              if (activity.quantity != null)
                Text(
                    'Quantity: ${activity.quantity} ${activity.quantityUnit ?? ''}'),
              if (activity.method?.isNotEmpty == true)
                Text('Method: ${activity.method}'),
              if (activity.equipmentNeeded?.isNotEmpty == true)
                Text('Equipment: ${activity.equipmentNeeded}'),
              if (activity.durationHours != null)
                Text('Duration: ${activity.durationHours} hours'),
              if (activity.startTime?.isNotEmpty == true)
                Text('Started: ${activity.startTime}'),
              if (activity.endTime?.isNotEmpty == true)
                Text('Completed: ${activity.endTime}'),
              if (activity.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(activity.notes!),
              ],
              if (!isComplete) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () {
                          Navigator.pop(context);
                          _changeStatus(display, complete: isInProgress);
                        },
                  child: Text(
                    isInProgress ? 'Complete activity' : 'Start activity',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchActivities() async {
    final controller = TextEditingController(text: _query);
    try {
      final query = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Search activities'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Activity, assignee, or due date',
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Search'),
            ),
          ],
        ),
      );
      if (query != null && mounted) setState(() => _query = query);
    } finally {
      controller.dispose();
    }
  }

  bool _isComplete(FarmActivityDisplay display) => {
        'completed',
        'done',
        'finished',
        'closed',
      }.contains(display.activity.safeStatus.toLowerCase());

  bool _isInProgress(FarmActivityDisplay display) => {
        'in progress',
        'in_progress',
        'in-progress',
        'ongoing',
      }.contains(display.activity.safeStatus.toLowerCase());

  String _category(FarmActivityDisplay display) {
    if (_isComplete(display)) return 'Completed';
    if (_isInProgress(display)) return 'In Progress';
    return 'Pending';
  }

  Widget _statusTabs() {
    const tabs = [
      ('Pending', Icons.hourglass_empty),
      ('In Progress', Icons.play_arrow),
      ('Completed', Icons.check_circle_outline),
    ];
    return Row(
      children: [
        for (final (label, icon) in tabs)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _statusFilter = label),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _statusFilter == label
                          ? _greenColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: _greenColor, size: 19),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: const TextStyle(
                        color: _greenColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _summaryCard(int count) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F2E8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: _greenColor,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF573D35),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$_statusFilter Tasks count',
                  style: const TextStyle(
                    color: Color(0xFF634E47),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _activityCard(FarmActivityDisplay display) {
    final activity = display.activity;
    final complete = _isComplete(display);
    final inProgress = _isInProgress(display);
    final statusLabel = switch (_category(display)) {
      'Pending' => 'Planned',
      'In Progress' => 'In Progress',
      _ => 'Completed',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showDetails(display),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F2E8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: _greenColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display.displayTitle,
                        style: const TextStyle(
                          color: Color(0xFF563D36),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        display.activityTypeName,
                        style: const TextStyle(
                          color: Color(0xFF705C55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5E7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: _greenColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActivityMeta(
                  icon: Icons.person_outline,
                  label: 'Assigned to',
                  value: display.assignedToName ?? 'Unassigned',
                ),
              ),
              Expanded(
                child: _ActivityMeta(
                  icon: Icons.calendar_month_outlined,
                  label: 'Due date',
                  value: activity.safeActivityDate.isEmpty
                      ? 'Not set'
                      : activity.safeActivityDate,
                ),
              ),
            ],
          ),
          if (!complete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _greenColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : () => _changeStatus(display, complete: inProgress),
                icon: Icon(
                  inProgress ? Icons.check : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(
                  inProgress ? 'Complete activity' : 'Begin activity',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = widget.user.role.toLowerCase() == 'worker';
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Activities',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Track tasks across the farm',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'search') _searchActivities();
              if (value == 'refresh') _refresh();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'search', child: Text('Search activities')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<FarmActivityDisplay>>(
        future: _activities,
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
          final allActivities = snapshot.data ?? const [];
          final query = _query.trim().toLowerCase();
          final categorizedActivities = allActivities.where((display) {
            final matchesQuery = query.isEmpty ||
                display.displayTitle.toLowerCase().contains(query) ||
                display.activity.safeActivityDate
                    .toLowerCase()
                    .contains(query) ||
                (display.assignedToName?.toLowerCase().contains(query) ??
                    false);
            return matchesQuery;
          }).toList();
          final activities = categorizedActivities
              .where((display) => _category(display) == _statusFilter)
              .toList();
          return Column(
            children: [
              _statusTabs(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                    children: [
                      _summaryCard(activities.length),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$_statusFilter Tasks',
                              style: const TextStyle(
                                color: Color(0xFF25211F),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!isWorker)
                            OutlinedButton.icon(
                              onPressed: _openAddActivityForm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF573D35),
                                side: const BorderSide(
                                  color: Color(0xFFD6C8D9),
                                ),
                                minimumSize: const Size(78, 34),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text(
                                'Add',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (activities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              query.isEmpty
                                  ? 'No $_statusFilter tasks yet.'
                                  : 'No $_statusFilter tasks match your search.',
                              style: const TextStyle(
                                color: Color(0xFF705C55),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final activity in activities)
                          _activityCard(activity),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityMeta extends StatelessWidget {
  const _ActivityMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF216A2D), size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF634E47),
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3D312D),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _AddFarmActivitySheet extends StatefulWidget {
  const _AddFarmActivitySheet({
    required this.farmId,
    required this.repository,
  });

  final String farmId;
  final FarmActivityRepository repository;

  @override
  State<_AddFarmActivitySheet> createState() => _AddFarmActivitySheetState();
}

class _AddFarmActivitySheetState extends State<_AddFarmActivitySheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'kg');
  final _notesController = TextEditingController();
  String _selectedRole = 'Worker';
  String _selectedAssignment = '';
  String _selectedLocation = 'entire';
  String _selectedMachinery = 'None / Not Required';
  String _selectedType = '';
  String _selectedDivision = '';
  late Future<FarmActivityFormOptions> _options;

  @override
  void initState() {
    super.initState();
    _options = widget.repository
        .getFarmActivityFormOptions(widget.farmId)
        .then((options) {
      if (_selectedType.isEmpty && options.activityTypes.isNotEmpty) {
        _selectedType = options.activityTypes.first.id;
      }
      final list =
          _selectedRole == 'Worker' ? options.workers : options.supervisors;
      if (_selectedAssignment.isEmpty && list.isNotEmpty) {
        _selectedAssignment = list.first.id;
      }
      return options;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      backgroundColor: const Color(0xFFF1EEE7),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: SafeArea(
          child: FutureBuilder<FarmActivityFormOptions>(
            future: _options,
            builder: (context, snapshot) {
              final options = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting ||
                  options == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final activityTypes = options.activityTypes;
              final divisions = options.divisions;
              final workers = options.workers;
              final supervisors = options.supervisors;
              final assignments =
                  _selectedRole == 'Worker' ? workers : supervisors;
              final activeTypeId =
                  _selectedType.isEmpty && activityTypes.isNotEmpty
                      ? activityTypes.first.id
                      : _selectedType;
              final activeAssignmentId = assignments.isNotEmpty
                  ? (_selectedAssignment.isEmpty
                      ? assignments.first.id
                      : _selectedAssignment)
                  : '';

              return Column(
                children: [
                  Container(
                    color: const Color(0xFF1B7AC9),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Add Farm Activity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                      children: [
                        _FormSection(
                          icon: Icons.assignment_outlined,
                          label: 'Activity Type',
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                activeTypeId.isEmpty ? null : activeTypeId,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF9F8F5),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final type in activityTypes)
                                DropdownMenuItem(
                                  value: type.id,
                                  child: Text(type.label),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormSection(
                          icon: Icons.edit_note_outlined,
                          label: 'Activity Name (optional)',
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF9F8F5),
                              hintText: 'Activity Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormSection(
                          icon: Icons.person_outline,
                          label: 'Assigned Employee & Role',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                      value: 'Worker', label: Text('Worker')),
                                  ButtonSegment(
                                      value: 'Supervisor',
                                      label: Text('Supervisor')),
                                ],
                                selected: {_selectedRole},
                                onSelectionChanged: (selection) {
                                  final value = selection.first;
                                  setState(() {
                                    _selectedRole = value;
                                    final list = value == 'Worker'
                                        ? workers
                                        : supervisors;
                                    if (list.isNotEmpty) {
                                      _selectedAssignment = list.first.id;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: assignments.isNotEmpty
                                    ? activeAssignmentId
                                    : null,
                                decoration: const InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFFF9F8F5),
                                  hintText: 'Select specific worker',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: '',
                                      child: Text('Unassigned / Any Worker')),
                                  for (final option in assignments)
                                    DropdownMenuItem(
                                      value: option.id,
                                      child: Text(option.label),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(
                                      () => _selectedAssignment = value ?? '');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormSection(
                          icon: Icons.location_on_outlined,
                          label: 'Farm Location',
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Entire Farm'),
                                    selected: _selectedLocation == 'entire',
                                    onSelected: (_) => setState(
                                        () => _selectedLocation = 'entire'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Specific Division'),
                                    selected: _selectedLocation == 'division',
                                    onSelected: (_) => setState(
                                        () => _selectedLocation = 'division'),
                                  ),
                                ],
                              ),
                              if (_selectedLocation == 'division')
                                DropdownButtonFormField<String>(
                                  initialValue: divisions.isNotEmpty
                                      ? (_selectedDivision.isEmpty
                                          ? divisions.first.id
                                          : _selectedDivision)
                                      : null,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Color(0xFFF9F8F5),
                                    hintText: 'Select division',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    for (final option in divisions)
                                      DropdownMenuItem(
                                        value: option.id,
                                        child: Text(option.label),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    setState(
                                        () => _selectedDivision = value ?? '');
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormSection(
                          icon: Icons.agriculture_outlined,
                          label: 'Machinery Required',
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMachinery,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF9F8F5),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'None / Not Required',
                                  child: Text('None / Not Required')),
                              DropdownMenuItem(
                                  value: 'Tractor', child: Text('Tractor')),
                              DropdownMenuItem(
                                  value: 'Harvester', child: Text('Harvester')),
                              DropdownMenuItem(
                                  value: 'Sprayer', child: Text('Sprayer')),
                            ],
                            onChanged: (value) => setState(() =>
                                _selectedMachinery =
                                    value ?? 'None / Not Required'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quantity & Measurement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'Quantity',
                                  filled: true,
                                  fillColor: Color(0xFFF9F8F5),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _unitController,
                                decoration: const InputDecoration(
                                  hintText: 'Unit',
                                  filled: true,
                                  fillColor: Color(0xFFF9F8F5),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Notes',
                            filled: true,
                            fillColor: Color(0xFFF9F8F5),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: const Color(0xFF1B7AC9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final quantityText =
                                  _quantityController.text.trim();
                              Navigator.pop(context, {
                                'activity_type_id': _selectedType,
                                'activity_name': _nameController.text.trim(),
                                'worker_profile_id': _selectedRole == 'Worker'
                                    ? _selectedAssignment
                                    : null,
                                'supervisor_profile_id':
                                    _selectedRole == 'Supervisor'
                                        ? _selectedAssignment
                                        : null,
                                'division_id': _selectedLocation == 'division'
                                    ? _selectedDivision
                                    : null,
                                'activity_date': DateTime.now()
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                                'quantity': quantityText.isEmpty
                                    ? null
                                    : double.tryParse(quantityText),
                                'quantity_unit':
                                    _unitController.text.trim().isEmpty
                                        ? null
                                        : _unitController.text.trim(),
                                'equipment_needed':
                                    _selectedMachinery == 'None / Not Required'
                                        ? null
                                        : _selectedMachinery,
                                'notes': _notesController.text.trim().isEmpty
                                    ? null
                                    : _notesController.text.trim(),
                              });
                            },
                            child: const Text('Create Activity'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1B7AC9)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
