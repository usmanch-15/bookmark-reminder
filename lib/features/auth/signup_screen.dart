import 'package:flutter/material.dart';
import '../../data/services/supabase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _message;

  Future<void> _signup() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      setState(() =>
      _error = 'Valid email dein aur password kam se kam 6 characters ka ho');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await SupabaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _message =
          'Account ban gaya! Apna email verify karein, phir login karein.';
        });
      }
    } catch (e) {
      setState(() => _error = 'Signup failed. Dobara try karein.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Password (min 6 chars)'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_message!,
                      style: const TextStyle(color: Colors.green)),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 12),
              if (_message != null)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Login'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}