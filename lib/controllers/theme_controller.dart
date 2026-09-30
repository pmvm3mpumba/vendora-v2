import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BONUS — mode sombre, persistant entre les sessions.
class ThemeController extends ChangeNotifier {
  static const _key = 'vendora_dark_mode';

  ThemeMode mode = ThemeMode.system;
  bool get isDark => mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_key);
    if (dark != null) {
      mode = dark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> setDark(bool dark) async {
    mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, dark);
  }
}
