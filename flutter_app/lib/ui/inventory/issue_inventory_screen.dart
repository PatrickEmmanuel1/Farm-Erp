import 'package:flutter/material.dart';

import '../../data/model/inventory_category.dart';
import '../../data/model/farm_user.dart';
import '../../data/model/inventory.dart';
import '../../data/model/farm.dart';
import '../../data/repository/division_repository.dart';
import '../../data/repository/inventory_repository.dart';
import '../../data/user_facing_error.dart';

class IssueInventoryScreen extends StatefulWidget {
  const IssueInventoryScreen({
    required this.user,
    required this.farmId,
    required this.repository,
    required this.divisionRepository,
    super.key,
  });

  final FarmUser user;
  final String farmId;
  final InventoryRepository repository;
  final DivisionRepository divisionRepository;

  @override
  State<IssueInventoryScreen> createState() => _IssueInventoryScreenState();
}

class _IssueInventoryScreenState extends State<IssueInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  InventoryCategory _category = inventoryCategories.first;
  String? _itemId;
  String? _divisionId;
  String _unit = '';
  late Future<_InventoryOptions> _options;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _options = _loadOptions();
  }

  Future<_InventoryOptions> _loadOptions() async {
    final stock = await widget.repository.getCategory(
      _inventoryCategory(_category),
      widget.farmId,
    );
    final divisions =
        await widget.divisionRepository.getDivisionsForFarm(widget.farmId);
    return _InventoryOptions(stock, divisions);
  }

  void _changeCategory(InventoryCategory? value) {
    if (value == null) return;
    setState(() {
      _category = value;
      _itemId = null;
      _unit = '';
      _error = null;
      _options = _loadOptions();
    });
  }

  void _changeItem(List<FarmStockItem> items, String? id) {
    final matching = items.where((row) => row.id == id);
    final selected = matching.isEmpty ? null : matching.first;
    setState(() {
      _itemId = id;
      _unit = selected?.unit ?? '';
    });
  }

  Future<void> _issue() async {
    if (!_formKey.currentState!.validate()) return;
    final itemId = _itemId;
    final quantity = num.tryParse(_quantityController.text.trim());
    if (itemId == null || quantity == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final now = DateTime.now();
    final issuanceDate = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    try {
      await widget.repository.issueStockItem(
        category: _inventoryCategory(_category),
        itemId: itemId,
        farmId: widget.farmId,
        quantity: quantity.toDouble(),
        issueDate: issuanceDate,
        divisionId: _divisionId,
        notes: _notesController.text,
      );
      if (mounted) {
        _quantityController.clear();
        _notesController.clear();
        setState(() {
          _itemId = null;
          _unit = '';
          _options = _loadOptions();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory issued.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue inventory')),
      body: FutureBuilder<_InventoryOptions>(
        future: _options,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(userFacingError(snapshot.error!)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          setState(() => _options = _loadOptions()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final options = snapshot.data!;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<InventoryCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: inventoryCategories
                      .where((category) => category.table != 'water')
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: _saving ? null : _changeCategory,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_category.table),
                  initialValue: _itemId,
                  decoration: const InputDecoration(labelText: 'Stock item'),
                  items: options.items
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(
                            '${item.name} · ${item.quantity} ${item.unit}',
                          ),
                        ),
                      )
                      .where((item) => item.value != null)
                      .toList(),
                  validator: (value) =>
                      value == null ? 'Select a stock item.' : null,
                  onChanged: _saving
                      ? null
                      : (value) => _changeItem(options.items, value),
                ),
                if (options.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('No active stock items in this category.'),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _divisionId,
                  decoration: const InputDecoration(
                    labelText: 'Division (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Whole farm'),
                    ),
                    for (final division in options.divisions)
                      DropdownMenuItem<String?>(
                        value: division.divisionId,
                        child: Text(division.name),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _divisionId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity to issue',
                    suffixText: _unit.isEmpty ? null : _unit,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final quantity = num.tryParse(value?.trim() ?? '');
                    return quantity == null || quantity <= 0
                        ? 'Enter a quantity greater than zero.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient / notes (optional)',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _issue,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Issue stock'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InventoryOptions {
  const _InventoryOptions(this.items, this.divisions);

  final List<FarmStockItem> items;
  final List<Division> divisions;
}

InventoryStockCategory _inventoryCategory(InventoryCategory category) =>
    switch (category.table) {
      'fertilizers' => InventoryStockCategory.fertilizer,
      'herbicide' => InventoryStockCategory.herbicide,
      'pesticide' => InventoryStockCategory.pesticide,
      'fungicide' => InventoryStockCategory.fungicide,
      'insecticide' => InventoryStockCategory.insecticide,
      'water' => InventoryStockCategory.water,
      _ => throw ArgumentError.value(category.table, 'category'),
    };
