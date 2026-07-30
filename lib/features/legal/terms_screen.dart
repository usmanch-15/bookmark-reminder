import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
                'Last updated: [DATE]\n\n'
                'By using Bookmark Reminder, you agree to use the app for personal '
                'reminder management only. You are responsible for the content you '
                'save in the app.\n\n'
                'We provide this app "as is" without warranty of any kind. We are '
                'not liable for missed reminders due to device settings, notification '
                'permissions, or connectivity issues.\n\n'
                'Replace this placeholder text with your actual terms of service '
                'before publishing to the Play Store or App Store.',
          ),
        ),
      ),
    );
  }
}