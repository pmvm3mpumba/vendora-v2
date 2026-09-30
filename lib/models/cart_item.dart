import '../core/utils/currency_converter.dart';
import 'product.dart';

/// Ligne de panier — stockée LOCALEMENT (Provider), jamais dans Firestore
/// (autorisé par l'énoncé §7 ; seule la commande finale est persistée).
class CartItem {
  final Product product; // instantané du produit au moment de l'ajout
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  double subtotalIn(String currency) =>
      CurrencyConverter.convert(subtotal, product.currency, currency);

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}
