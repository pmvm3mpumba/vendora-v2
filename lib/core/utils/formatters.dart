import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../constants/currencies.dart';

/// Formatage des prix et dates pour l'affichage.
class Formatters {
  Formatters._();

  static final _date = DateFormat('dd/MM/yyyy HH:mm');

  /// Format des maquettes : `135 000 BIF`, `45.0 USD`, `41.5 EUR`.
  static String price(double amount, String currency) {
    final pattern = currency == 'BIF' ? '#,##0' : '#,##0.0#';
    final value = NumberFormat(pattern, 'fr').format(amount);
    return '$value $currency';
  }

  static String date(dynamic ts) {
    final dt = ts is Timestamp ? ts.toDate() : (ts as DateTime? ?? DateTime.now());
    return _date.format(dt);
  }
}
