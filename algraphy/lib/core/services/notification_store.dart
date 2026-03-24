import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      referenceId: map['reference_id']?.toString(),
      isRead: map['is_read'] == true || map['is_read'] == 1,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationStore extends ChangeNotifier {
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  final ApiClient _api = ApiClient();
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  /// Add a notification that just arrived in the foreground
  void addForegroundNotification(String title, String body, {String type = 'general', String? referenceId}) {
    _notifications.insert(0, NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      isRead: false,
      createdAt: DateTime.now(),
    ));
    _unreadCount++;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) return;

      final response = await _api.get('get_notifications', token: token);
      if (response['status'] == 'success') {
        final List data = response['data'] ?? [];
        _notifications = data.map((e) => NotificationItem.fromMap(Map<String, dynamic>.from(e))).toList();
        _unreadCount = response['unread_count'] ?? 0;
      }
    } catch (e) {
      debugPrint('NotificationStore: Failed to fetch notifications: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) return;

      await _api.post('mark_notification_read', {'notification_id': notificationId}, token: token);
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx].isRead = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationStore: Failed to mark as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) return;

      await _api.post('mark_all_notifications_read', {}, token: token);
      for (final n in _notifications) {
        n.isRead = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationStore: Failed to mark all as read: $e');
    }
  }
}
