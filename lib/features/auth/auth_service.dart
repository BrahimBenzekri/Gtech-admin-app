import 'package:admin_app/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Service
class AuthService {
  final SupabaseService _supabase = SupabaseService();

  Stream<AuthState> get authStateChanges =>
      _supabase.client.auth.onAuthStateChange;

  User? get currentUser => _supabase.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }

      // Check role via Custom Claims (set by Hook)
      // Note: Claims might not be immediately available on first login if the hook is slow,
      // but usually it's fine.
      // Robust way: Check the 'user_role' claim.
      final claims = response.session?.user.appMetadata ?? {};
      final role = claims['user_role'] as String?;

      if (role != 'admin') {
        // Optional: Allow login but restrict access via RLS.
        // But for Admin App, we likely want to block UI.
        // await signOut(); // Uncomment to strict block
        // throw Exception('Access Denied: You are not an admin/employee.');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _supabase.signOut();
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  // Map Supabase AuthState to User?
  return ref
      .watch(authServiceProvider)
      .authStateChanges
      .map((event) => event.session?.user);
});
