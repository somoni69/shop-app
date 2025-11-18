class Product {
  final String id;
  final String title;
  final double price;
  final String description;
  final List<String> images; // <-- ИЗМЕНЕНИЕ (было String image)
  final String category;
  final double rating;
  final String sellerId;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.images, // <-- ИЗМЕНЕНИЕ
    required this.category,
    required this.rating,
    required this.sellerId,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    // --- ИЗМЕНЕНИЕ ---
    // Преобразуем данные из Supabase (List<dynamic>) в List<String>
    final List<String> imagesFromDb = [];
    if (map['images'] != null) {
      for (final image in map['images']) {
        imagesFromDb.add(image as String);
      }
    }
    // --- КОНЕЦ ИЗМЕНЕНИЯ ---

    return Product(
      id: map['id'] as String,
      title: map['title'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String,
      images: imagesFromDb, // <-- ИЗМЕНЕНИЕ
      category: map['category'] as String,
      rating: (map['rating'] as num? ?? 0.0).toDouble(), // Добавил ?? 0.0 на всякий случай
      sellerId: map['seller_id'] as String? ?? '', // Добавил ?? '' на всякий случай
    );
  }
}