import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalogue_controller.dart';
import '../controllers/currency_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/seller_controller.dart';
import '../controllers/theme_controller.dart';
import 'auth_gate.dart';
import 'routes.dart';
import 'theme.dart';

class VendoraApp extends StatelessWidget {
  const VendoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CatalogueController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => CurrencyController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => SellerController()),
        // Les favoris suivent l'utilisateur connecté (proxy sur AuthController).
        ChangeNotifierProxyProvider<AuthController, FavoritesController>(
          create: (_) => FavoritesController(),
          update: (_, auth, fav) => (fav ?? FavoritesController())
            ..updateUser(auth.appUser),
        ),
        ChangeNotifierProvider(create: (_) => NotificationController()),
      ],
      child: Consumer<ThemeController>(
        builder: (_, theme, child) => MaterialApp(
          title: 'Vendora',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          home: const AuthGate(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}
