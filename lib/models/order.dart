import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Article d'une commande — instantané figé au moment de l'achat
/// (le produit peut ensuite être modifié/supprimé sans casser l'historique).
class OrderItem {
  final String productId;
  final String name;
  final double unitPrice; // dans la devise de la commande
  final int quantity;
  final double subtotal;
  final String sellerId;
  final String sellerName;
  final String sellerWhatsapp;
  final String imageUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.sellerId,
    required this.sellerName,
    required this.sellerWhatsapp,
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerWhatsapp': sellerWhatsapp,
        'imageUrl': imageUrl,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] ?? '',
        name: map['name'] ?? '',
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        sellerId: map['sellerId'] ?? '',
        sellerName: map['sellerName'] ?? '',
        sellerWhatsapp: map['sellerWhatsapp'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
      );
}

/// Changement de statut (BONUS : suivi + annulation).
class StatusChange {
  final OrderStatus status;
  final DateTime at;

  const StatusChange({required this.status, required this.at});

  Map<String, dynamic> toMap() =>
      {'status': status.name, 'at': Timestamp.fromDate(at)};

  factory StatusChange.fromMap(Map<String, dynamic> map) => StatusChange(
        status: enumFromName(OrderStatus.values, map['status'], OrderStatus.pending),
        at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// Document Firestore `orders/{id}` (énoncé §12).
class OrderModel {
  final String id;
  final String orderNumber; // ex. ORD-1727172000000
  final String clientId;
  final String clientName;
  final String clientPhone;
  final List<OrderItem> items;

  /// Tous les vendeurs concernés → requête `arrayContains` côté vendeur (§14).
  final List<String> sellerIds;

  final double subtotal;
  final double deliveryFee; // 0 si retrait boutique
  final double total;
  final String currency; // devise choisie par le client au checkout
  final DeliveryOption deliveryOption;
  final String deliveryZoneId; // '' si pickup
  final String deliveryZoneName;
  final String deliveryLocation; // '' si pickup (adresse exigée si livraison)
  final String deliveryPhone;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String paymentReference; // référence SIMULÉE
  final OrderStatus orderStatus;
  final List<StatusChange> statusHistory;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.items,
    required this.sellerIds,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    required this.deliveryOption,
    this.deliveryZoneId = '',
    this.deliveryZoneName = '',
    this.deliveryLocation = '',
    this.deliveryPhone = '',
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentReference = '',
    this.orderStatus = OrderStatus.pending,
    this.statusHistory = const [],
    this.createdAt,
  });

  /// Articles d'UN vendeur (pour sa vue « commandes reçues » et WhatsApp).
  List<OrderItem> itemsOf(String sellerId) =>
      items.where((i) => i.sellerId == sellerId).toList();

  bool get isCancellable =>
      orderStatus == OrderStatus.pending; // bonus : annulation client

  Map<String, dynamic> toMap() => {
        'orderNumber': orderNumber,
        'clientId': clientId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'items': items.map((i) => i.toMap()).toList(),
        'sellerIds': sellerIds,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'currency': currency,
        'deliveryOption': deliveryOption.name,
        'deliveryZoneId': deliveryZoneId,
        'deliveryZoneName': deliveryZoneName,
        'deliveryLocation': deliveryLocation,
        'deliveryPhone': deliveryPhone,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'paymentReference': paymentReference,
        'orderStatus': orderStatus.name,
        'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) => OrderModel(
        id: id,
        orderNumber: map['orderNumber'] ?? '',
        clientId: map['clientId'] ?? '',
        clientName: map['clientName'] ?? '',
        clientPhone: map['clientPhone'] ?? '',
        items: ((map['items'] as List?) ?? const [])
            .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
            .toList(),
        sellerIds: List<String>.from(map['sellerIds'] ?? const []),
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] ?? 'BIF',
        deliveryOption: enumFromName(
            DeliveryOption.values, map['deliveryOption'], DeliveryOption.delivery),
        deliveryZoneId: map['deliveryZoneId'] ?? '',
        deliveryZoneName: map['deliveryZoneName'] ?? '',
        deliveryLocation: map['deliveryLocation'] ?? '',
        deliveryPhone: map['deliveryPhone'] ?? '',
        paymentMethod: enumFromName(
            PaymentMethod.values, map['paymentMethod'], PaymentMethod.mobileMoney),
        paymentStatus: enumFromName(
            PaymentStatus.values, map['paymentStatus'], PaymentStatus.pending),
        paymentReference: map['paymentReference'] ?? '',
        orderStatus:
            enumFromName(OrderStatus.values, map['orderStatus'], OrderStatus.pending),
        statusHistory: ((map['statusHistory'] as List?) ?? const [])
            .map((s) => StatusChange.fromMap(Map<String, dynamic>.from(s)))
            .toList(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
