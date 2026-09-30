/// Énumérations métier + (dé)sérialisation Firestore.

enum UserRole { client, seller }

enum DeliveryOption { delivery, pickup } // livraison | retrait boutique (§10)

enum PaymentMethod { mobileMoney, card } // paiement simulé (§11)

enum PaymentStatus { pending, paid, failed }

enum OrderStatus { pending, confirmed, delivered, cancelled }

enum ProductSort { newest, priceAsc, priceDesc, nameAsc } // bonus : tri

/// Conversion sûre String <-> enum (évite les crashs sur valeur inconnue).
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);
