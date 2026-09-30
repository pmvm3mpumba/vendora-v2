import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/seller_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/product.dart';

/// Écran 15 — Mes produits : édition, suppression, gestion du stock (§3/§5).
class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes produits'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => AppRoutes.pushProductForm(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Produit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: seller.myProducts.isEmpty
            ? EmptyView(
                icon: Icons.storefront_outlined,
                title: 'Aucun produit',
                message:
                    'Créez votre premier produit : il apparaîtra immédiatement dans le catalogue public.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                itemCount: seller.myProducts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _ProductTile(product: seller.myProducts[i]),
              ),
      ),
      floatingActionButton: seller.myProducts.isEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.brand,
              foregroundColor: Colors.white,
              onPressed: () => AppRoutes.pushProductForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Créer un produit'),
            )
          : null,
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final seller = context.read<SellerController>();
    final lowStock = product.stock < 5;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            child: SizedBox(
                width: 72, height: 72, child: AppImage(product.imageUrl)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.price(product.price, product.currency)} · ${product.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: context.mutedColor, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    QtyStepper(
                      compact: true,
                      quantity: product.stock,
                      onMinus: () => _adjustStock(context, seller, -1),
                      onPlus: () => _adjustStock(context, seller, 1),
                    ),
                    const SizedBox(width: 8),
                    if (lowStock)
                      const InfoPill(
                          label: 'stock faible',
                          background: AppTheme.peach,
                          foreground: AppTheme.brand)
                    else
                      const InfoPill.success(label: 'en stock'),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.mutedColor),
            onSelected: (v) {
              if (v == 'edit') {
                AppRoutes.pushProductForm(context, productId: product.id);
              } else if (v == 'delete') {
                _confirmDelete(context, seller);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 19),
                    SizedBox(width: 10),
                    Text('Modifier'),
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        size: 19, color: AppTheme.danger),
                    SizedBox(width: 10),
                    Text('Supprimer',
                        style: TextStyle(color: AppTheme.danger)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _adjustStock(
      BuildContext context, SellerController seller, int delta) async {
    final newStock = product.stock + delta;
    if (newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le stock ne peut pas être négatif')));
      return;
    }
    final ok = await seller.adjustStock(product, newStock);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(seller.error ?? 'Erreur lors de la mise à jour')));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, SellerController seller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text(
            '« ${product.name} » sera retiré définitivement du catalogue. Les commandes passées conservent leurs informations.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await seller.deleteProduct(product.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '« ${product.name} » supprimé'
            : seller.error ?? 'Erreur lors de la suppression')));
  }
}
