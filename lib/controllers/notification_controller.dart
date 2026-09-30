import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

/// Notifications internes (BONUS) — cloche + badge de non-lues.
class NotificationController extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  StreamSubscription? _sub;
  String? _userId;

  List<AppNotification> notifications = [];
  bool isLoading = false;

  int get unreadCount => notifications.where((n) => !n.read).length;

  void watch(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    isLoading = true;
    notifyListeners();
    _sub = _service.watchFor(userId).listen(
      (list) {
        notifications = list;
        isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(AppNotification n) => _service.markAsRead(n.id);
  Future<void> markAllAsRead() => _service.markAllAsRead(notifications);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
