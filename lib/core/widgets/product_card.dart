import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/currency_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../models/product.dart';
import '../utils/currency_converter.dart';
import '../utils/formatters.dart';
import 'app_image.dart';

/// Carte produit de la grille « À découvrir » (maquette Accueil) :
/// image arrondie + cœur, nom, vendeur, prix, disponibilité.
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  /// Couleurs de fond pastel (si l'image a des bords visibles) — maquette.
  static const tints = [
    Color(0xFFEFE9DC),
    Color(0xFFFBECE0),
    Color(0xFFEAF0E8),
    Color(0xFFF2E9E4),
  ];

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyController>().selected;
    final favorites = context.watch<FavoritesController>();
    final isFav = favorites.isFavorite(product.id);
    final price = CurrencyConverter.convert(
        product.price, product.currency, currency);
    final tint = tints[product.id.hashCode.abs() % tints.length];

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.rLg),
      onTap: () => AppRoutes.pushProductDetails(context, product.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image FLEXIBLE : elle occupe tout l'espace laissé par les
          // textes (nom/vendeur/prix/disponibilité = hauteur fixe), donc
          // AUCUN dépassement vertical possible, quels que soient la
          // grille, la police ou l'écran.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark ? context.cardColor : tint,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: context.lineColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(product.imageUrl),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _HeartButton(
                      active: isFav,
                      onTap: () => _toggleFavorite(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(product.sellerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.mutedColor, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            Formatters.price(price, currency),
            style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 16),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: product.isAvailable
                      ? AppTheme.greenText
                      : AppTheme.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                product.isAvailable
                    ? '${product.stock} disponibles'
                    : 'Rupture de stock',
                style: TextStyle(color: context.mutedColor, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final ok = await requireAuth(context); // visiteur → écran de connexion
    if (!ok || !context.mounted) return;
    final error =
        await context.read<FavoritesController>().toggle(product.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

/// Bouton cœur des maquettes : disque blanc, cœur rempli orange si favori.
class _HeartButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _HeartButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: context.lineColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
          ],
        ),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          size: 17,
          color: active ? AppTheme.brand : context.textColor,
        ),
      ),
    );
  }
}
