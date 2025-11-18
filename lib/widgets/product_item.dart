// lib/widgets/product_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../screens/product_detail_screen.dart';

class ProductItem extends StatelessWidget {
  final Product product;

  const ProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // --- ИЗМЕНЕНИЕ ---
    // Получаем ПЕРВУЮ картинку из списка.
    // Если список пуст, показываем заглушку.
    final String imageUrl = product.images.isNotEmpty
        ? product.images[0]
        : 'https://i.imgur.com/S8A4inC.png'; // Ссылка на картинку-заглушку
    // --- КОНЕЦ ИЗМЕНЕНИЯ ---

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(
            ProductDetailScreen.routeName,
            arguments: product,
          );
        },
        child: GridTile(
          footer: GridTileBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black54
                : Colors.black87,
            title: Text(
              product.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                cart.addItem(product);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Товар добавлен в корзину!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: Image.network(
            imageUrl, // <-- ИЗМЕНЕНИЕ
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            // Добавим обработчик ошибок на случай битой ссылки
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                child: Icon(Icons.broken_image,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[400]),
              );
            },
          ),
        ),
      ),
    );
  }
}
