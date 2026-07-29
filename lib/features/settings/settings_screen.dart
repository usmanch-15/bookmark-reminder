import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/services/supabase_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Kya aap logout karna chahte hain?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.themeMode,
        builder: (context, mode, _) {
          return ListView(
            children: [
              if (email.isNotEmpty)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(email),
                  subtitle: const Text('Logged in'),
                ),
              const Divider(),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: mode == ThemeMode.dark,
                onChanged: (value) => ThemeController.toggleTheme(value),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_done_outlined),
                title: const Text('Cloud Sync'),
                subtitle: const Text('Your items sync automatically via Supabase'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _logout(context),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Bookmark Reminder'),
                subtitle: Text('Version 1.0.0'),
              ),
            ],
          );
        },
      ),
    );
  }
}