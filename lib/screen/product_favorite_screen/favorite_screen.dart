import 'provider/favorite_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../widget/product_grid_view.dart';
import '../../utility/app_color.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Favorites",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColor.darkOrange),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Consumer<FavoriteProvider>(
          builder: (context, dataProvider, child) {
            final items = dataProvider.favoriteProducts;

            if (dataProvider.isLoading && items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (dataProvider.loadErrorMessage != null && items.isEmpty) {
              return _FavoriteLoadError(
                message: dataProvider.loadErrorMessage!,
                onRetry: dataProvider.loadFavorites,
              );
            }

            if (items.isEmpty) {
              return const Center(
                child: Text("No favorites yet"),
              );
            }

            return ProductGridView(
              items: items,
            );
          },
        ),
      ),
    );
  }
}

class _FavoriteLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FavoriteLoadError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColor.darkOrange),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
