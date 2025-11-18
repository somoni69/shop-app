import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Для kDebugMode

// ИМПОРТИРУЕМ НАШ ЛОКАТОР
import '../locator.dart'; 

import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/logging_service.dart';
import '../models/product.dart';

// Модель оставляем как есть (хотя в идеале лучше вынести в отдельный файл в папку models)
class CartItemModel {
  final String id;
  final String productId;
  final String title;
  final int quantity;
  final double price;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
  });

  factory CartItemModel.fromServiceItem(CartItem item) {
    return CartItemModel(
      id: item.id,
      productId: item.productId,
      title: item.title,
      quantity: item.quantity,
      price: item.price,
    );
  }
}

class CartProvider with ChangeNotifier {
  // -----------------------------------------------------------
  // ИЗМЕНЕНИЯ ЗДЕСЬ:
  // Мы больше не создаем сервисы сами (new CartService()).
  // Мы берем готовые, настроенные экземпляры из getIt.
  // -----------------------------------------------------------
  final CartService _cartService = getIt<CartService>();
  final AuthService _authService = getIt<AuthService>();

  Map<String, CartItemModel> _items = {};
  bool _isLoading = false;
  String? _error;
  String? _rawError; 
  bool _serverAvailable = true;
  final List<Map<String, dynamic>> _pendingActions = [];

  Map<String, CartItemModel> get items => {..._items};
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  String? get rawErrorForDebug => kDebugMode ? _rawError : null;
  bool get serverAvailable => _serverAvailable;

