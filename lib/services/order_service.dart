import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/order.dart';

/// Commandes (§12/§13/§14) + bonus : changement de statut, annulation.
class OrderService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('orders');

  /// Crée la commande ET décrémente les stocks dans une transaction
  /// (le stock est re-vérifié à l'intérieur — cas « quantité > stock » §21).
  Future<String> createOrder(OrderModel order) async {
    final ref = _col.doc();
    await _db.runTransaction((tx) async {
      // 1. Re-vérification du stock de chaque produit.
      final productRefs = order.items
          .map((i) => _db.collection('products').doc(i.productId))
          .toList();
      final snapshots = [for (final r in productRefs) await tx.get(r)];
      for (var i = 0; i < snapshots.length; i++) {
        final stock = (snapshots[i].data()?['stock'] as num?)?.toInt() ?? 0;
        if (!snapshots[i].exists || stock < order.items[i].quantity) {
          throw Exception(
              'Stock insuffisant pour « ${order.items[i].name} » (disponible : $stock)');
        }
      }
      // 2. Décrémentation.
      for (var i = 0; i < snapshots.length; i++) {
        tx.update(productRefs[i],
            {'stock': FieldValue.increment(-order.items[i].quantity)});
      }
      // 3. Création de la commande.
      tx.set(ref, order.toMap());
    });
    return ref.id;
  }

  /// Historique du client (§13) — tri côté client pour éviter un index composite.
  Stream<List<OrderModel>> watchClientOrders(String clientId) => _col
      .where('clientId', isEqualTo: clientId)
      .snapshots()
      .map(_sortedByDateDesc);

  /// Commandes contenant les produits du vendeur (§14).
  Stream<List<OrderModel>> watchSellerOrders(String sellerId) => _col
      .where('sellerIds', arrayContains: sellerId)
      .snapshots()
      .map(_sortedByDateDesc);

  Future<OrderModel?> getOrder(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? OrderModel.fromMap(doc.id, doc.data()!) : null;
  }

  /// BONUS — mise à jour du statut par le vendeur (pending → confirmed → delivered).
  Future<void> updateStatus(String orderId, OrderStatus status) =>
      _col.doc(orderId).update({
        'orderStatus': status.name,
        'statusHistory': FieldValue.arrayUnion([
          StatusChange(status: status, at: DateTime.now()).toMap(),
        ]),
      });

  /// BONUS — annulation par le client (commande 'pending') + restock.
  Future<void> cancelOrder(OrderModel order) async {
    if (!order.isCancellable) {
      throw Exception('Seule une commande en attente peut être annulée');
    }
    await _db.runTransaction((tx) async {
      for (final item in order.items) {
        tx.update(_db.collection('products').doc(item.productId),
            {'stock': FieldValue.increment(item.quantity)});
      }
      tx.update(_col.doc(order.id), {
        'orderStatus': OrderStatus.cancelled.name,
        'statusHistory': FieldValue.arrayUnion([
          StatusChange(status: OrderStatus.cancelled, at: DateTime.now()).toMap(),
        ]),
      });
    });
  }

  List<OrderModel> _sortedByDateDesc(QuerySnapshot<Map<String, dynamic>> s) {
    final list =
        s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
    list.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }
}
