// lib/screens/manage_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../widgets/app_drawer.dart';
import 'edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  static const routeName = '/manage-products';
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  // --- УБИРАЕМ _isInit и _isLoading ---
  // Мы будем использовать FutureBuilder, это намного чище.

  // --- 1. ДОБАВЛЯЕМ Future ДЛЯ ЗАГРУЗКИ ---
  late Future<void> _productsFuture;

  @override
  void initState() {
    super.initState();
    // --- 2. ЗАПУСКАЕМ ЗАГРУЗКУ ОДИН РАЗ ---
    _productsFuture = _refreshProducts(context);
  }

  Future<void> _refreshProducts(BuildContext context) async {
    // Загружаем ТОЛЬКО товары пользователя
    await Provider.of<ProductsProvider>(context, listen: false)
        .fetchProducts(refresh: true, onlyForUser: true);
  }

  Future<void> _deleteProduct(BuildContext context, String id) async {
    try {
      await Provider.of<ProductsProvider>(context, listen: false)
          .deleteProduct(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар удален!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои Товары'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // --- 3. ОБНОВЛЯЕМ НАВИГАЦИЮ ---
              // Мы используем .then() для перезагрузки списка
              // ПОСЛЕ того, как вернемся с экрана создания.
              Navigator.of(context)
                  .pushNamed(EditProductScreen.routeName)
                  .then((_) {
                // Обновляем Future и перестраиваем экран
                setState(() {
                  _productsFuture = _refreshProducts(context);
                });
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      // --- 4. ЗАМЕНЯЕМ ВСЕ ТЕЛО НА FutureBuilder ---
      // Это решает проблему с отображением новых/обновленных товаров
      body: FutureBuilder(
        future: _productsFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.error != null) {
            return const Center(child: Text('Произошла ошибка загрузки.'));
          }

          // Если все ок, используем Consumer для списка
          return Consumer<ProductsProvider>(
            builder: (ctx, productsData, child) => RefreshIndicator(
              onRefresh: () => _refreshProducts(context),
              child: ListView.builder(
                itemCount: productsData.items.length,
                itemBuilder: (_, i) => Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            // Используем первую картинку из списка
                            productsData.items[i].images.isNotEmpty
                                ? productsData.items[i].images[0]
                                : ''),
                      ),
                      title: Text(productsData.items[i].title),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: Theme.of(context).primaryColor),
                              onPressed: () {
                                // Навигация на редактирование с обновлением
                                Navigator.of(context)
                                    .pushNamed(
                                  EditProductScreen.routeName,
                                  arguments: productsData.items[i].id,
                                )
                                    .then((_) {
                                  setState(() {
                                    _productsFuture = _refreshProducts(context);
                                  });
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Theme.of(context).colorScheme.error),
                              onPressed: () {
                                // Логика удаления (остается)
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Вы уверены?'),
                                    content: const Text('Удалить этот товар?'),
                                    actions: [
                                      TextButton(
                                        child: const Text('Нет'),
                                        onPressed: () => Navigator.of(ctx).pop(),
                                      ),
                                      TextButton(
                                        child: const Text('Да'),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _deleteProduct(
                                              context, productsData.items[i].id);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}