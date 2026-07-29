import 'package:flutter/foundation.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/services/supabase_service.dart';

class SettingsController extends ChangeNotifier {
  bool get isDarkMode => ThemeController.themeMode.value.toString().contains('dark');

  String get userEmail => SupabaseService.currentUser?.email ?? '';

  Future<void> toggleTheme(bool isDark) async {
    await ThemeController.toggleTheme(isDark);
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
  }
}