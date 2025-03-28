import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => [..._orders];
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _setLoading(true);
    _setError(null);

    try {
      final fetchedOrders = await ApiService.getOrders();
      _orders = fetchedOrders;
      
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchOrderDetail(int orderId) async {
    _setLoading(true);
    _setError(null);

    try {
      final order = await ApiService.getOrderDetail(orderId);
      _selectedOrder = order;
      
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> createOrder(int shippingAddressId, String shippingMethod) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.createOrder(shippingAddressId, shippingMethod);
      
      // Refresh the orders list
      await fetchOrders();
      
      return response;
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchWaitlistItems() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getWaitlistItems();
      // TODO: Update state with waitlist items when model is available
      
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }
}