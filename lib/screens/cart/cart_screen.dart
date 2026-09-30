import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/client_shell.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/currency_menu.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/cart_item.dart';
import '../favorites/favorites_screen.dart';

/// Écran 6 — Mon panier (maquette « 05 / PANIER »).
/// Un vendeur par commande · quantités · sous-total · validation stock.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final currency = context.watch<CurrencyController>().selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        automaticallyImplyLeading: false,
        actions: const [CurrencyMenu(), SizedBox(width: 8)],
      ),
      body: SafeArea(child: _body(context, auth, cart, currency)),
      bottomNavigationBar: _cta(context, auth, cart, currency),
    );
  }

  Widget _body(BuildContext context, AuthController auth, CartController cart,
      String currency) {
    if (!auth.isAuthenticated) {
      return const GuestGate(
        title: 'Connectez-vous pour commander',
        message:
            'Votre panier et vos commandes seront liés à votre compte, en toute sécurité.',
      );
    }
    if (cart.isEmpty) {
      return EmptyView(
        icon: Icons.shopping_cart_outlined,
        title: 'Votre panier est vide',
        message: 'Parcourez le catalogue et ajoutez vos premières trouvailles.',
      );
    }
    final subtotal = cart.subtotalIn(currency);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        // ── En-tête vendeur (un vendeur par commande) ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.lineColor),
            borderRadius: BorderRadius.circular(AppTheme.rLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront, color: AppTheme.forest, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cart.sellerName ?? 'Vendeur',
                        style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w800)),
                  ),
                  Text('${cart.totalQuantity} article(s)',
                      style:
                          TextStyle(color: context.mutedColor, fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Un vendeur par commande, pour un suivi plus simple.',
                  style:
                      TextStyle(color: context.mutedColor, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Articles ──
        for (final item in cart.items) ...[
          _CartItemTile(item: item, currency: currency),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        // ── Résumé ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.lineColor),
            borderRadius: BorderRadius.circular(AppTheme.rLg),
          ),
          child: Column(
            children: [
              _row(context, 'Sous-total',
                  Formatters.price(subtotal, currency)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Livraison',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('Calculée à l\'étape suivante',
                      style:
                          TextStyle(color: context.mutedColor, fontSize: 12)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: context.lineColor, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total articles',
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  Text(Formatters.price(subtotal, currency),
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 17)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: TextStyle(
                  color: context.textColor, fontWeight: FontWeight.w700)),
        ],
      );

  Widget? _cta(BuildContext context, AuthController auth, CartController cart,
      String currency) {
    if (!auth.isAuthenticated || cart.isEmpty) return null;
    final subtotal = cart.subtotalIn(currency);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.lineColor)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.checkout),
          child: Text(
              'Passer commande · ${Formatters.price(subtotal, currency)}'),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final String currency;
  const _CartItemTile({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
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
              width: 76,
              height: 76,
              child: AppImage(item.product.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.price(item.subtotalIn(currency) / item.quantity, currency)} / unité',
                  style:
                      TextStyle(color: context.mutedColor, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                QtyStepper(
                  compact: true,
                  quantity: item.quantity,
                  onMinus: () => cart.decrement(item.product.id),
                  onPlus: () {
                    final err = cart.increment(item.product.id);
                    if (err != null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Retirer',
            icon: Icon(Icons.delete_outline, color: context.mutedColor),
            onPressed: () => cart.remove(item.product.id),
          ),
        ],
      ),
    );
  }
}
