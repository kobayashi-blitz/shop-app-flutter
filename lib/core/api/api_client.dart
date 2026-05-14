import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;

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

  ApiClient() {
    _dio = Dio(
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
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  /// 汎用 POST メソッド
  Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
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
