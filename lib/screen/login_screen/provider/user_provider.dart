import 'dart:developer';
import 'package:flutter_login/flutter_login.dart';
import '../../../core/data/data_provider.dart';
import '../../../models/api_response.dart';
import '../../../models/user.dart';
import '../../../utility/snack_bar_helper.dart';
import '../login_screen.dart';
import '../../../services/http_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../utility/constants.dart';

class UserProvider extends ChangeNotifier {
  HttpService service = HttpService();
  final DataProvider _dataProvider;
  final box = GetStorage();

  UserProvider(this._dataProvider);

  Future<String?> login(LoginData data) async {
    try {
      Map<String, dynamic> loginData = {
        "email": data.name.trim().toLowerCase(),
        "password": data.password
      };

      final response = await service.addItem(
          endpointUrl: 'users/login', itemData: loginData);

      if (response.isOk) {
        log('Dữ liệu API trả về: ${response.body}');
        final ApiResponse<User> apiResponse = ApiResponse<User>.fromJson(
            response.body,
                (json) => User.fromJson(json as Map<String, dynamic>));

        if (apiResponse.success == true) {
          User? user = apiResponse.data;

          await saveLoginInfo(user);
          _dataProvider.user = user;
          _dataProvider.notifyListeners();

          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          return null;
        } else {
          return apiResponse.message ?? 'Failed to Login';
        }
        // Trong UserProvider
      } else {
        // Kiểm tra nếu body là Map thì lấy 'message', nếu không lấy statusText
        String errorMsg = 'Unknown error';
        if (response.body is Map) {
          errorMsg = response.body['message'] ?? 'Unknown error';
        } else {
          errorMsg = response.statusText ?? 'Server Error';
        }
        return errorMsg;
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  Future<String?> register(SignupData data) async {
    try {
      Map<String, dynamic> signupData = {
        "email": (data.name ?? '').trim().toLowerCase(),
        "password": data.password
      };

      final response =
      await service.addItem(endpointUrl: 'users/register', itemData: signupData);

      if (response.isOk) {
        log('Dữ liệu API trả về: ${response.body}');
        final ApiResponse<User> apiResponse = ApiResponse<User>.fromJson(
            response.body,
                (json) => User.fromJson(json as Map<String, dynamic>));

        if (apiResponse.success == true) {
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          log('Register Success');
          return null;
        } else {
          return apiResponse.message ?? 'Failed to Register';
        }
        // Trong UserProvider
      } else {
        // Kiểm tra nếu body là Map thì lấy 'message', nếu không lấy statusText
        String errorMsg = 'Unknown error';
        if (response.body is Map) {
          errorMsg = response.body['message'] ?? 'Unknown error';
        } else {
          errorMsg = response.statusText ?? 'Server Error';
        }
        return errorMsg;
      }
    } catch (e) {
      log('Register Error: $e');
      return 'An error occurred: $e';
    }
  }

  Future<void> saveLoginInfo(User? loginUser) async {
    if (loginUser != null) {
      await box.write(USER_INFO_BOX, loginUser.toJson());

      if (loginUser.accessToken != null) {
        await box.write(TOKEN, loginUser.accessToken);
        log('Token saved: ${loginUser.accessToken}');
      }
    }
  }

  User? getLoginUsr() {
    Map<String, dynamic>? userJson = box.read(USER_INFO_BOX);
    if (userJson == null || userJson.isEmpty) return null;
    return User.fromJson(userJson);
  }

  logOutUser() {
    box.remove(USER_INFO_BOX);
    box.remove(TOKEN);
    _dataProvider.user = null;
    _dataProvider.favoriteProducts.clear();
    notifyListeners();
    Get.offAll(() => const LoginScreen());
  }
}