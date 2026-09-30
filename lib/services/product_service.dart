import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

/// CRUD produits (§5) + catalogue public (§6).
/// La recherche/le filtre/le tri sont faits côté client dans le
/// CatalogueController (volumes d'examen → simple et sans index composite).
class ProductService {
  final _col = FirebaseFirestore.instance.collection('products');

  /// Catalogue public — lu par les visiteurs (règle `read: if true`).
  Stream<List<Product>> watchActiveProducts() => _col
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());

  /// Produits d'UN vendeur (écran « Mes produits » — inclut les inactifs).
  Stream<List<Product>> watchSellerProducts(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());

  Future<Product?> getProduct(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? Product.fromMap(doc.id, doc.data()!) : null;
  }

  /// Produits par ids (écran Favoris — whereIn ≤ 30, largement suffisant ici).
  Future<List<Product>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _col
        .where(FieldPath.documentId, whereIn: ids.take(30).toList())
        .get();
    return snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
  }

  Future<String> createProduct(Product product) async {
    final ref = await _col.add(product.toMap());
    return ref.id;
  }

  Future<void> updateProduct(Product product) =>
      _col.doc(product.id).update(product.toMap());

  /// Suppression physique (§5 — « delete their own products »).
  /// Les commandes passées conservent leur instantané d'articles.
  Future<void> deleteProduct(String id) => _col.doc(id).delete();
}
