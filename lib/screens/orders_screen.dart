import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Нужно для форматирования даты
import 'package:get_it/get_it.dart';

import '../services/order_service.dart';
import '../widgets/app_drawer.dart'; // Не забудь про меню

class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders';

  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем сервис из локатора
    final orderService = GetIt.instance<OrderService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Order>>(
        // Загружаем заказы при открытии экрана
        future: orderService.fetchOrders(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Обработка ошибок
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Произошла ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Трюк для перезагрузки страницы:
                      // Просто перестраиваем виджет (в реальном проекте лучше использовать setState внутри Stateful)
                      Navigator.of(context).pushReplacementNamed(routeName);
                    },
                    child: const Text('Попробовать снова'),
                  )
                ],
              ),
            );
          }

          final orders = snapshot.data;

          if (orders == null || orders.isEmpty) {
            return const Center(child: Text('У вас пока нет заказов.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (ctx, i) => OrderItemWidget(orders[i]),
          );
        },
      ),
    );
  }
}

class OrderItemWidget extends StatefulWidget {
  final Order order;

  const OrderItemWidget(this.order, {super.key});

  @override
  State<OrderItemWidget> createState() => _OrderItemWidgetState();
}

class _OrderItemWidgetState extends State<OrderItemWidget> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Форматирование даты (потребуется пакет intl)
    // Если intl не установлен, можно использовать widget.order.createdAt.toString()
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(widget.order.createdAt);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _expanded ? (widget.order.items.length * 20.0 + 110) : 95,
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text('\$${widget.order.totalAmount.toStringAsFixed(2)}'),
              subtitle: Text(dateStr),
              trailing: IconButton(
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
            ),
            // Если развернуто — показываем детали
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              height: _expanded ? (widget.order.items.length * 20.0 + 10) : 0,
              child: ListView(
                children: widget.order.items
                    .map(
                      (prod) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            prod.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${prod.quantity}x \$${prod.price}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          )
                        ],
                      ),
                    )
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}