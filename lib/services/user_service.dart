import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Accès à la collection `users` (§4) + favoris (bonus).
class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null;
  }

  Stream<AppUser?> watchUser(String uid) => _col.doc(uid).snapshots().map(
      (doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);

  Future<void> createUser(AppUser user) =>
      _col.doc(user.uid).set(user.toMap());

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _col.doc(uid).update(data);

  /// Favoris (BONUS) — ajout/retrait atomiques dans le doc utilisateur.
  Future<void> toggleFavorite(String uid, String productId, bool isFavorite) =>
      _col.doc(uid).update({
        'favoriteIds': isFavorite
            ? FieldValue.arrayUnion([productId])
            : FieldValue.arrayRemove([productId]),
      });
}
