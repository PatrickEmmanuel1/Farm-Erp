import 'package:flutter/material.dart';

import '../../data/model/storage.dart';
import '../../data/repository/storage_repository.dart';
import '../../data/user_facing_error.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({
    required this.farmId,
    required this.repository,
    required this.canManage,
    super.key,
  });

  final String farmId;
  final StorageRepository repository;
  final bool canManage;

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  static const _background = Color(0xFFFAF6F0);
  static const _green = Color(0xFF287A34);

  late Future<_StorageData> _storage;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _storage = _loadStorage();
  }

  Future<_StorageData> _loadStorage() async {
    final values = await Future.wait([
      widget.repository.getStorageForFarm(widget.farmId),
      widget.repository.getFacilitiesForFarm(widget.farmId),
    ]);
    return _StorageData(
      values[0] as List<StoredProduce>,
      values[1] as List<StorageFacility>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _storage = _loadStorage());
    await _storage;
  }

  Future<void> _addProduce() async {
    final produce = await showDialog<StoredProduce>(
      context: context,
      builder: (context) => _AddStoredProduceDialog(farmId: widget.farmId),
    );
    if (produce == null || !mounted) return;
    try {
      await widget.repository.addStoredProduce(produce);
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _addFacility() async {
    final facility = await showDialog<StorageFacility>(
      context: context,
      builder: (context) => _AddStorageFacilityDialog(farmId: widget.farmId),
    );
    if (facility == null || !mounted) return;
    try {
      await widget.repository.createFacility(facility);
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _deleteProduce(StoredProduce produce) async {
    final id = produce.storageId;
    if (id == null || id.isEmpty) {
      _showError(StateError('This produce record is missing its identifier.'));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove stored produce?'),
        content: Text('Remove ${produce.cropName} from stored produce?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteStoredProduce(id);
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFacingError(error))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Manage harvested produce & storage facilities',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
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
      body: FutureBuilder<_StorageData>(
        future: _storage,
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
          final attentionCount =
              data.produce.where((produce) => produce.needsAttention).length;
          final selectedItems =
              _selectedTab == 0 ? data.produce.length : data.facilities.length;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              children: [
                _StorageSummary(
                  produceCount: data.produce.length,
                  facilityCount: data.facilities.length,
                  attentionCount: attentionCount,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StorageTab(
                        label: 'Stored Produce',
                        count: data.produce.length,
                        selected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StorageTab(
                        label: 'Storage Facilities',
                        count: data.facilities.length,
                        selected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTab == 0
                            ? 'Stored Produce Batches'
                            : 'Farm Storage Facilities',
                        style: const TextStyle(
                          color: Color(0xFF25211F),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.canManage)
                      OutlinedButton.icon(
                        onPressed:
                            _selectedTab == 0 ? _addProduce : _addFacility,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF573D35),
                          side: const BorderSide(color: Color(0xFFD6C8D9)),
                          minimumSize: const Size(78, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          _selectedTab == 0 ? 'Add Produce' : 'Add Facility',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (selectedItems == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        _selectedTab == 0
                            ? 'No stored produce recorded yet.'
                            : 'No storage facilities set up yet.',
                        style: const TextStyle(
                          color: Color(0xFF705C55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else if (_selectedTab == 0)
                  for (final produce in data.produce)
                    _ProduceCard(
                      produce: produce,
                      canManage: widget.canManage,
                      onDelete: () => _deleteProduce(produce),
                    )
                else
                  for (final facility in data.facilities)
                    _FacilityCard(facility: facility),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StorageData {
  const _StorageData(this.produce, this.facilities);

  final List<StoredProduce> produce;
  final List<StorageFacility> facilities;
}

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({
    required this.produceCount,
    required this.facilityCount,
    required this.attentionCount,
  });

  final int produceCount;
  final int facilityCount;
  final int attentionCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EAE5),
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
              child: const Icon(Icons.warehouse_outlined,
                  color: Color(0xFF287A34)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$produceCount batches in $facilityCount facilities',
                    style: const TextStyle(
                      color: Color(0xFF563D36),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    attentionCount == 0
                        ? 'Warehouse & store monitoring'
                        : '$attentionCount batches need attention',
                    style: const TextStyle(
                      color: Color(0xFF705C55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StorageTab extends StatelessWidget {
  const _StorageTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDDF2EF) : Colors.transparent,
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFD6C8D9),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color:
                  selected ? const Color(0xFF00695C) : const Color(0xFF573D35),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}

class _ProduceCard extends StatelessWidget {
  const _ProduceCard({
    required this.produce,
    required this.canManage,
    required this.onDelete,
  });

  final StoredProduce produce;
  final bool canManage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EAE5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const _StorageIcon(icon: Icons.spa_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produce.cropName,
                    style: const TextStyle(
                      color: Color(0xFF563D36),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${produce.quantity} ${produce.unit} · ${produce.location}',
                    style: const TextStyle(
                      color: Color(0xFF705C55),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Stored ${produce.dateStored} · ${produce.condition}',
                    style: const TextStyle(
                      color: Color(0xFF705C55),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (produce.needsAttention)
              const Icon(Icons.warning_amber, color: Color(0xFFB45309)),
            if (canManage)
              IconButton(
                tooltip: 'Remove produce',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      );
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.facility});

  final StorageFacility facility;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EAE5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const _StorageIcon(icon: Icons.warehouse_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                      color: Color(0xFF563D36),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${facility.displayType} · ${facility.capacityKg} kg capacity',
                    style: const TextStyle(
                      color: Color(0xFF705C55),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${facility.displayCondition}${facility.locationNote?.isNotEmpty == true ? ' · ${facility.locationNote}' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF705C55),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StorageIcon extends StatelessWidget {
  const _StorageIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE5F2E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF287A34)),
      );
}

class _AddStoredProduceDialog extends StatefulWidget {
  const _AddStoredProduceDialog({required this.farmId});

  final String farmId;

  @override
  State<_AddStoredProduceDialog> createState() =>
      _AddStoredProduceDialogState();
}

class _AddStoredProduceDialogState extends State<_AddStoredProduceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _crop = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _location = TextEditingController();
  final _condition = TextEditingController(text: 'Good');
  late final TextEditingController _date = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0]);

  @override
  void dispose() {
    _crop.dispose();
    _quantity.dispose();
    _unit.dispose();
    _location.dispose();
    _condition.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      _date.text = selected.toIso8601String().split('T')[0];
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      StoredProduce(
        farmId: widget.farmId,
        cropName: _crop.text.trim(),
        quantity: double.parse(_quantity.text.trim()),
        unit: _unit.text.trim(),
        location: _location.text.trim(),
        dateStored: _date.text.trim(),
        condition: _condition.text.trim(),
        needsAttention: _condition.text.toLowerCase().contains('poor') ||
            _condition.text.toLowerCase().contains('spoiled'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add Produce'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _requiredField(_crop, 'Crop name'),
                _requiredField(
                  _quantity,
                  'Quantity',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter quantity.';
                    }
                    return double.tryParse(value.trim()) == null
                        ? 'Enter a valid quantity.'
                        : null;
                  },
                ),
                _requiredField(_unit, 'Unit'),
                _requiredField(_location, 'Location'),
                TextFormField(
                  controller: _date,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date stored',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: _pickDate,
                ),
                TextField(
                  controller: _condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
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

class _AddStorageFacilityDialog extends StatefulWidget {
  const _AddStorageFacilityDialog({required this.farmId});

  final String farmId;

  @override
  State<_AddStorageFacilityDialog> createState() =>
      _AddStorageFacilityDialogState();
}

class _AddStorageFacilityDialogState extends State<_AddStorageFacilityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _capacity = TextEditingController();
  final _location = TextEditingController();
  String _type = 'store';
  String _condition = 'good';

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      StorageFacility(
        farmId: widget.farmId,
        name: _name.text.trim(),
        facilityType: _type,
        capacityKg: double.parse(_capacity.text.trim()),
        condition: _condition,
        locationNote:
            _location.text.trim().isEmpty ? null : _location.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add Storage Facility'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _requiredField(_name, 'Facility name'),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Facility type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'store', child: Text('General Store')),
                    DropdownMenuItem(
                        value: 'cold_room', child: Text('Cold Room')),
                    DropdownMenuItem(value: 'silo', child: Text('Silo')),
                    DropdownMenuItem(value: 'granary', child: Text('Granary')),
                    DropdownMenuItem(value: 'shed', child: Text('Shed')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                _requiredField(
                  _capacity,
                  'Capacity (kg)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter capacity.';
                    }
                    final capacity = double.tryParse(value.trim());
                    return capacity == null || capacity < 0
                        ? 'Enter a valid capacity.'
                        : null;
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: const [
                    DropdownMenuItem(value: 'good', child: Text('Good')),
                    DropdownMenuItem(value: 'fair', child: Text('Fair')),
                    DropdownMenuItem(value: 'poor', child: Text('Poor')),
                    DropdownMenuItem(
                      value: 'needs_repair',
                      child: Text('Needs repair'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _condition = value);
                  },
                ),
                TextField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Location note'),
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

Widget _requiredField(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (value) => value == null || value.trim().isEmpty
              ? 'Enter ${label.toLowerCase()}.'
              : null,
    );
