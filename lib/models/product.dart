import 'package:cloud_firestore/cloud_firestore.dart';

/// Document Firestore `products/{id}` (énoncé §5).
/// Les infos vendeur sont DÉNORMALISÉES (sellerName / sellerWhatsapp) afin
/// que le catalogue public et le checkout WhatsApp n'aient pas à lire
/// `users/*` (ce que les règles de sécurité interdisent aux visiteurs).
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency; // devise saisie par le vendeur (BIF/USD/EUR)
  final String categoryId;
  final String categoryName;
  final int stock;
  final String imageUrl; // https:// | asset: | data:image (base64)
  final String sellerId;
  final String sellerName;
  final String sellerWhatsapp;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.currency = 'BIF',
    this.categoryId = '',
    this.categoryName = '',
    this.stock = 0,
    this.imageUrl = '',
    this.sellerId = '',
    this.sellerName = '',
    this.sellerWhatsapp = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => isActive && stock > 0;

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameLower': name.toLowerCase(), // pour la recherche
        'description': description,
        'price': price,
        'currency': currency,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'stock': stock,
        'imageUrl': imageUrl,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerWhatsapp': sellerWhatsapp,
        'isActive': isActive,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
        id: id,
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] ?? 'BIF',
        categoryId: map['categoryId'] ?? '',
        categoryName: map['categoryName'] ?? '',
        stock: (map['stock'] as num?)?.toInt() ?? 0,
        imageUrl: map['imageUrl'] ?? '',
        sellerId: map['sellerId'] ?? '',
        sellerName: map['sellerName'] ?? '',
        sellerWhatsapp: map['sellerWhatsapp'] ?? '',
        isActive: map['isActive'] ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
