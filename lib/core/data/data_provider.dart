import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:get/get.dart';
import '../../../models/category.dart';
import '../../models/api_response.dart';
import '../../models/brand.dart';
import '../../models/order.dart';
import '../../models/poster.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../models/sub_category.dart';
import '../../models/user.dart';
import '../../services/http_services.dart';
import '../../utility/snack_bar_helper.dart';

class DataProvider extends ChangeNotifier {
  final HttpService service = HttpService();

  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  List<Category> get categories => _filteredCategories;

  List<SubCategory> _allSubCategories = [];
  List<SubCategory> _filteredSubCategories = [];
  List<SubCategory> get subCategories => _filteredSubCategories;

  List<Brand> _allBrands = [];
  List<Brand> _filteredBrands = [];
  List<Brand> get brands => _filteredBrands;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _allProducts;

  List<Poster> _allPosters = [];
  List<Poster> _filteredPosters = [];
  List<Poster> get posters => _filteredPosters;

  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  List<Order> get orders => _filteredOrders;

  List<Product> _favoriteProducts = [];
  List<Product> get favoriteProducts => _favoriteProducts;

  User? user;

  DataProvider();

  Future<void> initializeData() async {
    await Future.wait([
      getAllCategory(),
      getAllBrands(),
      getAllProducts(),
      getAllSubCategory(),
      getAllPosters(),
    ]);
  }

  Future<List<Category>> getAllCategory({bool showSnack = false}) async {
    try {
      Response response = await service.getItems(endpointUrl: "categories");
      if (response.isOk) {
        ApiResponse<List<Category>> apiResponse =
            ApiResponse<List<Category>>.fromJson(
          response.body,
          (json) =>
              (json as List).map((item) => Category.fromJson(item)).toList(),
        );
        _allCategories = apiResponse.data ?? [];
        _filteredCategories = List.from(_allCategories);
        notifyListeners();
        if (showSnack) SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      }
    } catch (e) {
      if (showSnack) SnackBarHelper.showErrorSnackBar(e.toString());
    }
    return _filteredCategories;
  }

  void filterCategories(String keyWord) {
    if (keyWord.isEmpty) {
      _filteredCategories = List.from(_allCategories);
    } else {
      final lowerKeyWord = keyWord.toLowerCase();
      _filteredCategories = _allCategories
          .where((category) =>
              (category.name ?? "").toLowerCase().contains(lowerKeyWord))
          .toList();
    }
    notifyListeners();
  }

  Future<List<SubCategory>> getAllSubCategory({bool showSnack = false}) async {
    try {
      Response response = await service.getItems(endpointUrl: "SubCategories");
      if (response.isOk) {
        ApiResponse<List<SubCategory>> apiResponse =
            ApiResponse<List<SubCategory>>.fromJson(
          response.body,
          (json) =>
              (json as List).map((item) => SubCategory.fromJson(item)).toList(),
        );
        _allSubCategories = apiResponse.data ?? [];
        _filteredSubCategories = List.from(_allSubCategories);
        notifyListeners();
        if (showSnack) SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      }
    } catch (e) {
      if (showSnack) SnackBarHelper.showErrorSnackBar(e.toString());
    }
    return _filteredSubCategories;
  }

  void filterSubCategories(String keyWord) {
    if (keyWord.isEmpty) {
      _filteredSubCategories = List.from(_allSubCategories);
    } else {
      final lowerKeyWord = keyWord.toLowerCase();
      _filteredSubCategories = _allSubCategories
          .where((subCategory) =>
              (subCategory.name ?? "").toLowerCase().contains(lowerKeyWord))
          .toList();
    }
    notifyListeners();
  }

  Future<List<Brand>> getAllBrands({bool showSnack = false}) async {
    try {
      Response response = await service.getItems(endpointUrl: "brands");
      if (response.isOk) {
        ApiResponse<List<Brand>> apiResponse =
            ApiResponse<List<Brand>>.fromJson(
          response.body,
          (json) => (json as List).map((item) => Brand.fromJson(item)).toList(),
        );
        _allBrands = apiResponse.data ?? [];
        _filteredBrands = List.from(_allBrands);
        notifyListeners();
        if (showSnack) SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      }
    } catch (e) {
      if (showSnack) SnackBarHelper.showErrorSnackBar(e.toString());
    }
    return _filteredBrands;
  }

