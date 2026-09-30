import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/client_shell.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/order_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../services/whatsapp_service.dart';

/// Écran 10 — Confirmation de commande (étape 3 du stepper des maquettes)
/// + bouton « Envoyer via WhatsApp » (§15/§16).
class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<OrderModel?>(
          future: context.read<OrderController>().getOrder(orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(
                  message: 'Confirmation de votre commande…');
            }
            final order = snapshot.data;
            if (order == null) {
              return ErrorView(
                message: 'Commande introuvable.',
                onRetry: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
              );
            }
            return _Content(order: order);
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final OrderModel order;
  const _Content({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppTheme.greenText.withValues(alpha: 0.15)
                  : AppTheme.greenSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppTheme.greenText, size: 52),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('Commande confirmée !',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Merci ${order.clientName}. Votre commande ${order.orderNumber} '
            'a été enregistrée et le paiement simulé a réussi.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.lineColor),
            borderRadius: BorderRadius.circular(AppTheme.rLg),
          ),
          child: Column(
            children: [
              _line(context, 'Commande', order.orderNumber),
              _line(context, 'Articles',
                  '${order.items.fold<int>(0, (s, i) => s + i.quantity)}'),
              _line(
                  context,
                  'Réception',
                  order.deliveryOption == DeliveryOption.delivery
                      ? 'Livraison — ${order.deliveryZoneName}'
                      : 'Retrait en boutique'),
              _line(
                  context,
                  'Paiement',
                  '${order.paymentMethod == PaymentMethod.mobileMoney ? 'Mobile Money' : 'Carte bancaire'} · Payé (simulé)'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: context.lineColor, height: 1),
              ),
              _line(context, 'Total',
                  Formatters.price(order.total, order.currency),
                  bold: true),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── WhatsApp (§15) : un message par vendeur de la commande ──
        for (final sellerId in order.sellerIds) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: Text(
                'Envoyer via WhatsApp à ${order.itemsOf(sellerId).first.sellerName}'),
            onPressed: () => _sendWhatsApp(context, order, sellerId),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.receipt_long, size: 18),
          label: const Text('Voir mes commandes'),
          onPressed: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            Navigator.of(context).pushNamed(AppRoutes.orderHistory);
          },
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            ClientShell.requestTab(0); // retour catalogue
          },
          child: const Text('Retour à l\'accueil'),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String label, String value,
          {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                  fontSize: bold ? 17 : 14,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _sendWhatsApp(
      BuildContext context, OrderModel order, String sellerId) async {
    final service = WhatsAppService();
    final seller = order.itemsOf(sellerId).first;
    final ok = await service.send(
      phone: seller.sellerWhatsapp,
      message: service.buildOrderMessage(order, sellerId),
    );
    if (!context.mounted) return;
    if (!ok) {
      // §16 — WhatsApp indisponible : message clair, JAMAIS de crash.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Impossible d\'ouvrir WhatsApp. Veuillez installer WhatsApp pour envoyer la commande.'),
        ),
      );
    }
  }
}