  /// Загружает корзину с сервера
  Future<void> loadCart() async {
    if (_authService.currentUser == null) {
      _items.clear();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _setError(null);
    _rawError = null;

    const maxAttempts = 3;
    var attempt = 0;
    while (attempt < maxAttempts) {
      attempt += 1;
      try {
        final cartItems = await _cartService.fetchCartItems();
        _items = {
          for (var item in cartItems)
            item.id: CartItemModel.fromServiceItem(item)
        };
        
        _rawError = null;
        _serverAvailable = true;
        if (_pendingActions.isNotEmpty) {
          await _flushPendingActions();
        }
        break;
      } catch (e, st) {
        _rawError = e.toString();
        LoggingService.logError(e, st,
            context: 'CartProvider.loadCart attempt $attempt');

        final formatted = _formatError(e);
        _setError(formatted);
        
        if (formatted.contains('отсутствует таблица')) {
          _serverAvailable = false;
          LoggingService.logInfo('Switching to local cart mode',
              context: 'CartProvider');
        }

        if (attempt >= maxAttempts) {
          break;
        }

        final waitMs = 200 * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }

    _setLoading(false);
  }

  /// Добавляет товар в корзину
  Future<void> addItem(Product product) async {
    if (_authService.currentUser == null) {
      _setError('Пользователь не авторизован');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      if (!_serverAvailable) {
        final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
        _items[localId] = CartItemModel(
          id: localId,
          productId: product.id,
          title: product.title,
          quantity: 1,
          price: product.price,
        );
        _pendingActions.add({
          'op': 'add',
          'productId': product.id,
          'title': product.title,
          'price': product.price,
          'localId': localId,
        });
        LoggingService.logInfo('Queued addItem locally: ${product.id}',
            context: 'CartProvider');
        notifyListeners();
      } else {
        final cartItem = await _cartService.addItem(
            product.id, product.title, product.price);
        _items[cartItem.id] = CartItemModel.fromServiceItem(cartItem);
        notifyListeners();
      }
    } catch (e) {
      _rawError = e.toString();
      LoggingService.logError(e, null, context: 'CartProvider.addItem');
      _setError(_formatError(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Удаляет товар из корзины
  Future<void> removeItem(String itemId) async {
    if (_authService.currentUser == null) {
      _setError('Пользователь не авторизован');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      if (!_serverAvailable && itemId.startsWith('local-')) {
        _items.remove(itemId);
        _pendingActions
            .removeWhere((a) => a['op'] == 'add' && a['localId'] == itemId);
        LoggingService.logInfo('Removed local-only cart item $itemId',
            context: 'CartProvider');
        notifyListeners();
      } else if (!_serverAvailable) {
        _pendingActions.add({'op': 'remove', 'itemId': itemId});
        _items.remove(itemId);
        notifyListeners();
        LoggingService.logInfo('Queued removeItem locally: $itemId',
            context: 'CartProvider');
      } else {
        await _cartService.removeItem(itemId);
        _items.remove(itemId);
        notifyListeners();
      }
    } catch (e) {
      _rawError = e.toString();
      LoggingService.logError(e, null, context: 'CartProvider.removeItem');
      _setError(_formatError(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Обновляет количество товара в корзине
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    if (_authService.currentUser == null) {
      _setError('Пользователь не авторизован');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      if (quantity <= 0) {
        await removeItem(itemId);
        return;
      }

      if (!_serverAvailable) {
        if (_items.containsKey(itemId)) {
          final curr = _items[itemId]!;
          _items[itemId] = CartItemModel(
            id: curr.id,
            productId: curr.productId,
            title: curr.title,
            quantity: quantity,
            price: curr.price,
          );
          _pendingActions
              .add({'op': 'update', 'itemId': itemId, 'quantity': quantity});
          LoggingService.logInfo(
              'Queued updateItem locally: $itemId -> $quantity',
              context: 'CartProvider');
          notifyListeners();
        }
      } else {
        final cartItem =
            await _cartService.updateItemQuantity(itemId, quantity);
        _items[cartItem.id] = CartItemModel.fromServiceItem(cartItem);
        notifyListeners();
      }
    } catch (e) {
      _rawError = e.toString();
      LoggingService.logError(e, null,
          context: 'CartProvider.updateItemQuantity');
      _setError(_formatError(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Очищает корзину
  Future<void> clear() async {
    if (_authService.currentUser == null) {
      _setError('Пользователь не авторизован');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      if (!_serverAvailable) {
        _pendingActions.add({'op': 'clear'});
        _items.clear();
        notifyListeners();
        LoggingService.logInfo('Queued clear cart locally',
            context: 'CartProvider');
      } else {
        await _cartService.clearCart();
        _items.clear();
        notifyListeners();
      }
    } catch (e) {
      _rawError = e.toString();
      LoggingService.logError(e, null, context: 'CartProvider.clear');
      _setError(_formatError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _flushPendingActions() async {
    if (_pendingActions.isEmpty) return;
    
    final actions = List<Map<String, dynamic>>.from(_pendingActions);
    for (var action in actions) {
      try {
        final op = action['op'] as String?;
        if (op == null) continue; 

        if (op == 'add') {
          final productId = action['productId'] as String?;
          if (productId == null) continue;

          final localId = action['localId'] as String?;
          if (localId == null) continue; 

          final title = action['title'] as String?;
          final price = action['price'] as double?;
          if (title == null || price == null)
            continue; 

          final created = await _cartService.addItem(productId, title, price);
          
          final local = _items.remove(localId);
          if (local != null) {
            _items[created.id] = CartItemModel.fromServiceItem(created);
          }
        } else if (op == 'remove') {
          final itemId = action['itemId'] as String?;
          if (itemId != null) {
            await _cartService.removeItem(itemId);
          }
        } else if (op == 'update') {
          final itemId = action['itemId'] as String?;
          final quantity = action['quantity'] as int?;
          if (itemId != null && quantity != null) {
            final updated =
                await _cartService.updateItemQuantity(itemId, quantity);
            _items[updated.id] = CartItemModel.fromServiceItem(updated);
          }
        } else if (op == 'clear') {
          await _cartService.clearCart();
          _items.clear();
        }

        _pendingActions.removeWhere((element) => element == action);
      } catch (e, st) {
        LoggingService.logError(e, st,
            context: 'CartProvider._flushPendingActions');
      }
    }
    notifyListeners();
  }

  String _formatError(Object e) {
    final s = e.toString();
    if (s.contains("Could not find the table") ||
        s.contains('PGRST205') ||
        s.contains('public.cart_items')) {
      return 'Корзина временно недоступна. Обратитесь в поддержку.';
    }
    return 'Ошибка при работе с корзиной. Попробуйте снова.';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}