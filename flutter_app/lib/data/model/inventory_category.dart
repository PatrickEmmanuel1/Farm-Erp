class InventoryCategory {
  const InventoryCategory({
    required this.name,
    required this.table,
    required this.itemIdColumn,
    required this.issuanceTable,
    required this.issuanceIdColumn,
    required this.stockColumn,
    required this.itemNameColumn,
  });

  final String name;
  final String table;
  final String itemIdColumn;
  final String issuanceTable;
  final String issuanceIdColumn;
  final String stockColumn;
  final String itemNameColumn;
}

const inventoryCategories = [
  InventoryCategory(
    name: 'Fertilizer',
    table: 'fertilizers',
    itemIdColumn: 'fertilizer_id',
    issuanceTable: 'fertilizer_issuance',
    issuanceIdColumn: 'fertilizer_issuance_id',
    stockColumn: 'quantity',
    itemNameColumn: 'name',
  ),
  InventoryCategory(
    name: 'Herbicide',
    table: 'herbicide',
    itemIdColumn: 'herbicide_id',
    issuanceTable: 'herbicide_issuance',
    issuanceIdColumn: 'herbicide_issuance_id',
    stockColumn: 'quantity',
    itemNameColumn: 'name',
  ),
  InventoryCategory(
    name: 'Pesticide',
    table: 'pesticide',
    itemIdColumn: 'pesticide_id',
    issuanceTable: 'pesticide_issuance',
    issuanceIdColumn: 'pesticide_issuance_id',
    stockColumn: 'quantity',
    itemNameColumn: 'name',
  ),
  InventoryCategory(
    name: 'Fungicide',
    table: 'fungicide',
    itemIdColumn: 'fungicide_id',
    issuanceTable: 'fungicide_issuance',
    issuanceIdColumn: 'fungicide_issuance_id',
    stockColumn: 'quantity',
    itemNameColumn: 'name',
  ),
  InventoryCategory(
    name: 'Insecticide',
    table: 'insecticide',
    itemIdColumn: 'insecticide_id',
    issuanceTable: 'insecticide_issuance',
    issuanceIdColumn: 'insecticide_issuance_id',
    stockColumn: 'quantity',
    itemNameColumn: 'name',
  ),
  InventoryCategory(
    name: 'Water',
    table: 'water',
    itemIdColumn: 'water_id',
    issuanceTable: 'water_issuance',
    issuanceIdColumn: 'water_issuance_id',
    stockColumn: 'available_quantity',
    itemNameColumn: 'source_name',
  ),
];
