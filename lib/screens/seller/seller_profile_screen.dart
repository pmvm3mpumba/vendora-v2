import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/widgets/currency_menu.dart';
import '../../core/widgets/inputs.dart';
import '../../seed/seed_data.dart';
import 'categories_manage_screen.dart';

/// Écran 19 — Profil vendeur : infos, WhatsApp (§3), données de démo,
/// préférences, déconnexion.
class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.appUser;
    final theme = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Aucun profil chargé'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  // ── Carte d'identité ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.forest,
                      borderRadius:
                          BorderRadius.circular(AppTheme.rLg),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.cream,
                          child: Text(_initials(user.name),
                              style: const TextStyle(
                                  color: AppTheme.forest,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18)),
                              const SizedBox(height: 2),
                              Text('Compte vendeur',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                      fontSize: 12.5)),
                              Text(user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.6),
                                      fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SectionCaption('Ma boutique'),
                  _row(context,
                      icon: Icons.category_outlined,
                      label: 'Gérer les catégories',
                      trailing: Text('12 par défaut + personnalisées',
                          style: TextStyle(
                              color: context.mutedColor, fontSize: 12)),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CategoriesManageScreen()))),
                  const SizedBox(height: 10),
                  _row(context,
                      icon: Icons.person_outline,
                      label: 'Informations personnelles',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.personalInfo)),
                  const SizedBox(height: 10),
                  _row(context,
                      icon: Icons.chat_outlined,
                      label: 'Numéro WhatsApp',
                      trailing: Text(
                        user.whatsappNumber.isEmpty
                            ? 'À renseigner'
                            : '+${user.whatsappNumber}',
                        style: TextStyle(
                            color: user.whatsappNumber.isEmpty
                                ? AppTheme.danger
                                : context.mutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.personalInfo),
                      last: true),
                  const SizedBox(height: 10),

                  const SectionCaption('Démonstration'),
                  _SeedRow(userName: user.name, whatsapp: user.whatsappNumber, uid: user.uid),

                  const SectionCaption('Préférences'),
                  _row(context,
                      icon: Icons.payments_outlined,
                      label: 'Devise d\'affichage',
                      trailing: const CurrencyMenu(prominent: true),
                      onTap: () {}),
                  _row(context,
                      icon: Icons.dark_mode_outlined,
                      label: 'Mode sombre',
                      trailing: Switch(
                        value: theme.isDark,
                        onChanged: (v) =>
                            context.read<ThemeController>().setDark(v),
                      ),
                      onTap: () => context
                          .read<ThemeController>()
                          .setDark(!theme.isDark),
                      last: true),

                  const SectionCaption('Compte'),
                  _row(context,
                      icon: Icons.logout,
                      label: 'Se déconnecter',
                      danger: true,
                      onTap: () => _logout(context),
                      last: true),
                ],
              ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
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
    }
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
    bool danger = false,
    bool last = false,
  }) {
    final color = danger ? AppTheme.danger : context.textColor;
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      margin: EdgeInsets.only(bottom: last ? 0 : 0),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.rLg),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Icon(icon, size: 21, color: color),
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
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'V';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Bouton « Charger les données de démo » (seed Firestore : catégories +
/// produits avec images embarquées — garantit la démo hors-ligne).
class _SeedRow extends StatefulWidget {
  final String uid;
  final String userName;
  final String whatsapp;
  const _SeedRow(
      {required this.uid, required this.userName, required this.whatsapp});

  @override
  State<_SeedRow> createState() => _SeedRowState();
}

class _SeedRowState extends State<_SeedRow> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: InkWell(
        onTap: _running ? null : _seed,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              const Icon(Icons.cloud_download_outlined,
                  size: 21, color: AppTheme.brand),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Charger les données de démo',
                        style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5)),
                    Text('3 catégories + 6 produits avec images',
                        style: TextStyle(
                            color: context.mutedColor, fontSize: 12)),
                  ],
                ),
              ),
              if (_running)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(Icons.chevron_right,
                    size: 20, color: context.mutedColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seed() async {
    setState(() => _running = true);
    try {
      await SeedData.seedAll(
        sellerId: widget.uid,
        sellerName: widget.userName,
        sellerWhatsapp: widget.whatsapp,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Données de démo chargées ✓ — consultez le catalogue public')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur du seed : $e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}
