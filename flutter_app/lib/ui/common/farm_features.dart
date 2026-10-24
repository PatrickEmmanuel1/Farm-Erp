import 'farm_feature.dart';

const divisionsFeature = FarmFeature(
  title: 'Divisions',
  table: 'division',
  idColumn: 'division_id',
  orderBy: 'name',
  fields: [
    FarmField(column: 'name', label: 'Division name', required: true),
    FarmField(
      column: 'size',
      label: 'Size',
      kind: FarmFieldKind.number,
      required: true,
    ),
    FarmField(column: 'units', label: 'Size unit', initialValue: 'Acres'),
    FarmField(column: 'soil_ph', label: 'Soil pH', kind: FarmFieldKind.number),
    FarmField(
      column: 'soil_health',
      label: 'Soil health',
      kind: FarmFieldKind.multiline,
    ),
  ],
);

const cropsFeature = FarmFeature(
  title: 'Crops',
  table: 'crop',
  idColumn: 'crop_id',
  orderBy: 'name',
  showFarmId: false,
  fields: [
    FarmField(column: 'name', label: 'Crop name', required: true),
    FarmField(column: 'scientific_name', label: 'Scientific name'),
    FarmField(
      column: 'description',
      label: 'Description',
      kind: FarmFieldKind.multiline,
    ),
  ],
);

const plantingsFeature = FarmFeature(
  title: 'Crop plantings',
  table: 'crop_planting',
  idColumn: 'planting_id',
  orderBy: 'planting_date',
  fields: [
    FarmField(
      column: 'crop_id',
      label: 'Crop',
      kind: FarmFieldKind.choice,
      required: true,
      referenceTable: 'crop',
      referenceIdColumn: 'crop_id',
      referenceLabelColumn: 'name',
      referenceFarmScoped: false,
    ),
    FarmField(
      column: 'division_id',
      label: 'Division',
      kind: FarmFieldKind.choice,
      required: true,
      referenceTable: 'division',
      referenceIdColumn: 'division_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(
      column: 'planting_date',
      label: 'Planting date',
      kind: FarmFieldKind.date,
      required: true,
    ),
    FarmField(
      column: 'area_planted',
      label: 'Area planted',
      kind: FarmFieldKind.number,
    ),
    FarmField(
      column: 'area_unit',
      label: 'Area unit',
      required: true,
      initialValue: 'Acres',
    ),
    FarmField(
      column: 'quantity_planted',
      label: 'Quantity planted',
      kind: FarmFieldKind.number,
    ),
    FarmField(
      column: 'number_of_seeds',
      label: 'Number of seeds',
      kind: FarmFieldKind.number,
    ),
    FarmField(
      column: 'expected_first_harvest_date',
      label: 'Expected harvest date',
      kind: FarmFieldKind.date,
    ),
    FarmField(
      column: 'planting_status',
      label: 'Status',
      required: true,
      initialValue: 'Planned',
    ),
    FarmField(column: 'notes', label: 'Notes', kind: FarmFieldKind.multiline),
  ],
);

const harvestsFeature = FarmFeature(
  title: 'Harvests',
  table: 'crop_harvest',
  idColumn: 'harvest_id',
  orderBy: 'harvest_date',
  fields: [
    FarmField(
      column: 'planting_id',
      label: 'Planting',
      kind: FarmFieldKind.choice,
      required: true,
      referenceTable: 'crop_planting',
      referenceIdColumn: 'planting_id',
      referenceLabelColumn: 'planting_date',
    ),
    FarmField(
      column: 'division_id',
      label: 'Division',
      kind: FarmFieldKind.choice,
      required: true,
      referenceTable: 'division',
      referenceIdColumn: 'division_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(
      column: 'harvest_date',
      label: 'Harvest date',
      kind: FarmFieldKind.date,
      required: true,
    ),
    FarmField(
      column: 'quantity_harvested',
      label: 'Quantity harvested',
      kind: FarmFieldKind.number,
      required: true,
    ),
    FarmField(column: 'quantity_unit', label: 'Unit', required: true),
    FarmField(column: 'quality_grade', label: 'Quality grade'),
    FarmField(column: 'notes', label: 'Notes', kind: FarmFieldKind.multiline),
  ],
);

