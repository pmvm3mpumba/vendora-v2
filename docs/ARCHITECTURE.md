# VENDORA — Architecture & Structure du projet
**Examen final — Développement Flutter : Application e-commerce Firebase**
Plateformes : Android + Web | Plan Firebase : Spark (gratuit) | Projet existant : `vendora-19a5c`

> **Mise à jour 24/09/2026** : bonus validés par le client (§14), écrans complétés, squelette Flutter créé.

---

## 1. Analyse rapide de l'énoncé

| Exigence | Conséquence architecturale |
|---|---|
| Visiteur navigue sans compte | Le catalogue est l'écran d'accueil ; l'auth est demandée **au moment d'une action protégée** |
| Deux rôles (client / vendeur) | Champ `role` dans Firestore + `AuthGate` (routing selon rôle) |
| Firebase Auth + Firestore + Storage | 3 services dédiés, aucune auth locale |
| Panier local OU Firestore | **Choix : panier local** (Provider). Seule la commande finale va dans Firestore (§7) |
| ≥ 3 devises, sans API réelle | Taux fixes documentés (`core/constants/currencies.dart`) |
| Paiement simulé (succès + échec) | `PaymentSimulator` avec valeurs de test déterministes |
| WhatsApp sans API Business | `url_launcher` + `wa.me` + gestion du cas « WhatsApp absent » |
| Règles inspectées | `firestore.rules` versionné à la racine du projet |

## 2. Choix techniques

| Sujet | Choix |
|---|---|
| State management | **Provider** (`ChangeNotifier`) |
| Navigation | `Navigator` nommé + `AuthGate` |
| Auth / Données / Images | `firebase_auth` / `cloud_firestore` / `firebase_storage` **ou** fallback base64 (§8) |
| WhatsApp | `url_launcher` (`https://wa.me/...`) |
| Autres | `image_picker`, `cached_network_image`, `intl`, `shared_preferences` (dark mode) |

## 3. Arborescence (squelette créé ✅)

```
vendora/
├── assets/images/test/              # 6 images de démo embarquées (seed)
├── firestore.rules                  # règles de sécurité (§9)
├── docs/ARCHITECTURE.md
├── README.md                        # procédure de mise en route
├── pubspec.yaml
└── lib/
    ├── main.dart                    # init Firebase + runApp
    ├── firebase_options.dart        # PLACEHOLDER → flutterfire configure
    ├── app/
    │   ├── vendora_app.dart         # MultiProvider + MaterialApp (light/dark)
    │   ├── routes.dart              # routes nommées + navigation typée
    │   ├── auth_gate.dart           # visiteur / client / vendeur
    │   └── theme.dart               # ⚠️ SOURCE UNIQUE du design (maquettes)
    ├── core/
    │   ├── constants/  app_constants (zones de livraison) · currencies · payment_test_data
    │   ├── utils/      validators · formatters · currency_converter
    │   └── widgets/    state_views (loading/empty/error) · price_text · app_image · app_text_field
    ├── models/
    │   ├── enums.dart               # UserRole, DeliveryOption, PaymentMethod,
    │   │                            # PaymentStatus, OrderStatus, ProductSort
    │   ├── app_user.dart            # + favoriteIds (bonus)
    │   ├── category.dart · delivery_zone.dart
    │   ├── product.dart · cart_item.dart
    │   ├── order.dart               # OrderModel + OrderItem + StatusChange
    │   └── app_notification.dart    # bonus
    ├── services/
    │   ├── auth_service · user_service · category_service · product_service
    │   ├── order_service · notification_service
    │   ├── image_storage_service    # interface + plan A (Storage) + plan B (base64)
    │   ├── payment_simulator · whatsapp_service
    ├── controllers/                 # 9 ChangeNotifier (Provider)
    │   ├── auth · catalogue · cart · currency · order · seller
    │   └── favorites · theme (dark mode) · notification
    ├── screens/                     # 22 écrans — design à appliquer depuis les MAQUETTES
    │   ├── splash/        splash_screen
    │   ├── auth/          login · register · complete_profile
    │   ├── catalogue/     home(3) · product_details(4) · search_filter(5)
    │   ├── favorites/     favorites          (bonus)
    │   ├── cart/          cart(6)
    │   ├── checkout/      checkout(7+8) · payment(9) · order_confirmation(10)
    │   ├── orders/        order_history(11) · order_details(12)
    │   ├── profile/       profile(13) · settings (bonus dark mode)
    │   ├── notifications/ notifications      (bonus)
    │   └── seller/        dashboard(14) · my_products(15) · product_form(16+17)
    │                      · seller_orders(18) · seller_profile(19)
    └── seed/seed_data.dart          # 6 catégories + 6 produits de démo (images assets)
```

## 4. Modèle de données Firestore

### `users/{uid}`
```json
{
  "name": "Jean Ndayishimiye", "email": "mpumba@biu.bi", "phone": "+257 79 000 000",
  "role": "seller",
  "whatsappNumber": "25779000000",
  "favoriteIds": ["p1", "p2"],
  "createdAt": "Timestamp"
}
```
> Les 3 comptes déjà créés dans la console n'ont pas de doc `users/{uid}` → écran `complete_profile` au premier login.

### `categories/{id}` — `products/{id}` (inchangés, voir modèles `lib/models/`).

