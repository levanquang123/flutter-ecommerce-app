import '../../models/order.dart';
import '../../services/http_services.dart';
import 'catalog_repository.dart';
import '../../models/api_response.dart';

class OrderRepository {
  final HttpService _service;

  OrderRepository(this._service);

  Future<ApiResponse<List<Order>>> getOrdersByUser(String userId) async {
    final response =
        await _service.getItems(endpointUrl: 'orders/orderByUserId/$userId');
    if (!response.isOk) throw ResponseException(response);
    return ApiResponse<List<Order>>.fromJson(
      response.body,
      (json) => (json as List)
          .map((item) => Order.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
