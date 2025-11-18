import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

import '../providers/cart_provider.dart';
import '../widgets/cart_item.dart';
import '../services/order_service.dart';
import '../services/fake_payment_service.dart';

class CartScreen extends StatefulWidget {
  static const routeName = '/cart';
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // При открытии экрана пробуем обновить корзину
    Future.microtask(
        () => Provider.of<CartProvider>(context, listen: false).loadCart());
  }

  Future<void> _processPayment(CartProvider cartProvider) async {
    setState(() => _isProcessing = true);
    try {
      final cartItems = cartProvider.items;
      final total = cartProvider.totalAmount;

      // 1. Фейковая оплата
      final paymentService = FakePaymentService();
      final paymentSuccessful =
          await paymentService.showFakePaymentDialog(context, total);

      if (paymentSuccessful) {
        // 2. Создаем заказ через OrderService (из GetIt)
        final orderService = GetIt.instance<OrderService>();

        await orderService.createOrder(cartItems.values.toList(), total);

        // 3. Очищаем корзину
        await cartProvider.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заказ успешно оформлен!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Возвращаемся назад
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ваша корзина')),
      body: Consumer<CartProvider>(
        builder: (ctx, cart, child) {
          // Сценарий 1: Загрузка и нет данных
          if (cart.isLoading && cart.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Сценарий 2: Данных нет, и мы не загружаемся (Корзина пуста)
          if (cart.items.isEmpty && !cart.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey),
                  const SizedBox(height: 16),
                  Text('Корзина пуста',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey)),
                ],
              ),
            );
          }

          // Сценарий 3: Данные есть (или ошибка, но старые данные остались)
          return RefreshIndicator(
            onRefresh: () => cart.loadCart(),
            child: Column(
              children: [
                // --- БЛОК ПРЕДУПРЕЖДЕНИЙ ---

                // Если нет связи с сервером (Offline Mode)
                if (!cart.serverAvailable)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.orangeAccent.shade700
                        : Colors.orangeAccent.shade100,
                    padding: const EdgeInsets.all(8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: Colors.brown),
                        SizedBox(width: 8),
                        Text('Режим оффлайн. Данные синхронизируются позже.',
                            style:
                                TextStyle(color: Colors.brown, fontSize: 12)),
                      ],
                    ),
                  ),

                // Если есть ошибка, но данные показываем из кэша
                if (cart.error != null && cart.serverAvailable)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.redAccent.shade700
                        : Colors.redAccent.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Ошибка синхронизации: ${cart.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                // --- КАРТОЧКА ИТОГО ---
                Card(
                  margin: const EdgeInsets.all(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text('Итого:', style: TextStyle(fontSize: 20)),
                        const Spacer(),
                        Chip(
                          label: Text(
                            '\$${cart.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),

                        // Кнопка оплаты
                        _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : TextButton(
                                onPressed: (cart.items.isEmpty || _isProcessing)
                                    ? null
                                    : () => _processPayment(cart),
                                child: const Text('ОПЛАТИТЬ'),
                              )
                      ],
                    ),
                  ),
                ),

                // --- СПИСОК ТОВАРОВ ---
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.elementAt(i);
                      return CartItemWidget(
                        id: item.id,
                        productId: item.productId,
                        title: item.title,
                        quantity: item.quantity,
                        price: item.price,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
