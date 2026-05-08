import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;
  // adb reverse tcp:8080 tcp:8080 で実機からも localhost に届く
  static const String baseUrl = 'http://localhost:8080';

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

  /// 代理店担当者ログインAPI
  Future<Response> spLogin({
    required String shopId,
    required String loginId,
    required String loginPassword,
  }) async {
    try {
      return await _dio.post(
        '/api/sp/login',
        data: {
          'shop_id': shopId,
          'login_id': loginId,
          'login_password': loginPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 明日の配送件数取得API
  Future<Response> fetchSpTomorrowDeliveryCount({
    required String shopId,
  }) async {
    try {
      return await _dio.post(
        '/api/pcwMobileApi/sp-tomorrow-delivery-count',
        data: {
          'shop_id': shopId,
        },
      );
    } catch (e) {
      rethrow;
    }
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
