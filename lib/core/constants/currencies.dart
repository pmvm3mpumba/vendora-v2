/// Devises supportées (énoncé §8) — taux FIXES, documentés, sans API réelle.
///
/// Base interne de conversion : **BIF**
///   1 USD = 3 000 BIF
///   1 EUR = 3 250 BIF
/// Frais de livraison : voir zones dans `app_constants.dart`
/// (≈ 10 000 → 30 000 BIF ≈ 3,3 → 10 USD).
class Currencies {
  Currencies._();

  static const List<String> supported = ['BIF', 'USD', 'EUR'];

  /// Valeur d'UNE unité de devise en BIF.
  static const Map<String, double> toBif = {
    'BIF': 1,
    'USD': 3000,
    'EUR': 3250,
  };

  static const Map<String, String> symbols = {
    'BIF': 'FBu',
    'USD': r'$',
    'EUR': '€',
  };

  static String symbolOf(String code) => symbols[code] ?? code;
}
