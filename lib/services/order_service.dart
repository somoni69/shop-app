import 'package:supabase_flutter/supabase_flutter.dart';
// Убираем import '../main.dart';
// Убедись, что путь к модели правильный. Если CartItemModel лежит в cart_provider, то ок.
// Но лучше перенести CartItemModel в отдельный файл в папку models.
import '../providers/cart_provider.dart';
import 'package:flutter/foundation.dart';

class Order {
  final String id;
  final double totalAmount;
  final DateTime createdAt;
  final List<CartItemModel> items;

  Order({
    required this.id,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });
}

class OrderService {
  // 1. Внедряем зависимость
  final SupabaseClient _supabase;

  // 2. Конструктор
  OrderService(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Создает новый заказ на основе текущей корзины
  Future<Order> createOrder(
      List<CartItemModel> cartItems, double totalAmount) async {
    final userId = _userId;
    if (userId == null) throw Exception('Пользователь не авторизован');
    if (cartItems.isEmpty) throw Exception('Корзина пуста');

    try {
      // 1. Создаем запись в таблице 'orders'
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'total_amount': totalAmount,
            // created_at создается автоматически Supabase, если не передать,
            // но при select нам его вернут
          })
          .select()
          .single();

      final orderId = orderResponse['id'];
      // Исправляем парсинг даты (используем created_at из базы)
      final createdAt = DateTime.parse(orderResponse['created_at']);

      // 2. Создаем записи в 'order_items'
      final orderItemsData = cartItems
          .map((item) => {
                'order_id': orderId,
                'product_id': item.productId,
                'quantity': item.quantity,
                'price': item.price,
                'title': item.title,
              })
          .toList();

      await _supabase.from('order_items').insert(orderItemsData);

      return Order(
          id: orderId,
          totalAmount: totalAmount,
          createdAt: createdAt,
          items: cartItems);
    } catch (e) {
      // Лучше использовать log, но пока print ок
      debugPrint('Ошибка создания заказа: $e');
      throw Exception('Не удалось создать заказ. Попробуйте снова.');
    }
  }

  /// Загружает историю заказов текущего пользователя
  Future<List<Order>> fetchOrders() async {
    final userId = _userId;
    if (userId == null) throw Exception('Пользователь не авторизован');

    try {
      // 1. Загружаем основные данные заказов
      final ordersResponse = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          // ВАЖНО: В базе колонка называется 'created_at', а не 'createdAt'
          .order('created_at', ascending: false);

      final List<Order> loadedOrders = [];

      // 2. Для каждого заказа загружаем его товары (order_items)
      // Примечание для будущего: Это проблема N+1 (много запросов).
      // Позже мы оптимизируем это через .select('*, order_items(*)'), но пока пусть работает так.
      for (final orderData in ordersResponse as List) {
        final orderId = orderData['id'];

        final itemsResponse = await _supabase
            .from('order_items')
            .select()
            .eq('order_id', orderId);

        final List<CartItemModel> orderItems =
            (itemsResponse as List).map((itemData) {
          return CartItemModel(
            id: itemData['id'],
            productId: itemData['product_id'],
            title: itemData['title'],
            quantity: itemData['quantity'],
            price: (itemData['price'] as num).toDouble(),
          );
        }).toList();

        loadedOrders.add(Order(
          id: orderId,
          totalAmount: (orderData['total_amount'] as num).toDouble(),
          // ВАЖНО: Берем поле created_at
          createdAt: DateTime.parse(orderData['created_at']),
          items: orderItems,
        ));
      }

      return loadedOrders;
    } catch (e) {
      debugPrint('Ошибка загрузки заказов: $e');
      throw Exception('Не удалось загрузить историю заказов.');
    }
  }
}
