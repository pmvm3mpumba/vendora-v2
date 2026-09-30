import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/product.dart';

/// Données de démonstration alignées sur les MAQUETTES (Casque Studio,
/// Baskets Everyday, Sac Nomade, Montre Classique…) — images embarquées
/// dans les assets → démo garantie, même hors-ligne et sans Storage.
///
/// Lancé depuis le PROFIL VENDEUR (« Charger les données de démo ») :
/// conforme aux règles Firestore (écriture réservée aux vendeurs).
class SeedData {
  SeedData._();

  /// ①② catégories PAR DÉFAUT avec icônes (chargeables sans les produits
  /// via « Gérer les catégories » → bouton dédié).
  static const categories = <Category>[
    Category(id: 'tech', name: 'Tech', icon: '🎧', order: 1),
    Category(id: 'mode', name: 'Mode & Vêtements', icon: '👕', order: 2),
    Category(id: 'accessoires', name: 'Accessoires', icon: '⌚', order: 3),
    Category(id: 'electronique', name: 'Électronique', icon: '📱', order: 4),
    Category(id: 'chaussures', name: 'Chaussures', icon: '👟', order: 5),
    Category(id: 'alimentation', name: 'Alimentation', icon: '🧺', order: 6),
    Category(id: 'boissons', name: 'Boissons', icon: '🥤', order: 7),
    Category(id: 'maison', name: 'Maison & Déco', icon: '🏠', order: 8),
    Category(id: 'beaute', name: 'Beauté & Santé', icon: '💄', order: 9),
    Category(id: 'sport', name: 'Sports & Loisirs', icon: '⚽', order: 10),
    Category(id: 'livres', name: 'Livres & Études', icon: '📚', order: 11),
    Category(id: 'bijoux', name: 'Montres & Bijoux', icon: '💍', order: 12),
  ];

  /// Charge UNIQUEMENT les 12 catégories par défaut (sans produits).
  static Future<void> seedCategoriesOnly() async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (final c in categories) {
      batch.set(db.collection('categories').doc(c.id), c.toMap());
    }
    await batch.commit();
  }

  /// Produits de démo rattachés au vendeur connecté.
  static List<Product> demoProducts({
    required String sellerId,
    required String sellerName,
    required String sellerWhatsapp,
  }) =>
      [
        _p(
          'Casque sans fil Studio',
          'Un design enveloppant, des coussinets confortables et un style minimaliste pour accompagner votre quotidien.',
          135000, 'BIF', 'tech', 12, 'assets/images/test/headphones.jpg',
        ),
        _p(
          'Baskets Everyday',
          'Baskets légères et respirantes, semelle souple antidérapante. Parfaites au quotidien. Tailles 39–45.',
          99000, 'BIF', 'mode', 8, 'assets/images/test/sneakers.jpg',
        ),
        _p(
          'Sac à dos Nomade',
          'Toile robuste et sangles en cuir, compartiment ordinateur 15". Le compagnon de vos journées.',
          75000, 'BIF', 'accessoires', 16, 'assets/images/test/backpack.jpg',
        ),
        _p(
          'Montre Classique',
          'Cadran épuré, boîtier doré et bracelet cuir véritable. Étanchéité 3 ATM. Garantie 2 ans.',
          165000, 'BIF', 'accessoires', 5, 'assets/images/test/watch.jpg',
        ),
        _p(
          'Smartphone Nova X6',
          'Écran 6,5", 128 Go, double SIM, batterie 5 000 mAh. Garantie 1 an.',
          450000, 'BIF', 'tech', 12, 'assets/images/test/phone.jpg',
        ),
        _p(
          'T-shirt Coton Bio',
          'T-shirt 100 % coton biologique, coupe unisexe. Tailles S–XXL.',
          25000, 'BIF', 'mode', 50, 'assets/images/test/tshirt.jpg',
        ),
      ]
          .map((p) => Product(
                id: '',
                name: p.name,
                description: p.description,
                price: p.price,
                currency: p.currency,
                categoryId: p.categoryId,
                categoryName:
                    categories.firstWhere((c) => c.id == p.categoryId).name,
                stock: p.stock,
                imageUrl: 'asset:${p.assetPath}',
                sellerId: sellerId,
                sellerName: sellerName,
                sellerWhatsapp: sellerWhatsapp,
              ))
          .toList();

  static Future<void> seedAll({
    required String sellerId,
    required String sellerName,
    required String sellerWhatsapp,
  }) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (final c in categories) {
      batch.set(db.collection('categories').doc(c.id), c.toMap());
    }
    await batch.commit();
    for (final p in demoProducts(
        sellerId: sellerId,
        sellerName: sellerName,
        sellerWhatsapp: sellerWhatsapp)) {
      await db.collection('products').add(p.toMap());
    }
  }
}

class _DemoProduct {
  final String name, description, categoryId, assetPath;
  final double price;
  final String currency;
  final int stock;
  const _DemoProduct(this.name, this.description, this.price, this.currency,
      this.categoryId, this.stock, this.assetPath);
}

_DemoProduct _p(String name, String desc, double price, String currency,
        String categoryId, int stock, String asset) =>
    _DemoProduct(name, desc, price, currency, categoryId, stock, asset);
