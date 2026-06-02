import '../../../models/api_response.dart';
import '../../../models/coupon.dart';
import '../../../services/http_services.dart';
import 'cart_repository.dart';

class CheckoutRepository {
  final HttpService _service;

  CheckoutRepository(this._service);

  Future<CouponCheckResult> checkCoupon(Map<String, dynamic> couponData) async {
    final response = await _service.addItem(
      endpointUrl: 'couponCodes/check-coupon',
      itemData: couponData,
    );
    if (!response.isOk) throw CartResponseException(response);
    final apiResponse = ApiResponse<Coupon>.fromJson(
      response.body,
      (json) => Coupon.fromJson(json as Map<String, dynamic>),
    );
    return CouponCheckResult(
      apiResponse: apiResponse,
      serverDiscount: _extractServerDiscount(response.body),
    );
  }

  Future<ApiResponse<dynamic>> createOrder(Map<String, dynamic> order) async {
    final response =
        await _service.addItem(endpointUrl: 'orders', itemData: order);
    if (!response.isOk) throw CartResponseException(response);
    return ApiResponse.fromJson(response.body, (json) => json);
  }

  Future<dynamic> initializeStripePayment(
      Map<String, dynamic> paymentData) async {
    final response = await _service.addItem(
      endpointUrl: 'payment/stripe',
      itemData: paymentData,
    );
    if (!response.isOk) throw CartResponseException(response);
    return response.body;
  }

  double? _extractServerDiscount(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;

    final orderTotal = data['orderTotal'];
    if (orderTotal is Map<String, dynamic> && orderTotal['discount'] is num) {
      return (orderTotal['discount'] as num).toDouble();
    }

    if (data['calculatedDiscount'] is num) {
      return (data['calculatedDiscount'] as num).toDouble();
    }

    return null;
  }
}

class CouponCheckResult {
  final ApiResponse<Coupon> apiResponse;
  final double? serverDiscount;

  const CouponCheckResult({
    required this.apiResponse,
    required this.serverDiscount,
  });
}
