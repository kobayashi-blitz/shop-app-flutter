import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;
  final StreamController<void> _unauthorized =
      StreamController<void>.broadcast();

  /// リクエストに付けたトークンを入れておく `RequestOptions.extra` のキー。
  static const String _sentTokenKey = 'auth_token';

  /// ログイン API。ここの 401 はセッション切れではないので通知しない。
  static const String _loginPath = '/api/pcwMobileApi/shop/login';

  /// API 接続先 base URL。
  ///
  /// ビルド時に `--dart-define=API_BASE_URL=...` で外部注入する。
  /// 未指定の場合は開発用の localhost にフォールバック。
  /// 値はコンパイル時定数のため、切替には hot restart ではなく再ビルドが必要。
  ///
  ///   flutter run                                                            (Local)
  ///   flutter run --dart-define=API_BASE_URL=https://fatest.pcw-system.com   (Test)
  ///   adb reverse tcp:8080 tcp:8080  ← Local + 実機 Android のとき
  static const String _defaultBaseUrl = 'http://localhost:8080';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  /// [dio] はテストで Adapter を差し替えるための入口。通常は省略する。
  ApiClient({TokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            options.extra[_sentTokenKey] = token;
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.path != _loginPath) {
            // ログインし直した後に、古いトークンで送ったリクエストの 401 が遅れて
            // 届くことがある。今のトークンで送ったものだけをセッション切れとみなす。
            final sent = error.requestOptions.extra[_sentTokenKey];
            final current = await _tokenStorage.read();
            if (sent != null && sent == current) {
              _unauthorized.add(null);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// 今のトークンが 401 で拒否されたときに流れる。
  ///
  /// ログアウト処理は Provider の依存の外 (アプリのルート Widget) で受ける。
  /// Provider の中から SessionController を読むと、
  /// SessionController → Push → ApiClient と依存が循環するため。
  Stream<void> get unauthorizedEvents => _unauthorized.stream;

  /// 汎用 POST メソッド
  ///
  /// [options] で個別 API ごとの receiveTimeout 等を上書き可能。
  Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PDF など重いレスポンスをバイナリで取得する。
  /// pcw 側 SQL+dompdf が遅いことがあるため receive timeout を長めに上書き。
  Future<Response<List<int>>> postBytes(
    String path, {
    Map<String, dynamic>? data,
    Duration receiveTimeout = const Duration(seconds: 180),
  }) async {
    try {
      return await _dio.post<List<int>>(
        path,
        data: data,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: receiveTimeout,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }
}
