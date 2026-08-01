import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/sync/sync_service.dart';
import 'data/services/supabase_service.dart';
import 'data/services/notification_service.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await SupabaseService.init();
  await NotificationService().init();
  await NotificationService().requestPermission();
  await ThemeController.loadSavedTheme();
  SyncService().init();

  runApp(const BookmarkReminderApp());
}

class BookmarkReminderApp extends StatelessWidget {
  const BookmarkReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Bookmark Reminder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}