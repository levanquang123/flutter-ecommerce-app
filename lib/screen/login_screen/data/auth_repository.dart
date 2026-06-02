import '../../../models/api_response.dart';
import '../../../models/user.dart';
import '../../../services/http_services.dart';

class AuthRepository {
  final HttpService _service;

  AuthRepository(this._service);

  Future<ApiResponse<User>> login(Map<String, dynamic> loginData) async {
    final response = await _service.addItem(
      endpointUrl: 'users/login',
      itemData: loginData,
      includeAuth: false,
      allowRefreshOn401: false,
    );
    if (!response.isOk) {
      throw AuthResponseException(response);
    }
    return ApiResponse<User>.fromJson(
      response.body,
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<dynamic> register(Map<String, dynamic> signupData) async {
    final response = await _service.addItem(
      endpointUrl: 'users/register',
      itemData: signupData,
      includeAuth: false,
      allowRefreshOn401: false,
    );
    if (!response.isOk) {
      throw AuthResponseException(response);
    }
    return response.body;
  }

  Future<ApiResponse<User>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _service.addItem(
      endpointUrl: 'users/verify-email',
      itemData: {'email': email, 'code': code},
      includeAuth: false,
      allowRefreshOn401: false,
    );
    if (!response.isOk) {
      throw AuthResponseException(response);
    }
    return ApiResponse<User>.fromJson(
      response.body,
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<dynamic> resendVerificationCode(String email) async {
    final response = await _service.addItem(
      endpointUrl: 'users/resend-verification-code',
      itemData: {'email': email},
      includeAuth: false,
      allowRefreshOn401: false,
    );
    if (!response.isOk) {
      throw AuthResponseException(response);
    }
    return response.body;
  }

  Future<dynamic> fetchCurrentUserProfile() async {
    final response = await _service.getItems(endpointUrl: 'users/me');
    if (!response.isOk || response.body == null) {
      throw AuthResponseException(response);
    }
    return response.body;
  }

  Future<void> logout() async {
    await _service.addItem(
      endpointUrl: 'users/logout',
      itemData: const <String, dynamic>{},
      includeAuth: true,
      allowRefreshOn401: false,
    );
  }
}

class AuthResponseException implements Exception {
  final dynamic response;

  const AuthResponseException(this.response);
}
