import '../../../models/cart.dart';
import '../../../models/product.dart';
import '../../../services/http_services.dart';

class CartRepository {
  final HttpService _service;

  CartRepository(this._service);

  Future<Cart> loadCart() async {
    final response = await _service.getItems(endpointUrl: 'cart');
    if (!response.isOk || response.body == null) {
      throw CartResponseException(response);
    }
    return extractCartFromResponse(response.body);
  }

  Future<Cart> addItem({
    required Product product,
    required String variantId,
    required int quantity,
  }) async {
    final response = await _service.addItem(
      endpointUrl: 'cart/items',
      itemData: {
        'productId': product.sId,
        'quantity': quantity,
        if (_isValidObjectId(variantId)) 'variantId': variantId,
      },
    );
    if (!response.isOk) throw CartResponseException(response);
    return extractCartFromResponse(response.body);
  }

  Future<Cart> updateItem({
    required String productId,
    required String variantId,
    required int quantity,
  }) async {
    final response = await _service.putItem(
      endpointUrl: 'cart/items',
      itemData: {
        'productId': productId,
        if (_isValidObjectId(variantId)) 'variantId': variantId,
        'quantity': quantity,
      },
    );
    if (!response.isOk) throw CartResponseException(response);
    return extractCartFromResponse(response.body);
  }

  Future<Cart> removeItem({
    required String productId,
    required String variantId,
  }) async {
    final response = await _service.deleteWithBody(
      endpointUrl: 'cart/items',
      body: {
        'productId': productId,
        if (_isValidObjectId(variantId)) 'variantId': variantId,
      },
    );
    if (!response.isOk) throw CartResponseException(response);
    return extractCartFromResponse(response.body);
  }

  Future<void> clearCart() async {
    final response = await _service.deleteItem(
      endpointUrl: 'cart',
      itemId: 'clear',
    );
    if (!response.isOk) throw CartResponseException(response);
  }

  static Cart extractCartFromResponse(dynamic body) {
    if (body is! Map<String, dynamic>) return const Cart(items: []);
    dynamic payload = body;
    if (payload['data'] is Map<String, dynamic>) payload = payload['data'];
    if (payload is Map<String, dynamic> &&
        payload['cart'] is Map<String, dynamic>) {
      payload = payload['cart'];
    }
    if (payload is Map<String, dynamic>) return Cart.fromJson(payload);
    return const Cart(items: []);
  }

  static bool _isValidObjectId(String? value) {
    if (value == null) return false;
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);
  }
}

class CartResponseException implements Exception {
  final dynamic response;

  const CartResponseException(this.response);
}
