import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// pcw が発行するショップ担当者トークン (Sanctum personal access token) の保存先。
///
/// サーバ側のトークンは無期限 (`config/sanctum.php` の expiration=null) のため、
/// `.claude/rules/security.md` に従い shared_preferences ではなく
/// Keychain / Keystore ベースの flutter_secure_storage に置く。
///
/// リクエストのたびに Keychain を読まないよう、一度読んだ値はメモリに保持する。
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String key = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _cache;
  bool _loaded = false;

  /// 保存済みトークン。無い・空・読み取り失敗のときは null。
  ///
  /// 読み取り失敗 (Android のバックアップ復元で鍵が壊れた等) は未ログイン扱いにして、
  /// 起動処理を止めない。
  Future<String?> read() async {
    if (_loaded) return _cache;
    try {
      final value = await _storage.read(key: key);
      _cache = (value == null || value.isEmpty) ? null : value;
    } catch (_) {
      _cache = null;
    }
    _loaded = true;
    return _cache;
  }

  Future<void> write(String token) async {
    await _storage.write(key: key, value: token);
    _cache = token;
    _loaded = true;
  }

  Future<void> delete() async {
    _cache = null;
    _loaded = true;
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // 消せなくてもメモリ上は未ログイン。次回起動時の read 失敗も未ログイン扱いになる。
    }
  }
}
