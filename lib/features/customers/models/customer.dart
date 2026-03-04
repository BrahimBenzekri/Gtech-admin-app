// ignore_for_file: unnecessary_this

class Customer {
  final String id;
  final String name;
  final String email;
  final String role;
  final double discountPercent;
  final String? phoneNumber;
  final String? address;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.discountPercent,
    this.phoneNumber,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'discount_percent': discountPercent,
      'phone_number': phoneNumber,
      'address': address,
    };
  }

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'client',
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: map['phone_number'],
      address: map['address'],
    );
  }

  Customer copyWith({
    String? name,
    String? email,
    String? role,
    double? discountPercent,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      discountPercent: discountPercent ?? this.discountPercent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }
}
