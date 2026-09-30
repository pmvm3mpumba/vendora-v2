// ⚠️ FICHIER PLACEHOLDER — sera écrasé par :
//     flutterfire configure --project=vendora-19a5c
// Ne jamais saisir les clés à la main : la CLI les génère depuis la console.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBK8mFAayPeftIFC8IYngTuokQjjYAOM8k',
    appId: '1:665015311283:web:e258359f76d371c9d2c9c6',
    messagingSenderId: '665015311283',
    projectId: 'vendora-19a5c',
    authDomain: 'vendora-19a5c.firebaseapp.com',
    storageBucket: 'vendora-19a5c.firebasestorage.app',
    measurementId: 'G-7LNJQLB2W9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDisF4YqX_wZOjCiAnw6ii7IKhRwFZZ5dU',
    appId: '1:665015311283:android:326bb5fd96a1b964d2c9c6',
    messagingSenderId: '665015311283',
    projectId: 'vendora-19a5c',
    storageBucket: 'vendora-19a5c.firebasestorage.app',
  );
}
