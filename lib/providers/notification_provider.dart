import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');
      
      if (notificationsJson != null) {
        final List<dynamic> notificationsData = json.decode(notificationsJson);
        _notifications = notificationsData
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      } else {
        _notifications = _getMockNotifications();
        await _saveNotifications();
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification(NotificationItem notification) async {
    try {
      _notifications.insert(0, notification);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotifications();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        _notifications.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('notifications', notificationsJson);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Mock notifications for demonstration
  List<NotificationItem> _getMockNotifications() {
    return [
      NotificationItem(
        id: '1',
        title: 'Order Delivered',
        message: 'Your order #ORD-001 has been delivered successfully!',
        type: NotificationType.order,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        data: {'order_id': 'ORD-001'},
      ),
      NotificationItem(
        id: '2',
        title: 'Special Offer',
        message: 'Get 20% off on all seafood items this weekend!',
        type: NotificationType.promotion,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: false,
        data: {'discount': '20%'},
      ),
      NotificationItem(
        id: '3',
        title: 'Order Shipped',
        message: 'Your order #ORD-002 is on its way. Track it now!',
        type: NotificationType.order,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        data: {'order_id': 'ORD-002', 'tracking': 'TRK123456789'},
      ),
      NotificationItem(
        id: '4',
        title: 'App Update',
        message: 'New features added! Check out the latest improvements.',
        type: NotificationType.system,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: 'Reminder',
        message: 'Don\'t forget to review your recent order!',
        type: NotificationType.reminder,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        data: {'order_id': 'ORD-001'},
      ),
      NotificationItem(
        id: '6',
        title: 'New Product Alert',
        message: 'Fresh lobster tails are now available!',
        type: NotificationType.promotion,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
        data: {'product_id': 'lobster_tails'},
      ),
    ];
  }
}
