import 'model_parsing.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.farmId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String farmId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  factory AppNotification.fromJson(JsonRow json) => AppNotification(
        id: stringValue(json, 'notification_id') ?? '',
        farmId: stringValue(json, 'farm_id') ?? '',
        type: stringValue(json, 'type') ?? '',
        title: stringValue(json, 'title') ?? '',
        body: stringValue(json, 'body') ?? '',
        isRead: boolValue(json, 'is_read'),
        createdAt: stringValue(json, 'created_at') ?? '',
      );

  JsonRow toJson() => {
        'notification_id': id,
        'farm_id': farmId,
        'type': type,
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': createdAt,
      };
}
