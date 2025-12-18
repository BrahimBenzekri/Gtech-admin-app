import 'package:admin_app/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';

class CustomerService {
  final SupabaseService _supabase = SupabaseService();

  Stream<List<Customer>> getCustomers() {
    // Assuming 'profiles' has the 'role' column as per schema provided.
    // If not, we might need to join user_roles.
    return _supabase.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'customer') // Filter for customers/clients
        .map((data) => data.map((json) => Customer.fromMap(json['id'], json)).toList());
  }

  Future<void> updateDiscount(String customerId, double discount) async {
    await _supabase.from('profiles').update({
      'discount_percent': discount, // Ensure this column exists in profiles schema
    }).eq('id', customerId);
  }
}

final customerServiceProvider = Provider<CustomerService>((ref) => CustomerService());

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerServiceProvider).getCustomers();
});
