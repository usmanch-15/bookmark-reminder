import 'package:flutter/foundation.dart';
import '../../data/services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      errorMessage = 'Email aur password dono zaroori hain';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.signIn(email.trim(), password);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Login failed. Email/password check karein.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    if (email.trim().isEmpty || password.length < 6) {
      errorMessage = 'Valid email dein aur password kam se kam 6 characters ka ho';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await SupabaseService.signUp(email.trim(), password);
      isLoading = false;
      successMessage = 'Account ban gaya! Apna email verify karein, phir login karein.';
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Signup failed. Dobara try karein.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
  }
}