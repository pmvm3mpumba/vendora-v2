import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

/// Panier LOCAL (§7) — seule la commande finale est persistée (Firestore).
///
/// RÈGLE MAQUETTE (« Mon panier ») : **un vendeur par commande**, pour un
/// suivi plus simple → l'ajout d'un produit d'un AUTRE vendeur renvoie
/// [conflict] ; l'UI propose alors de vider le panier et remplacer.
class CartController extends ChangeNotifier {
  static const conflict = '__seller_conflict__';

  final Map<String, CartItem> _items = {}; // productId -> ligne

  List<CartItem> get items => List.unmodifiable(_items.values);
  int get distinctCount => _items.length;
  int get totalQuantity => _items.values.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  /// Vendeur unique du panier (null si vide).
  String? get sellerId =>
      _items.isEmpty ? null : _items.values.first.product.sellerId;
  String? get sellerName =>
      _items.isEmpty ? null : _items.values.first.product.sellerName;

  double subtotalIn(String currency) =>
      _items.values.fold(0, (sum, i) => sum + i.subtotalIn(currency));

  int quantityOf(String productId) => _items[productId]?.quantity ?? 0;

  /// Ajout avec validations — retourne : null (ok) | [conflict] | message.
  String? add(Product product, {int quantity = 1}) {
    if (!product.isAvailable) return '« ${product.name} » est en rupture de stock';
    if (_items.isNotEmpty && sellerId != product.sellerId) return conflict;
    final current = quantityOf(product.id);
    if (current + quantity > product.stock) {
      return 'Stock insuffisant : ${product.stock} disponible(s)';
    }
    _items[product.id] =
        CartItem(product: product, quantity: current + quantity);
    notifyListeners();
    return null;
  }

  /// Remplace le panier par ce produit (après confirmation « changer de vendeur »).
  void replaceWith(Product product, {int quantity = 1}) {
    _items
      ..clear()
      ..[product.id] = CartItem(product: product, quantity: quantity);
    notifyListeners();
  }

  String? increment(String productId) {
    final item = _items[productId];
    if (item == null) return null;
    if (item.quantity + 1 > item.product.stock) {
      return 'Stock insuffisant : ${item.product.stock} disponible(s)';
    }
    _items[productId] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
    return null;
  }

  void decrement(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(productId);
    } else {
      _items[productId] = item.copyWith(quantity: item.quantity - 1);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
