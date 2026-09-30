import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/seller_shell.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/seller_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';

/// Écran 14 — Tableau de bord vendeur (maquette « 09 / TABLEAU DE BORD
/// VENDEUR ») : 4 cartes de stats, ventes de la semaine (barres),
/// répartition livraison/retrait (donut), stocks à surveiller.
/// BONUS : toutes les statistiques sont calculées depuis les VRAIES
/// commandes/produits Firestore du vendeur connecté.
class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().appUser;
    final seller = context.watch<SellerController>();
    final currency = context.watch<CurrencyController>().selected;

    if (seller.isLoading && seller.myProducts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Espace vendeur'),
            automaticallyImplyLeading: false),
        body: const LoadingView(message: 'Chargement de votre boutique…'),
      );
    }
    if (seller.error != null && seller.myProducts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Espace vendeur'),
            automaticallyImplyLeading: false),
        body: ErrorView(
            message: seller.error!,
            onRetry: () => seller.watchAll(user?.uid ?? '')),
      );
    }

    final active =
        seller.myOrders.where((o) => o.orderStatus != OrderStatus.cancelled);
    final deliveries =
        active.where((o) => o.deliveryOption == DeliveryOption.delivery).length;
    final pickups = active.length - deliveries;
    final lowStock =
        seller.myProducts.where((p) => p.stock < 5).toList()
          ..sort((a, b) => a.stock.compareTo(b.stock));
    final (weekValues, weekLabels) = _weeklySales(seller);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace vendeur'),
        automaticallyImplyLeading: false,
        actions: const [_NotificationsBell()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            // ── En-tête ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user?.name ?? 'Vendeur'} · vendeur',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Text('Votre boutique,\nen un coup d\'œil.',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? AppTheme.greenText.withValues(alpha: 0.15)
                        : AppTheme.greenSoft,
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                  ),
                  child: Text(
                    _initials(user?.name ?? 'V'),
                    style: const TextStyle(
                        color: AppTheme.greenText,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('7 derniers jours · temps réel Firestore',
                    style: Theme.of(context).textTheme.bodySmall),
                InkWell(
                  onTap: () => AppRoutes.pushProductForm(context),
                  child: const Text('+ Produit',
                      style: TextStyle(
                          color: AppTheme.brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── 4 cartes de statistiques ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
              children: [
                _StatCard(
                  icon: Icons.bar_chart,
                  iconColor: AppTheme.forest,
                  label: 'Ventes confirmées',
                  value: Formatters.price(
                          seller.revenueIn(currency), currency)
                      .replaceAll(' $currency', ''),
                  caption: '$currency · paiements simulés',
                ),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppTheme.forest,
                  label: 'Commandes',
                  value: '${seller.ordersCount}',
                  caption: '$deliveries livraisons · $pickups retraits',
                ),
                _StatCard(
                  icon: Icons.storefront_outlined,
                  iconColor: AppTheme.forest,
                  label: 'Produits actifs',
                  value: '${seller.productsCount}',
                  caption: 'Sur votre catalogue',
                ),
                _StatCard(
                  icon: Icons.notifications_none,
                  iconColor: AppTheme.brand,
                  label: 'Stocks à surveiller',
                  value: '${lowStock.length}',
                  caption: 'Moins de 5 unités',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Ventes sur la semaine ──
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ventes sur la semaine',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text('k BIF',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  WeeklyBarChart(values: weekValues, dayLabels: weekLabels),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Répartition livraison / retrait ──
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comment les clients reçoivent-ils ?',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                      'Répartition des ${active.length} commande${active.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SplitDonut(
                        fraction: active.isEmpty
                            ? 0
                            : deliveries / active.length,
                        centerTop: '${active.length}',
                        centerBottom: 'commandes',
                        size: 140,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _LegendRow(
                              color: AppTheme.forest,
                              label: 'Livraison',
                              count: deliveries,
                              total: active.length,
                            ),
                            const SizedBox(height: 14),
                            _LegendRow(
                              color: AppTheme.cream,
                              label: 'Retrait',
                              count: pickups,
                              total: active.length,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Stocks à surveiller ──
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stocks à surveiller',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('Moins de 5 unités restantes',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  if (lowStock.isEmpty)
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppTheme.greenText, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Tous vos stocks sont confortables.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    )
                  else
                    for (final p in lowStock.take(3)) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: context.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5)),
                          ),
                          const InfoPill(
                              label: 'stock faible',
                              background: AppTheme.peach,
                              foreground: AppTheme.brand),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (p.stock / 10).clamp(0.05, 1.0),
                          minHeight: 7,
                          backgroundColor:
                              context.isDark
                                  ? const Color(0xFF37332C)
                                  : const Color(0xFFEFEDE7),
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.brand),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${p.stock} unités restantes',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                    ],
                  InkWell(
                    onTap: () => SellerShell.requestTab(1),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Gérer mes produits',
                            style: TextStyle(
                                color: AppTheme.brand,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward,
                            size: 16, color: AppTheme.brand),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Statistiques réelles : calculées uniquement à partir de vos produits et commandes Firestore.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Chiffre d'affaires des 7 derniers jours (en k BIF) + initiales des jours.
  (List<double>, List<String>) _weeklySales(SellerController seller) {
    const dayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];
    for (var d = 6; d >= 0; d--) {
      final day = DateTime(now.year, now.month, now.day - d);
      var sum = 0.0;
      for (final o in seller.myOrders) {
        if (o.createdAt == null ||
            o.orderStatus == OrderStatus.cancelled ||
            o.paymentStatus != PaymentStatus.paid) {
          continue;
        }
        final c = o.createdAt!;
        if (c.year == day.year && c.month == day.month && c.day == day.day) {
          final share =
              seller.myItemsOf(o).fold<double>(0, (s, i) => s + i.subtotal);
          const toBif = {'BIF': 1.0, 'USD': 3000.0, 'EUR': 3250.0};
          sum += share * (toBif[o.currency] ?? 1);
        }
      }
      values.add(sum / 1000); // k BIF
      labels.add(dayLetters[day.weekday - 1]);
    }
    return (values, labels);
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'V';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: iconColor),
          const Spacer(),
          Text(label,
              style: TextStyle(color: context.mutedColor, fontSize: 12)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    color: context.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 2),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.mutedColor, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count * 100 / total).round();
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              Text('$pct % des commandes',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Text('$count',
            style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 16)),
      ],
    );
  }
}

/// Cloche + badge des notifications non lues de l'espace vendeur —
/// cliquer ouvre le centre de notifications (nouvelles commandes,
/// annulations de clients…).
class _NotificationsBell extends StatelessWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationController>().unreadCount;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: 'Notifications',
        onPressed: () =>
            Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.notifications),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 9 ? '9+' : '$unread'),
          backgroundColor: AppTheme.brand,
          textColor: Colors.white,
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }
}

