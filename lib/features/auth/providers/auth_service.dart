import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/models/user.dart';

/// 起動時に端末に残っているログイン情報の判定結果。
sealed class SessionCheck {
  const SessionCheck();
}

/// トークンとログイン情報がそろっている。
class SessionLoggedIn extends SessionCheck {
  const SessionLoggedIn(this.user);
  final User user;
}

/// ログインしていない。食い違って残っていた値は消してある。
class SessionLoggedOut extends SessionCheck {
  const SessionLoggedOut();
}

/// 旧版 (トークン導入前) でログインしたまま更新した。1 回だけ再ログインしてもらう。
class SessionNeedsRelogin extends SessionCheck {
  const SessionNeedsRelogin();
}

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService(this._apiClient, this._tokenStorage);

  static const _prefKeys = [
    'sp_shop_syain_id',
    'sp_name',
    'sp_shop_id',
    'sp_shop_name',
    'sp_login_id',
  ];

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

      // トークンが無いと担当者再登録などの API を使えないため、ログイン失敗として扱う。
      final token = data['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('ログインに失敗しました');
      }

      final user = User(
        shopSyainId: (data['shop_syain_id'] as num).toInt(),
        shopSyainName: (data['shop_syain_name'] ?? '') as String,
        shopId: (data['shop_id'] as num).toInt(),
        loginId: loginId,
        shopName: data['shop_name'] as String?,
      );

      await _tokenStorage.write(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sp_shop_syain_id', user.shopSyainId.toString());
      await prefs.setString('sp_name', user.shopSyainName);
      await prefs.setString('sp_shop_id', user.shopId.toString());
      await prefs.setString('sp_login_id', loginId);
      await prefs.setString('sp_shop_name', user.shopName ?? '');

      return user;
    } on DioException catch (e) {
      debugPrint('### [AuthService] DioException: ${e.type}');
      if (e.response != null) {
        throw Exception('ログインに失敗しました（HTTP ${e.response?.statusCode}）');
      }
      throw Exception('ネットワークエラーが発生しました');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('予期しないエラーが発生しました');
    }
  }

  /// pcw 側で今のトークンを無効にする。失敗してもローカルのログアウトは続ける。
  Future<void> logoutRemote() async {
    try {
      await _apiClient.post('/api/pcwMobileApi/shop/logout');
    } catch (_) {}
  }

  /// 端末に保存したログイン情報とトークンを消す。
  Future<void> clearSession() async {
    await _tokenStorage.delete();
    final prefs = await SharedPreferences.getInstance();
    for (final key in _prefKeys) {
      await prefs.remove(key);
    }
  }

  Future<SessionCheck> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _tokenStorage.read();
    final userId = int.tryParse(prefs.getString('sp_shop_syain_id') ?? '');
    final userName = prefs.getString('sp_name');
    final shopId = int.tryParse(prefs.getString('sp_shop_id') ?? '');

    if (token != null && userId != null && userName != null && shopId != null) {
      return SessionLoggedIn(User(
        shopSyainId: userId,
        shopSyainName: userName,
        shopId: shopId,
        loginId: prefs.getString('sp_login_id') ?? '',
        shopName: prefs.getString('sp_shop_name') ?? '',
      ));
    }
    if (token == null && prefs.getString('sp_shop_syain_id') != null) {
      return const SessionNeedsRelogin();
    }
    // iOS で入れ直した後の「Keychain のトークンだけ残っている」や、
    // ログイン情報が一部だけ欠けている状態。残りを消して未ログインにそろえる。
    if (token != null || _prefKeys.any(prefs.containsKey)) {
      await clearSession();
    }
    return const SessionLoggedOut();
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
