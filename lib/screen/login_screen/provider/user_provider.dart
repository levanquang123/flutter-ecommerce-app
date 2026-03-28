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

  Future<String?> login(LoginData data) async {
    try {
      final loginData = {
        'email': data.name.trim().toLowerCase(),
        'password': data.password,
      };

      final response =
          await service.addItem(endpointUrl: 'users/login', itemData: loginData);

      if (!response.isOk) {
        if (response.body is Map<String, dynamic>) {
          return response.body['message']?.toString() ?? 'Unknown error';
        }
        return response.statusText ?? 'Server Error';
      }

      final apiResponse = ApiResponse<User>.fromJson(
        response.body,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success) {
        return apiResponse.message;
      }

      await saveLoginInfo(apiResponse.data);
      await fetchCurrentUserProfile(showSnack: false);

      SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      return null;
    } catch (e) {
      return 'An error occurred: $e';
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
      );

      if (!response.isOk) {
        if (response.body is Map<String, dynamic>) {
          return response.body['message']?.toString() ?? 'Unknown error';
        }
        return response.statusText ?? 'Server Error';
      }

      final apiResponse = ApiResponse<User>.fromJson(
        response.body,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success) {
        SnackBarHelper.showSuccessSnackBar(apiResponse.message);
        return null;
      }
      return apiResponse.message;
    } catch (e) {
      log('Register Error: $e');
      return 'An error occurred: $e';
    }
  }

  Future<void> saveLoginInfo(User? loginUser) async {
    if (loginUser == null) return;

    if (loginUser.accessToken != null && loginUser.accessToken!.isNotEmpty) {
      await box.write(TOKEN, loginUser.accessToken);
    }
    await box.write(USER_INFO_BOX, loginUser.toJson());
  }

  Future<bool> fetchCurrentUserProfile({bool showSnack = false}) async {
    try {
      final response = await service.getItems(endpointUrl: 'users/me');
      if (!response.isOk || response.body == null) return false;

      final user = _extractUser(response.body);
      if (user == null) return false;

      _currentUser = user;
      _dataProvider.user = user;
      await box.write(USER_INFO_BOX, user.toJson());
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
    if (payload is Map<String, dynamic> && payload['user'] is Map<String, dynamic>) {
      payload = payload['user'];
    }

    if (payload is Map<String, dynamic>) {
      return User.fromJson(payload);
    }
    return null;
  }

  User? getLoginUsr() {
    if (_currentUser != null) return _currentUser;
    final userJson = box.read(USER_INFO_BOX);
    if (userJson is! Map<String, dynamic> || userJson.isEmpty) return null;
    _currentUser = User.fromJson(userJson);
    return _currentUser;
  }

  void logOutUser() {
    box.remove(USER_INFO_BOX);
    box.remove(TOKEN);
    box.remove(PHONE_KEY);
    box.remove(STREET_KEY);
    box.remove(CITY_KEY);
    box.remove(STATE_KEY);
    box.remove(POSTAL_CODE_KEY);
    box.remove(COUNTRY_KEY);

    _currentUser = null;
    _dataProvider.user = null;
    _dataProvider.favoriteProducts.clear();
    notifyListeners();
    Get.offAll(() => const LoginScreen());
  }
}
