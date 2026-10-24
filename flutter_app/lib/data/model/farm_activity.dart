import 'model_parsing.dart';

class ActivityType {
  const ActivityType({
    this.activityTypeId,
    required this.name,
    this.category,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  final String? activityTypeId;
  final String name;
  final String? category;
  final String? description;
  final bool isActive;
  final String? createdAt;

  factory ActivityType.fromJson(JsonRow json) => ActivityType(
        activityTypeId: stringValue(json, 'activity_type_id'),
        name: stringValue(json, 'name') ?? '',
        category: stringValue(json, 'category'),
        description: stringValue(json, 'description'),
        isActive: boolValue(json, 'is_active', fallback: true),
        createdAt: stringValue(json, 'created_at'),
      );

  JsonRow toJson() => {
        if (activityTypeId != null) 'activity_type_id': activityTypeId,
        'name': name,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        'is_active': isActive,
        if (createdAt != null) 'created_at': createdAt,
      };
}

class FarmActivity {
  const FarmActivity({
    this.activityId,
    this.activityTypeId,
    this.farmId,
    this.divisionId,
    this.plantingId,
    this.workerProfileId,
    this.supervisorProfileId,
    this.activityDate,
    this.startTime,
    this.endTime,
    this.durationHours,
    this.quantity,
    this.quantityUnit,
    this.method,
    this.equipmentNeeded,
    this.notes,
    this.status,
    this.activityName,
    this.createdAt,
    this.updatedAt,
    this.startedAt,
    this.completedAt,
  });

  final String? activityId;
  final String? activityTypeId;
  final String? farmId;
  final String? divisionId;
  final String? plantingId;
  final String? workerProfileId;
  final String? supervisorProfileId;
  final String? activityDate;
  final String? startTime;
  final String? endTime;
  final double? durationHours;
  final double? quantity;
  final String? quantityUnit;
  final String? method;
  final String? equipmentNeeded;
  final String? notes;
  final String? status;
  final String? activityName;
  final String? createdAt;
  final String? updatedAt;
  final String? startedAt;
  final String? completedAt;

  String get safeActivityTypeId => activityTypeId?.trim().isNotEmpty == true
      ? activityTypeId!
      : 'General Activity';
  String get safeFarmId => farmId ?? '';
  String get safeActivityDate =>
      activityDate?.trim().isNotEmpty == true ? activityDate! : '';
  String get safeStatus =>
      status?.trim().isNotEmpty == true ? status! : 'Pending';

  factory FarmActivity.fromJson(JsonRow json) => FarmActivity(
        activityId: stringValue(json, 'activity_id'),
        activityTypeId: stringValue(json, 'activity_type_id'),
        farmId: stringValue(json, 'farm_id'),
        divisionId: stringValue(json, 'division_id'),
        plantingId: stringValue(json, 'planting_id'),
        workerProfileId: stringValue(json, 'worker_profile_id'),
        supervisorProfileId: stringValue(json, 'supervisor_profile_id'),
        activityDate: stringValue(json, 'activity_date'),
        startTime: stringValue(json, 'start_time'),
        endTime: stringValue(json, 'end_time'),
        durationHours: doubleValue(json, 'duration_hours'),
        quantity: doubleValue(json, 'quantity'),
        quantityUnit: stringValue(json, 'quantity_unit'),
        method: stringValue(json, 'method'),
        equipmentNeeded: stringValue(json, 'equipment_needed'),
        notes: stringValue(json, 'notes'),
        status: stringValue(json, 'status'),
        activityName: stringValue(json, 'activity_name'),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
        startedAt: stringValue(json, 'started_at'),
        completedAt: stringValue(json, 'completed_at'),
      );

  JsonRow toJson() => {
        if (activityId != null) 'activity_id': activityId,
        if (activityTypeId != null) 'activity_type_id': activityTypeId,
        if (farmId != null) 'farm_id': farmId,
        if (divisionId != null) 'division_id': divisionId,
        if (plantingId != null) 'planting_id': plantingId,
        if (workerProfileId != null) 'worker_profile_id': workerProfileId,
        if (supervisorProfileId != null)
          'supervisor_profile_id': supervisorProfileId,
        if (activityDate != null) 'activity_date': activityDate,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (durationHours != null) 'duration_hours': durationHours,
        if (quantity != null) 'quantity': quantity,
        if (quantityUnit != null) 'quantity_unit': quantityUnit,
        if (method != null) 'method': method,
        if (equipmentNeeded != null) 'equipment_needed': equipmentNeeded,
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
        if (activityName != null) 'activity_name': activityName,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        if (startedAt != null) 'started_at': startedAt,
        if (completedAt != null) 'completed_at': completedAt,
      };
}

class ActivitySelectionOption {
  const ActivitySelectionOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class FarmActivityFormOptions {
  const FarmActivityFormOptions({
    required this.activityTypes,
    required this.divisions,
    required this.workers,
    required this.supervisors,
  });

  final List<ActivitySelectionOption> activityTypes;
  final List<ActivitySelectionOption> divisions;
  final List<ActivitySelectionOption> workers;
  final List<ActivitySelectionOption> supervisors;
}

class FarmActivityDisplay {
  const FarmActivityDisplay({
    required this.activity,
    required this.activityTypeName,
    this.divisionName,
    this.assignedToName,
  });

  final FarmActivity activity;
  final String activityTypeName;
  final String? divisionName;
  final String? assignedToName;

  String get displayTitle {
    final title = activity.activityName?.trim();
    final text = title == null || title.isEmpty ? activityTypeName : title;
    return divisionName == null ? text : '$text ($divisionName)';
  }
}
