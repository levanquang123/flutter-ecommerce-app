import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cart/cart.dart';

import 'core/data/data_provider.dart';
import 'models/user.dart';
import 'screen/home_screen.dart';
import 'screen/login_screen/login_screen.dart';
import 'screen/login_screen/provider/user_provider.dart';
import 'screen/product_by_category_screen/provider/product_by_category_provider.dart';
import 'screen/product_cart_screen/provider/cart_provider.dart';
import 'screen/product_details_screen/provider/product_detail_provider.dart';
import 'screen/product_favorite_screen/provider/favorite_provider.dart';
import 'screen/profile_screen/provider/profile_provider.dart';
import 'utility/app_theme.dart';
import 'utility/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    GetStorage.init(),
  ]);

  final cart = FlutterCart();
  await cart.initializeCart(isPersistenceSupportEnabled: true);

  OneSignal.initialize(ONE_SIGNAL_APP_ID);
  OneSignal.Notifications.requestPermission(true);

  final box = GetStorage();
  final dynamic userRaw = box.read(USER_INFO_BOX);
  User? loginUser;

  if (userRaw != null && userRaw is Map<String, dynamic>) {
    loginUser = User.fromJson(userRaw);
  }

  final bool isAuthenticated = loginUser?.sId != null && box.read(TOKEN) != null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DataProvider()..user = loginUser,
        ),
        ChangeNotifierProxyProvider<DataProvider, UserProvider>(
          create: (context) => UserProvider(context.read<DataProvider>()),
          update: (_, data, __) => UserProvider(data),
        ),
        ChangeNotifierProxyProvider<DataProvider, ProfileProvider>(
          create: (context) => ProfileProvider(context.read<DataProvider>()),
          update: (_, data, __) => ProfileProvider(data),
        ),
        ChangeNotifierProxyProvider<DataProvider, ProductByCategoryProvider>(
          create: (context) => ProductByCategoryProvider(context.read<DataProvider>()),
          update: (_, data, __) => ProductByCategoryProvider(data),
        ),
        ChangeNotifierProxyProvider<DataProvider, ProductDetailProvider>(
          create: (context) => ProductDetailProvider(context.read<DataProvider>()),
          update: (_, data, __) => ProductDetailProvider(data),
        ),
        ChangeNotifierProxyProvider<UserProvider, CartProvider>(
          create: (context) => CartProvider(context.read<UserProvider>()),
          update: (_, userProv, __) => CartProvider(userProv),
        ),
        ChangeNotifierProxyProvider<DataProvider, FavoriteProvider>(
          create: (context) => FavoriteProvider(context.read<DataProvider>()),
          update: (_, data, __) => FavoriteProvider(data),
        ),
      ],
      child: MyApp(isAuthenticated: isAuthenticated),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isAuthenticated;
  const MyApp({super.key, required this.isAuthenticated});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      _loadInitialData(dataProvider);
    });
  }

  void _loadInitialData(DataProvider provider) async {
    await provider.initializeData();

    if (widget.isAuthenticated) {
      await provider.getFavoriteProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
        },
      ),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightAppTheme,
      home: widget.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}