/// Paiement SIMULÉ (énoncé §11/§22) — aucune transaction réelle.
///
/// Selon la maquette « Finaliser ma commande » : le scénario est choisi
/// explicitement dans un menu déroulant « Scénario à tester ».
class PaymentTestData {
  PaymentTestData._();

  static const scenarioSuccess = 'Paiement réussi';
  static const scenarioFailure = 'Paiement refusé (simulation)';

  static const scenarios = [scenarioSuccess, scenarioFailure];
}
