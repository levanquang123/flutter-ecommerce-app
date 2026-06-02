import '../../models/product.dart';
import '../../services/http_services.dart';
import 'catalog_repository.dart';

class FavoriteRepository {
  final HttpService _service;

  FavoriteRepository(this._service);

  Future<List<Product>> getFavoriteProducts() async {
    final response = await _service.getItems(endpointUrl: 'users/favorites');
    if (!response.isOk) throw ResponseException(response);
    final body = response.body;
    final List<dynamic> favList = body is Map<String, dynamic>
        ? body['data'] ?? const <dynamic>[]
        : const <dynamic>[];
    return favList
        .map((item) => Product.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> toggleFavorite(String productId) async {
    final response = await _service.addItem(
      endpointUrl: 'users/favorite',
      itemData: {'productId': productId},
    );
    if (!response.isOk) throw ResponseException(response);
  }
}
