import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('Verify Supabase Connection', () async {
    // 1. Load Env
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      fail('Failed to load .env file. Ensure it exists in the root of admin_app.');
    }

    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || key == null) {
      fail('SUPABASE_URL or SUPABASE_ANON_KEY not found in .env');
    }

    // 2. Initialize Client (using Direct Client to avoid Flutter binding issues if possible, 
    // but supabase_flutter exports SupabaseClient which is pure Dart)
    final client = SupabaseClient(url, key);

    // 3. Test Connection by fetching basic data
    // We try to fetch 1 row from 'users' or 'profiles' or just check health if possible.
    // 'profiles' is likely to exist based on finding 'CustomerService'.
    try {
      // Trying to fetch count of profiles, simpler than reading data which might be RLS protected for anon
      // But we need to see if we can connect.
      // If RLS is strict, this might fail with simple AuthException or empty list.
      // Let's try to just select * limit 1
      final response = await client.from('profiles').select().limit(1);
      
      print('Supabase Connection Successful!');
      print('Response: $response');
    } catch (e) {
      fail('Failed to connect to Supabase: $e');
    }
  });
}
