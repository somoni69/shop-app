import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart'; // Не забываем get_it
import '../providers/products_provider.dart';
import '../screens/orders_screen.dart';
import '../screens/manage_products_screen.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../locator.dart'; // Импорт локатора

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _selectCategory(BuildContext context, String? category) {
    Navigator.of(context).pop(); // Закрываем меню
    // Обновляем список товаров через провайдер
    Provider.of<ProductsProvider>(context, listen: false)
        .fetchProducts(category: category, refresh: true, onlyForUser: false);
    
    // Если мы не на главном экране, нужно вернуться туда
    if (ModalRoute.of(context)?.settings.name != '/') {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            title: const Text('Меню'),
            automaticallyImplyLeading: false, // Убираем кнопку "назад" в меню
          ),
          
          // --- 1. КАТЕГОРИИ ---
          ListTile(
            leading: const Icon(Icons.shop),
            title: const Text('Магазин (Все товары)'),
            onTap: () => _selectCategory(context, null),
          ),
          ListTile(
            leading: const Icon(Icons.speaker), // Или Icons.category
            title: const Text('Электроника'),
            onTap: () => _selectCategory(context, 'electronics'),
          ),
          ListTile(
            leading: const Icon(Icons.diamond),
            title: const Text('Украшения'),
            onTap: () => _selectCategory(context, 'jewelery'),
          ),
          ListTile(
            leading: const Icon(Icons.man),
            title: const Text('Мужская одежда'),
            onTap: () => _selectCategory(context, "men's clothing"),
          ),
           ListTile(
            leading: const Icon(Icons.woman),
            title: const Text('Женская одежда'),
            onTap: () => _selectCategory(context, "women's clothing"),
          ),
          
          const Divider(), // Разделитель

          // --- 2. ЛИЧНЫЙ КАБИНЕТ ---
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Мой профиль'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(ProfileScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Мои Товары'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(ManageProductsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Мои заказы'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(OrdersScreen.routeName);
            },
          ),

          const Spacer(), // Прижимает кнопку "Выход" к низу

          // --- 3. ВЫХОД ---
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Выход', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              
              // Переходим на главный экран (обычно это AuthWrapper)
              Navigator.of(context).pushReplacementNamed('/');
              
              // Вызываем выход через наш новый сервис
              getIt<AuthService>().signOut();
            },
          ),
          const SizedBox(height: 20), // Отступ снизу для красоты
        ],
      ),
    );
  }
}