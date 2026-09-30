import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/order_controller.dart';
import '../core/widgets/app_bars_and_nav.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/catalogue/categories_screen.dart';
import '../screens/catalogue/home_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Coque CLIENT : barre du bas permanente (Accueil · Catégories · Favoris ·
/// Panier · Compte), comme sur les maquettes. Les autres pages
/// (détails, checkout, commandes…) sont poussées AU-DESSUS.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  /// Permet de demander un onglet depuis n'importe quel écran
  /// (ex. « Voir les produits » → onglet Accueil).
  static final tabRequest = ValueNotifier<int?>(null);
  static void requestTab(int index) => tabRequest.value = index;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    CategoriesScreen(),
    FavoritesScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ClientShell.tabRequest.addListener(_onTabRequest);
    // Active historique de commandes + notifications pour le compte connecté.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().appUser;
      if (user != null) {
        context.read<OrderController>().watchClientOrders(user.uid);
        context.read<NotificationController>().watch(user.uid);
      }
    });
  }

  void _onTabRequest() {
    final requested = ClientShell.tabRequest.value;
    if (requested != null && mounted) {
      setState(() => _index = requested);
      ClientShell.tabRequest.value = null;
    }
  }

  @override
  void dispose() {
    ClientShell.tabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: ClientBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