const activitiesFeature = FarmFeature(
  title: 'Farm activities',
  table: 'farm_activity',
  idColumn: 'activity_id',
  orderBy: 'activity_date',
  excludeDeleted: false,
  softDelete: false,
  fields: [
    FarmField(
      column: 'activity_type_id',
      label: 'Activity type',
      kind: FarmFieldKind.choice,
      required: true,
      referenceTable: 'activity_type',
      referenceIdColumn: 'activity_type_id',
      referenceLabelColumn: 'name',
      referenceFarmScoped: false,
    ),
    FarmField(
      column: 'division_id',
      label: 'Division',
      kind: FarmFieldKind.choice,
      referenceTable: 'division',
      referenceIdColumn: 'division_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(
      column: 'supervisor_profile_id',
      label: 'Assigned supervisor',
      kind: FarmFieldKind.choice,
      referenceTable: 'supervisor_profile',
      referenceIdColumn: 'supervisor_profile_id',
      referenceLabelColumn: 'full_name',
    ),
    FarmField(
      column: 'worker_profile_id',
      label: 'Assigned worker',
      kind: FarmFieldKind.choice,
      referenceTable: 'worker_profile',
      referenceIdColumn: 'worker_profile_id',
      referenceLabelColumn: 'full_name',
    ),
    FarmField(
      column: 'activity_date',
      label: 'Activity date',
      kind: FarmFieldKind.date,
      required: true,
    ),
    FarmField(
      column: 'status',
      label: 'Status',
      kind: FarmFieldKind.choice,
      initialValue: 'Pending',
      options: ['Pending', 'In Progress', 'Completed'],
    ),
    FarmField(
      column: 'duration_hours',
      label: 'Duration (hours)',
      kind: FarmFieldKind.number,
    ),
    FarmField(
        column: 'quantity', label: 'Quantity', kind: FarmFieldKind.number),
    FarmField(column: 'quantity_unit', label: 'Quantity unit'),
    FarmField(column: 'method', label: 'Method'),
    FarmField(column: 'equipment', label: 'Equipment'),
    FarmField(column: 'notes', label: 'Notes', kind: FarmFieldKind.multiline),
  ],
);

const fertilizersFeature = FarmFeature(
  title: 'Fertilizers',
  table: 'fertilizers',
  idColumn: 'fertilizer_id',
  orderBy: 'name',
  fields: [
    ..._stockFields,
    FarmField(column: 'fertilizer_type', label: 'Fertilizer type'),
  ],
);

const herbicidesFeature = FarmFeature(
  title: 'Herbicides',
  table: 'herbicide',
  idColumn: 'herbicide_id',
  orderBy: 'name',
  fields: [
    ..._stockFields,
    FarmField(column: 'active_ingredient', label: 'Active ingredient'),
  ],
);

const pesticidesFeature = FarmFeature(
  title: 'Pesticides',
  table: 'pesticide',
  idColumn: 'pesticide_id',
  orderBy: 'name',
  fields: [
    ..._stockFields,
    FarmField(column: 'active_ingredient', label: 'Active ingredient'),
  ],
);

const fungicidesFeature = FarmFeature(
  title: 'Fungicides',
  table: 'fungicide',
  idColumn: 'fungicide_id',
  orderBy: 'name',
  fields: [
    ..._stockFields,
    FarmField(column: 'active_ingredient', label: 'Active ingredient'),
  ],
);

const insecticidesFeature = FarmFeature(
  title: 'Insecticides',
  table: 'insecticide',
  idColumn: 'insecticide_id',
  orderBy: 'name',
  fields: [
    ..._stockFields,
    FarmField(column: 'active_ingredient', label: 'Active ingredient'),
  ],
);

const waterFeature = FarmFeature(
  title: 'Water',
  table: 'water',
  idColumn: 'water_id',
  orderBy: 'source_name',
  fields: [
    FarmField(column: 'source_name', label: 'Source name', required: true),
    FarmField(
      column: 'available_quantity',
      label: 'Available quantity',
      kind: FarmFieldKind.number,
      required: true,
    ),
    FarmField(column: 'unit', label: 'Unit', required: true),
    FarmField(
      column: 'reorder_level',
      label: 'Reorder level',
      kind: FarmFieldKind.number,
    ),
    FarmField(
      column: 'description',
      label: 'Description',
      kind: FarmFieldKind.multiline,
    ),
  ],
);

