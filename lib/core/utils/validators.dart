/// Validateurs de formulaires — couvre les cas d'erreur de l'énoncé (§21) :
/// champs vides, email invalide, prix invalide, stock négatif, etc.
class Validators {
  Validators._();

  static String? required(String? v, [String label = 'Ce champ']) =>
      (v == null || v.trim().isEmpty) ? '$label est requis' : null;

  static String? email(String? v) {
    if ((v ?? '').trim().isEmpty) return 'L\'email est requis';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim());
    return ok ? null : 'Email invalide';
  }

  /// Maquette « Créer un compte » : 8 caractères minimum.
  static String? password(String? v) {
    if ((v ?? '').isEmpty) return 'Le mot de passe est requis';
    return v!.length >= 8 ? null : '8 caractères minimum';
  }

  /// Prix : nombre strictement positif (cas « prix invalide »).
  static String? price(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Le prix est requis';
    final p = double.tryParse(v!.replaceAll(' ', '').replaceAll(',', '.'));
    if (p == null) return 'Prix invalide';
    if (p <= 0) return 'Le prix doit être supérieur à 0';
    return null;
  }

  /// Stock : entier >= 0 (cas « stock négatif »).
  static String? stock(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Le stock est requis';
    final s = int.tryParse(v!);
    if (s == null) return 'Stock invalide';
    if (s < 0) return 'Le stock ne peut pas être négatif';
    return null;
  }

  /// Téléphone burundais / international : 8 à 15 chiffres.
  static String? phone(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Le téléphone est requis';
    final digits = v!.replaceAll(RegExp(r'[\s+\-()]'), '');
    final ok = RegExp(r'^\d{8,15}$').hasMatch(digits);
    return ok ? null : 'Numéro invalide (8 à 15 chiffres)';
  }

  /// Numéro WhatsApp au format international (requis vendeur).
  static String? whatsapp(String? v) => phone(v);

  static String? cardNumber(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Le numéro de carte est requis';
    final digits = v!.replaceAll(' ', '');
    return RegExp(r'^\d{16}$').hasMatch(digits)
        ? null
        : 'Numéro de carte invalide (16 chiffres)';
  }
}
