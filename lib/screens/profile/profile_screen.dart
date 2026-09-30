import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/client_shell.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/widgets/currency_menu.dart';
import '../../core/widgets/inputs.dart';
import '../../models/enums.dart';
import '../favorites/favorites_screen.dart';

/// Écran 13 — Mon compte (maquette « 08 / MON COMPTE »).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: !auth.isAuthenticated
            ? const GuestGate(
                title: 'Votre espace personnel',
                message:
                    'Commandes, favoris, préférences : connectez-vous pour tout retrouver ici.',
              )
            : const _AccountBody(),
      ),
    );
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.appUser!;
    final orders = context.watch<OrderController>().myOrders.length;
    final favorites = context.watch<FavoritesController>().ids.length;
    final cart = context.watch<CartController>().totalQuantity;
    final theme = context.watch<ThemeController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        // ── Carte d'identité (vert forêt) ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.forest,
            borderRadius: BorderRadius.circular(AppTheme.rLg),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.cream,
                child: Text(
                  _initials(user.name),
                  style: const TextStyle(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w900,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      user.role == UserRole.seller
                          ? 'Compte vendeur'
                          : 'Compte client',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5),
                    ),
                    Text(user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Statistiques ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.lineColor),
            borderRadius: BorderRadius.circular(AppTheme.rLg),
          ),
          child: Row(
            children: [
              _Stat(value: orders, label: 'Commandes'),
              _divider(context),
              _Stat(value: favorites, label: 'Favoris'),
              _divider(context),
              _Stat(value: cart, label: 'Au panier'),
            ],
          ),
        ),

        const SectionCaption('Mon activité'),
        _Card(
          children: [
            _NavRow(
              icon: Icons.inventory_2_outlined,
              label: 'Mes commandes',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.orderHistory),
            ),
            _NavRow(
              icon: Icons.favorite_border,
              label: 'Mes favoris',
              onTap: () => ClientShell.requestTab(2),
            ),
            _NavRow(
              icon: Icons.shopping_cart_outlined,
              label: 'Mon panier',
              onTap: () => ClientShell.requestTab(3),
              last: true,
            ),
          ],
        ),

        const SectionCaption('Mes préférences'),
        _Card(
          children: [
            _NavRow(
              icon: Icons.payments_outlined,
              label: 'Devise d\'affichage',
              trailing: const CurrencyMenu(prominent: true),
              onTap: () {}, // le menu s'ouvre via le libellé à droite
            ),
            _NavRow(
              icon: Icons.dark_mode_outlined,
              label: 'Mode sombre',
              trailing: Switch(
                value: theme.isDark,
                onChanged: (v) =>
                    context.read<ThemeController>().setDark(v),
              ),
              onTap: () =>
                  context.read<ThemeController>().setDark(!theme.isDark),
            ),
            _NavRow(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.notifications),
              last: true,
            ),
          ],
        ),

        const SectionCaption('Informations'),
        _Card(
          children: [
            _NavRow(
              icon: Icons.person_outline,
              label: 'Informations personnelles',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.personalInfo),
            ),
            _NavRow(
              icon: Icons.logout,
              label: 'Se déconnecter',
              danger: true,
              onTap: () => _logout(context),
              last: true,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous pourrez vous reconnecter à tout moment.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthController>().logout();
      // AuthGate rebascule automatiquement vers la coque visiteur.
    }
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'V';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(color: context.mutedColor, fontSize: 11.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

Widget _divider(BuildContext context) =>
    Container(width: 1, height: 40, color: context.lineColor);

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: Column(children: children),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool danger;
  final bool last;

  const _NavRow({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    this.danger = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.danger : context.textColor;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 21, color: danger ? AppTheme.danger : context.textColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5)),
                ),
                trailing ??
                    Icon(Icons.chevron_right,
                        size: 20, color: context.mutedColor),
              ],
            ),
          ),
        ),
        if (!last)
          Divider(
              height: 1, indent: 50, endIndent: 16, color: context.lineColor),
      ],
    );
  }
}
