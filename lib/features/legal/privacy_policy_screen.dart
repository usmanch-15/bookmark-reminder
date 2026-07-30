import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
                'Last updated: [DATE]\n\n'
                'Bookmark Reminder stores your reminders, categories, and account '
                'email using Supabase. We do not sell your data to third parties.\n\n'
                'Data we collect:\n'
                '- Email address (for account login)\n'
                '- Reminder titles, notes, categories, and dates you create\n'
                '- Optional file attachments you upload\n\n'
                'Data storage: Your data is stored securely on Supabase servers '
                'with row-level security, meaning only you can access your own data.\n\n'
                'Replace this placeholder text with your actual privacy policy '
                'before publishing to the Play Store or App Store.',
          ),
        ),
      ),
    );
  }
}