enum FarmFieldKind { text, number, date, multiline, choice, boolean }

class FarmField {
  const FarmField({
    required this.column,
    required this.label,
    this.kind = FarmFieldKind.text,
    this.required = false,
    this.initialValue,
    this.options,
    this.referenceTable,
    this.referenceIdColumn,
    this.referenceLabelColumn,
    this.referenceFarmScoped = true,
  });

  final String column;
  final String label;
  final FarmFieldKind kind;
  final bool required;
  final String? initialValue;
  final List<String>? options;
  final String? referenceTable;
  final String? referenceIdColumn;
  final String? referenceLabelColumn;
  final bool referenceFarmScoped;
}

class FarmFeature {
  const FarmFeature({
    required this.title,
    required this.table,
    required this.idColumn,
    required this.fields,
    this.orderBy,
    this.readOnly = false,
    this.canCreate = true,
    this.canEditExisting = true,
    this.canDelete = true,
    this.showFarmId = true,
    this.excludeDeleted = true,
    this.softDelete = true,
    this.description,
  });

  final String title;
  final String table;
  final String idColumn;
  final List<FarmField> fields;
  final String? orderBy;
  final bool readOnly;
  final bool canCreate;
  final bool canEditExisting;
  final bool canDelete;
  final bool showFarmId;
  final bool excludeDeleted;
  final bool softDelete;
  final String? description;
}
