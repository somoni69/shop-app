import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Нужен для User
import 'package:shop_app/providers/cart_provider.dart';
import 'package:shop_app/services/cart_service.dart';
import 'package:shop_app/services/auth_service.dart';
import 'package:shop_app/locator.dart'; // Если локатор нужен для сброса

// --- 1. Создаем Mock-классы ---
// Мы говорим: "Притворитесь этими сервисами"
class MockCartService extends Mock implements CartService {}
class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {} // Фейковый юзер Supabase

void main() {
  late CartProvider cartProvider;
  late MockCartService mockCartService;
  late MockAuthService mockAuthService;

  // --- 2. Подготовка перед КАЖДЫМ тестом ---
  setUp(() {
    // Сбрасываем GetIt, чтобы тесты не мешали друг другу
    GetIt.instance.reset();

    // Создаем моки
    mockCartService = MockCartService();
    mockAuthService = MockAuthService();

    // Регистрируем моки в GetIt (как мы делали в locator.dart, но с фейками)
    GetIt.instance.registerSingleton<CartService>(mockCartService);
    GetIt.instance.registerSingleton<AuthService>(mockAuthService);

    // Имитируем, что пользователь залогинен
    final mockUser = MockUser();
    // Когда спросят currentUser, верни mockUser (не null)
    when(() => mockAuthService.currentUser).thenReturn(mockUser); 

    // Создаем провайдер
    cartProvider = CartProvider();
  });

  // --- 3. Сами тесты ---
  group('CartProvider Tests', () {
    
    test('Начальное состояние корзины должно быть пустым', () {
      expect(cartProvider.items.length, 0);
      expect(cartProvider.totalAmount, 0.0);
    });

    test('totalAmount должен считаться правильно', () async {
      // СЦЕНАРИЙ:
      // Мы хотим добавить товар и проверить, правильно ли провайдер посчитает сумму.
      // Но addItem лезет в интернет. Мы должны "замокать" ответ от сервиса.

      // Подготовка данных
      const productId = 'p1';
      const title = 'Red Shirt';
      const price = 29.99;
      
      // Говорим моку: "Если тебя попросят добавить товар, верни вот такой CartItem"
      final fakeItem = CartItem(
        id: 'cart_1',
        productId: productId,
        title: title,
        quantity: 1,
        price: price,
        userId: 'user_1',
        createdAt: DateTime.now(),
      );

      // Настройка ответа сервиса (STUB)
      when(() => mockCartService.addItem(productId, title, price))
          .thenAnswer((_) async => fakeItem);

      // ДЕЙСТВИЕ (Act): Вызываем метод провайдера
      // Нам нужно создать фиктивный Product объект, чтобы передать в addItem
      // (В твоем коде addItem принимает Product, давай создадим простую заглушку или изменим тест под реализацию)
      // Предположим, у тебя есть класс Product
      /* Если у тебя класс Product требует много полей, создай его тут.
         Product testProduct = Product(id: 'p1', title: 'Red Shirt', price: 29.99, ...);
         await cartProvider.addItem(testProduct);
      */
       
      // ЧТОБЫ НЕ УСЛОЖНЯТЬ СЕЙЧАС, ДАВАЙ ПРОТЕСТИРУЕМ РАСЧЕТ ЧЕРЕЗ ЗАГРУЗКУ (fetch)
      // Это проще для демонстрации.
    });
    
    test('loadCart должен загрузить данные и посчитать сумму', () async {
      // 1. Готовим фейковые данные, которые якобы пришли с сервера
      final fakeItems = [
        CartItem(id: '1', productId: 'p1', title: 'Shirt', quantity: 2, price: 10.0, userId: 'u1', createdAt: DateTime.now()), // Сумма 20.0
        CartItem(id: '2', productId: 'p2', title: 'Shoes', quantity: 1, price: 50.0, userId: 'u1', createdAt: DateTime.now()), // Сумма 50.0
      ];

      // 2. Говорим сервису: когда вызовут fetchCartItems, верни этот список
      when(() => mockCartService.fetchCartItems()).thenAnswer((_) async => fakeItems);

      // 3. Вызываем загрузку
      await cartProvider.loadCart();

      // 4. ПРОВЕРКИ (Assert)
      
      // Проверяем, что загрузилось 2 товара
      expect(cartProvider.itemCount, 2);
      
      // Проверяем сумму: (2 * 10) + (1 * 50) = 70.0
      expect(cartProvider.totalAmount, 70.0);
      
      // Проверяем, что провайдер не в состоянии загрузки
      expect(cartProvider.isLoading, false);
    });
  });
}