import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/seller_controller.dart';
import '../core/widgets/app_bars_and_nav.dart';
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
