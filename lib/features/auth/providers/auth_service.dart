import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/login_response.dart';
import '../../../core/models/user.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<User> login(String loginId, String password) async {
    try {
      debugPrint('### [AuthService] login start: loginId=$loginId');

      final response = await _apiClient.post(
        '/api/sp/login',
        data: {
          'login_id': loginId,
          'login_password': password,
        },
      );

      debugPrint('### [AuthService] login response status: ${response.statusCode}');
      debugPrint('### [AuthService] login response data: ${response.data}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sp_shop_syain_id', response.data['data']['shop_syain_id'].toString());
      await prefs.setString('sp_name', response.data['data']['shop_syain_name']);
      await prefs.setString('sp_shop_id', response.data['data']['shop_id'].toString());
      await prefs.setString('sp_login_id', loginId);

      return User(
        shopSyainId: response.data['data']['shop_syain_id'],
        shopSyainName: response.data['data']['shop_syain_name'],
        shopId: response.data['data']['shop_id'].toString(),
        loginId: loginId,
      );
    } on DioException catch (e) {
      debugPrint('### [AuthService] DioException: $e');
      debugPrint('### [AuthService] DioException response: ${e.response?.data}');

      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'ログインに失敗しました');
      } else {
        throw Exception('ネットワークエラーが発生しました');
      }
    } catch (e) {
      debugPrint('### [AuthService] unexpected error: $e');
      throw Exception('予期しないエラーが発生しました');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sp_shop_syain_id');
    await prefs.remove('sp_name');
    await prefs.remove('sp_shop_id');
    await prefs.remove('sp_login_id');
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('sp_shop_syain_id');
    final userName = prefs.getString('sp_name');
    final shopId = prefs.getString('sp_shop_id');

    if (userId != null && userName != null && shopId != null) {
      return User(
        shopSyainId: int.parse(userId),
        shopSyainName: userName,
        shopId: shopId,
        loginId: prefs.getString('sp_login_id') ?? '',
      );
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sp_shop_syain_id') != null;
  }
}
