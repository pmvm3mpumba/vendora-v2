import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════
/// THÈME VENDORA — tokens extraits des maquettes (Design Direction 01)
/// ════════════════════════════════════════════════════════════════════════
///  • Orange-rouge de marque  : boutons, liens, icônes actives, badges
///  • Vert forêt              : hero, focus des champs, étapes, badges « Confirmée »
///  • Fond crème chaud        : scaffold
///  • Cartes blanches         : bordure fine `#E7E3DA`, rayon 14–24
///  • Pills pêche             : éléments sélectionnés (catégories, rôle)
///  Aucune couleur codée en dur ailleurs dans l'app.
/// ════════════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  // --- Couleurs ---
  static const brand = Color(0xFFE04E17);      // orange-rouge Vendora
  static const brandDark = Color(0xFFC2400F);
  static const forest = Color(0xFF0E4A38);     // vert foncé (hero, focus)
  static const forestSoft = Color(0xFFE9F2EC); // fond vert teinté (encadrés)
  static const bg = Color(0xFFF5F3EE);         // fond crème chaud
  static const card = Color(0xFFFFFFFF);
  static const inputFill = Color(0xFFF7F5F0);
  static const line = Color(0xFFE7E3DA);       // bordures fines
  static const ink = Color(0xFF1B1915);        // texte principal
  static const muted = Color(0xFF6F6A60);      // texte secondaire
  static const peach = Color(0xFFFBEADB);      // pill sélectionnée
  static const greenSoft = Color(0xFFE2F1E8);  // badge vert (confirmée)
  static const greenText = Color(0xFF1C7A45);
  static const sage = Color(0xFFAABFA9);       // barres du graphique
  static const cream = Color(0xFFEDE5D3);      // cercles image / donut neutre
  static const danger = Color(0xFFB3261E);

  // --- Rayons ---
  static const double rSm = 10;
  static const double rMd = 14;
  static const double rLg = 20;
  static const double rXl = 26;

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark); // bonus : mode sombre

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    ).copyWith(
      primary: brand,
      surface: isDark ? const Color(0xFF171512) : bg,
      error: danger,
    );

    final scaffoldBg = isDark ? const Color(0xFF14120F) : bg;
    final cardColor = isDark ? const Color(0xFF211E1A) : card;
    final lineColor = isDark ? const Color(0xFF37332C) : line;
    final textColor = isDark ? const Color(0xFFF1EEE8) : ink;
    final mutedColor = isDark ? const Color(0xFFA39D92) : muted;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(rMd),
      borderSide: BorderSide(color: lineColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      dividerColor: lineColor,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: textColor, fontSize: 17, fontWeight: FontWeight.w800),
        iconTheme: IconThemeData(color: textColor),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
            color: textColor, fontSize: 27, fontWeight: FontWeight.w900, height: 1.15),
        titleLarge: TextStyle(
            color: textColor, fontSize: 19, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(
            color: textColor, fontSize: 16, fontWeight: FontWeight.w800),
        titleSmall: TextStyle(
            color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: mutedColor, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: mutedColor, fontSize: 12, height: 1.4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF26231E) : inputFill,
        hintStyle: TextStyle(color: mutedColor, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: border,
        enabledBorder: border,
        // FOCUS — bordure VERT FONCÉ 2 px (maquette « Connexion »)
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: forest, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: danger, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rLg),
          side: BorderSide(color: lineColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? const Color(0xFF3A352E) : const Color(0xFFE3DED4),
          disabledForegroundColor: mutedColor,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: brand),
          minimumSize: const Size.fromHeight(48),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: brand,
        unselectedItemColor: mutedColor,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? brand : mutedColor),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? brand.withValues(alpha: 0.35)
                : lineColor),
      ),
    );
  }
}

/// Extension pratique : tokens accessibles partout via `context.colors`.
extension VendoraColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardColor =>
      isDark ? const Color(0xFF211E1A) : AppTheme.card;
  Color get lineColor =>
      isDark ? const Color(0xFF37332C) : AppTheme.line;
  Color get textColor =>
      isDark ? const Color(0xFFF1EEE8) : AppTheme.ink;
  Color get mutedColor =>
      isDark ? const Color(0xFFA39D92) : AppTheme.muted;
}
