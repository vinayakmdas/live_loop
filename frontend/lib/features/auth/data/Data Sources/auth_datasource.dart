import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import 'package:frontend/features/auth/data/model/user_model.dart';

class AuthRemoteDataSource {
  final ApiService apiService;
  final SessionLocalDataSource? sessionLocalDataSource;

  AuthRemoteDataSource({
    required this.apiService,
    this.sessionLocalDataSource,
  });

  Future<UserModel> login(String email, String password) async {
    final response = await apiService.post(ApiConstants.loginEndpoint, {
      'email': email,
      'password': password,
    });

    final token = response['data'] != null
        ? response['data']['accessToken']
        : response['accessToken'];
    final refreshToken = response['data'] != null
        ? response['data']['refreshToken']
        : response['refreshToken'];

    if (token != null && sessionLocalDataSource != null) {
      await sessionLocalDataSource!.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final userData = response['data'] != null
        ? response['data']['user']
        : response['user'];
    return UserModel.fromJson(
      userData,
      token: token?.toString(),
      refreshToken: refreshToken?.toString(),
    );
  }

  Future<UserModel> register(String name, String email, String password) async {
    final response = await apiService.post(ApiConstants.registerEndpoint, {
      'name': name,
      'username': name,
      'email': email,
      'password': password,
    });

    final token = response['data'] != null
        ? response['data']['accessToken']
        : response['accessToken'];
    final refreshToken = response['data'] != null
        ? response['data']['refreshToken']
        : response['refreshToken'];

    if (token != null && sessionLocalDataSource != null) {
      await sessionLocalDataSource!.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final userData = response['data'] != null
        ? response['data']['user']
        : response['user'];
    return UserModel.fromJson(
      userData,
      token: token?.toString(),
      refreshToken: refreshToken?.toString(),
    );
  }

  Future<UserModel> googleSignIn({
    required String email,
    required String name,
    String? profileImage,
    String? googleId,
    String? idToken,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'name': name,
    };
    if (profileImage != null) payload['profileImage'] = profileImage;
    if (googleId != null) payload['googleId'] = googleId;
    if (idToken != null) payload['idToken'] = idToken;

    final response = await apiService.post('/api/auth/google', payload);

    final token = response['data'] != null
        ? response['data']['accessToken']
        : response['accessToken'];
    final refreshToken = response['data'] != null
        ? response['data']['refreshToken']
        : response['refreshToken'];

    if (token != null && sessionLocalDataSource != null) {
      await sessionLocalDataSource!.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final userData = response['data'] != null
        ? response['data']['user']
        : response['user'];
    return UserModel.fromJson(
      Map<String, dynamic>.from(userData as Map),
      token: token?.toString(),
      refreshToken: refreshToken?.toString(),
    );
  }

  Future<void> logout() async {
    final refreshToken = sessionLocalDataSource?.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await apiService.post(ApiConstants.logoutEndpoint, {
          'refreshToken': refreshToken,
        });
      } catch (_) {
        // Local logout should still proceed even if server is unreachable
      }
    }
  }

  Future<String> forgotPassword(String email) async {
    final response = await apiService.post(
      '/api/auth/forgot-password',
      {'email': email.trim().toLowerCase()},
    );
    return response['message']?.toString() ??
        'If that email exists in our system, a password reset link has been sent.';
  }

  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await apiService.post(
      '/api/auth/reset-password',
      {
        'resetToken': resetToken.trim(),
        'newPassword': newPassword,
      },
    );
    return response['message']?.toString() ??
        'Password reset successful. Please log in with your new password.';
  }
}
