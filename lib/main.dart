import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

import 'core/data/data_provider.dart';
import 'models/user.dart';
import 'services/http_services.dart';
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

  OneSignal.initialize(ONE_SIGNAL_APP_ID);
  OneSignal.Notifications.requestPermission(true);

  final bool isAuthenticated = await HttpService.bootstrapSession();

  final box = GetStorage();
  final dynamic userRaw = box.read(USER_INFO_BOX);
  User? loginUser;

  if (userRaw != null && userRaw is Map<String, dynamic>) {
    loginUser = User.fromJson(userRaw);
  }
  if (!isAuthenticated) {
    loginUser = null;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DataProvider()..user = loginUser,
        ),
        ChangeNotifierProxyProvider<DataProvider, UserProvider>(
          create: (context) => UserProvider(context.read<DataProvider>()),
          update: (_, data, prev) => prev ?? UserProvider(data),
        ),
        ChangeNotifierProxyProvider<UserProvider, ProfileProvider>(
          create: (context) => ProfileProvider(context.read<UserProvider>()),
          update: (_, userProvider, prev) => prev ?? ProfileProvider(userProvider),
        ),
        ChangeNotifierProxyProvider<DataProvider, ProductByCategoryProvider>(
          create: (context) => ProductByCategoryProvider(context.read<DataProvider>()),
          update: (_, data, prev) => prev ?? ProductByCategoryProvider(data),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductDetailProvider(),
        ),
        ChangeNotifierProxyProvider<UserProvider, CartProvider>(
          create: (context) => CartProvider(context.read<UserProvider>()),
          update: (_, userProvider, prev) => prev ?? CartProvider(userProvider),
        ),
        ChangeNotifierProxyProvider<DataProvider, FavoriteProvider>(
          create: (context) => FavoriteProvider(context.read<DataProvider>()),
          update: (_, data, prev) => prev ?? FavoriteProvider(data),
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
      final userProvider = context.read<UserProvider>();
      final cartProvider = context.read<CartProvider>();
      final profileProvider = context.read<ProfileProvider>();
      _loadInitialData(dataProvider, userProvider, cartProvider, profileProvider);
    });
  }

  void _loadInitialData(
    DataProvider provider,
    UserProvider userProvider,
    CartProvider cartProvider,
    ProfileProvider profileProvider,
  ) async {
    await provider.initializeData();

    if (widget.isAuthenticated) {
      await userProvider.fetchCurrentUserProfile();
      profileProvider.fillControllersFromCurrentUser();
      await cartProvider.loadCart();
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
