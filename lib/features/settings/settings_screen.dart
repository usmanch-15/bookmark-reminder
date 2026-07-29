import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/prefs_service.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'widgets/quiet_hours_tile.dart';
import 'widgets/sync_status_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sound = await PrefsService.isSoundEnabled();
    final vibration = await PrefsService.isVibrationEnabled();
    setState(() {
      _soundEnabled = sound;
      _vibrationEnabled = vibration;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Kya aap logout karna chahte hain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (mounted) {
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
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Profile'),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: mode == ThemeMode.dark,
                onChanged: (value) => ThemeController.toggleTheme(value),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 12, bottom: 4),
                child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text('Notification Sound'),
                value: _soundEnabled,
                onChanged: (v) async {
                  await PrefsService.setSoundEnabled(v);
                  setState(() => _soundEnabled = v);
                },
              ),
              SwitchListTile(
                title: const Text('Notification Vibration'),
                value: _vibrationEnabled,
                onChanged: (v) async {
                  await PrefsService.setVibrationEnabled(v);
                  setState(() => _vibrationEnabled = v);
                },
              ),
              const QuietHoursTile(),
              const Divider(),
              const SyncStatusTile(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: _logout,
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