import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/order_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../services/whatsapp_service.dart';

/// Écran 12 — Détails de la commande : articles, montants, livraison,
/// paiement, suivi de statut, annulation (bonus), renvoi WhatsApp.
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<OrderModel?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future =
      context.read<OrderController>().getOrder(widget.orderId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la commande')),
      body: SafeArea(
        child: FutureBuilder<OrderModel?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Chargement de la commande…');
            }
            final order = snapshot.data;
            if (order == null) {
              return ErrorView(
                  message: 'Commande introuvable.',
                  onRetry: () => Navigator.of(context).pop());
            }
            return _Content(
              order: order,
              onCancelled: () => setState(_reload),
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onCancelled;
  const _Content({required this.order, required this.onCancelled});

  @override
  Widget build(BuildContext context) {
    final qty = order.items.fold<int>(0, (s, i) => s + i.quantity);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderNumber,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text('Passée le ${Formatters.date(order.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            StatusPill.of(order.orderStatus.name),
          ],
        ),
        const SizedBox(height: 20),

        // ── Suivi du statut (bonus) ──
        SectionTitle('Suivi'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _deco(context),
          child: Column(
            children: _timeline(context),
          ),
        ),
        const SizedBox(height: 20),

        // ── Articles ──
        SectionTitle('Articles ($qty)'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _deco(context),
          child: Column(children: [
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.rSm),
                      child: SizedBox(
                          width: 48,
                          height: 48,
                          child: AppImage(item.imageUrl)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: context.textColor,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${item.quantity} × ${Formatters.price(item.unitPrice, order.currency)}',
                            style: TextStyle(
                                color: context.mutedColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(Formatters.price(item.subtotal, order.currency),
                        style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Montants ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _deco(context),
          child: Column(
            children: [
              _amount(context, 'Sous-total', order.subtotal),
              _amount(context, 'Livraison', order.deliveryFee,
                  note: order.deliveryOption == DeliveryOption.pickup
                      ? 'Retrait gratuit'
                      : null),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: context.lineColor, height: 1),
              ),
              _amount(context, 'Total', order.total, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Réception & paiement ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _deco(context),
          child: Column(
            children: [
              _infoRow(
                context,
                Icons.local_shipping_outlined,
                'Réception',
                order.deliveryOption == DeliveryOption.delivery
                    ? 'Livraison — ${order.deliveryZoneName}\n${order.deliveryLocation}\nTél. ${order.deliveryPhone}'
                    : 'Retrait en boutique (gratuit)',
              ),
              const SizedBox(height: 14),
              _infoRow(
                context,
                order.paymentMethod == PaymentMethod.mobileMoney
                    ? Icons.smartphone
                    : Icons.credit_card,
                'Paiement',
                '${order.paymentMethod == PaymentMethod.mobileMoney ? 'Mobile Money' : 'Carte bancaire'} · ${order.paymentStatus == PaymentStatus.paid ? 'Payé' : 'En attente'} (simulé)\nRéf. ${order.paymentReference}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── WhatsApp (§15) ──
        for (final sellerId in order.sellerIds) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: Text(
                'Renvoyer via WhatsApp à ${order.itemsOf(sellerId).first.sellerName}'),
            onPressed: () => _sendWhatsApp(context, sellerId),
          ),
          const SizedBox(height: 10),
        ],

        // ── Annulation (BONUS) ──
        if (order.isCancellable)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger)),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Annuler la commande'),
            onPressed: () => _cancel(context),
          ),
      ],
    );
  }

  List<Widget> _timeline(BuildContext context) {
    final history = order.statusHistory;
    final widgets = <Widget>[];
    for (var i = 0; i < history.length; i++) {
      final h = history[i];
      final last = i == history.length - 1;
      widgets.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: last ? AppTheme.brand : AppTheme.greenText,
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Container(
                    width: 2, height: 26, color: context.lineColor),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_statusLabel(h.status),
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  Text(Formatters.date(h.at),
                      style: TextStyle(
                          color: context.mutedColor, fontSize: 11.5)),
                ],
              ),
            ),
          ),
        ],
      ));
    }
    return widgets;
  }

  static String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.pending => 'Commande enregistrée',
        OrderStatus.confirmed => 'Confirmée par le vendeur',
        OrderStatus.delivered => 'En livraison / livrée',
        OrderStatus.cancelled => 'Annulée',
      };

  BoxDecoration _deco(BuildContext context) => BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      );

  Widget _amount(BuildContext context, String label, double value,
          {bool bold = false, String? note}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: bold
                        ? TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)
                        : Theme.of(context).textTheme.bodyMedium!),
                if (note != null)
                  Text(note,
                      style: TextStyle(
                          color: context.mutedColor, fontSize: 11)),
              ],
            ),
            Text(Formatters.price(value, order.currency),
                style: TextStyle(
                    color: context.textColor,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                    fontSize: bold ? 18 : 14)),
          ],
        ),
      );

  Widget _infoRow(
          BuildContext context, IconData icon, String label, String value) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.brand),
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
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: context.mutedColor,
                        fontSize: 12.5,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      );

  Future<void> _cancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text(
            'Cette action est définitive. Le stock des produits sera restauré.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non, garder')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await context.read<OrderController>().cancel(order);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Commande annulée — le vendeur en est informé.'
          : context.read<OrderController>().error ?? 'Erreur'),
    ));
    if (ok) onCancelled();
  }

  Future<void> _sendWhatsApp(BuildContext context, String sellerId) async {
    final service = WhatsAppService();
    final seller = order.itemsOf(sellerId).first;
    final ok = await service.send(
      phone: seller.sellerWhatsapp,
      message: service.buildOrderMessage(order, sellerId),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Impossible d\'ouvrir WhatsApp. Veuillez installer WhatsApp.')));
    }
  }
}
