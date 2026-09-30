import '../../models/delivery_zone.dart';

/// Constantes globales de l'application.
class AppConstants {
  AppConstants._();

  static const appName = 'Vendora';

  /// Zones de livraison (BONUS — multi-zones).
  /// Frais en BIF (convertis comme les prix). La zone par défaut affiche
  /// 5 000 BIF comme sur la maquette « Finaliser ma commande ».
  /// Le retrait en boutique [DeliveryOption.pickup] n'ajoute AUCUN frais
  /// (adresse fictive de la maquette : centre-ville, Gitega).
  static const pickupAddress = 'Centre-ville, Gitega';

  static const deliveryZones = <DeliveryZone>[
    DeliveryZone(id: 'bujumbura', name: 'Bujumbura', feeBif: 5000),
    DeliveryZone(id: 'gitega', name: 'Gitega', feeBif: 7000),
    DeliveryZone(id: 'ngozi', name: 'Ngozi', feeBif: 10000),
    DeliveryZone(id: 'autres', name: 'Autres provinces', feeBif: 15000),
  ];
}
