import 'package:flutter/material.dart';

import '../../data/model/inventory_category.dart';
import '../../data/model/inventory.dart';
import '../../data/repository/inventory_repository.dart';
import '../../data/user_facing_error.dart';

class InventoryIssuanceHistoryScreen extends StatefulWidget {
  const InventoryIssuanceHistoryScreen({
    required this.farmId,
    required this.repository,
    super.key,
  });

  final String farmId;
  final InventoryRepository repository;

  @override
  State<InventoryIssuanceHistoryScreen> createState() =>
      _InventoryIssuanceHistoryScreenState();
}

class _InventoryIssuanceHistoryScreenState
    extends State<InventoryIssuanceHistoryScreen> {
  InventoryCategory _category = inventoryCategories.first;
  late Future<List<StockIssuance>> _records;

  @override
  void initState() {
    super.initState();
    _records = _loadRecords();
  }

  Future<List<StockIssuance>> _loadRecords() {
    return widget.repository.getStockIssuancesForFarm(
      _inventoryCategory(_category),
      widget.farmId,
    );
  }

  Future<void> _refresh() async {
    setState(() => _records = _loadRecords());
    await _records;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issuance history')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<InventoryCategory>(
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
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                  _records = _loadRecords();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StockIssuance>>(
              future: _records,
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
                        TextButton(
                            onPressed: _refresh, child: const Text('Retry')),
                      ],
                    ),
                  );
                }
                final records = snapshot.data ?? const [];
                if (records.isEmpty) {
                  return const Center(
                      child: Text('No issuance records found.'));
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.outbox_outlined),
                          title: Text(
                            '${record.safeQuantityIssued} ${record.safeUnit}'
                            '${record.itemName == null ? '' : ' · ${record.itemName}'}',
                          ),
                          subtitle: Text(
                            '${record.issueDate ?? ''} · '
                            '${record.status ?? 'Issued'}'
                            '${record.notes == null ? '' : ' · ${record.notes}'}',
                          ),
                        ),
                      );
                    },
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
