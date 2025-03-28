import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groupbuy_app/utils/theme.dart';
import 'package:groupbuy_app/utils/routes.dart';
import 'package:groupbuy_app/services/api_service.dart';
import 'package:groupbuy_app/screens/splash_screen.dart';
import 'package:groupbuy_app/providers/auth_provider.dart';
import 'package:groupbuy_app/providers/cart_provider.dart';
import 'package:groupbuy_app/providers/product_provider.dart';
import 'package:groupbuy_app/providers/category_provider.dart';
import 'package:groupbuy_app/providers/order_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load initial preferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? false;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }
  
  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => ProductProvider()),
        ChangeNotifierProvider(create: (ctx) => CategoryProvider()),
        ChangeNotifierProvider(create: (ctx) => OrderProvider()),
        Provider<void Function()>.value(value: _toggleTheme),
      ],
      child: MaterialApp(
        title: 'GroupBuy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
        routes: AppRoutes.routes,
      ),
    );
  }
}