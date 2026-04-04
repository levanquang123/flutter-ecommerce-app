import '../../../core/data/data_provider.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/product.dart';

class FavoriteProvider extends ChangeNotifier {
  final DataProvider _dataProvider;

  FavoriteProvider(this._dataProvider);

  List<Product> get favoriteProducts => _dataProvider.favoriteProducts;

  bool checkIsItemFavorite(String productId) {
    return _dataProvider.user?.favorites?.any((p) => p.sId == productId) ?? false;
  }

  Future<void> updateToFavoriteList(String productId) async {
    await _dataProvider.toggleFavoriteApi(productId);
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    await _dataProvider.getFavoriteProducts();
    notifyListeners();
  }

  void clearFavoriteList() {
    notifyListeners();
  }
}
