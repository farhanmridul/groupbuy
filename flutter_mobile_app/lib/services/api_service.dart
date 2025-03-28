import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for API requests
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Points to Django server when using Android emulator
  
  // Authentication endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String logoutEndpoint = '/auth/logout/';
  static const String userEndpoint = '/auth/user/';
  
  // Product endpoints
  static const String productsEndpoint = '/products/';
  static const String categoriesEndpoint = '/categories/';
  static const String reviewsEndpoint = '/reviews/';
  static const String waitlistEndpoint = '/products/waitlist/';
  
  // Cart endpoints
  static const String cartEndpoint = '/cart/';
  static const String addToCartEndpoint = '/cart/add/';
  static const String updateCartEndpoint = '/cart/update/';
  static const String removeFromCartEndpoint = '/cart/remove/';
  static const String clearCartEndpoint = '/cart/clear/';
  
  // Order endpoints
  static const String ordersEndpoint = '/orders/';
  static const String createOrderEndpoint = '/orders/create/';
  static const String orderPaymentEndpoint = '/orders/payment/';
  
  // Address endpoints
  static const String addressesEndpoint = '/addresses/';
  static const String setDefaultAddressEndpoint = '/addresses/set-default/';
  
  // Token storage key
  static const String tokenKey = 'auth_token';
  
  // HTTP client
  final http.Client _client = http.Client();
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }
  
  // Save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }
  
  // Clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
  
  // Get authorization headers
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }
    
    return headers;
  }
  
  // Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return json.decode(response.body);
    } else {
      try {
        final errorData = json.decode(response.body);
        final errorMsg = errorData is Map ? 
          (errorData['detail'] ?? errorData.values.first) : 
          'Error: ${response.statusCode}';
        throw HttpException(errorMsg.toString());
      } catch (e) {
        if (e is HttpException) {
          rethrow;
        }
        throw HttpException('Error: ${response.statusCode}');
      }
    }
  }
  
  // GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, bool requiresAuth = true}) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    String url = baseUrl + endpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      url = '$url?$queryString';
    }
    
    final response = await _client.get(
      Uri.parse(url),
      headers: headers,
    );
    
    return _handleResponse(response);
  }
  
  // POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data, bool requiresAuth = true}) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    final response = await _client.post(
      Uri.parse(baseUrl + endpoint),
      headers: headers,
      body: data != null ? json.encode(data) : null,
    );
    
    return _handleResponse(response);
  }
  
  // PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? data, bool requiresAuth = true}) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    final response = await _client.put(
      Uri.parse(baseUrl + endpoint),
      headers: headers,
      body: data != null ? json.encode(data) : null,
    );
    
    return _handleResponse(response);
  }
  
  // PATCH request
  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? data, bool requiresAuth = true}) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    final response = await _client.patch(
      Uri.parse(baseUrl + endpoint),
      headers: headers,
      body: data != null ? json.encode(data) : null,
    );
    
    return _handleResponse(response);
  }
  
  // DELETE request
  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    final response = await _client.delete(
      Uri.parse(baseUrl + endpoint),
      headers: headers,
    );
    
    return _handleResponse(response);
  }
  
  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = {
      'email': email,
      'password': password,
    };
    
    final response = await post(loginEndpoint, data: data, requiresAuth: false);
    
    if (response != null && response['token'] != null) {
      await saveToken(response['token']);
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> register(String email, String firstName, String lastName, String password) async {
    final data = {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'password1': password,
      'password2': password,
    };
    
    final response = await post(registerEndpoint, data: data, requiresAuth: false);
    
    if (response != null && response['token'] != null) {
      await saveToken(response['token']);
    }
    
    return response;
  }
  
  Future<void> logout() async {
    await post(logoutEndpoint);
    await clearToken();
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await get(userEndpoint);
  }
  
  // Product methods
  Future<List<dynamic>> getProducts({
    String? category,
    String? search,
    int? page,
    String? ordering,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page;
    if (ordering != null) queryParams['ordering'] = ordering;
    
    final response = await get(productsEndpoint, queryParams: queryParams, requiresAuth: false);
    
    if (response is Map && response.containsKey('results')) {
      return response['results'];
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> getProductDetail(int productId) async {
    return await get('$productsEndpoint$productId/', requiresAuth: false);
  }
  
  Future<List<dynamic>> getCategories() async {
    final response = await get(categoriesEndpoint, requiresAuth: false);
    
    if (response is Map && response.containsKey('results')) {
      return response['results'];
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> getCategoryDetail(int categoryId) async {
    return await get('$categoriesEndpoint$categoryId/', requiresAuth: false);
  }
  
  Future<Map<String, dynamic>> addReview(int productId, String title, String content, int rating) async {
    final data = {
      'title': title,
      'content': content,
      'rating': rating,
    };
    
    return await post('$productsEndpoint$productId/reviews/', data: data);
  }
  
  Future<Map<String, dynamic>> joinWaitlist(int productId, int batchId, int quantity) async {
    final data = {
      'product_id': productId,
      'batch_id': batchId,
      'quantity': quantity,
    };
    
    return await post(waitlistEndpoint, data: data);
  }
  
  // Cart methods
  Future<Map<String, dynamic>> getCart() async {
    return await get(cartEndpoint);
  }
  
  Future<Map<String, dynamic>> addToCart(int productId, int quantity) async {
    final data = {
      'product_id': productId,
      'quantity': quantity,
    };
    
    return await post(addToCartEndpoint, data: data);
  }
  
  Future<Map<String, dynamic>> updateCartItem(int productId, int quantity) async {
    final data = {
      'product_id': productId,
      'quantity': quantity,
    };
    
    return await post(updateCartEndpoint, data: data);
  }
  
  Future<Map<String, dynamic>> removeFromCart(int productId) async {
    return await delete('$removeFromCartEndpoint$productId/');
  }
  
  Future<Map<String, dynamic>> clearCart() async {
    return await post(clearCartEndpoint);
  }
  
  // Order methods
  Future<List<dynamic>> getOrders() async {
    final response = await get(ordersEndpoint);
    
    if (response is Map && response.containsKey('results')) {
      return response['results'];
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    return await get('$ordersEndpoint$orderId/');
  }
  
  Future<Map<String, dynamic>> createOrder({
    required int shippingAddressId,
    required String shippingMethod,
    required String paymentMethod,
    String? notes,
  }) async {
    final data = {
      'shipping_address_id': shippingAddressId,
      'shipping_method': shippingMethod,
      'payment_method': paymentMethod,
      'notes': notes,
    };
    
    return await post(createOrderEndpoint, data: data);
  }
  
  Future<Map<String, dynamic>> processPayment(int orderId, String paymentMethod) async {
    final data = {
      'payment_method': paymentMethod,
    };
    
    return await post('$ordersEndpoint$orderId/payment/', data: data);
  }
  
  // Address methods
  Future<List<dynamic>> getAddresses() async {
    final response = await get(addressesEndpoint);
    
    if (response is Map && response.containsKey('results')) {
      return response['results'];
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> addAddress({
    required String name,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String phone,
    bool isDefault = false,
  }) async {
    final data = {
      'name': name,
      'address_line1': addressLine1,
      'address_line2': addressLine2 ?? '',
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'is_default': isDefault,
    };
    
    return await post(addressesEndpoint, data: data);
  }
  
  Future<Map<String, dynamic>> updateAddress({
    required int addressId,
    required String name,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String phone,
    bool isDefault = false,
  }) async {
    final data = {
      'name': name,
      'address_line1': addressLine1,
      'address_line2': addressLine2 ?? '',
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'is_default': isDefault,
    };
    
    return await put('$addressesEndpoint$addressId/', data: data);
  }
  
  Future<Map<String, dynamic>> deleteAddress(int addressId) async {
    return await delete('$addressesEndpoint$addressId/');
  }
  
  Future<Map<String, dynamic>> setDefaultAddress(int addressId) async {
    return await post('$setDefaultAddressEndpoint$addressId/');
  }
  
  // Waitlist methods
  Future<List<dynamic>> getWaitlistItems() async {
    final response = await get('$waitlistEndpoint');
    
    if (response is Map && response.containsKey('results')) {
      return response['results'];
    }
    
    return response;
  }
}