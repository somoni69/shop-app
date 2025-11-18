import 'package:supabase_flutter/supabase_flutter.dart';
// УДАЛИЛИ import '../main.dart'; -> Больше не нужен!

class CartItem {
  final String id;
  final String productId;
  final String title;
  final int quantity;
  final double price;
  final String userId;
  final DateTime createdAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
    required this.userId,
    required this.createdAt,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final productData = map['products'];
    if (productData == null || productData is! Map<String, dynamic>) {
      throw Exception(
          'Данные о товаре (products) отсутствуют. Проверьте RLS для таблицы products.');
    }

    return CartItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      title: productData['title'] as String,
      price: (productData['price'] as num).toDouble(),
    );
  }
}

class CartService {
  // 1. Объявляем приватное поле для клиента
  final SupabaseClient _supabase;

  // 2. Конструктор принимает клиент
  CartService(this._supabase);

  // Используем переданный клиент для получения ID пользователя
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Получает все товары в корзине
  Future<List<CartItem>> fetchCartItems() async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final response = await _supabase
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at');

      return (response as List)
          .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Ошибка при загрузке корзины: $e');
    }
  }

  /// Добавляет товар в корзину
  Future<CartItem> addItem(String productId, String title, double price) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final existingItemsResponse = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItemsResponse != null) {
        final existingItem = existingItemsResponse;
        final updatedQuantity = existingItem['quantity'] + 1;

        final updateResponse = await _supabase
            .from('cart_items')
            .update({'quantity': updatedQuantity})
            .eq('id', existingItem['id'])
            .select('*, products(*)')
            .single();

        return CartItem.fromMap(updateResponse);
      }

      final dataToInsert = {
        'product_id': productId,
        'quantity': 1,
        'user_id': userId,
      };

      final response = await _supabase
          .from('cart_items')
          .insert(dataToInsert)
          .select('*, products(*)')
          .single();

      return CartItem.fromMap(response);
    } catch (e) {
      throw Exception('Ошибка при добавлении товара в корзину: $e');
    }
  }

  /// Удаляет товар из корзины
  Future<void> removeItem(String itemId) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('id', itemId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Ошибка при удалении товара из корзины: $e');
    }
  }

  /// Обновляет количество товара в корзине
  Future<CartItem> updateItemQuantity(String itemId, int quantity) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    if (quantity <= 0) {
      await removeItem(itemId);
      // Тут лучше вернуть какое-то значение или бросить специальное исключение,
      // которое обработает провайдер, но пока оставим так.
      throw Exception('Количество 0, товар удален');
    }

    try {
      final response = await _supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('id', itemId)
          .eq('user_id', userId)
          .select('*, products(*)')
          .single();

      return CartItem.fromMap(response);
    } catch (e) {
      throw Exception('Ошибка при обновлении количества товара: $e');
    }
  }

  /// Очищает корзину пользователя
  Future<void> clearCart() async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      await _supabase.from('cart_items').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Ошибка при очистке корзины: $e');
    }
  }
}