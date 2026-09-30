

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';

class CategoryService {
  final _col = FirebaseFirestore.instance.collection('categories');

  Stream<List<Category>> watchCategories() => _col
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map((d) => Category.fromMap(d.id, d.data())).toList());

  /// Création / mise à jour (règles : écriture réservée aux vendeurs).
  Future<void> upsert(Category category) =>
      _col.doc(category.id).set(category.toMap());

  /// Suppression — les produits existants conservent leur `categoryName`
  /// (dénormalisé), ils disparaissent simplement du filtre de catégorie.
  Future<void> delete(String id) => _col.doc(id).delete();
}
