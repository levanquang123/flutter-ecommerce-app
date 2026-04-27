import '../../core/data/data_provider.dart';
import '../../screen/my_address_screen/my_address_screen.dart';
import '../../screen/my_order_screen/my_order_screen.dart';
import '../../utility/app_color.dart';
import '../../utility/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/custom_app_bar.dart';
import '../../../../widget/product_grid_view.dart';
import 'components/category_selector.dart';
import 'components/poster_section.dart';

class ProductListScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const ProductListScreen({
    super.key,
    this.onNavigateToTab,
  });

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openTab(BuildContext context, int index) {
    Navigator.of(context).pop();
    onNavigateToTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      drawer: _HomeDrawer(
        onOrdersTap: () => _openScreen(context, const MyOrderScreen()),
        onAddressesTap: () => _openScreen(context, const MyAddressPage()),
        onFavoriteTap: () => _openTab(context, 1),
        onCartTap: () => _openTab(context, 2),
        onProfileTap: () => _openTab(context, 3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello Sina",
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  "Lets gets somethings?",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const PosterSection(),
                Text(
                  "Top categories",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Consumer<DataProvider>(
                  builder: (context, dataProvider, child) {
                    return CategorySelector(
                      categories: dataProvider.categories,
                    );
                  },
                ),
                Consumer<DataProvider>(
                  builder: (context, dataProvider, child) {
                    return ProductGridView(
                      items: dataProvider.products,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final VoidCallback onOrdersTap;
  final VoidCallback onAddressesTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCartTap;
  final VoidCallback onProfileTap;

  const _HomeDrawer({
    required this.onOrdersTap,
    required this.onAddressesTap,
    required this.onFavoriteTap,
    required this.onCartTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.userProvider.getLoginUsr();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              color: AppColor.darkOrange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        AssetImage('assets/images/profile_pic.png'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.email ?? 'Guest',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'My account',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _DrawerItem(
                    icon: Icons.list,
                    title: 'My Orders',
                    onTap: onOrdersTap,
                  ),
                  _DrawerItem(
                    icon: Icons.location_on,
                    title: 'My Addresses',
                    onTap: onAddressesTap,
                  ),
                  const Divider(height: 18),
                  _DrawerItem(
                    icon: Icons.favorite,
                    title: 'Favorites',
                    onTap: onFavoriteTap,
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_cart,
                    title: 'Cart',
                    onTap: onCartTap,
                  ),
                  _DrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: onProfileTap,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                Navigator.of(context).pop();
                await context.userProvider.logOutUser();
              },
              isDestructive: true,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;

    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? Colors.redAccent : AppColor.darkOrange),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