  void filterBrands(String keyWord) {
    if (keyWord.isEmpty) {
      _filteredBrands = List.from(_allBrands);
    } else {
      final lowerKeyWord = keyWord.toLowerCase();
      _filteredBrands = _allBrands
          .where((brand) =>
              (brand.name ?? "").toLowerCase().contains(lowerKeyWord))
          .toList();
    }
    notifyListeners();
  }

  Future<List<Product>> getAllProducts({bool showSnack = false}) async {
    try {
      Response response = await service.getItems(endpointUrl: 'products');
      if (response.isOk) {
        ApiResponse<List<Product>> apiResponse =
            ApiResponse<List<Product>>.fromJson(
          response.body,
          (json) => (json as List).map((e) => Product.fromJson(e)).toList(),
        );
        _allProducts = apiResponse.data ?? [];
        _filteredProducts = List.from(_allProducts);
        notifyListeners();
        if (showSnack) SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      }
    } catch (e) {
      if (showSnack) SnackBarHelper.showErrorSnackBar(e.toString());
    }
    return _filteredProducts;
  }

  void filterProducts(String keyword) {
    if (keyword.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      final lowerKeyword = keyword.toLowerCase();
      _filteredProducts = _allProducts.where((product) {
        final name = (product.name ?? '').toLowerCase();
        final category = (product.proCategoryId?.name ?? '').toLowerCase();
        final brand = (product.proBrandId?.name ?? '').toLowerCase();
        return name.contains(lowerKeyword) ||
            category.contains(lowerKeyword) ||
            brand.contains(lowerKeyword);
      }).toList();
    }
    notifyListeners();
  }

  Future<List<Poster>> getAllPosters({bool showSnack = false}) async {
    try {
      Response response = await service.getItems(endpointUrl: "posters");
      if (response.isOk) {
        ApiResponse<List<Poster>> apiResponse =
            ApiResponse<List<Poster>>.fromJson(
          response.body,
          (json) =>
              (json as List).map((item) => Poster.fromJson(item)).toList(),
        );
        _allPosters = apiResponse.data ?? [];
        _filteredPosters = List.from(_allPosters);
        notifyListeners();
        if (showSnack) SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      }
    } catch (e) {
      if (showSnack) SnackBarHelper.showErrorSnackBar(e.toString());
    }
    return _filteredPosters;
  }

  Future<bool> getAllOrderByUser(User? user, {bool showSnack = false}) async {
    try {
      final userId = user?.sId;
      if ((userId ?? '').isEmpty) {
        _allOrders = [];
        _filteredOrders = [];
        notifyListeners();
        return false;
      }
      Response response =
          await service.getItems(endpointUrl: 'orders/orderByUserId/$userId');
      if (response.isOk) {
        ApiResponse<List<Order>> apiResponse =
            ApiResponse<List<Order>>.fromJson(
          response.body,
          (json) => (json as List).map((item) => Order.fromJson(item)).toList(),
        );
        _allOrders = apiResponse.data ?? [];
        _filteredOrders = List.from(_allOrders);
        notifyListeners();
        if (showSnack) SnackBarHelper.showSuccessSnackBar(apiResponse.message);
        return true;
      }
      if (showSnack) {
        SnackBarHelper.showErrorSnackBar(
          HttpService.parseResponseMessage(
            response,
            fallback: 'Unable to load your orders.',
          ),
        );
      }
      return false;
    } catch (e) {
      if (showSnack) {
        SnackBarHelper.showErrorSnackBar(
          HttpService.humanizeError(
            e,
            fallback: 'Unable to load your orders right now.',
          ),
        );
      }
      return false;
    }
  }

  double calculateDiscountPercentage(num originalPrice, num? discountedPrice) {
    if (originalPrice <= 0) return 0;
    num finalDiscountedPrice = discountedPrice ?? originalPrice;
    if (finalDiscountedPrice >= originalPrice) return 0;
    return ((originalPrice - finalDiscountedPrice) / originalPrice) * 100;
  }

