import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/client_shell.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/order_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bars_and_nav.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../models/order.dart';

/// Écran 11 — Mes commandes (maquette « 07 / MES COMMANDES ») :
/// filtres Toutes / Confirmées / En livraison (+ En attente / Annulées).
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: const SafeArea(child: _Body()),
      bottomNavigationBar: ClientBottomNav(
        currentIndex: 4,
        onTap: (i) {
          Navigator.of(context).popUntil((r) => r.isFirst);
          ClientShell.requestTab(i);
        },
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  OrderStatus? _filter; // null = Toutes

  static const _chips = <(String, OrderStatus?)>[
    ('Toutes', null),
    ('En attente', OrderStatus.pending),
    ('Confirmées', OrderStatus.confirmed),
    ('En livraison', OrderStatus.delivered),
    ('Annulées', OrderStatus.cancelled),
  ];

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderController>();
    final list = _filter == null
        ? orders.myOrders
        : orders.myOrders.where((o) => o.orderStatus == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (label, status) = _chips[i];
              final selected = _filter == status;
              return InkWell(
                onTap: () => setState(() => _filter = status),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    // Maquette : filtre actif = pastille NOIRE, texte blanc.
                    color: selected
                        ? (context.isDark
                            ? const Color(0xFFF1EEE8)
                            : const Color(0xFF1B1915))
                        : context.cardColor,
                    border: Border.all(
                        color: selected ? Colors.transparent : context.lineColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? (context.isDark
                              ? const Color(0xFF1B1915)
                              : Colors.white)
                          : context.mutedColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text('${list.length} commande(s)',
              style: TextStyle(color: context.mutedColor, fontSize: 12.5)),
        ),
        Expanded(
          child: orders.isLoadingOrders
              ? const LoadingView(message: 'Chargement de vos commandes…')
              : list.isEmpty
                  ? const EmptyView(
                      icon: Icons.receipt_long,
                      title: 'Aucune commande',
                      message:
                          'Vos commandes confirmées apparaîtront ici.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _OrderCard(order: list[i]),
                    ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.first;
    final qty = order.items.fold<int>(0, (s, i) => s + i.quantity);
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
          Row(
            children: [
              Expanded(
                child: Text(order.orderNumber,
                    style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w800)),
              ),
              StatusPill.of(order.orderStatus.name),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Commande du ${Formatters.date(order.createdAt)} · ${firstItem.sellerName}',
            style: TextStyle(color: context.mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.rSm),
                child: SizedBox(
                    width: 52,
                    height: 52,
                    child: AppImage(firstItem.imageUrl)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.items.length > 1
                          ? '${firstItem.name} +${order.items.length - 1}'
                          : firstItem.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qty article(s) · ${order.deliveryOption == DeliveryOption.delivery ? 'Livraison' : 'Retrait'}',
                      style: TextStyle(
                          color: context.mutedColor, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(Formatters.price(order.total, order.currency),
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 17)),
              const Spacer(),
              InkWell(
                onTap: () =>
                    AppRoutes.pushOrderDetails(context, order.id),
                child: const Row(
                  children: [
                    Text('Voir le détail',
                        style: TextStyle(
                            color: AppTheme.brand,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        size: 15, color: AppTheme.brand),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.lineColor, height: 1),
          ),
          Text(
            'Paiement simulé : ${order.paymentStatus == PaymentStatus.paid ? 'Payé' : 'En attente'}',
            style: TextStyle(color: context.mutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
