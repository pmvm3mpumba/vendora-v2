import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/seller_controller.dart';
import '../core/widgets/app_bars_and_nav.dart';
import '../seed/seed_data.dart';
import '../services/category_service.dart';
import '../screens/seller/my_products_screen.dart';
import '../screens/seller/seller_dashboard_screen.dart';
import '../screens/seller/seller_orders_screen.dart';
import '../screens/seller/seller_profile_screen.dart';

/// Coque VENDEUR : barre du bas (Tableau de bord · Produits · Commandes ·
/// Profil), comme sur les maquettes « Espace vendeur ».
class SellerShell extends StatefulWidget {
  const SellerShell({super.key});

  static final tabRequest = ValueNotifier<int?>(null);
  static void requestTab(int index) => tabRequest.value = index;

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _index = 0;
  bool _seedChecked = false;

  Future<void> _autoSeedCategories() async {
    if (_seedChecked || !mounted) return;
    _seedChecked = true;
    final auth = context.read<AuthController>();
    if (!auth.isSeller) return;

    try {
      // Première émission réelle du stream (évite l'état transitoire
      // vide). En cas de délai dépassé ou d'erreur, on bascule dans le
      // catch : le bouton manuel reste disponible.
      final existing = await CategoryService()
          .watchCategories()
          .first
          .timeout(const Duration(seconds: 8));
      if (existing.isNotEmpty) return;
      await SeedData.seedCategoriesOnly();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('12 catégories par défaut chargées automatiquement ✓')));
    } catch (_) {
      // Hors-ligne ou erreur : le bouton manuel reste disponible dans
      // Profil → Gérer les catégories.
    }
  }

  static const _tabs = [
    SellerDashboardScreen(),
    MyProductsScreen(),
    SellerOrdersScreen(),
    SellerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SellerShell.tabRequest.addListener(_onTabRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().appUser;
      if (user != null) context.read<SellerController>().watchAll(user.uid);
      // Chargement AUTOMATIQUE des 12 catégories par défaut : si la
      // collection est vide on la remplit (écriture autorisée : isSeller).
      _autoSeedCategories();
    });
  }

  void _onTabRequest() {
    final requested = SellerShell.tabRequest.value;
    if (requested != null && mounted) {
      setState(() => _index = requested);
      SellerShell.tabRequest.value = null;
    }
  }

  @override
  void dispose() {
    SellerShell.tabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SellerBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
