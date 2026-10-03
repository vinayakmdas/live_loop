
import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/features/auth/data/model/user_model.dart';

class AuthRemoteDataSource {
  final ApiService apiService;

  AuthRemoteDataSource(dynamic dio, {required this.apiService});

  Future<UserModel> login(String email, String password) async {
    final response = await apiService.post(ApiConstants.loginEndpoint, {
      'email': email,
      'password': password,
    });

    final userData = response['data'] != null ? response['data']['user'] : response['user'];
    return UserModel.fromJson(userData);
  }

  Future<UserModel> register(String name, String email, String password) async {
    final response = await apiService.post(ApiConstants.registerEndpoint, {
      'name': name,
      'username': name,
      'email': email,
      'password': password,
    });
    final userData = response['data'] != null ? response['data']['user'] : response['user'];
    return UserModel.fromJson(userData);
  }
}
