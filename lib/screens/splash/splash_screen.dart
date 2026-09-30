import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/vendora_logo.dart';

/// Écran de démarrage — restauration de la session Firebase.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VendoraLogo(size: 64),
            const SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.brand.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
