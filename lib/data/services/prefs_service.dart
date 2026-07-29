import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _onboardingKey = 'onboarding_completed';
  static const _darkModeKey = 'dark_mode_enabled';
  static const _quietHoursEnabledKey = 'quiet_hours_enabled';
  static const _quietStartHourKey = 'quiet_start_hour';
  static const _quietEndHourKey = 'quiet_end_hour';
  static const _soundEnabledKey = 'notification_sound_enabled';
  static const _vibrationEnabledKey = 'notification_vibration_enabled';
  static const _lastSyncKey = 'last_sync_timestamp';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  // Quiet hours
  static Future<bool> isQuietHoursEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quietHoursEnabledKey) ?? false;
  }

  static Future<void> setQuietHoursEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quietHoursEnabledKey, value);
  }

  static Future<int> getQuietStartHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quietStartHourKey) ?? 22; // 10 PM default
  }

  static Future<int> getQuietEndHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quietEndHourKey) ?? 7; // 7 AM default
  }

  static Future<void> setQuietHours(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietStartHourKey, startHour);
    await prefs.setInt(_quietEndHourKey, endHour);
  }

  // Sound / vibration
  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  static Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
  }

  static Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, value);
  }

  // Last sync
  static Future<void> setLastSyncNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastSyncKey);
    return value != null ? DateTime.tryParse(value) : null;
  }
}