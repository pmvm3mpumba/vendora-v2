import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// ════════════════════════════════════════════════════════════════════════
/// STOCKAGE DES IMAGES — stratégie interchangeable (Spark-safe)
/// ════════════════════════════════════════════════════════════════════════
///  Plan A : Firebase Storage (si le bucket peut être créé sur le projet)
///  Plan B : base64 dans Firestore (100 % gratuit, aucun bucket requis) ← défaut
///
///  ➜ Pour activer le plan A : mettre [kUseFirebaseStorage] à true APRÈS
///    avoir créé le bucket Storage dans la console.
/// ════════════════════════════════════════════════════════════════════════
const bool kUseFirebaseStorage = false;

abstract class ImageStorageService {
  /// Retourne la référence stockée dans `product.imageUrl`
  /// (URL de téléchargement OU data-URI base64).
  Future<String> uploadProductImage(Uint8List bytes, String fileName);
}

/// Plan A — Firebase Storage.
class FirebaseImageStorageService implements ImageStorageService {
  final _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    final ref = _storage.ref('products/$fileName.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}

/// Plan B — base64 dans le document Firestore (limite doc : 1 Mo).
/// L'image doit être prise avec compression :
/// `image_picker.pickImage(imageQuality: 70, maxWidth: 1024)` (~150–350 Ko).
class Base64ImageStorageService implements ImageStorageService {
  @override
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    if (bytes.lengthInBytes > 800 * 1024) {
      throw Exception(
          'Image trop lourde (> 800 Ko) — choisissez une image plus petite.');
    }
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}

/// Point d'entrée unique — l'app ne connaît que cette fabrique.
ImageStorageService createImageStorageService() => kUseFirebaseStorage
    ? FirebaseImageStorageService()
    : Base64ImageStorageService();
