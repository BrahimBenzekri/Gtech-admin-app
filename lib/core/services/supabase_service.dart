import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();

  /// Initialize Supabase with keys from .env
  Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  }

  /// Get the Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Get the Auth client
  GoTrueClient get auth => client.auth;

  /// Get the current user
  User? get currentUser => auth.currentUser;

  /// Helper to access a table
  SupabaseQueryBuilder from(String table) => client.from(table);
  
  /// Helper to sign out
  Future<void> signOut() async {
    await auth.signOut();
  }
}
