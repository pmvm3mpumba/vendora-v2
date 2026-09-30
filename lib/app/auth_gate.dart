import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/enums.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'client_shell.dart';
import 'seller_shell.dart';

/// Aiguillage central selon l'état d'authentification et le rôle (§3/§10).
///
///  • non connecté            → coque CLIENT en mode visiteur (catalogue libre)
///  • connecté sans doc users → complétion du profil
///  • rôle seller             → coque VENDEUR
///  • rôle client             → coque CLIENT
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isLoading) return const SplashScreen();
    if (auth.firebaseUser == null) return const ClientShell();
    if (auth.appUser == null) return const CompleteProfileScreen();
    if (auth.appUser!.role == UserRole.seller) return const SellerShell();
    return const ClientShell();
  }
}
