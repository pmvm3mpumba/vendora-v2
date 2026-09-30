import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Document Firestore `users/{uid}` — informations additionnelles (§4).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// Format international SANS « + » (ex. 25779000000) — requis vendeur.
  final String whatsappNumber;

  /// Favoris (BONUS) : ids de produits.
  final List<String> favoriteIds;

  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.whatsappNumber = '',
    this.favoriteIds = const [],
    this.createdAt,
  });

  bool get isSeller => role == UserRole.seller;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'whatsappNumber': whatsappNumber,
        'favoriteIds': favoriteIds,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        role: enumFromName(UserRole.values, map['role'], UserRole.client),
        whatsappNumber: map['whatsappNumber'] ?? '',
        favoriteIds: List<String>.from(map['favoriteIds'] ?? const []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
