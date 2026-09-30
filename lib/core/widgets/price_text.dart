import 'package:flutter/material.dart';

import '../utils/currency_converter.dart';
import '../utils/formatters.dart';

/// Affiche un prix converti dans la devise choisie par le client.
/// [currency] = devise d'ORIGINE du montant (celle stockée dans Firestore).
class PriceText extends StatelessWidget {
  final double amount;
  final String currency;
  final String displayCurrency;
  final TextStyle? style;

  const PriceText({
    super.key,
    required this.amount,
    required this.currency,
    required this.displayCurrency,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final converted = CurrencyConverter.convert(amount, currency, displayCurrency);
    return Text(Formatters.price(converted, displayCurrency), style: style);
  }
}
