import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/data/data_provider.dart';
import '../../../models/user.dart';
import '../../../services/http_services.dart';
import '../../../utility/constants.dart';
import '../../../utility/snack_bar_helper.dart';
import '../data/auth_repository.dart';
import '../login_screen.dart';

class UserProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final DataProvider _dataProvider;
  final GetStorage box = GetStorage();
  User? _currentUser;
  String? _pendingVerificationEmail;

  UserProvider(this._dataProvider, {AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(HttpService()) {
    _currentUser = _dataProvider.user;
  }

  User? get currentUser => _currentUser;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  void clearPendingVerificationEmail() {
    _pendingVerificationEmail = null;
  }

  String? _readToken(String key) {
    return HttpService.readStoredToken(key);
  }

  Future<String?> login(LoginData data) async {
    try {
      final loginData = {
        'email': data.name.trim().toLowerCase(),
        'password': data.password,
      };

      final apiResponse = await _authRepository.login(loginData);

      if (!apiResponse.success) {
        return HttpService.parseApiMessage(
          null,
          fallback: apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Unable to sign in. Please try again.',
        );
      }

      await saveLoginInfo(apiResponse.data);
      await fetchCurrentUserProfile(showSnack: false);
      if (_currentUser?.emailVerified == false) {
        _pendingVerificationEmail = _currentUser?.email ?? loginData['email'];
      } else {
        _pendingVerificationEmail = null;
      }

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

      final body = await _authRepository.register(signupData);

      final success = body is Map<String, dynamic> && body['success'] == true;

      if (success) {
        _pendingVerificationEmail = signupData['email'];
        SnackBarHelper.showSuccessSnackBar(
          HttpService.parseApiMessage(
            body,
            fallback: 'Verification code sent. Please check your email.',
          ),
        );
        return null;
      }
      return HttpService.parseApiMessage(
        body,
        fallback: 'Unable to create your account. Please try again.',
      );
    } catch (e) {
      log('Register Error: $e');
      return HttpService.humanizeError(
        e,
        fallback: 'Unable to create your account right now. Please try again.',
      );
    }
  }

  Future<String?> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final apiResponse = await _authRepository.verifyEmail(
        email: email.trim().toLowerCase(),
        code: code.trim(),
      );

      if (!apiResponse.success) {
        return HttpService.parseApiMessage(
          null,
          fallback: apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Unable to verify this code. Please try again.',
        );
      }

      await HttpService.clearAuthSession();
      _currentUser = null;
      _dataProvider.user = null;
      _pendingVerificationEmail = null;
      notifyListeners();
      SnackBarHelper.showSuccessSnackBar(apiResponse.message);
      return null;
    } catch (e) {
      return HttpService.humanizeError(
        e,
        fallback: 'Unable to verify email right now. Please try again.',
      );
    }
  }

  Future<String?> resendVerificationCode(String email) async {
    try {
      final body = await _authRepository.resendVerificationCode(
        email.trim().toLowerCase(),
      );

      SnackBarHelper.showSuccessSnackBar(
        HttpService.parseApiMessage(
          body,
          fallback: 'Verification code sent.',
        ),
      );
      return null;
    } catch (e) {
      return HttpService.humanizeError(
        e,
        fallback: 'Unable to send a new code right now. Please try again.',
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
      final body = await _authRepository.fetchCurrentUserProfile();

      final user = _extractUser(body);
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
        await _authRepository.logout();
      } catch (_) {}
    }

    await HttpService.clearAuthSession();

    _currentUser = null;
    _pendingVerificationEmail = null;
    _dataProvider.user = null;
    notifyListeners();
    Get.offAll(() => const LoginScreen());
  }
}
