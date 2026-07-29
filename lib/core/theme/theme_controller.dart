import 'package:flutter/material.dart';
import '../../data/services/prefs_service.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
  ValueNotifier(ThemeMode.light);

  static Future<void> loadSavedTheme() async {
    final isDark = await PrefsService.isDarkMode();
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    await PrefsService.setDarkMode(isDark);
  }
}