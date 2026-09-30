import '../constants/currencies.dart';

/// Conversion entre devises via la base interne BIF (taux fixes — §8).
class CurrencyConverter {
  CurrencyConverter._();

  /// Convertit [amount] de [from] vers [to] (codes : BIF / USD / EUR).
  static double convert(double amount, String from, String to) {
    if (from == to) return amount;
    final amountInBif = amount * (Currencies.toBif[from] ?? 1);
    return amountInBif / (Currencies.toBif[to] ?? 1);
  }
}
