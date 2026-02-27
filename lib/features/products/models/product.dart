class Product {
  final String id;
  final String name;
  final String? categoryId;
  final double price;
  final double? discountPrice;
  final String imageUrl;
  final String description;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    this.categoryId,
    required this.price,
    this.discountPrice,
    required this.imageUrl,
    required this.description,
    required this.inStock,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category_id': categoryId,
      'price': price,
      'discount_price': discountPrice,
      'description': description,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    // Handle joined product_images data
    String imageUrl = '';
    if (map['product_images'] != null && map['product_images'] is List) {
      final images = map['product_images'] as List;
      if (images.isNotEmpty) {
        // Prefer main image, fallback to first
        final mainImage = images.firstWhere(
          (img) => img['is_main'] == true,
          orElse: () => images.first,
        );
        imageUrl = mainImage['image_url'] ?? '';
      }
    }
    // Fallback to direct image_url if present
    if (imageUrl.isEmpty) {
      imageUrl = map['image_url'] ?? '';
    }

    final stock = map['stock'] as int? ?? 0;

    return Product(
      id: id,
      name: map['name'] ?? '',
      categoryId: map['category_id'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (map['discount_price'] as num?)?.toDouble(),
      imageUrl: imageUrl,
      description: map['description'] ?? '',
      inStock: map['in_stock'] ?? (stock > 0),
    );
  }
}
