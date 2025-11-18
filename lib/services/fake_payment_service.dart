import 'package:flutter/material.dart';

class FakePaymentService {
  // Этот метод будет показывать наше "фейковое" окно оплаты
  Future<bool> showFakePaymentDialog(BuildContext context, double totalAmount) async {
    final bool? paymentSuccess = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        // --- 1. ДОБАВЛЯЕМ КОНТРОЛЛЕРЫ ---
        final cardController = TextEditingController(text: '4242424242424242');
        final expiryController = TextEditingController(text: '12/30');
        final cvcController = TextEditingController(text: '123');

        bool isLoading = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Тестовая оплата'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Сумма к оплате: \$${totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else
                    Column(
                      children: [
                        TextField(
                          controller: cardController,
                          decoration: InputDecoration(
                            labelText: 'Тестовая карта',
                            hintText: '4242 4242 4242 4242',
                            errorText: errorText,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        // --- 2. ДОБАВЛЯЕМ НОВЫЕ ПОЛЯ ---
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: expiryController,
                                decoration: const InputDecoration(
                                  labelText: 'Срок (ММ/ГГ)',
                                  hintText: '12/30',
                                ),
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: cvcController,
                                decoration: const InputDecoration(
                                  labelText: 'CVC/CVV',
                                  hintText: '123',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        // --- КОНЕЦ НОВЫХ ПОЛЕЙ ---
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                FilledButton(
                  child: const Text('Оплатить'),
                  onPressed: isLoading ? null : () async {
                    // --- 3. ОБНОВЛЯЕМ ПРОВЕРКУ ---
                    if (cardController.text != '4242424242424242' || 
                        expiryController.text.isEmpty || 
                        cvcController.text.isEmpty) {
                      setState(() {
                        errorText = 'Заполните все поля (карта 4242...)';
                      });
                      return;
                    }

                    setState(() {
                      isLoading = true;
                      errorText = null;
                    });

                    // Имитируем задержку сети (2 секунды)
                    await Future.delayed(const Duration(seconds: 2));

                    Navigator.of(ctx).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    return paymentSuccess ?? false;
  }
}