import 'inventory_category.dart';
import 'model_parsing.dart';

enum InventoryStockCategory {
  fertilizer,
  herbicide,
  pesticide,
  fungicide,
  insecticide,
  water
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.category,
    required this.name,
    this.subtype,
    required this.quantity,
    required this.unit,
    this.reorderLevel,
    this.description,
  });

  final String id;
  final InventoryStockCategory category;
  final String name;
  final String? subtype;
  final double quantity;
  final String unit;
  final double? reorderLevel;
  final String? description;

  bool get isLowStock => reorderLevel != null && quantity <= reorderLevel!;
}

class FarmStockItem {
  const FarmStockItem({
    this.id,
    required this.farmId,
    this.divisionId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.reorderLevel,
    this.description,
    this.activeIngredient,
    this.fertilizerType,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String? id;
  final String farmId;
  final String? divisionId;
  final String name;
  final InventoryStockCategory category;
  final double quantity;
  final String unit;
  final double? reorderLevel;
  final String? description;
  final String? activeIngredient;
  final String? fertilizerType;
  final String? createdAt;
  final String? updatedAt;
  final bool isDeleted;

  InventoryCategory get schema => inventoryCategories.singleWhere(
        (entry) => entry.table == _table,
      );

  String get _table => switch (category) {
        InventoryStockCategory.fertilizer => 'fertilizers',
        InventoryStockCategory.herbicide => 'herbicide',
        InventoryStockCategory.pesticide => 'pesticide',
        InventoryStockCategory.fungicide => 'fungicide',
        InventoryStockCategory.insecticide => 'insecticide',
        InventoryStockCategory.water => 'water',
      };

  factory FarmStockItem.fromJson(
    JsonRow json, {
    required InventoryStockCategory category,
  }) {
    final schema = inventoryCategories.singleWhere(
      (entry) => entry.table == _tableFor(category),
    );
    return FarmStockItem(
      id: stringValue(json, schema.itemIdColumn),
      farmId: stringValue(json, 'farm_id') ?? '',
      divisionId: stringValue(json, 'division_id'),
      name: stringValue(json, schema.itemNameColumn) ?? '',
      category: category,
      quantity: doubleValue(json, schema.stockColumn) ?? 0,
      unit: stringValue(json, 'unit') ?? '',
      reorderLevel: doubleValue(json, 'reorder_level'),
      description: stringValue(json, 'description'),
      activeIngredient: stringValue(json, 'active_ingredient'),
      fertilizerType: stringValue(json, 'fertilizer_type'),
      createdAt: stringValue(json, 'created_at'),
      updatedAt: stringValue(json, 'updated_at'),
      isDeleted: boolValue(json, 'is_deleted'),
    );
  }

  JsonRow toJson() => {
        if (id != null) schema.itemIdColumn: id,
        'farm_id': farmId,
        if (divisionId != null) 'division_id': divisionId,
        schema.itemNameColumn: name,
        schema.stockColumn: quantity,
        'unit': unit,
        if (reorderLevel != null) 'reorder_level': reorderLevel,
        if (description != null) 'description': description,
        if (activeIngredient != null) 'active_ingredient': activeIngredient,
        if (fertilizerType != null) 'fertilizer_type': fertilizerType,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        'is_deleted': isDeleted,
      };

  InventoryItem toInventoryItem() => InventoryItem(
        id: id ?? (throw StateError('Inventory item is missing its id.')),
        category: category,
        name: name,
        subtype: category == InventoryStockCategory.fertilizer
            ? fertilizerType
            : activeIngredient,
        quantity: quantity,
        unit: unit,
        reorderLevel: reorderLevel,
        description: description,
      );

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

class StockIssuance {
  const StockIssuance({
    this.issuanceId,
    this.itemId,
    this.category,
    this.itemName,
    this.quantityIssued,
    this.unit,
    this.issuedTo,
    this.issuedBy,
    this.divisionId,
    this.divisionName,
    this.issueDate,
    this.notes,
    this.farmId,
    this.status = 'Issued',
  });

  final String? issuanceId;
  final String? itemId;
  final String? category;
  final String? itemName;
  final double? quantityIssued;
  final String? unit;
  final String? issuedTo;
  final String? issuedBy;
  final String? divisionId;
  final String? divisionName;
  final String? issueDate;
  final String? notes;
  final String? farmId;
  final String? status;

  String get safeItemName =>
      itemName?.trim().isNotEmpty == true ? itemName! : 'Stock Item';
  double get safeQuantityIssued => quantityIssued ?? 0;
  String get safeUnit => unit?.trim().isNotEmpty == true ? unit! : 'units';

  factory StockIssuance.fromJson(JsonRow json) => StockIssuance(
        issuanceId: stringValue(json, 'issuance_id'),
        itemId: stringValue(json, 'item_id'),
        category: stringValue(json, 'category'),
        itemName: stringValue(json, 'item_name'),
        quantityIssued: doubleValue(json, 'quantity_issued'),
        unit: stringValue(json, 'unit'),
        issuedTo: stringValue(json, 'issued_to'),
        issuedBy: stringValue(json, 'issued_by'),
        divisionId: stringValue(json, 'division_id'),
        divisionName: stringValue(json, 'division_name'),
        issueDate: stringValue(json, 'issue_date'),
        notes: stringValue(json, 'notes'),
        farmId: stringValue(json, 'farm_id'),
        status: stringValue(json, 'status') ?? 'Issued',
      );

  JsonRow toJson() => {
        if (issuanceId != null) 'issuance_id': issuanceId,
        if (itemId != null) 'item_id': itemId,
        if (category != null) 'category': category,
        if (itemName != null) 'item_name': itemName,
        if (quantityIssued != null) 'quantity_issued': quantityIssued,
        if (unit != null) 'unit': unit,
        if (issuedTo != null) 'issued_to': issuedTo,
        if (issuedBy != null) 'issued_by': issuedBy,
        if (divisionId != null) 'division_id': divisionId,
        if (divisionName != null) 'division_name': divisionName,
        if (issueDate != null) 'issue_date': issueDate,
        if (notes != null) 'notes': notes,
        if (farmId != null) 'farm_id': farmId,
        if (status != null) 'status': status,
      };
}
