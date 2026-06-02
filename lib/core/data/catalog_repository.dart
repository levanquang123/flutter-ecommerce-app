import 'package:get/get.dart';

import '../../models/api_response.dart';
import '../../models/brand.dart';
import '../../models/category.dart';
import '../../models/poster.dart';
import '../../models/product.dart';
import '../../models/sub_category.dart';
import '../../services/http_services.dart';

class CatalogRepository {
  final HttpService _service;

  CatalogRepository(this._service);

  Future<ApiResponse<List<Category>>> getCategories() async {
    return _getList<Category>(
      endpointUrl: 'categories',
      fromJson: (json) => Category.fromJson(json),
    );
  }

  Future<ApiResponse<List<SubCategory>>> getSubCategories() async {
    return _getList<SubCategory>(
      endpointUrl: 'SubCategories',
      fromJson: (json) => SubCategory.fromJson(json),
    );
  }

  Future<ApiResponse<List<Brand>>> getBrands() async {
    return _getList<Brand>(
      endpointUrl: 'brands',
      fromJson: (json) => Brand.fromJson(json),
    );
  }

  Future<ApiResponse<List<Product>>> getProducts() async {
    return _getList<Product>(
      endpointUrl: 'products',
      fromJson: (json) => Product.fromJson(json),
    );
  }

  Future<ApiResponse<List<Poster>>> getPosters() async {
    return _getList<Poster>(
      endpointUrl: 'posters',
      fromJson: (json) => Poster.fromJson(json),
    );
  }

  Future<ApiResponse<List<T>>> _getList<T>({
    required String endpointUrl,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final response = await _service.getItems(endpointUrl: endpointUrl);
    if (!response.isOk) {
      throw ResponseException(response);
    }
    return ApiResponse<List<T>>.fromJson(
      response.body,
      (json) => (json as List)
          .map((item) => fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ResponseException implements Exception {
  final Response response;

  const ResponseException(this.response);
}
