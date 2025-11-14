import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/login_response.dart';
import '../../../core/models/user.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/api/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final loginResponse = LoginResponse.fromJson(response.data);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', loginResponse.token);
      await prefs.setString('user_id', loginResponse.user.id.toString());
      await prefs.setString('user_name', loginResponse.user.name);
      await prefs.setString('user_office_name', loginResponse.user.officeName);

      return loginResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'ログインに失敗しました');
      } else {
        throw Exception('ネットワークエラーが発生しました');
      }
    } catch (e) {
      throw Exception('予期しないエラーが発生しました');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_office_name');
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userName = prefs.getString('user_name');
    final userOfficeName = prefs.getString('user_office_name');

    if (userId != null && userName != null && userOfficeName != null) {
      return User(
        id: int.parse(userId),
        name: userName,
        officeName: userOfficeName,
      );
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }
}
