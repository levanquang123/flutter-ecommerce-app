import 'dart:async';
import 'dart:ui' show PlatformDispatcher, PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
  final packageInfo = await PackageInfo.fromPlatform();
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  const sentryEnvRaw = String.fromEnvironment('SENTRY_ENV');
  final sentryEnvironment =
      sentryEnvRaw.trim().isEmpty ? 'development' : sentryEnvRaw.trim();
  final isProduction = sentryEnvironment.toLowerCase() == 'production';
  final release =
      'mobile-client@${packageInfo.version}+${packageInfo.buildNumber}';

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.environment = sentryEnvironment;
      options.release = release;
      options.sendDefaultPii = false;
      options.tracesSampleRate = isProduction ? 0.1 : 1.0;
      options.profilesSampleRate = isProduction ? 0.0 : 1.0;
    },
    appRunner: () {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        Sentry.captureException(
          details.exception,
          stackTrace: details.stack,
          withScope: (scope) {
            scope.level = SentryLevel.error;
            scope.setTag('service', 'mobile-client');
            scope.setContexts('flutter_error', {
              'library': details.library ?? 'unknown',
              'context': details.context?.toDescription() ?? 'unknown',
            });
          },
        );
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        Sentry.captureException(
          error,
          stackTrace: stack,
          withScope: (scope) {
            scope.level = SentryLevel.fatal;
            scope.setTag('service', 'mobile-client');
            scope.setTag('error_source', 'platform_dispatcher');
          },
        );
        return true;
      };

      runZonedGuarded(
        () async {
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
          await HttpService.setSentryUser(loginUser);

          runApp(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => DataProvider()..user = loginUser,
                ),
                ChangeNotifierProxyProvider<DataProvider, UserProvider>(
                  create: (context) =>
                      UserProvider(context.read<DataProvider>()),
                  update: (_, data, prev) => prev ?? UserProvider(data),
                ),
                ChangeNotifierProxyProvider<UserProvider, ProfileProvider>(
                  create: (context) =>
                      ProfileProvider(context.read<UserProvider>()),
                  update: (_, userProvider, prev) =>
                      prev ?? ProfileProvider(userProvider),
                ),
                ChangeNotifierProxyProvider<DataProvider,
                    ProductByCategoryProvider>(
                  create: (context) =>
                      ProductByCategoryProvider(context.read<DataProvider>()),
                  update: (_, data, prev) =>
                      prev ?? ProductByCategoryProvider(data),
                ),
                ChangeNotifierProvider(
                  create: (context) => ProductDetailProvider(),
                ),
                ChangeNotifierProxyProvider<UserProvider, CartProvider>(
                  create: (context) =>
                      CartProvider(context.read<UserProvider>()),
                  update: (_, userProvider, prev) =>
                      prev ?? CartProvider(userProvider),
                ),
                ChangeNotifierProxyProvider<DataProvider, FavoriteProvider>(
                  create: (context) =>
                      FavoriteProvider(context.read<DataProvider>()),
                  update: (_, data, prev) => prev ?? FavoriteProvider(data),
                ),
              ],
              child: MyApp(isAuthenticated: isAuthenticated),
            ),
          );
        },
        (Object error, StackTrace stack) {
          Sentry.captureException(
            error,
            stackTrace: stack,
            withScope: (scope) {
              scope.level = SentryLevel.fatal;
              scope.setTag('service', 'mobile-client');
              scope.setTag('error_source', 'run_zoned_guarded');
            },
          );
        },
      );
    },
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
      _loadInitialData(
          dataProvider, userProvider, cartProvider, profileProvider);
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
    HttpService.setCurrentRouteName(
      widget.isAuthenticated ? 'HomeScreen' : 'LoginScreen',
    );

    return GetMaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
        },
      ),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        SentryNavigatorObserver(),
        AppRouteObserver(),
      ],
      theme: AppTheme.lightAppTheme,
      home: widget.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}

class AppRouteObserver extends NavigatorObserver {
  void _track(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name?.trim();
    if (name != null && name.isNotEmpty) {
      HttpService.setCurrentRouteName(name);
      return;
    }
    HttpService.setCurrentRouteName(route.runtimeType.toString());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _track(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
