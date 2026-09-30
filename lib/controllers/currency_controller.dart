import 'package:flutter/foundation.dart';

import '../core/constants/currencies.dart';

/// Devise sélectionnée par le client (§8) — BIF par défaut.
class CurrencyController extends ChangeNotifier {
  String selected = 'BIF';

  void select(String currency) {
    if (!Currencies.supported.contains(currency) || currency == selected) return;
    selected = currency;
    notifyListeners();
  }

  String get symbol => Currencies.symbolOf(selected);
}