  Future<List<Product>> getFavoriteProducts({bool showSnack = false}) async {
    try {
      Response response =
          await service.getItems(endpointUrl: "users/favorites");
      if (response.isOk && response.body != null) {
        final List<dynamic> favList = response.body['data'] ?? [];
        _favoriteProducts =
            favList.map((item) => Product.fromJson(item)).toList();
        if (user != null) {
          user!.favorites = List.from(_favoriteProducts);
        }
        notifyListeners();
      }
    } catch (e) {
      log("Favorite Parsing Error: $e");
    }
    return _favoriteProducts;
  }

  Future<ReviewQueryResult> getProductReviews(
    String productId, {
    int? rating,
    String sort = 'newest',
  }) async {
    final query = <String>[];
    if (rating != null && rating >= 1 && rating <= 5) {
      query.add('rating=$rating');
    }
    final normalizedSort = sort.toLowerCase() == 'oldest' ? 'oldest' : 'newest';
    query.add('sort=$normalizedSort');
    final endpoint = query.isEmpty
        ? 'reviews/product/$productId'
        : 'reviews/product/$productId?${query.join('&')}';

    Response response = await service.getItems(endpointUrl: endpoint);
    if (!response.isOk) {
      throw Exception(
          _extractMessage(response.body, fallback: 'Cannot load reviews'));
    }

    if (response.body is Map<String, dynamic>) {
      return ReviewQueryResult.fromJson(response.body as Map<String, dynamic>);
    }

    final List<dynamic> list = _extractList(response.body);
    final reviews =
        list.whereType<Map<String, dynamic>>().map(Review.fromJson).toList();
    return ReviewQueryResult(reviews: reviews);
  }

  Future<Review> createProductReview({
    required String productId,
    required String orderID,
    required String orderItemID,
    required int rating,
    required String comment,
  }) async {
    Response response = await service.addItem(
      endpointUrl: 'reviews/product/$productId',
      itemData: {
        'orderID': orderID,
        'orderItemID': orderItemID,
        'rating': rating,
        'comment': comment,
      },
    );
    if (!response.isOk) {
      throw Exception(
          _extractMessage(response.body, fallback: 'Cannot create review'));
    }

    final raw = _extractDataObject(response.body);
    if (raw == null) {
      throw Exception('Review payload is invalid');
    }
    return Review.fromJson(raw);
  }

  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    Response response = await service.putItem(
      endpointUrl: 'reviews/$reviewId',
      itemData: {
        'rating': rating,
        'comment': comment,
      },
    );
    if (!response.isOk) {
      throw Exception(
          _extractMessage(response.body, fallback: 'Cannot update review'));
    }

    final raw = _extractDataObject(response.body);
    if (raw == null) {
      throw Exception('Review payload is invalid');
    }
    return Review.fromJson(raw);
  }

  Future<void> deleteReview(String reviewId) async {
    Response response =
        await service.deleteItem(endpointUrl: 'reviews', itemId: reviewId);
    if (!response.isOk) {
      throw Exception(
          _extractMessage(response.body, fallback: 'Cannot delete review'));
    }
  }

  Future<void> toggleFavoriteApi(String productId) async {
    try {
      bool isCurrentlyFavorite =
          _favoriteProducts.any((p) => p.sId == productId);
      Response response = await service.addItem(
        endpointUrl: 'users/favorite',
        itemData: {'productId': productId},
      );

      if (response.isOk) {
        await getFavoriteProducts();
        SnackBarHelper.showSuccessSnackBar(
          isCurrentlyFavorite ? "Removed from favorites" : "Added to favorites",
        );
        notifyListeners();
      } else {
        SnackBarHelper.showErrorSnackBar(
          HttpService.parseResponseMessage(
            response,
            fallback: 'Unable to update your favorite list.',
          ),
        );
      }
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to update your favorite list right now.',
        ),
      );
    }
  }

  static List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data['reviews'] is List) {
        return data['reviews'] as List;
      }
      if (body['reviews'] is List) return body['reviews'] as List;
    }
    return const <dynamic>[];
  }

  static Map<String, dynamic>? _extractDataObject(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>;
      }
      if (body['review'] is Map<String, dynamic>) {
        return body['review'] as Map<String, dynamic>;
      }
    }
    return body is Map<String, dynamic> ? body : null;
  }

  static String _extractMessage(dynamic body, {required String fallback}) {
    return HttpService.parseApiMessage(body, fallback: fallback);
  }
}
