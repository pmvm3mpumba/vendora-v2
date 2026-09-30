import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';

/// Espace vendeur : ses produits (§5), ses commandes (§14),
/// statistiques (bonus) et mises à jour de statut (bonus).
class SellerController extends ChangeNotifier {
  final ProductService _products = ProductService();
  final OrderService _orders = OrderService();
  final NotificationService _notifications = NotificationService();
  StreamSubscription? _productsSub;
  StreamSubscription? _ordersSub;
  String? _sellerId;

  List<Product> myProducts = [];
  List<OrderModel> myOrders = [];
  bool isLoading = false;
  bool isBusy = false;
  String? error;

  /// Appelé depuis le tableau de bord vendeur (idempotent par vendeur).
  void watchAll(String sellerId) {
    if (_sellerId == sellerId) return;
    _sellerId = sellerId;
    _productsSub?.cancel();
    _ordersSub?.cancel();
    isLoading = true;
    notifyListeners();
    _productsSub = _products.watchSellerProducts(sellerId).listen(
      (list) {
        myProducts = list
          ..sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        error = 'Erreur Firebase — réessayez';
        isLoading = false;
        notifyListeners();
      },
    );
    _ordersSub = _orders.watchSellerOrders(sellerId).listen(
      (list) {
        myOrders = list;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Mes articles au sein d'une commande (le vendeur ne voit que les siens — §14).
  List<OrderItem> myItemsOf(OrderModel order) => order.itemsOf(_sellerId ?? '');

  // ---- CRUD produits ----------------------------------------------------
  Future<bool> saveProduct(Product product) => _run(() async {
        if (product.id.isEmpty) {
          await _products.createProduct(product);
        } else {
          await _products.updateProduct(product);
        }
      });

  Future<bool> deleteProduct(String productId) =>
      _run(() => _products.deleteProduct(productId));

  /// Gestion du stock (§3) — ajustement direct depuis « Mes produits ».
  Future<bool> adjustStock(Product product, int newStock) => _run(() async {
        if (newStock < 0) throw Exception('Le stock ne peut pas être négatif');
        await _products.updateProduct(
          Product(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            currency: product.currency,
            categoryId: product.categoryId,
            categoryName: product.categoryName,
            stock: newStock,
            imageUrl: product.imageUrl,
            sellerId: product.sellerId,
            sellerName: product.sellerName,
            sellerWhatsapp: product.sellerWhatsapp,
            isActive: newStock >= 0 ? product.isActive : product.isActive,
            createdAt: product.createdAt,
          ),
        );
      });

  // ---- BONUS : statuts + statistiques -----------------------------------
  Future<bool> updateOrderStatus(OrderModel order, OrderStatus status) =>
      _run(() async {
        await _orders.updateStatus(order.id, status);
        unawaited(_notifications.send(
          userId: order.clientId,
          title: 'Commande ${order.orderNumber} : ${_statusLabel(status)}',
          orderId: order.id,
        ));
      });

  static String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.pending => 'en attente',
        OrderStatus.confirmed => 'confirmée',
        OrderStatus.delivered => 'livrée',
        OrderStatus.cancelled => 'annulée',
      };

  /// Statistiques vendeur (BONUS) — calculées sur ses commandes.
  int get ordersCount => myOrders.length;
  int get productsCount => myProducts.length;
  int get pendingOrdersCount =>
      myOrders.where((o) => o.orderStatus == OrderStatus.pending).length;
  int get deliveredOrdersCount =>
      myOrders.where((o) => o.orderStatus == OrderStatus.delivered).length;

  /// Chiffre d'affaires (commandes payées, hors annulées) dans la devise demandée.
  double revenueIn(String currency) {
    var sum = 0.0;
    for (final o in myOrders.where((o) =>
        o.paymentStatus == PaymentStatus.paid &&
        o.orderStatus != OrderStatus.cancelled)) {
      final sellerShare =
          myItemsOf(o).fold<double>(0, (s, i) => s + i.subtotal);
      sum += _convert(sellerShare, o.currency, currency);
    }
    return sum;
  }

  /// Top 3 produits vendus (quantités cumulées).
  List<MapEntry<String, int>> topProducts() {
    final qty = <String, int>{};
    for (final o in myOrders.where((o) => o.orderStatus != OrderStatus.cancelled)) {
      for (final i in myItemsOf(o)) {
        qty[i.name] = (qty[i.name] ?? 0) + i.quantity;
      }
    }
    final entries = qty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }

  double _convert(double amount, String from, String to) {
    if (from == to) return amount;
    // Conversion via taux fixes (évite d'importer le contrôleur devise ici).
    const toBif = {'BIF': 1.0, 'USD': 3000.0, 'EUR': 3250.0};
    return amount * (toBif[from] ?? 1) / (toBif[to] ?? 1);
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on Exception catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }
}
