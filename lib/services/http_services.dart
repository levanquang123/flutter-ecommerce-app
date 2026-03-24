import 'dart:developer';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../utility/constants.dart';

class HttpService extends GetConnect {
  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    baseUrl = MAIN_URL;
    httpClient.baseUrl = MAIN_URL;
    timeout = const Duration(seconds: 30);
    super.onInit();
  }

  Map<String, String> _getHeaders() {
    final token = _box.read(TOKEN);
    if (token != null && token.toString().isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  String _buildUrl(String endpoint) {
    if (endpoint.startsWith('http')) return endpoint;
    String base = MAIN_URL.endsWith('/') ? MAIN_URL : '$MAIN_URL/';
    String path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$base$path';
  }

  Future<Response> getItems({required String endpointUrl}) async {
    try {
      final response = await get(_buildUrl(endpointUrl), headers: _getHeaders());
      log('🌐 [GET] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
    }
  }

  Future<Response> addItem({required String endpointUrl, required dynamic itemData}) async {
    try {
      final response = await post(_buildUrl(endpointUrl), itemData, headers: _getHeaders());
      log('🌐 [POST] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
    }
  }

  Future<Response> updateItem({required String endpointUrl, required String itemId, required dynamic itemData}) async {
    try {
      final response = await put(_buildUrl('$endpointUrl/$itemId'), itemData);
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
    }
  }

  Future<Response> deleteItem({required String endpointUrl, required String itemId}) async {
    try {
      final response = await delete(_buildUrl('$endpointUrl/$itemId'));
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
    }
  }
}
