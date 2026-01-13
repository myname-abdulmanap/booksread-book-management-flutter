import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Stream perubahan auth (login / logout)
  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// User auth saat ini
  User? get currentUser => _supabase.auth.currentUser;

  // ==========================
  // SIGN UP
  // ==========================
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, // masuk ke raw_user_meta_data
        },
      );

      // ⛔ JANGAN INSERT KE TABLE users DI SINI
      // Profile akan dibuat otomatis oleh TRIGGER di DB
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // ==========================
  // SIGN IN
  // ==========================
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) return null;

      return await getUserProfile(user.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // ==========================
  // GET USER PROFILE
  // ==========================
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Get profile failed: $e');
    }
  }

  // ==========================
  // SIGN OUT
  // ==========================
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }
}
