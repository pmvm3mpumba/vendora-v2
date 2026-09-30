import '../models/enums.dart';

class PaymentResult {
  final bool success;
  final String reference;
  final String? failureReason;

  const PaymentResult.ok(this.reference)
      : success = true,
        failureReason = null;
  const PaymentResult.failed(this.failureReason)
      : success = false,
        reference = '';
}

/// Paiement SIMULÉ (énoncé §11/§22) — aucune transaction réelle, aucune
/// donnée bancaire demandée (maquette). Simule : traitement (délai),
/// succès, échec — selon le scénario choisi dans le checkout.
class PaymentSimulator {
  Future<PaymentResult> pay({
    required PaymentMethod method,
    required bool shouldSucceed,
    required double amount,
    required String currency,
  }) async {
    // « Payment processing » simulé.
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!shouldSucceed) {
      return const PaymentResult.failed(
          'Paiement refusé (scénario de simulation). Votre commande n\'a pas été créée — vous pouvez réessayer.');
    }
    final ref =
        'SIM-${method == PaymentMethod.mobileMoney ? 'MOMO' : 'CARD'}-${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult.ok(ref);
  }
}
