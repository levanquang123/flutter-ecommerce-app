import 'dart:async';

import 'product_cart_screen/cart_screen.dart';
import 'product_favorite_screen/favorite_screen.dart';
import 'product_list_screen/product_list_screen.dart';
import 'profile_screen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import '../../../utility/app_data.dart';
import '../../../widget/page_wrapper.dart';
import '../core/data/data_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int newIndex = 0;
  bool _isRefreshingHomeCatalog = false;
  Timer? _homeCatalogRefreshTimer;
  DateTime? _lastPausedAt;

  static const Duration _resumeRefreshDelay = Duration(milliseconds: 700);
  static const Duration _minimumBackgroundRefreshAge = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHomeCatalog(force: true);
    });
    _homeCatalogRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        if (newIndex == 0) {
          _refreshHomeCatalog();
        }
      },
    );
  }

  @override
  void dispose() {
    _homeCatalogRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed && newIndex == 0) {
      final pausedAt = _lastPausedAt;
      if (pausedAt != null &&
          DateTime.now().difference(pausedAt) < _minimumBackgroundRefreshAge) {
        return;
      }

      Future<void>.delayed(_resumeRefreshDelay, () {
        if (mounted && newIndex == 0) {
          _refreshHomeCatalog(force: true);
        }
      });
    }
  }

  Future<void> _refreshHomeCatalog({bool force = false}) async {
    if (_isRefreshingHomeCatalog || !mounted) return;
    _isRefreshingHomeCatalog = true;
    try {
      await context.read<DataProvider>().refreshHomeCatalog(force: force);
    } finally {
      _isRefreshingHomeCatalog = false;
    }
  }

  void _changeTab(int index) {
    setState(() => newIndex = index);
    if (index == 0) {
      _refreshHomeCatalog(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProductListScreen(onNavigateToTab: _changeTab),
      const FavoriteScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return PageWrapper(
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                ),
              ],
            ),
            child: GNav(
              gap: 8,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              selectedIndex: newIndex,
              onTabChange: (currentIndex) {
                _changeTab(currentIndex);
              },
              tabs: AppData.bottomNavyBarItems.map((item) {
                return GButton(
                  icon: (item.icon).icon!,
                  text: item.title,
                );
              }).toList(),
            ),
          ),
        ),
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (
            Widget child,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: screens[newIndex],
        ),
      ),
    );
  }
}
