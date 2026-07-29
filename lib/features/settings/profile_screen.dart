import 'package:flutter/material.dart';
import '../../data/services/supabase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user?.email ?? 'Unknown'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Account Created'),
            subtitle: Text(user?.createdAt != null
                ? DateTime.parse(user!.createdAt).toLocal().toString().split(' ').first
                : 'Unknown'),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('User ID'),
            subtitle: Text(user?.id ?? 'Unknown', style: const TextStyle(fontSize: 11)),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Multi-Device Sync'),
            subtitle: const Text('Your data syncs automatically across all your devices via Supabase.'),
          ),
        ],
      ),
    );
  }
}