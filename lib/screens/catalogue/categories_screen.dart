import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/client_shell.dart';
import '../../app/theme.dart';
import '../../controllers/catalogue_controller.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/product.dart';
import '../catalogue/product_details_screen.dart';

/// Écran 5 — Catégories (maquette « 02 / CATÉGORIES ») : rail latéral
/// (Pour vous · Tech · Mode · Accessoires) + grille circulaire « Nos
/// essentiels » + encadré vert « Voir les produits ».
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _selected; // null = « Pour vous » (tout)

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueController>();
    final products = _selected == null
        ? catalogue.all
        : catalogue.all.where((p) => p.categoryId == _selected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rail latéral ─────────────────────────────────────
            SizedBox(
              width: 128,
              child: ListView(
                children: [
                  _RailItem(
                    label: 'Pour vous',
                    selected: _selected == null,
                    onTap: () => setState(() => _selected = null),
                  ),
                  for (final c in catalogue.categories)
                    _RailItem(
                      label: c.name,
                      selected: _selected == c.id,
                      onTap: () => setState(() => _selected = c.id),
                    ),
                ],
              ),
            ),
            // ── Contenu ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 24),
                children: [
                  Text('Nos essentiels',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (catalogue.isLoading)
                    const LoadingView()
                  else if (products.isEmpty)
                    const EmptyView(
                      title: 'Aucun produit',
                      message: 'Aucun produit dans cette catégorie.',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (_, i) => _CircleProduct(
                          product: products[i],
                          tint: ProductCard.tints[
                              products[i].id.hashCode.abs() %
                                  ProductCard.tints.length]),
                    ),
                  const SizedBox(height: 24),
                  _EssentielsBox(selectedCategory: _selected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: selected ? AppTheme.brand : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 18),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.brand : context.mutedColor,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Produit en médaillon circulaire (maquette « Nos essentiels »).
class _CircleProduct extends StatelessWidget {
  final Product product;
  final Color tint;
  const _CircleProduct({required this.product, required this.tint});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(productId: product.id))),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark ? context.cardColor : tint,
                shape: BoxShape.circle,
                border: Border.all(color: context.lineColor),
              ),
              child: ClipOval(child: AppImage(product.imageUrl)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Encadré vert « Trouvez votre prochain essentiel. » + bouton contour.
class _EssentielsBox extends StatelessWidget {
  final String? selectedCategory;
  const _EssentielsBox({this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppTheme.forest.withValues(alpha: 0.25)
            : AppTheme.forestSoft,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trouvez votre prochain essentiel.',
            style: TextStyle(
                color: AppTheme.forest,
                fontWeight: FontWeight.w800,
                fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Une sélection facile à parcourir, sans détour.',
            style: TextStyle(color: context.mutedColor, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            onPressed: () {
              context
                  .read<CatalogueController>()
                  .setCategory(selectedCategory);
              ClientShell.requestTab(0); // onglet Accueil, filtre appliqué
            },
            icon: const Icon(Icons.arrow_forward, size: 17),
            label: const Text('Voir les produits'),
          ),
        ],
      ),
    );
  }
}
