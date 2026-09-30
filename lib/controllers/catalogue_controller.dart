import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../core/utils/currency_converter.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';

/// Catalogue public (§6) : produits + recherche + filtre catégorie + tri (bonus).
class CatalogueController extends ChangeNotifier {
  final ProductService _products = ProductService();
  final CategoryService _categories = CategoryService();
  StreamSubscription? _productsSub;
  StreamSubscription? _categoriesSub;

  List<Product> all = [];
  List<Category> categories = [];
  bool isLoading = true;
  String? error;

  /// Recherche par id (détails produit) — null si supprimé/indisponible.
  Product? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  String query = '';
  String? categoryId; // null = toutes
  ProductSort sort = ProductSort.newest;

  CatalogueController() {
    _start();
  }

  void _start() {
    _productsSub?.cancel();
    isLoading = true;
    notifyListeners();
    _productsSub = _products.watchActiveProducts().listen(
      (list) {
        all = list;
        isLoading = false;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        error = 'Erreur Firebase — réessayez';
        isLoading = false;
        notifyListeners();
      },
    );
    _categoriesSub ??= _categories.watchCategories().listen(
      (list) {
        categories = list;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Bouton « Réessayer » de l'état d'erreur (ErrorView).
  void retry() => _start();

  /// Liste visible après recherche/filtre/tri.
  /// [displayCurrency] : les tri par prix se font APRÈS conversion
  /// (devises d'origine différentes).
  List<Product> visible({String displayCurrency = 'BIF'}) {
    final q = query.trim().toLowerCase();
    var list = all.where((p) {
      final matchQuery =
          q.isEmpty || p.name.toLowerCase().contains(q);
      final matchCategory = categoryId == null || p.categoryId == categoryId;
      return matchQuery && matchCategory;
    }).toList();

    switch (sort) {
      case ProductSort.newest:
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      case ProductSort.priceAsc:
        list.sort((a, b) => _priceIn(a, displayCurrency)
            .compareTo(_priceIn(b, displayCurrency)));
      case ProductSort.priceDesc:
        list.sort((a, b) => _priceIn(b, displayCurrency)
            .compareTo(_priceIn(a, displayCurrency)));
      case ProductSort.nameAsc:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  double _priceIn(Product p, String currency) =>
      CurrencyConverter.convert(p.price, p.currency, currency);

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(String? id) {
    categoryId = id;
    notifyListeners();
  }

  void setSort(ProductSort value) {
    sort = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
