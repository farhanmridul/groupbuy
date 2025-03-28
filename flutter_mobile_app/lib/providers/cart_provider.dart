import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.wholesalePrice * quantity;
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => [..._items];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> fetchCart() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getCart();
      final cartItems = response['items'] as List<dynamic>;
      
      _items = cartItems.map((item) {
        final product = Product.fromJson(item['product']);
        return CartItem(
          product: product,
          quantity: item['quantity'],
        );
      }).toList();
      
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addItem(Product product, int quantity) async {
    _setLoading(true);
    _setError(null);

    try {
      await ApiService.addToCart(product.id, quantity);
      
      // Refetch the cart to get updated data
      await fetchCart();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateItemQuantity(Product product, int quantity) async {
    if (quantity <= 0) {
      return removeItem(product.id);
    }

    _setLoading(true);
    _setError(null);

    try {
      await ApiService.updateCartItem(product.id, quantity);
      
      // Refetch the cart to get updated data
      await fetchCart();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeItem(int productId) async {
    _setLoading(true);
    _setError(null);

    try {
      await ApiService.removeCartItem(productId);
      
      // Refetch the cart to get updated data
      await fetchCart();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clear() async {
    _setLoading(true);
    _setError(null);

    try {
      await ApiService.clearCart();
      
      _items = [];
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}