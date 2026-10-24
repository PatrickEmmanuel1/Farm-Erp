import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/inventory.dart';
import '../model/inventory_category.dart';
import '../model/model_parsing.dart';

class InventoryRepository {
  InventoryRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<InventoryItem>> getInventoryForFarm(String farmId) async {
    final lists = await Future.wait(
      inventoryCategories.map((category) => _getCategory(category, farmId)),
    );
    return lists
        .expand((items) => items.map((item) => item.toInventoryItem()))
        .toList();
  }

  Future<List<FarmStockItem>> getFertilizers(String farmId) =>
      getCategory(InventoryStockCategory.fertilizer, farmId);
  Future<List<FarmStockItem>> getHerbicides(String farmId) =>
      getCategory(InventoryStockCategory.herbicide, farmId);
  Future<List<FarmStockItem>> getPesticides(String farmId) =>
      getCategory(InventoryStockCategory.pesticide, farmId);
  Future<List<FarmStockItem>> getFungicides(String farmId) =>
      getCategory(InventoryStockCategory.fungicide, farmId);
  Future<List<FarmStockItem>> getInsecticides(String farmId) =>
      getCategory(InventoryStockCategory.insecticide, farmId);
  Future<List<FarmStockItem>> getWater(String farmId) =>
      getCategory(InventoryStockCategory.water, farmId);

  Future<List<FarmStockItem>> getCategory(
    InventoryStockCategory category,
    String farmId,
  ) {
    return _getCategory(
      inventoryCategories.singleWhere(
        (entry) => entry.table == _tableFor(category),
      ),
      farmId,
    );
  }

  Future<List<FarmStockItem>> _getCategory(
    InventoryCategory schema,
    String farmId,
  ) async {
    final rows = await _client
        .from(schema.table)
        .select()
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .order(schema.itemNameColumn);
    final type = _categoryFor(schema);
    return List<JsonRow>.from(rows)
        .map((row) => FarmStockItem.fromJson(row, category: type))
        .toList();
  }

  Future<FarmStockItem> insertStock(FarmStockItem item) async {
    final schema = item.schema;
    final id = item.id ?? _uuid.v4();
    final row = await _client
        .from(schema.table)
        .insert({...item.toJson(), schema.itemIdColumn: id})
        .select()
        .single();
    return FarmStockItem.fromJson(
      Map<String, dynamic>.from(row),
      category: item.category,
    );
  }

  Future<void> deleteStock(
    InventoryStockCategory category,
    String id,
  ) async {
    final schema = inventoryCategories.singleWhere(
      (entry) => entry.table == _tableFor(category),
    );
    await _client
        .from(schema.table)
        .update(const {'is_deleted': true}).eq(schema.itemIdColumn, id);
  }

