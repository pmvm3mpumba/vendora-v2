import 'package:url_launcher/url_launcher.dart';

import '../core/utils/formatters.dart';
import '../models/enums.dart';
import '../models/order.dart';

/// Intégration WhatsApp (§15/§16) — lien `wa.me`, SANS API Business.
/// Retourne false si WhatsApp ne peut pas être ouvert → l'UI affiche alors
/// « Veuillez installer WhatsApp » (jamais de crash).
class WhatsAppService {
  /// Construit le message de commande (modèle de l'énoncé §15) pour UN
  /// vendeur donné (une commande multi-vendeurs → un message par vendeur).
  String buildOrderMessage(OrderModel order, String sellerId) {
    final items = order.itemsOf(sellerId);
    final sellerSubtotal =
        items.fold<double>(0, (sum, i) => sum + i.subtotal);
    final b = StringBuffer()
      ..writeln('*NOUVELLE COMMANDE — VENDORA*')
      ..writeln('Commande : ${order.orderNumber}')
      ..writeln('Client : ${order.clientName}')
      ..writeln('Téléphone : ${order.deliveryPhone.isNotEmpty ? order.deliveryPhone : order.clientPhone}')
      ..writeln('')
      ..writeln('Produits :');
    for (final i in items) {
      b.writeln('- ${i.name} × ${i.quantity}  (${Formatters.price(i.subtotal, order.currency)})');
    }
    b
      ..writeln('')
      ..writeln('Sous-total (vos articles) : ${Formatters.price(sellerSubtotal, order.currency)}')
      ..writeln('Livraison : ${Formatters.price(order.deliveryFee, order.currency)}')
      ..writeln('*Total : ${Formatters.price(order.total, order.currency)}*')
      ..writeln(
          'Option : ${order.deliveryOption == DeliveryOption.delivery ? 'Livraison — ${order.deliveryZoneName}' : 'Retrait en boutique'}');
    if (order.deliveryOption == DeliveryOption.delivery) {
      b.writeln('Adresse : ${order.deliveryLocation}');
    }
    b
      ..writeln(
          'Paiement : ${order.paymentMethod == PaymentMethod.mobileMoney ? 'Mobile Money' : 'Carte bancaire'} (simulé)')
      ..writeln(
          'Statut du paiement : ${order.paymentStatus == PaymentStatus.paid ? 'Payé' : order.paymentStatus.name}');
    return b.toString();
  }

  /// Ouvre WhatsApp (Android : app ; Web : nouvel onglet wa.me).
  /// [phone] accepte « +257 79 000 000 » → nettoyé en « 25779000000 ».
  Future<bool> send({required String phone, required String message}) async {
    final sanitized = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (sanitized.isEmpty) return false;
    final uri = Uri.parse(
        'https://wa.me/$sanitized?text=${Uri.encodeComponent(message)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false; // §16 — WhatsApp indisponible
    }
  }
}
