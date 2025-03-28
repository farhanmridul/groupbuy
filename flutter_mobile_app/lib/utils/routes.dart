import 'package:flutter/material.dart';

import '../models/order.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/category/category_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/order/order_confirmation_screen.dart';
import '../screens/order/order_detail_screen.dart';
import '../screens/order/order_list_screen.dart';
import '../screens/order/waitlist_items_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/product_list_screen.dart';
import '../screens/profile/address_form_screen.dart';
import '../screens/profile/addresses_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Main routes
  static const String home = '/home';
  static const String categories = '/categories';
  static const String productList = '/products';
  static const String productDetail = '/product-detail';
  
  // Cart routes
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  
  // Order routes
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String waitlist = '/waitlist';
  
  // Profile routes
  static const String profile = '/profile';
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String editAddress = '/edit-address';
  
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      
      home: (context) => const HomeScreen(),
      categories: (context) => const CategoryListScreen(),
      productList: (context) => const ProductListScreen(),
      productDetail: (context) => const ProductDetailScreen(),
      
      cart: (context) => const CartScreen(),
      checkout: (context) => const CheckoutScreen(),
      orderConfirmation: (context) {
        final order = ModalRoute.of(context)!.settings.arguments as Order;
        return OrderConfirmationScreen(order: order);
      },
      
      orders: (context) => const OrderListScreen(),
      orderDetail: (context) {
        final orderID = ModalRoute.of(context)!.settings.arguments as int;
        return OrderDetailScreen(orderId: orderID);
      },
      waitlist: (context) => const WaitlistItemsScreen(),
      
      profile: (context) => const ProfileScreen(),
      addresses: (context) => const AddressesScreen(),
      addAddress: (context) => const AddressFormScreen(),
      editAddress: (context) {
        final addressId = ModalRoute.of(context)!.settings.arguments as int;
        return AddressFormScreen(addressId: addressId);
      },
    };
  }
}