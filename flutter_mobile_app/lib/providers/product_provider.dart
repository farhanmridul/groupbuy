import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  
  // Getters
  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  
  // Fetch products with optional filters
  Future<void> fetchProducts({
    String? category,
    String? search,
    int? page,
    String? ordering,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final productsData = await _apiService.getProducts(
        category: category,
        search: search,
        page: page,
        ordering: ordering,
      );
      
      // If it's the first page, replace the list; otherwise, append
      if (page == null || page == 1) {
        _products = [];
      }
      
      final newProducts = productsData.map((data) => Product.fromJson(data)).toList();
      
      if (newProducts.isEmpty) {
        _hasMore = false;
      } else {
        _products.addAll(newProducts as List<Product>);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch a specific product's details
  Future<void> fetchProductDetail(int productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final productData = await _apiService.getProductDetail(productId);
      _selectedProduct = Product.fromJson(productData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a product review
  Future<void> addReview(int productId, String title, String content, int rating) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _apiService.addReview(productId, title, content, rating);
      
      // Refresh product to show the new review
      await fetchProductDetail(productId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Join a product's waitlist
  Future<void> joinWaitlist(int productId, int batchId, int quantity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _apiService.joinWaitlist(productId, batchId, quantity);
      
      // Refresh product to update batch status
      await fetchProductDetail(productId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Find a product by ID in the current list
  Product? findById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Clear the product list
  void clear() {
    _products = [];
    _selectedProduct = null;
    _isLoading = false;
    _error = null;
    _hasMore = true;
    notifyListeners();
  }
  
  // Reset pagination
  void resetPagination() {
    _hasMore = true;
    notifyListeners();
  }
}