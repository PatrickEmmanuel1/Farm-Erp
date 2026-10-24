import 'package:flutter/material.dart';

import '../../data/model/app_notification.dart';
import '../../data/repository/notification_repository.dart';
import '../../data/user_facing_error.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    required this.farmId,
    required this.repository,
    super.key,
  });

  final String farmId;
  final NotificationRepository repository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notifications;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notifications = widget.repository.fetch(farmId: widget.farmId);
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _notifications = widget.repository.fetch(farmId: widget.farmId);
    });
    try {
      await _notifications;
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    try {
      await widget.repository.markRead(notification.id);
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await widget.repository.markAllRead(farmId: widget.farmId);
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(onPressed: _refresh, child: const Text('Dismiss')),
              ],
            ),
          Expanded(
            child: FutureBuilder<List<AppNotification>>(
              future: _notifications,
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
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final rows = snapshot.data ?? const [];
                if (rows.isEmpty) {
                  return const Center(child: Text('No notifications yet.'));
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final notification = rows[index];
                      final isRead = notification.isRead;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                          ),
                          title: Text(notification.title),
                          subtitle: Text(notification.body),
                          trailing: isRead
                              ? null
                              : IconButton(
                                  tooltip: 'Mark read',
                                  onPressed: () => _markRead(notification),
                                  icon: const Icon(Icons.done),
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
