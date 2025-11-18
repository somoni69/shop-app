import 'package:flutter/material.dart';
import 'dart:async';
import '../locator.dart';
import '../models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Убедись, что 'uuid' есть в pubspec.yaml

class ProductsProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  String _currentQuery = '';
  String? _currentCategory;
  Timer? _debounce;

  List<Product> get items => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  ProductsProvider() {
    // Конструктор
  }

  Product findById(String id) {
    try {
      return _products.firstWhere((prod) => prod.id == id);
    } catch (e) {
      return Product(
          id: id,
          title: '',
          price: 0,
          description: '',
          images: [],
          category: '',
          rating: 0,
          sellerId: '');
    }
  }

  /// Загружает товары (с пагинацией, поиском И КАТЕГОРИЕЙ)
  Future<void> fetchProducts({
    String query = '',
    String? category,
    bool refresh = false,
    bool onlyForUser = false,
  }) async {
    if (refresh) {
      _products = [];
      _currentPage = 0;
      _hasMore = true;
      _currentQuery = query;
      _currentCategory = category;
      _isLoading = true;
      _isLoadingMore = false;
      notifyListeners();
    }

    if (_isLoadingMore || !_hasMore) return;

    if (_products.isNotEmpty && !refresh) {
      _isLoadingMore = true;
      notifyListeners();
    } else if (refresh == false && _products.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;

      var request = getIt<SupabaseClient>().from('products').select();

      if (onlyForUser) {
        final userId = getIt<SupabaseClient>().auth.currentUser?.id;
        if (userId != null) {
          request = request.eq('seller_id', userId);
        } else {
          throw Exception('Пользователь не авторизован.');
        }
      }

      if (_currentCategory != null) {
        request = request.eq('category', _currentCategory!);
      }

      if (_currentQuery.isNotEmpty) {
        request = request.ilike('title', '%$_currentQuery%');
      }

      // --- ИСПРАВЛЕНИЕ ЗДЕСЬ ---
      // Меняем тип переменной и порядок вызовов для совместимости с Supabase v2.5.0
      final response =
          await request.range(from, to).order('createdAt', ascending: false);
      // --- КОНЕЦ ИСПРАВЛЕНИЯ ---

      final List<Product> loadedProducts =
          (response as List).map((data) => Product.fromMap(data)).toList();

      if (loadedProducts.length < _pageSize) {
        _hasMore = false;
      }

      if (refresh) {
        _products = loadedProducts;
      } else {
        _products.addAll(loadedProducts);
      }
      _currentPage++;
    } catch (e) {
      print('### Ошибка загрузки товаров: $e');
      _hasMore = false;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreProducts({bool onlyForUser = false}) async {
    if (_currentQuery.isEmpty) {
      await fetchProducts(category: _currentCategory, onlyForUser: onlyForUser);
    }
  }

  void searchProducts(String query, {bool onlyForUser = false}) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchProducts(
          query: query.trim(),
          category: _currentCategory,
          refresh: true,
          onlyForUser: onlyForUser);
    });
  }

  Future<void> addProduct(Product product) async {
    final userId = getIt<SupabaseClient>().auth.currentUser?.id;
    if (userId == null) throw Exception('Пользователь не авторизован.');

    try {
      final response = await getIt<SupabaseClient>().from('products').insert({
        'title': product.title,
        'price': product.price,
        'description': product.description,
        'images': product.images,
        'seller_id': userId,
        'category': 'electronics' // TODO: Заменить на выбор категории
      }).select();

      if (response == null || (response is List && response.isEmpty)) {
        throw Exception('Supabase не вернул созданный продукт.');
      }
    } catch (e) {
      print('### Ошибка добавления товара: $e');
      throw Exception('Не удалось добавить товар. Ошибка: $e');
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    try {
      await getIt<SupabaseClient>().from('products').update({
        'title': updatedProduct.title,
        'price': updatedProduct.price,
        'description': updatedProduct.description,
        'images': updatedProduct.images,
      }).eq('id', updatedProduct.id);
    } catch (e) {
      print('### Ошибка обновления товара: $e');
      throw Exception('Не удалось обновить товар. Ошибка: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await getIt<SupabaseClient>().from('products').delete().eq('id', id);
    } catch (e) {
      print('### Ошибка удаления товара: $e');
      throw Exception('Не удалось удалить товар. Ошибка: $e');
    }
  }
}
