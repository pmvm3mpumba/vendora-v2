import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

/// Notifications internes (BONUS) — collection Firestore.
class NotificationService {
  final _col = FirebaseFirestore.instance.collection('notifications');

  Future<void> send({
    required String userId,
    required String title,
    String body = '',
    String orderId = '',
  }) =>
      _col.add(AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        orderId: orderId,
      ).toMap());

  Stream<List<AppNotification>> watchFor(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });

  Future<void> markAsRead(String notificationId) =>
      _col.doc(notificationId).update({'read': true});

  Future<void> markAllAsRead(List<AppNotification> notifications) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final n in notifications.where((n) => !n.read)) {
      batch.update(_col.doc(n.id), {'read': true});
    }
    await batch.commit();
  }
}
