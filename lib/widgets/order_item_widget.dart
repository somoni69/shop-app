import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart'; // Нужна модель Order

class OrderItemWidget extends StatefulWidget {
  final Order order;
  const OrderItemWidget({super.key, required this.order});

  @override
  State<OrderItemWidget> createState() => _OrderItemWidgetState();
}

class _OrderItemWidgetState extends State<OrderItemWidget> {
  bool _expanded = false; // Состояние для раскрытия списка товаров

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            title: Text('\$${widget.order.totalAmount.toStringAsFixed(2)}'),
            subtitle: Text(
              DateFormat('dd.MM.yyyy hh:mm').format(widget.order.createdAt),
            ),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
          ),
          // --- Раскрывающийся список товаров ---
          if (_expanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              // Ограничим высоту, если товаров ОЧЕНЬ много
              height: (widget.order.items.length * 25.0 + 10).clamp(0.0, 150.0),
              child: ListView(
                children: widget.order.items
                    .map((prod) => Padding(
                          // Добавим отступ между товарами
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              // --- ИСПРАВЛЕНИЕ ЗДЕСЬ ---
                              // 1. Оборачиваем Text в Expanded, чтобы он занимал
                              //    все доступное место и не выталкивал соседа.
                              Expanded(
                                child: Text(
                                  prod.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  // 2. Добавляем overflow, чтобы длинный текст
                                  //    обрезался с многоточием.
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              // --- КОНЕЦ ИСПРАВЛЕНИЯ ---

                              // Добавим отступ между элементами
                              const SizedBox(width: 10),

                              Text(
                                '${prod.quantity}x \$${prod.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade400
                                        : Colors.grey),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
            )
        ],
      ),
    );
  }
}
