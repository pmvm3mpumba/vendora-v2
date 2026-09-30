import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/currency_converter.dart';
import '../models/app_user.dart';
import '../models/delivery_zone.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/payment_simulator.dart';
import 'cart_controller.dart';

/// Checkout (§9-§12) + historique client (§13) + bonus annulation.
class OrderController extends ChangeNotifier {
  final OrderService _orders = OrderService();
  final PaymentSimulator _payment = PaymentSimulator();
  final NotificationService _notifications = NotificationService();
  StreamSubscription? _sub;

  List<OrderModel> myOrders = [];
  bool isLoadingOrders = false;
  bool isProcessing = false; // pendant paiement + création
  String? error;

  void clearError() {
    error = null;
    notifyListeners();
  }

  /// Abonne l'historique du client (appelé depuis l'app cliente).
  void watchClientOrders(String clientId) {
    _sub?.cancel();
    isLoadingOrders = true;
    notifyListeners();
    _sub = _orders.watchClientOrders(clientId).listen(
      (list) {
        myOrders = list;
        isLoadingOrders = false;
        notifyListeners();
      },
      onError: (_) {
        error = 'Erreur Firebase — réessayez';
        isLoadingOrders = false;
        notifyListeners();
      },
    );
  }

  Future<OrderModel?> getOrder(String id) => _orders.getOrder(id);

  /// Validation de l'étape livraison AVANT le paiement (§10/§21).
  String? validateDelivery({
    required DeliveryOption option,
    DeliveryZone? zone,
    String? location,
    String? phone,
  }) {
    if (option == DeliveryOption.pickup) return null; // retrait : rien d'exigé
    if (zone == null) return 'Choisissez une zone de livraison';
    if ((location ?? '').trim().isEmpty) {
      return 'L\'adresse de livraison est requise';
    }
    if ((phone ?? '').trim().isEmpty) return 'Le téléphone de contact est requis';
    return null;
  }

  /// Processus complet : paiement simulé → création de la commande.
  /// Retourne l'id de la commande en cas de succès, null sinon ([error] renseigné).
  Future<String?> checkout({
    required AppUser client,
    required CartController cart,
    required String currency,
    required DeliveryOption option,
    DeliveryZone? zone,
    String location = '',
    String phone = '',
    required PaymentMethod paymentMethod,
    required bool paymentShouldSucceed, // « Scénario à tester » (maquette)
  }) async {
    error = null;

    if (cart.isEmpty) {
      error = 'Votre panier est vide';
      notifyListeners();
      return null;
    }
    final deliveryError = validateDelivery(
        option: option, zone: zone, location: location, phone: phone);
    if (deliveryError != null) {
      error = deliveryError;
      notifyListeners();
      return null;
    }

    isProcessing = true;
    notifyListeners();
    try {
      // 1. Montants convertis dans la devise choisie.
      final subtotal = cart.subtotalIn(currency);
      final feeBif = option == DeliveryOption.delivery ? (zone?.feeBif ?? 0) : 0.0;
      final deliveryFee = CurrencyConverter.convert(feeBif, 'BIF', currency);
      final total = subtotal + deliveryFee;

      // 2. Paiement SIMULÉ (scénario choisi par l'utilisateur).
      final result = await _payment.pay(
        method: paymentMethod,
        shouldSucceed: paymentShouldSucceed,
        amount: total,
        currency: currency,
      );
      if (!result.success) {
        error = result.failureReason; // §21 — échec : AUCUNE commande créée
        return null;
      }

      // 3. Articles figés dans la devise de la commande.
      final items = cart.items.map((ci) {
        final unit = CurrencyConverter.convert(
            ci.product.price, ci.product.currency, currency);
        return OrderItem(
          productId: ci.product.id,
          name: ci.product.name,
          unitPrice: unit,
          quantity: ci.quantity,
          subtotal: unit * ci.quantity,
          sellerId: ci.product.sellerId,
          sellerName: ci.product.sellerName,
          sellerWhatsapp: ci.product.sellerWhatsapp,
          imageUrl: ci.product.imageUrl,
        );
      }).toList();
      final sellerIds = items.map((i) => i.sellerId).toSet().toList();

      // 4. Création Firestore (transaction : stock re-vérifié puis décrémenté).
      final order = OrderModel(
        id: '',
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        clientId: client.uid,
        clientName: client.name,
        clientPhone: client.phone,
        items: items,
        sellerIds: sellerIds,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        currency: currency,
        deliveryOption: option,
        deliveryZoneId:
            option == DeliveryOption.delivery ? (zone?.id ?? '') : '',
        deliveryZoneName:
            option == DeliveryOption.delivery ? (zone?.name ?? '') : '',
        deliveryLocation: location.trim(),
        deliveryPhone: phone.trim(),
        paymentMethod: paymentMethod,
        paymentStatus: PaymentStatus.paid,
        paymentReference: result.reference,
        statusHistory: [
          StatusChange(status: OrderStatus.pending, at: DateTime.now())
        ],
      );
      final orderId = await _orders.createOrder(order);

      // 5. Notifications vendeurs + vidage du panier.
      for (final sellerId in sellerIds) {
        unawaited(_notifications.send(
          userId: sellerId,
          title: 'Nouvelle commande ${order.orderNumber}',
          body:
              '${items.where((i) => i.sellerId == sellerId).length} article(s) — ${client.name}',
          orderId: orderId,
        ));
      }
      cart.clear();
      return orderId;
    } on Exception catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  /// BONUS — annulation par le client (commande 'pending') + restock.
  Future<bool> cancel(OrderModel order) async {
    isProcessing = true;
    error = null;
    notifyListeners();
    try {
      await _orders.cancelOrder(order);
      unawaited(_notifications.send(
        userId: order.clientId,
        title: 'Commande ${order.orderNumber} annulée',
        orderId: order.id,
      ));
      // Rafraîchissement local optimiste.
      final idx = myOrders.indexWhere((o) => o.id == order.id);
      if (idx >= 0) {
        final fresh = await _orders.getOrder(order.id);
        if (fresh != null) myOrders[idx] = fresh;
        notifyListeners();
      }
      return true;
    } on Exception catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
