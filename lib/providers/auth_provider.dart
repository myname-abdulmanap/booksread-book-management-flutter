import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    _initAuth();
  }

  // ==========================
  // LISTEN AUTH STATE
  // ==========================
  void _initAuth() {
    _authService.authStateChanges.listen((event) async {
      final session = event.session;

      if (session != null) {
        _user =
            await _authService.getUserProfile(session.user.id);
      } else {
        _user = null;
      }

      notifyListeners();
    });
  }

  // ==========================
  // SIGN IN
  // ==========================
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.signIn(
        email: email,
        password: password,
      );

      return _user != null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // SIGN UP
  // ==========================
  Future<bool> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );

      // Signup sukses ≠ login
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================
  // SIGN OUT
  // ==========================
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
