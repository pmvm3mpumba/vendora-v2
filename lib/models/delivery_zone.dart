/// Zone de livraison (BONUS multi-zones) — liste fixe dans
/// `core/constants/app_constants.dart`. Frais en BIF.
class DeliveryZone {
  final String id;
  final String name;
  final double feeBif;

  const DeliveryZone({
    required this.id,
    required this.name,
    required this.feeBif,
  });
}
