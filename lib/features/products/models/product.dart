class Product {
  final String id;
  final String name;
  final String category;
  final double basePrice;
  final double? oldPrice;
  final String imageUrl;
  final String description;
  final bool inStock;
  final List<String> storeIds;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.basePrice,
    this.oldPrice,
    required this.imageUrl,
    required this.description,
    required this.inStock,
    required this.storeIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'base_price': basePrice,
      'old_price': oldPrice,
      'image_url': imageUrl,
      'description': description,
      'in_stock': inStock,
      'store_ids': storeIds,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (map['old_price'] as num?)?.toDouble(),
      imageUrl: map['image_url'] ?? '',
      description: map['description'] ?? '',
      inStock: map['in_stock'] ?? true,
      storeIds: List<String>.from(map['store_ids'] ?? []),
    );
  }
}