  Future<void> issueStockItem({
    required InventoryStockCategory category,
    required String itemId,
    required String farmId,
    required double quantity,
    required String issueDate,
    String? divisionId,
    String? issuedTo,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(
          quantity, 'quantity', 'Must be greater than zero.');
    }
    if (category == InventoryStockCategory.water) {
      throw StateError(
        'Water issuance is unavailable because water_issuance has no policy '
        'in the supplied RLS inventory.',
      );
    }
    final issuedBy = _client.auth.currentUser?.id;
    if (issuedBy == null || issuedBy.isEmpty) {
      throw StateError('A signed-in user is required to issue inventory.');
    }
    final schema = inventoryCategories.singleWhere(
      (entry) => entry.table == _tableFor(category),
    );
    final itemRow = await _client
        .from(schema.table)
        .select()
        .eq(schema.itemIdColumn, itemId)
        .eq('farm_id', farmId)
        .eq('is_deleted', false)
        .single();
    final available = doubleValue(itemRow, schema.stockColumn);
    if (available == null) {
      throw StateError('Inventory stock quantity is missing or invalid.');
    }
    if (quantity > available) {
      throw StateError(
          'Only $available ${itemRow['unit'] ?? ''} are available.');
    }
    final remaining = available - quantity;
    final updated = await _client
        .from(schema.table)
        .update({schema.stockColumn: remaining})
        .eq(schema.itemIdColumn, itemId)
        .eq('farm_id', farmId)
        .eq(schema.stockColumn, available)
        .select(schema.itemIdColumn);
    if (updated.isEmpty) {
      throw StateError(
          'Stock changed while issuing; reload inventory and retry.');
    }

    final issuanceId = _uuid.v4();
    final cleanNotes = [
      if (notes?.trim().isNotEmpty == true) notes!.trim(),
      if (issuedTo?.trim().isNotEmpty == true) 'Recipient: ${issuedTo!.trim()}',
    ].join(' | ');
    final payload = <String, dynamic>{
      schema.issuanceIdColumn: issuanceId,
      schema.itemIdColumn: itemId,
      'farm_id': farmId,
      if (divisionId?.isNotEmpty == true) 'division_id': divisionId,
      'issued_by': issuedBy,
      'quantity_issued': quantity,
      'unit': stringValue(itemRow, 'unit') ?? 'units',
      'issuance_date': issueDate,
      'status': 'Issued',
      if (cleanNotes.isNotEmpty) 'notes': cleanNotes,
    };

    try {
      await _client.from(schema.issuanceTable).insert(payload);
    } catch (issueError) {
      try {
        await _client
            .from(schema.table)
            .update({schema.stockColumn: available})
            .eq(schema.itemIdColumn, itemId)
            .eq('farm_id', farmId)
            .eq(schema.stockColumn, remaining);
      } catch (restoreError) {
        throw StateError(
          'Issuance failed ($issueError), and the stock rollback failed '
          '($restoreError). Verify the stock before retrying.',
        );
      }
      rethrow;
    }
  }

  Future<List<StockIssuance>> getStockIssuancesForFarm(
    InventoryStockCategory category,
    String farmId,
  ) async {
    if (category == InventoryStockCategory.water) {
      throw StateError(
        'Water issuance history is unavailable because water_issuance has '
        'no policy in the supplied RLS inventory.',
      );
    }
    final schema = inventoryCategories.singleWhere(
      (entry) => entry.table == _tableFor(category),
    );
    final rows = await _client
        .from(schema.issuanceTable)
        .select()
        .eq('farm_id', farmId)
        .order('issuance_date', ascending: false);
    final items = await getCategory(category, farmId);
    final itemById = {for (final item in items) item.id!: item};
    return List<JsonRow>.from(rows).map((row) {
      final itemId = stringValue(row, schema.itemIdColumn);
      final item = itemId == null ? null : itemById[itemId];
      return StockIssuance(
        issuanceId: stringValue(row, schema.issuanceIdColumn),
        itemId: itemId,
        category: category.name,
        itemName: item?.name,
        quantityIssued: doubleValue(row, 'quantity_issued'),
        unit: stringValue(row, 'unit'),
        issuedBy: stringValue(row, 'issued_by'),
        divisionId: stringValue(row, 'division_id'),
        issueDate: stringValue(row, 'issuance_date'),
        notes: stringValue(row, 'notes'),
        farmId: stringValue(row, 'farm_id'),
        status: stringValue(row, 'status') ?? 'Issued',
      );
    }).toList();
  }

  static InventoryStockCategory _categoryFor(InventoryCategory category) =>
      switch (category.table) {
        'fertilizers' => InventoryStockCategory.fertilizer,
        'herbicide' => InventoryStockCategory.herbicide,
        'pesticide' => InventoryStockCategory.pesticide,
        'fungicide' => InventoryStockCategory.fungicide,
        'insecticide' => InventoryStockCategory.insecticide,
        'water' => InventoryStockCategory.water,
        _ => throw ArgumentError.value(category.table, 'table'),
      };

  static String _tableFor(InventoryStockCategory category) =>
      switch (category) {
        InventoryStockCategory.fertilizer => 'fertilizers',
        InventoryStockCategory.herbicide => 'herbicide',
        InventoryStockCategory.pesticide => 'pesticide',
        InventoryStockCategory.fungicide => 'fungicide',
        InventoryStockCategory.insecticide => 'insecticide',
        InventoryStockCategory.water => 'water',
      };
}
