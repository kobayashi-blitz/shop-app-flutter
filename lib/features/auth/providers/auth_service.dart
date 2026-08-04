import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/user.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<User> login(String loginId, String password) async {
    try {
      // ログイン ID は認証情報なのでログに出さない (`.claude/rules/security.md`)。
      // debugPrint はリリースビルドでも出力されるため、開発用でも残さない。
      final response = await _apiClient.post(
        '/api/pcwMobileApi/shop/login',
        data: {
          'login_id': loginId,
          'password': password,
        },
      );

      final data = _asMap(response.data);

      if (data['result'] != '1') {
        throw Exception('ログインIDまたはパスワードが正しくありません');
      }

      final user = User(
        shopSyainId: (data['shop_syain_id'] as num).toInt(),
        shopSyainName: (data['shop_syain_name'] ?? '') as String,
        shopId: (data['shop_id'] as num).toInt(),
        loginId: loginId,
        shopName: data['shop_name'] as String?,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sp_shop_syain_id', user.shopSyainId.toString());
      await prefs.setString('sp_name', user.shopSyainName);
      await prefs.setString('sp_shop_id', user.shopId.toString());
      await prefs.setString('sp_login_id', loginId);
      await prefs.setString('sp_shop_name', user.shopName ?? '');

      return user;
    } on DioException catch (e) {
      debugPrint('### [AuthService] DioException: $e');
      if (e.response != null) {
        throw Exception('ログインに失敗しました（HTTP ${e.response?.statusCode}）');
      }
      throw Exception('ネットワークエラーが発生しました');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('予期しないエラーが発生しました');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sp_shop_syain_id');
    await prefs.remove('sp_name');
    await prefs.remove('sp_shop_id');
    await prefs.remove('sp_shop_name');
    await prefs.remove('sp_login_id');
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('sp_shop_syain_id');
    final userName = prefs.getString('sp_name');
    final shopId = prefs.getString('sp_shop_id');
    final shopName = prefs.getString('sp_shop_name');

    if (userId != null && userName != null && shopId != null) {
      return User(
        shopSyainId: int.parse(userId),
        shopSyainName: userName,
        shopId: int.parse(shopId),
        loginId: prefs.getString('sp_login_id') ?? '',
        shopName: shopName ?? '',
      );
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sp_shop_syain_id') != null;
  }

  // pcw 側 Content-Type が text/html のため Dio が自動 JSON 化しない。文字列のときは手動 decode。
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }
}
