import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/seller_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../models/order.dart';

/// Écran 18 — Commandes reçues (§14) : le vendeur ne voit que SES articles.
/// BONUS : mise à jour du statut (pending → confirmed → delivered).
class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes reçues'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: seller.myOrders.isEmpty
            ? const EmptyView(
                icon: Icons.inventory_2_outlined,
                title: 'Aucune commande',
                message:
                    'Les commandes contenant vos produits apparaîtront ici en temps réel.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                itemCount: seller.myOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _SellerOrderCard(order: seller.myOrders[i]),
              ),
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final OrderModel order;
  const _SellerOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final seller = context.read<SellerController>();
    final myItems = seller.myItemsOf(order);
    final myTotal = myItems.fold<double>(0, (s, i) => s + i.subtotal);

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
          Text(Formatters.date(order.createdAt),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 17, color: context.mutedColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.clientName} · ${order.deliveryPhone.isNotEmpty ? order.deliveryPhone : order.clientPhone}',
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: context.lineColor, height: 1),
          ),
          for (final item in myItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.name} × ${item.quantity}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Text(Formatters.price(item.subtotal, order.currency),
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                order.deliveryOption == DeliveryOption.delivery
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                size: 16,
                color: context.mutedColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.deliveryOption == DeliveryOption.delivery
                      ? 'Livraison — ${order.deliveryZoneName} · ${order.deliveryLocation}'
                      : 'Retrait en boutique',
                  style:
                      TextStyle(color: context.mutedColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Paiement : ${order.paymentMethod == PaymentMethod.mobileMoney ? 'Mobile Money' : 'Carte bancaire'} · ${order.paymentStatus == PaymentStatus.paid ? 'Payé' : 'En attente'} (simulé)',
            style: TextStyle(color: context.mutedColor, fontSize: 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: context.lineColor, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Votre part',
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w700)),
              Text(Formatters.price(myTotal, order.currency),
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          _statusAction(context, seller, order),
        ],
      ),
    );
  }

  Widget _statusAction(
      BuildContext context, SellerController seller, OrderModel order) {
    Future<void> update(OrderStatus status) async {
      final ok = await seller.updateOrderStatus(order, status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Statut mis à jour — le client est notifié ✓'
              : seller.error ?? 'Erreur')));
    }

    switch (order.orderStatus) {
      case OrderStatus.pending:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
            onPressed: seller.isBusy
                ? null
                : () => update(OrderStatus.confirmed),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Confirmer la commande'),
          ),
        );
      case OrderStatus.confirmed:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
            onPressed: seller.isBusy
                ? null
                : () => update(OrderStatus.delivered),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: Text(order.deliveryOption == DeliveryOption.delivery
                ? 'Marquer comme livrée'
                : 'Marquer comme remise'),
          ),
        );
      case OrderStatus.delivered:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: AppTheme.greenText, size: 18),
            SizedBox(width: 6),
            Text('Commande finalisée',
                style: TextStyle(
                    color: AppTheme.greenText,
                    fontWeight: FontWeight.w700)),
          ],
        );
      case OrderStatus.cancelled:
        return Center(
          child: Text('Annulée par le client — stock restauré',
              style: TextStyle(color: context.mutedColor, fontSize: 12.5)),
        );
    }
  }
}
