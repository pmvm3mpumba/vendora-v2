import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/product.dart';

/// BONUS — Favoris / liste de souhaits (maquette « 04 / FAVORIS »).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(child: _body(context, auth, favorites)),
    );
  }

  Widget _body(BuildContext context, AuthController auth,
      FavoritesController favorites) {
    // Visiteur : zone protégée (§3).
    if (!auth.isAuthenticated) {
      return _GuestGate(
        title: 'Vos favoris vous attendent',
        message:
            'Connectez-vous pour retrouver les produits que vous aimez sur tous vos appareils.',
      );
    }
    if (favorites.ids.isEmpty) {
      return const EmptyView(
        icon: Icons.favorite_border,
        title: 'Aucun favori',
        message:
            'Touchez le cœur d\'un produit pour le retrouver ici, sur tous vos appareils.',
      );
    }
    return FutureBuilder<List<Product>>(
      key: ValueKey(favorites.ids.join('-')), // recharge si la liste change
      future: favorites.favoriteProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Chargement de vos favoris…');
        }
        if (snapshot.hasError) {
          return ErrorView(
              message: 'Erreur Firebase — réessayez',
              onRetry: () =>
                  (context as Element).markNeedsBuild());
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const EmptyView(
            icon: Icons.favorite_border,
            title: 'Aucun favori',
            message: 'Touchez le cœur d\'un produit pour le garder ici.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 14,
            childAspectRatio: 0.63,
          ),
          itemBuilder: (_, i) => ProductCard(product: products[i]),
        );
      },
    );
  }
}

/// Invité à se connecter — utilisé par Favoris / Panier / Compte.
class GuestGate extends StatelessWidget {
  final String title;
  final String message;
  const GuestGate({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppTheme.brand.withValues(alpha: 0.12)
                    : AppTheme.peach,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.lock_outline, color: AppTheme.brand, size: 32),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 22),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () => requireAuth(context),
                child: const Text('Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alias privé pour la lisibilité.
class _GuestGate extends GuestGate {
  const _GuestGate({required super.title, required super.message});
}
