class Category {
  final String id;
  final String name;
  final String slug;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      imageUrl: map['image_url'] ?? '',
    );
  }
}
