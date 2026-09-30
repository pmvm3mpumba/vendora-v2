import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/vendora_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Tant que `flutterfire configure` n'a pas été exécuté, les options sont
    // des placeholders et l'initialisation échoue : l'app démarre quand même
    // et l'écran affichera les états d'erreur prévus.
    debugPrint('Firebase non initialisé — exécutez: flutterfire configure ($e)');
  }
  runApp(const VendoraApp());
}
