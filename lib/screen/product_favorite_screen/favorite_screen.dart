import 'package:e_commerce_flutter/core/data/data_provider.dart';

import '../../utility/extensions.dart';
import 'provider/favorite_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../widget/product_grid_view.dart';
import '../../utility/app_color.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => context.read<DataProvider>().getFavoriteProducts());

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
