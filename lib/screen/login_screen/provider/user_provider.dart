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
        "name": data.name.toLowerCase(),
        "password": data.password
      };

      final response = await service.addItem(
          endpointUrl: 'users/login', itemData: loginData);

      if (response.isOk) {
        final ApiResponse<User> apiResponse = ApiResponse<User>.fromJson(
            response.body,
                (json) => User.fromJson(json as Map<String, dynamic>));

        if (apiResponse.success == true) {
          User? user = apiResponse.data;
          await saveLoginInfo(user);

          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          log('Login success');
          return null;
        } else {
          return apiResponse.message ?? 'Failed to Login';
        }
      } else {
        String errorMsg = response.body?['message'] ?? response.statusText ?? 'Unknown error';
        return errorMsg;
      }
    } catch (e) {
      log('Login Error: $e');
      return 'An error occurred: $e';
    }
  }

  Future<String?> register(SignupData data) async {
    try {
      Map<String, dynamic> user = {
        "name": (data.name ?? '').toLowerCase(),
        "password": data.password
      };

      final response =
      await service.addItem(endpointUrl: 'users/register', itemData: user);

      if (response.isOk) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.body, (json) => json);

        if (apiResponse.success == true) {
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          log('Register Success');
          return null;
        } else {
          return apiResponse.message ?? 'Failed to Register';
        }
      } else {
        String errorMsg = response.body?['message'] ?? response.statusText ?? 'Unknown error';
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
    }
  }

  User? getLoginUsr() {
    Map<String, dynamic>? userJson = box.read(USER_INFO_BOX);
    if (userJson == null || userJson.isEmpty) return null;
    return User.fromJson(userJson);
  }

  logOutUser() {
    box.remove(USER_INFO_BOX);
    Get.offAll(const LoginScreen());
  }
}