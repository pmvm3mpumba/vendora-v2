import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/client_shell.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/catalogue_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/currency_menu.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/vendora_logo.dart';

/// Écran 3 — Accueil & catalogue (maquette « 01 / ACCUEIL & CATALOGUE »).
/// Accessible aux visiteurs SANS compte (énoncé §3).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _discoverKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueController>();

    return Scaffold(
      body: SafeArea(
        child: catalogue.isLoading
            ? const LoadingView(message: 'Chargement du catalogue…')
            : catalogue.error != null
                ? ErrorView(
                    message: catalogue.error!, onRetry: catalogue.retry)
                : _buildContent(context, catalogue),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CatalogueController catalogue) {
    final currency = context.watch<CurrencyController>().selected;
    final products = catalogue.visible(displayCurrency: currency);
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _Header(),
        const SizedBox(height: 18),
        _SearchBar(),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 16, color: context.mutedColor),
            const SizedBox(width: 4),
            Text('Livraison ou retrait au Burundi',
                style:
                    TextStyle(color: context.mutedColor, fontSize: 12.5)),
            const Spacer(),
            const CurrencyMenu(),
          ],
        ),
        const SizedBox(height: 14),
        _HeroCard(discoverKey: _discoverKey),
        const SizedBox(height: 22),
        SectionTitle(
          'À chaque envie',
          linkLabel: 'Tout voir',
          onLink: () =>
              Navigator.of(context).pushNamed(AppRoutes.search),
        ),
        const SizedBox(height: 12),
        _CategoryPills(catalogue: catalogue),
        const SizedBox(height: 22),
        Row(
          key: _discoverKey,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('À découvrir',
                style: Theme.of(context).textTheme.titleLarge),
            Text('Sélection Vendora',
                style:
                    TextStyle(color: context.mutedColor, fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const EmptyView(
            icon: Icons.search_off,
            title: 'Aucun produit',
            message:
                'Aucun produit ne correspond à votre recherche pour le moment.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.63,
            ),
            itemBuilder: (_, i) => ProductCard(product: products[i]),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.lineColor),
            borderRadius: BorderRadius.circular(AppTheme.rLg),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: AppTheme.forest, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Un achat, en toute clarté',
                        style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Stock visible · Vendeur identifié · Total détaillé',
                      style: TextStyle(
                          color: context.mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// En-tête : logo + cloche (badge non-lues) + avatar compte.
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unread =
        context.select<NotificationController, int>((c) => c.unreadCount);

    return Row(
      children: [
        const VendoraLogo(size: 34),
        const Spacer(),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            if (await requireAuth(context) && context.mounted) {
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppTheme.brand,
              smallSize: 9,
              child: Icon(Icons.notifications_none,
                  size: 26, color: context.textColor),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            final auth = context.read<AuthController>();
            if (auth.isAuthenticated) {
              ClientShell.requestTab(4); // onglet Compte
            } else {
              await requireAuth(context);
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.lineColor),
            ),
            child: Icon(Icons.person_outline,
                size: 22, color: context.textColor),
          ),
        ),
      ],
    );
  }
}

/// Barre de recherche de la maquette (ouvre l'écran de recherche).
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.search),
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border.all(color: context.lineColor),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: context.mutedColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Un produit, une envie…',
                  style: TextStyle(
                      color: context.mutedColor, fontSize: 14)),
            ),
            Container(width: 1, height: 24, color: context.lineColor),
            const SizedBox(width: 8),
            Icon(Icons.tune, color: context.textColor, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Hero vert forêt « De belles trouvailles. Tout simplement. »
class _HeroCard extends StatelessWidget {
  final GlobalKey discoverKey;
  const _HeroCard({required this.discoverKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.forest,
        borderRadius: BorderRadius.circular(AppTheme.rXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -46,
            bottom: -46,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          const Positioned(
            right: 10,
            bottom: 14,
            child: ClipOval(
              child: SizedBox(
                width: 112,
                height: 112,
                child: AppImage('asset:assets/images/test/headphones.jpg'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LES ESSENTIELS DU QUOTIDIEN',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.48,
                  child: const Text(
                    'De belles trouvailles.\nTout simplement.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Explorez les produits de nos vendeurs.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.ink,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => Scrollable.ensureVisible(
                    discoverKey.currentContext!,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                  icon: const Text('Explorer la sélection'),
                  label: const Icon(Icons.north_east, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilles de catégories « À chaque envie » (maquette) — l'ICÔNE vient
/// de Firestore (c.icon), donc toute nouvelle catégorie s'affiche toute
/// seule. Sélectionnée = pêche + bordure orange.
class _CategoryPills extends StatelessWidget {
  final CatalogueController catalogue;
  const _CategoryPills({required this.catalogue});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _Pill(
        iconContent: Icon(Icons.grid_view_rounded,
            color: catalogue.categoryId == null
                ? AppTheme.brand
                : context.textColor),
        label: 'Tout',
        selected: catalogue.categoryId == null,
        onTap: () => catalogue.setCategory(null),
      ),
      for (final c in catalogue.categories)
        _Pill(
          iconContent:
              Text(c.icon, style: const TextStyle(fontSize: 24)),
          label: c.name,
          selected: catalogue.categoryId == c.id,
          onTap: () => catalogue.setCategory(c.id),
        ),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget iconContent;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.iconContent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? (context.isDark
                      ? AppTheme.brand.withValues(alpha: 0.12)
                      : AppTheme.peach)
                  : context.cardColor,
              border: Border.all(
                  color: selected ? AppTheme.brand : context.lineColor,
                  width: selected ? 1.6 : 1),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: iconContent,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppTheme.brand : context.mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