const _stockFields = [
  FarmField(column: 'name', label: 'Item name', required: true),
  FarmField(
    column: 'quantity',
    label: 'Quantity',
    kind: FarmFieldKind.number,
    required: true,
  ),
  FarmField(column: 'unit', label: 'Unit', required: true),
  FarmField(
    column: 'reorder_level',
    label: 'Reorder level',
    kind: FarmFieldKind.number,
  ),
  FarmField(
    column: 'description',
    label: 'Description',
    kind: FarmFieldKind.multiline,
  ),
];

const machineryFeature = FarmFeature(
  title: 'Machinery',
  table: 'machinery',
  idColumn: 'machinery_id',
  orderBy: 'name',
  fields: [
    FarmField(column: 'name', label: 'Name', required: true),
    FarmField(column: 'machinery_type', label: 'Type', required: true),
    FarmField(
      column: 'division_id',
      label: 'Division',
      kind: FarmFieldKind.choice,
      referenceTable: 'division',
      referenceIdColumn: 'division_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(column: 'brand', label: 'Brand'),
    FarmField(column: 'model', label: 'Model'),
    FarmField(column: 'serial_number', label: 'Serial number'),
    FarmField(
      column: 'purchase_date',
      label: 'Purchase date',
      kind: FarmFieldKind.date,
    ),
    FarmField(
      column: 'purchase_cost',
      label: 'Purchase cost',
      kind: FarmFieldKind.number,
    ),
    FarmField(column: 'purpose', label: 'Purpose'),
    FarmField(column: 'location', label: 'Location'),
    FarmField(column: 'condition', label: 'Condition', required: true),
    FarmField(column: 'status', label: 'Status', required: true),
    FarmField(column: 'notes', label: 'Notes', kind: FarmFieldKind.multiline),
  ],
);

const machineryUsageFeature = FarmFeature(
  title: 'Machinery usage',
  table: 'machinery_usage',
  idColumn: 'usage_id',
  orderBy: 'usage_date',
  canDelete: false,
  canEditExisting: false,
  excludeDeleted: false,
  fields: [
    FarmField(
      column: 'machinery_id',
      label: 'Machinery',
      kind: FarmFieldKind.choice,
      required: true,
      referenceTable: 'machinery',
      referenceIdColumn: 'machinery_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(
      column: 'division_id',
      label: 'Division',
      kind: FarmFieldKind.choice,
      referenceTable: 'division',
      referenceIdColumn: 'division_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(
      column: 'usage_date',
      label: 'Usage date',
      kind: FarmFieldKind.date,
      required: true,
    ),
    FarmField(
        column: 'hours_used', label: 'Hours used', kind: FarmFieldKind.number),
    FarmField(
        column: 'fuel_used', label: 'Fuel used', kind: FarmFieldKind.number),
    FarmField(column: 'fuel_unit', label: 'Fuel unit'),
    FarmField(
      column: 'hour_meter_reading',
      label: 'Hour meter reading',
      kind: FarmFieldKind.number,
    ),
    FarmField(column: 'purpose', label: 'Purpose', required: true),
    FarmField(column: 'condition_after', label: 'Condition after use'),
    FarmField(column: 'notes', label: 'Notes', kind: FarmFieldKind.multiline),
  ],
);

const machineryMaintenanceFeature = FarmFeature(
  title: 'Machinery maintenance',
  table: 'machinery_maintenance',
  idColumn: 'maintenance_id',
  orderBy: 'maintenance_date',
  canDelete: false,
  canEditExisting: false,
  excludeDeleted: false,
  fields: [
    FarmField(
      column: 'machinery_id',
      label: 'Machinery',
      kind: FarmFieldKind.choice,
      required: true,
      referenceTable: 'machinery',
      referenceIdColumn: 'machinery_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(
      column: 'maintenance_date',
      label: 'Maintenance date',
      kind: FarmFieldKind.date,
      required: true,
    ),
    FarmField(
      column: 'maintenance_type',
      label: 'Maintenance type',
      required: true,
    ),
    FarmField(
      column: 'description',
      label: 'Description',
      required: true,
      kind: FarmFieldKind.multiline,
    ),
    FarmField(column: 'cost', label: 'Cost', kind: FarmFieldKind.number),
    FarmField(column: 'service_provider', label: 'Service provider'),
    FarmField(column: 'parts_replaced', label: 'Parts replaced'),
    FarmField(
      column: 'next_maintenance_date',
      label: 'Next maintenance date',
      kind: FarmFieldKind.date,
    ),
    FarmField(
      column: 'hour_meter_reading',
      label: 'Hour meter reading',
      kind: FarmFieldKind.number,
    ),
    FarmField(column: 'condition_after', label: 'Condition after maintenance'),
    FarmField(column: 'notes', label: 'Notes', kind: FarmFieldKind.multiline),
  ],
);

const storageFacilitiesFeature = FarmFeature(
  title: 'Storage facilities',
  table: 'storage_facility',
  idColumn: 'facility_id',
  orderBy: 'name',
  canDelete: false,
  excludeDeleted: false,
  fields: [
    FarmField(column: 'name', label: 'Facility name', required: true),
    FarmField(column: 'facility_type', label: 'Facility type', required: true),
    FarmField(
      column: 'division_id',
      label: 'Division',
      kind: FarmFieldKind.choice,
      referenceTable: 'division',
      referenceIdColumn: 'division_id',
      referenceLabelColumn: 'name',
    ),
    FarmField(
      column: 'capacity_kg',
      label: 'Capacity (kg)',
      kind: FarmFieldKind.number,
    ),
    FarmField(column: 'condition', label: 'Condition'),
    FarmField(column: 'location_note', label: 'Location note'),
  ],
);

const storedProduceFeature = FarmFeature(
  title: 'Stored produce',
  table: 'stored_produce',
  idColumn: 'storage_id',
  orderBy: 'date_stored',
  fields: [
    FarmField(column: 'crop_name', label: 'Crop name', required: true),
    FarmField(
      column: 'quantity',
      label: 'Quantity',
      kind: FarmFieldKind.number,
      required: true,
    ),
    FarmField(column: 'unit', label: 'Unit', required: true),
    FarmField(column: 'location', label: 'Location'),
    FarmField(
      column: 'date_stored',
      label: 'Date stored',
      kind: FarmFieldKind.date,
      required: true,
    ),
    FarmField(column: 'condition', label: 'Condition'),
    FarmField(
      column: 'needs_attention',
      label: 'Needs attention',
      kind: FarmFieldKind.boolean,
    ),
  ],
);

const employeeProfilesFeature = FarmFeature(
  title: 'Workers',
  table: 'worker_profile',
  idColumn: 'worker_profile_id',
  orderBy: 'employee_number',
  readOnly: true,
  excludeDeleted: false,
  fields: [
    FarmField(column: 'account_id', label: 'Account'),
    FarmField(column: 'employee_number', label: 'Employee number'),
  ],
);

const notificationsFeature = FarmFeature(
  title: 'Notifications',
  table: 'notification',
  idColumn: 'notification_id',
  orderBy: 'created_at',
  readOnly: true,
  canDelete: false,
  excludeDeleted: false,
  fields: [
    FarmField(column: 'title', label: 'Notification'),
    FarmField(column: 'body', label: 'Details'),
    FarmField(column: 'type', label: 'Type'),
    FarmField(column: 'is_read', label: 'Read'),
  ],
);

const reportsFeature = FarmFeature(
  title: 'Reports',
  table: 'report',
  idColumn: 'report_id',
  orderBy: 'created_at',
  readOnly: true,
  canDelete: false,
  excludeDeleted: false,
  fields: [
    FarmField(column: 'title', label: 'Report'),
    FarmField(column: 'category', label: 'Category'),
    FarmField(column: 'status', label: 'Status'),
    FarmField(column: 'created_at', label: 'Created'),
  ],
);
