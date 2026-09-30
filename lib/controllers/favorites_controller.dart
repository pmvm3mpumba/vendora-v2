import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';

/// Favoris / liste de souhaits (BONUS) — synchronisés avec `users/{uid}`.
class FavoritesController extends ChangeNotifier {
  final UserService _users = UserService();
  final ProductService _products = ProductService();

  Set<String> ids = {};
  String? _uid;
  String? error;

  /// Branché sur AuthController via ChangeNotifierProxyProvider.
  void updateUser(AppUser? user) {
    _uid = user?.uid;
    final newIds = (user?.favoriteIds ?? const <String>[]).toSet();
    if (!_setEquals(newIds, ids)) {
      ids = newIds;
      notifyListeners();
    }
  }

  bool isFavorite(String productId) => ids.contains(productId);

  /// Retourne un message si l'action est impossible (visiteur → §3).
  Future<String?> toggle(String productId) async {
    final uid = _uid;
    if (uid == null) return 'Connectez-vous pour ajouter des favoris';
    final nowFavorite = !ids.contains(productId);
    ids = {...ids, if (nowFavorite) productId else ...[]}..removeWhere(
        (id) => !nowFavorite && id == productId);
    notifyListeners(); // optimiste
    try {
      await _users.toggleFavorite(uid, productId, nowFavorite);
      return null;
    } catch (_) {
      updateUser(null); // rollback minimal — la prochaine synchro corrigera
      error = 'Erreur Firebase — réessayez';
      notifyListeners();
      return error;
    }
  }

  Future<List<Product>> favoriteProducts() => _products.getByIds(ids.toList());

  bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
