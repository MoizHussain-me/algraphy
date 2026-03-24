import 'package:flutter/material.dart';
import '../../../core/services/notification_store.dart';
import '../../../core/theme/colors.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final NotificationStore _store = NotificationStore();

  @override
  void initState() {
    super.initState();
    // Panel shows the in-memory store immediately (updated by NotificationService).
    // Pull-to-refresh is available to force a server sync.
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'task_assignment': return Icons.task_alt_rounded;
      case 'chat_message': return Icons.chat_bubble_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'task_assignment': return Colors.blue;
      case 'chat_message': return Colors.green;
      default: return AppColors.primaryRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : Colors.white;
    final surface = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5);

    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Container(
          width: 340,
          color: bg,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_rounded, color: AppColors.primaryRed, size: 22),
                      const SizedBox(width: 8),
                      const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (_store.unreadCount > 0)
                        TextButton(
                          onPressed: _store.markAllAsRead,
                          child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.primaryRed)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // List
                Expanded(
                  child: _store.loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                      : _store.notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('No notifications yet', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.primaryRed,
                              onRefresh: _store.fetchNotifications,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _store.notifications.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                                itemBuilder: (context, index) {
                                  final notif = _store.notifications[index];
                                  return Material(
                                    color: notif.isRead ? Colors.transparent : surface,
                                    child: InkWell(
                                      onTap: () => _store.markAsRead(notif.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Icon
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _colorForType(notif.type).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(_iconForType(notif.type), color: _colorForType(notif.type), size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            // Text
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(notif.title,
                                                          style: TextStyle(
                                                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (!notif.isRead)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration: const BoxDecoration(
                                                            color: AppColors.primaryRed,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(notif.body,
                                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(_timeAgo(notif.createdAt),
                                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
