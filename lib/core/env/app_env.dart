import '../api/api_client.dart';

/// アプリの接続先環境。
enum AppEnv { local, test, prod, custom }

/// `ApiClient.baseUrl`（または引数の URL）の host を見て env を判定する。
///
/// - `localhost` / `10.0.2.2` / `127.0.0.1` → [AppEnv.local]
/// - `fatest.*` → [AppEnv.test]
/// - `*.pcw-system.com` → [AppEnv.prod]
/// - それ以外 → [AppEnv.custom]
///
/// 任意 URL に "fatest" が含まれるだけで Test 扱いになるのを防ぐため、
/// `Uri.tryParse` で host を抽出して比較する。
AppEnv detectAppEnv([String? url]) {
  final raw = (url ?? ApiClient.baseUrl);
  final host = Uri.tryParse(raw)?.host.toLowerCase() ?? raw.toLowerCase();
  if (host == 'localhost' || host == '10.0.2.2' || host == '127.0.0.1') {
    return AppEnv.local;
  }
  if (host.startsWith('fatest.')) return AppEnv.test;
  if (host.endsWith('pcw-system.com')) return AppEnv.prod;
  return AppEnv.custom;
}

extension AppEnvX on AppEnv {
  String get label => switch (this) {
        AppEnv.local => 'Local',
        AppEnv.test => 'Test',
        AppEnv.prod => 'Prod',
        AppEnv.custom => 'Custom',
      };
}
