import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/client_shell.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/catalogue_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/utils/currency_converter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/currency_menu.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/product.dart';

/// Écran 4 — Fiche produit (maquette « 03 / FICHE PRODUIT »).
class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueController>();
    final product = catalogue.byId(widget.productId);

    // §6 : produit supprimé/indisponible depuis l'ouverture.
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'Ce produit n\'est plus disponible.',
          onRetry: () => Navigator.of(context).pop(),
        ),
      );
    }

    final currency = context.watch<CurrencyController>().selected;
    final unitPrice =
        CurrencyConverter.convert(product.price, product.currency, currency);
    final max = product.stock < 1 ? 1 : product.stock;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le détail qui compte'),
        actions: const [CurrencyMenu(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // ── Image + compteur + favori ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? context.cardColor
                        : ProductCard.tints[
                            product.id.hashCode.abs() %
                                ProductCard.tints.length],
                    borderRadius: BorderRadius.circular(AppTheme.rLg),
                    border: Border.all(color: context.lineColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(product.imageUrl),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.lineColor),
                          ),
                          child: Text('01 / 01',
                              style: TextStyle(
                                  color: context.mutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Consumer<FavoritesController>(
                          builder: (_, fav, child) => _FavCircle(
                            active: fav.isFavorite(product.id),
                            onTap: () async {
                              if (await requireAuth(context) &&
                                  context.mounted) {
                                await context
                                    .read<FavoritesController>()
                                    .toggle(product.id);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // stock + catégorie
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.isAvailable
                            ? '${product.stock} pièces en stock'
                            : 'Rupture de stock',
                        style: TextStyle(
                          color: product.isAvailable
                              ? AppTheme.greenText
                              : AppTheme.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(product.categoryName,
                          style: TextStyle(
                              color: context.mutedColor, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(product.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.price(unitPrice, currency),
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(product.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  Divider(color: context.lineColor),
                  const SizedBox(height: 14),
                  // ── Vendeur identifié ──
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? AppTheme.greenText.withValues(alpha: 0.15)
                              : AppTheme.greenSoft,
                          borderRadius: BorderRadius.circular(AppTheme.rMd),
                        ),
                        child: Text(
                          _initials(product.sellerName),
                          style: const TextStyle(
                              color: AppTheme.greenText,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.sellerName,
                                style: TextStyle(
                                    color: context.textColor,
                                    fontWeight: FontWeight.w800)),
                            Text('Vendeur Vendora',
                                style: TextStyle(
                                    color: context.mutedColor,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Icon(Icons.storefront_outlined,
                          color: context.mutedColor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: context.lineColor),
                  const SizedBox(height: 14),
                  // ── Quantité ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantité',
                              style: TextStyle(
                                  color: context.textColor,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('Maximum $max unités',
                              style: TextStyle(
                                  color: context.mutedColor, fontSize: 12)),
                        ],
                      ),
                      QtyStepper(
                        quantity: _quantity,
                        onMinus: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : () {},
                        onPlus: _quantity < max
                            ? () => setState(() => _quantity++)
                            : () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 22, color: context.textColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Livraison ou retrait gratuit en boutique',
                                style: TextStyle(
                                    color: context.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5)),
                            const SizedBox(height: 3),
                            Text(
                              'Les frais de livraison sont détaillés avant confirmation.',
                              style: TextStyle(
                                  color: context.mutedColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // ── Barre d'action : Ajouter au panier ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: context.lineColor)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed:
                product.isAvailable ? () => _addToCart(context, product) : null,
            child: Text(
              product.isAvailable
                  ? 'Ajouter au panier · ${Formatters.price(unitPrice * _quantity, currency)}'
                  : 'Produit indisponible',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, Product product) async {
    // §3 : action protégée → authentification exigée.
    if (!await requireAuth(context) || !context.mounted) return;

    final cart = context.read<CartController>();
    var result = cart.add(product, quantity: _quantity);

    // Règle maquette : un vendeur par commande → proposer le remplacement.
    if (result == CartController.conflict && context.mounted) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Changer de vendeur ?'),
          content: Text(
              'Votre panier contient déjà des produits de « ${cart.sellerName} ». '
              'Un vendeur par commande : voulez-vous vider le panier et ajouter « ${product.name} » ?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remplacer')),
          ],
        ),
      );
      if (replace == true) {
        cart.replaceWith(product, quantity: _quantity);
        result = null;
      } else {
        return;
      }
    }

    if (!context.mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} ajouté au panier'),
          action: SnackBarAction(
            label: 'Voir le panier',
            onPressed: () {
              // Retour à la coque, onglet Panier.
              Navigator.of(context).popUntil((r) => r.isFirst);
              ClientShell.requestTab(3);
            },
          ),
        ),
      );
    }
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'V';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _FavCircle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FavCircle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: context.lineColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
          ],
        ),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: active ? AppTheme.brand : context.textColor,
        ),
      ),
    );
  }
}
