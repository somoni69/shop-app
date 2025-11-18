// lib/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/product_item.dart';
import '../widgets/app_drawer.dart';
import 'cart_screen.dart';
import 'package:flutter/foundation.dart'; // Для kDebugMode

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  var _isInit = true;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_performSearch);
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<CartProvider>(context, listen: false).loadCart();
      
      // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
      // Вызываем fetchProducts с refresh: true и onlyForUser: false,
      // чтобы загрузить ВСЕ товары при первом входе.
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts(
        refresh: true,
        onlyForUser: false 
      );
      // --- КОНЕЦ ИЗМЕНЕНИЯ ---
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isSearching &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      // Передаем onlyForUser: false при дозагрузке
      Provider.of<ProductsProvider>(context, listen: false).fetchMoreProducts(onlyForUser: false);
    }
  }

  void _performSearch() {
    final query = _searchController.text;
    // Передаем onlyForUser: false при поиске
    Provider.of<ProductsProvider>(context, listen: false).searchProducts(query, onlyForUser: false);
  }

  AppBar _buildAppBar(BuildContext context) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            // Перезагружаем ВСЕ товары
            Provider.of<ProductsProvider>(context, listen: false)
                .fetchProducts(refresh: true, onlyForUser: false);
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск по всем товарам...',
            border: InputBorder.none,
          ),
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
      );
    } else {
      // Обычный AppBar
      return AppBar(
        title: const Text('Каталог'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
          ),
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: ch,
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.of(context).pushNamed(CartScreen.routeName);
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: Consumer<ProductsProvider>(
        builder: (ctx, productsData, child) {
          final bool showLoading = productsData.isLoading && productsData.items.isEmpty;
          final bool showEmpty = !productsData.isLoading && productsData.items.isEmpty;
          final bool showLoadingMore = productsData.isLoadingMore && productsData.items.isNotEmpty;

          if (showLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (showEmpty) {
            return Center(child: Text(_isSearching ? 'Ничего не найдено' : 'Товары не найдены.'));
          }

          return GridView.builder(
            controller: _isSearching ? null : _scrollController,
            padding: const EdgeInsets.all(10.0),
            itemCount: productsData.items.length + (showLoadingMore ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (ctx, i) {
              if (i == productsData.items.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return ProductItem(
                product: productsData.items[i],
              );
            },
          );
        },
      ),
    );
  }
}