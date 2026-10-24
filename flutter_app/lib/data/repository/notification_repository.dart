import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/app_notification.dart';
import '../model/model_parsing.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetch({String? farmId}) async {
    var query = _client.from('notification').select();
    if (farmId != null && farmId.isNotEmpty) {
      query = query.eq('farm_id', farmId);
    }
    final rows = await query.order('created_at', ascending: false).limit(50);
    return List<JsonRow>.from(rows).map(AppNotification.fromJson).toList();
  }

  Stream<List<AppNotification>> watch({required String farmId}) {
    return _client
        .from('notification')
        .stream(primaryKey: ['notification_id'])
        .eq('farm_id', farmId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromJson).toList());
  }

  Future<void> markRead(String id) async {
    await _client
        .from('notification')
        .update(const {'is_read': true}).eq('notification_id', id);
  }

  Future<void> markAllRead({String? farmId}) async {
    var query = _client
        .from('notification')
        .update(const {'is_read': true}).eq('is_read', false);
    if (farmId != null && farmId.isNotEmpty) {
      query = query.eq('farm_id', farmId);
    }
    await query;
  }
}
