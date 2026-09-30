import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/seller_controller.dart';

/// Barre de navigation CLIENT — maquette : Accueil · Catégories ·
/// Favoris · Panier (badge) · Compte.
class ClientBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const ClientBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cartCount =
        context.select<CartController, int>((c) => c.totalQuantity);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Catégories'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoris'),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: cartCount > 0,
            backgroundColor: AppTheme.brand,
            label: Text('$cartCount',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: cartCount > 0,
            backgroundColor: AppTheme.brand,
            label: Text('$cartCount',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Panier',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Compte'),
      ],
    );
  }
}

/// Barre de navigation VENDEUR — maquette : Tableau de bord · Produits ·
/// Commandes · Profil (badge = commandes en attente).
class SellerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const SellerBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pending =
        context.select<SellerController, int>((c) => c.pendingOrdersCount);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Tableau de bord'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Produits'),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: pending > 0,
            backgroundColor: AppTheme.brand,
            label: Text('$pending',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.inventory_2_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: pending > 0,
            backgroundColor: AppTheme.brand,
            label: Text('$pending',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.inventory_2),
          ),
          label: 'Commandes',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil'),
      ],
    );
  }
}