### `orders/{orderId}`
```json
{
  "orderNumber": "ORD-1727186400000",
  "clientId": "uid_client", "clientName": "Alice", "clientPhone": "+257...",
  "items": [{ "productId": "p1", "name": "Smartphone X", "unitPrice": 450000,
              "quantity": 2, "subtotal": 900000, "sellerId": "uid_vendeur",
              "sellerName": "Jean N.", "sellerWhatsapp": "25779000000", "imageUrl": "..." }],
  "sellerIds": ["uid_vendeur"],
  "subtotal": 900000, "deliveryFee": 15000, "total": 915000,
  "currency": "BIF",
  "deliveryOption": "delivery",
  "deliveryZoneId": "buj_centre", "deliveryZoneName": "Bujumbura — Centre-ville",
  "deliveryLocation": "Rohero, Av. X n°12", "deliveryPhone": "+257...",
  "paymentMethod": "mobile_money", "paymentStatus": "paid",
  "paymentReference": "SIM-MOMO-...",
  "orderStatus": "pending",
  "statusHistory": [{ "status": "pending", "at": "Timestamp" }],
  "createdAt": "Timestamp"
}
```
> **Multi-vendeurs** : un item par produit avec son `sellerId` ; `sellerIds` (array) pour la requête vendeur ; **un message WhatsApp par vendeur**.

### `notifications/{id}` (BONUS)
```json
{ "userId": "uid", "title": "Nouvelle commande ORD-...", "body": "...",
  "orderId": "...", "read": false, "createdAt": "Timestamp" }
```

## 5. Devises (§8) — taux fixes documentés
Base **BIF** : `1 USD = 3 000 BIF` · `1 EUR = 3 250 BIF` (`core/constants/currencies.dart`).
Conversion à l'affichage ; devise figée dans la commande.

## 6. Paiement simulé (§11) — valeurs de test
Mobile Money finissant par `00` → échec · Carte `4242…4242` → succès · Carte `4000…0002` → échec.
Processing 2 s simulé ; échec ⇒ **aucune commande créée**, retour au checkout.

## 7. WhatsApp (§15/16)
Message exact du modèle de l'énoncé, un **par vendeur** ; `wa.me/<num>?text=...` ;
échec d'ouverture → message « Veuillez installer WhatsApp » (jamais de crash).

## 8. Images (plan Spark)
Interface `ImageStorageService` interchangeable (`kUseFirebaseStorage`) :
- **Plan A** : Firebase Storage (à activer si la console permet de créer le bucket) ;
- **Plan B — défaut** : base64 compressé dans Firestore (gratuit, aucune dépendance) ;
- **Seed** : 6 produits avec images **assets embarquées** → toujours présentes.
Rendu unique : `core/widgets/app_image.dart` (http / `asset:` / `data:image`).

## 9. Règles de sécurité
Version canonique : **`firestore.rules`** (racine). Points clés : catalogue public en lecture ;
vendeur = uniquement ses produits ; client = uniquement ses commandes ; vendeur = commandes
`sellerIds array-contains` ; **client ne peut qu'annuler** sa commande (update restreint) ;
profil modifiable uniquement par son propriétaire.

## 10. Rôles & navigation
`AuthGate` : non connecté → catalogue visiteur · doc users absent → complétion profil ·
seller → dashboard · client → catalogue. Actions protégées → redirection login puis retour.

## 11. Cas d'erreur (§21)
Identifiants incorrects · champs vides · prix invalide · stock négatif · rupture ·
quantité > stock · lieu de livraison manquant · paiement échoué · panier vide ·
erreur Firebase/réseau · WhatsApp absent · action protégée sans auth → **tous couverts**
(validateurs + contrôleurs + `state_views`).

## 12. Connexion Firebase
Voir `README.md` : `flutter create .` puis `flutterfire configure --project=vendora-19a5c`.

## 13. Plan de travail
1. ✅ Squelette (modèles, services, contrôleurs, règles, seed, routes)
2. ⏳ Appliquer les MAQUETTES écran par écran (via `theme.dart` en source unique)
3. Brancher les contrôleurs aux écrans
4. `flutterfire configure` + règles console + seed
5. Répétition du scénario de démo (§19)

## 14. Bonus RETENUS (validé)
✅ **Favoris / wishlist** (`favoriteIds` + écran Favoris) ·
✅ **Zones de livraison multiples** (frais variables, `app_constants.dart`) ·
✅ **Tri des produits** (prix ↑↓, nouveautés, nom) ·
✅ **Annulation de commande** (client, si `pending`, + restock) ·
✅ **Mise à jour du statut** (vendeur : pending → confirmed → delivered, historique horodaté) ·
✅ **Statistiques vendeur** (CA, commandes, top 3 produits — onglet dashboard) ·
✅ **Notifications internes** (collection Firestore + badge) ·
✅ **Mode sombre** (persistant).
❌ Exclus à la demande : ratings, reviews, codes promo, produits promotionnels.

## 15. Exigence design (maquettes)
Les maquettes fournies sont la **référence absolue** : couleurs, fonds, bordures (rayon/épaisseur),
états focus des champs, espacements, typographie, composants et parcours UX seront reproduits
**à l'identique**, centralisés dans `lib/app/theme.dart` (aucune couleur codée en dur ailleurs).
