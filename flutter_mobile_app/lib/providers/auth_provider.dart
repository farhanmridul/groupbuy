import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> autoLogin() async {
    _setLoading(true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        _setLoading(false);
        return;
      }

      _token = token;
      
      // Fetch user profile
      final userData = await ApiService.getUserProfile();
      _user = userData;
      
      notifyListeners();
    } catch (error) {
      logout();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password, bool rememberMe) async {
    _setLoading(true);
    
    try {
      final response = await ApiService.login(email, password);
      
      _token = response['token'];
      
      // Save token if rememberMe is true
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
      }
      
      // Fetch user profile
      final userData = await ApiService.getUserProfile();
      _user = userData;
      
      notifyListeners();
    } catch (error) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    _setLoading(true);
    
    try {
      final response = await ApiService.register(
        email,
        password,
        firstName,
        lastName,
      );
      
      _token = response['token'];
      
      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
      // Fetch user profile
      final userData = await ApiService.getUserProfile();
      _user = userData;
      
      notifyListeners();
    } catch (error) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    
    try {
      if (_token != null) {
        await ApiService.logout();
      }
      
      _token = null;
      _user = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      notifyListeners();
    } catch (error) {
      // Even if the API call fails, we still want to clear local data
      _token = null;
      _user = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      notifyListeners();
      
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> userData) async {
    _setLoading(true);
    
    try {
      await ApiService.updateUserProfile(userData);
      
      // Update local user data
      final updatedUser = await ApiService.getUserProfile();
      _user = updatedUser;
      
      notifyListeners();
    } catch (error) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}