import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Customer>> getCustomers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> updateDiscount(String customerId, double discount) async {
    await _firestore.collection('users').doc(customerId).update({
      'discount_percent': discount,
    });
  }
}

final customerServiceProvider = Provider<CustomerService>((ref) => CustomerService());

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerServiceProvider).getCustomers();
});
