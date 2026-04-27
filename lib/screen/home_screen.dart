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

  static const List<Widget> screens = [
    ProductListScreen(),
    FavoriteScreen(),
    CartScreen(),
    ProfileScreen()
  ];

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int newIndex = 0;
  bool _isRefreshingHomeProducts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && newIndex == 0) {
      _refreshHomeProducts();
    }
  }

  Future<void> _refreshHomeProducts() async {
    if (_isRefreshingHomeProducts) return;
    _isRefreshingHomeProducts = true;
    try {
      await context.read<DataProvider>().getAllProducts();
    } finally {
      _isRefreshingHomeProducts = false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                setState(() => newIndex = currentIndex);
                if (currentIndex == 0) {
                  _refreshHomeProducts();
                }
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
          duration: const Duration(seconds: 1),
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
          child: HomeScreen.screens[newIndex],
        ),
      ),
    );
  }
}
