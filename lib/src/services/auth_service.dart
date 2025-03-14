import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _loading = false;
  String? _error;
  User? _currentUser;

  bool get loading => _loading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _currentUser = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> signInWithOtp({required String email}) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _supabase.auth.signInWithOtp(
        email: email
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp({required String email, required String token}) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      try {
        // First attempt with magic link
        await _supabase.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.magiclink,
        );
        return; // If successful, return early
      } catch (magicLinkError) {
        try {
          // If magic link fails, try signup
          await _supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.signup,
          );
          return; // If successful, return early
        } catch (signupError) {
          // If both methods fail, throw combined error
          throw 'Verification failed for both magic link and signup. Please try again or request a new code.';
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _supabase.auth.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}