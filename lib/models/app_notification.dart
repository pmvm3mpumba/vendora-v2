import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification interne (BONUS) — collection Firestore `notifications`.
/// Créée par l'app lors des événements : nouvelle commande (→ vendeur),
/// changement de statut / annulation (→ client).
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String orderId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    this.body = '',
    this.orderId = '',
    this.read = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'orderId': orderId,
        'read': read,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        userId: map['userId'] ?? '',
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        orderId: map['orderId'] ?? '',
        read: map['read'] ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
