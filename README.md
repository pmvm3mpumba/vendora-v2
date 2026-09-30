# VENDORA — Mise en route (SETUP)

> Squelette Flutter du projet d'examen. **La logique métier est implémentée** (modèles, services Firebase,
> contrôleurs Provider, panier, checkout, paiement simulé, WhatsApp, bonus). **Le style des écrans sera
> appliqué strictement selon les maquettes fournies** (couleurs, fonds, bordures, états focus — voir `lib/app/theme.dart`).

## 1. Prérequis

- Flutter SDK stable récent (≥ 3.32 conseillé) : https://docs.flutter.dev/get-started/install
- Node.js (pour la CLI Firebase) : `npm install -g firebase-tools`
- CLI FlutterFire : `dart pub global activate flutterfire_cli`

## 2. Générer les dossiers plateformes (android / web)

Les dossiers `android/` et `web/` ne sont **pas** versionnés dans ce squelette — ils se régénèrent :

```bash
cd vendora
flutter create . --project-name vendora --org bi.vendora --platforms android,web
flutter pub get
```

Dans `android/app/build.gradle.kts` (généré) : vérifier `minSdkVersion = 23`.

## 3. Connecter au projet Firebase EXISTANT (vendora-19a5c)

```bash
firebase login
flutterfire configure --project=vendora-19a5c   # sélectionner : android + web
```

Cela écrase `lib/firebase_options.dart` (placeholder) avec les vraies clés et génère `android/app/google-services.json`.

## 4. Console Firebase — 3 réglages

1. **Authentication** : Email/Password déjà activé ✅ (visible dans vos captures).
2. **Cloud Firestore** : créer la base (mode production), onglet **Règles** → coller le contenu de `firestore.rules` → Publier.
3. **Storage (optionnel)** : si le plan Spark refuse la création du bucket, **rien à faire** — l'app utilise déjà
   le fallback base64 (voir `lib/services/image_storage_service.dart`, constante `kUseFirebaseStorage`).

## 5. Lancer

```bash
flutter run -d chrome        # Web
flutter run -d <device>      # Android
```

## 6. Données de test

Depuis le **Profil vendeur** (compte de rôle `seller`) : **« Charger les données de démo »**
→ 3 catégories (Tech, Mode, Accessoires) + 6 produits des maquettes avec images embarquées
(dans `assets/images/test/` — affichés même hors-ligne).

Paiement simulé : menu **« Scénario à tester »** dans le checkout
(« Paiement réussi » / « Paiement refusé ») — démo des 2 cas, sans aucune donnée bancaire.

## État d'avancement

| Couche | État |
|---|---|
| Modèles, enums, constantes (devises, zones de livraison) | ✅ fait |
| Services Firebase (auth, users, produits, commandes, notifications) | ✅ fait |
| Paiement simulé, WhatsApp, convertisseur de devises | ✅ fait |
| Contrôleurs Provider (auth, catalogue, panier, commandes, vendeur, favoris, thème, notifications) | ✅ fait |
| Règles Firestore (`firestore.rules`) | ✅ fait |
| **UI des 22 écrans** | ✅ **fidèle aux maquettes** (thème centralisé `lib/app/theme.dart`) |
| Bonus validés (favoris, zones, tri, annulation, statuts, stats, notifications, dark mode) | ✅ fait |

## 7. Dernier réglage requis (2 min) — connexion Firebase

Les clés Web/Android (`apiKey`, `appId`) ne sont lisibles que depuis votre console/compte
(jamais dans les captures) : elles sont générées par `flutterfire configure` (étape 3 ci-dessus).
Alternative : Console Firebase → Paramètres du projet → **Vos applications** → Web →
copier l'objet `firebaseConfig` dans `lib/firebase_options.dart`.
