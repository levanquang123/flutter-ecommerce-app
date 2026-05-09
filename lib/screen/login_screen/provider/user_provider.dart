import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/data/data_provider.dart';
import '../../../models/api_response.dart';
import '../../../models/user.dart';
import '../../../services/http_services.dart';
import '../../../utility/constants.dart';
import '../../../utility/snack_bar_helper.dart';
import '../login_screen.dart';

class UserProvider extends ChangeNotifier {
  final HttpService service = HttpService();
  final DataProvider _dataProvider;
  final GetStorage box = GetStorage();
  User? _currentUser;

  UserProvider(this._dataProvider) {
    _currentUser = _dataProvider.user;
  }

  User? get currentUser => _currentUser;

  String? _readToken(String key) {
    return HttpService.readStoredToken(key);
  }

  Future<String?> login(LoginData data) async {
    try {
      final loginData = {
        'email': data.name.trim().toLowerCase(),
        'password': data.password,
      };

      final response = await service.addItem(
        endpointUrl: 'users/login',
        itemData: loginData,
        includeAuth: false,
        allowRefreshOn401: false,
      );

      if (!response.isOk) {
        return HttpService.parseResponseMessage(
          response,
          fallback: 'Unable to sign in. Please try again.',
        );
      }

      final apiResponse = ApiResponse<User>.fromJson(
        response.body,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success) {
        return HttpService.parseApiMessage(
          response.body,
          fallback: apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Unable to sign in. Please try again.',
        );
      }

      await saveLoginInfo(apiResponse.data);
      await fetchCurrentUserProfile(showSnack: false);

      SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      return null;
    } catch (e) {
      return HttpService.humanizeError(
        e,
        fallback: 'Unable to sign in right now. Please try again.',
      );
    }
  }

  Future<String?> register(SignupData data) async {
    try {
      final signupData = {
        'email': (data.name ?? '').trim().toLowerCase(),
        'password': data.password,
      };

      final response = await service.addItem(
        endpointUrl: 'users/register',
        itemData: signupData,
        includeAuth: false,
        allowRefreshOn401: false,
      );

      if (!response.isOk) {
        return HttpService.parseResponseMessage(
          response,
          fallback: 'Unable to create your account. Please try again.',
        );
      }

      final apiResponse = ApiResponse<User>.fromJson(
        response.body,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success) {
        SnackBarHelper.showSuccessSnackBar(apiResponse.message);
        return null;
      }
      return HttpService.parseApiMessage(
        response.body,
        fallback: apiResponse.message.isNotEmpty
            ? apiResponse.message
            : 'Unable to create your account. Please try again.',
      );
    } catch (e) {
      log('Register Error: $e');
      return HttpService.humanizeError(
        e,
        fallback: 'Unable to create your account right now. Please try again.',
      );
    }
  }

  Future<void> saveLoginInfo(User? loginUser) async {
    if (loginUser == null) return;
    await HttpService.persistAuthSession(loginUser);
    _currentUser = loginUser;
    _dataProvider.user = loginUser;
    notifyListeners();
  }

  Future<bool> fetchCurrentUserProfile({bool showSnack = false}) async {
    try {
      final response = await service.getItems(endpointUrl: 'users/me');
      if (!response.isOk || response.body == null) return false;

      final user = _extractUser(response.body);
      if (user == null) return false;

      _currentUser = user;
      _dataProvider.user = user;
      await HttpService.persistAuthSession(user);
      _dataProvider.notifyListeners();
      notifyListeners();

      if (showSnack) {
        SnackBarHelper.showSuccessSnackBar('Profile loaded');
      }
      return true;
    } catch (e) {
      log('Fetch profile error: $e');
      return false;
    }
  }

  User? _extractUser(dynamic body) {
    if (body is! Map<String, dynamic>) return null;

    dynamic payload = body;
    if (payload['data'] is Map<String, dynamic>) {
      payload = payload['data'];
    }
    if (payload is Map<String, dynamic> &&
        payload['user'] is Map<String, dynamic>) {
      payload = payload['user'];
    }

    if (payload is Map<String, dynamic>) {
      return User.fromJson(payload);
    }
    return null;
  }

  User? getLoginUsr() {
    final token = _readToken(TOKEN);
    if ((token ?? '').isEmpty) {
      _currentUser = null;
      _dataProvider.user = null;
      return null;
    }

    if (_currentUser != null) return _currentUser;
    final userJson = box.read(USER_INFO_BOX);
    if (userJson is! Map<String, dynamic> || userJson.isEmpty) return null;
    _currentUser = User.fromJson(userJson);
    return _currentUser;
  }

  Future<void> logOutUser() async {
    final accessToken = _readToken(TOKEN);
    if ((accessToken ?? '').isNotEmpty) {
      try {
        await service.addItem(
          endpointUrl: 'users/logout',
          itemData: const <String, dynamic>{},
          includeAuth: true,
          allowRefreshOn401: false,
        );
      } catch (_) {}
    }

    await HttpService.clearAuthSession();

    _currentUser = null;
    _dataProvider.user = null;
    notifyListeners();
    Get.offAll(() => const LoginScreen());
  }
}
