import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/haisou_detail.dart';

class HaisouDetailService {
  final ApiClient _apiClient;

  HaisouDetailService(this._apiClient);

  /// 1 配送 (`hs1.haisou_id`) の詳細を pcw `haisou/detail` から取得する。
  ///
  /// shop_id 不一致 / 該当配送なしは pcw 側で `result: '2'` を返し、
  /// Service 層では **例外を throw** する (Provider 側で state.error に詰める)。
  /// DioException も例外 throw。
  Future<HaisouDetail> fetchDetail({
    required int shopId,
    required int tantoId,
    required int haisouId,
  }) async {
    final Response res;
    try {
      res = await _apiClient.post(
        '/api/pcwMobileApi/shop/haisou/detail',
        data: {
          'shop_id': shopId,
          'tanto_id': tantoId,
          'haisou_id': haisouId,
        },
      );
    } on DioException catch (e) {
      throw Exception('配送詳細の取得に失敗しました (${e.message ?? "通信エラー"})');
    }

    final data = _asMap(res.data);
    if (data['result'] != '1') {
      throw Exception('配送詳細が見つかりませんでした');
    }
    final detailJson = _asMap(data['detail']);
    final productsJson = (data['products'] as List?) ?? const [];
    if (detailJson.isEmpty) {
      throw Exception('配送詳細データが空です');
    }
    return HaisouDetail.fromJson(detailJson, productsJson);
  }

  // pcw 側 Content-Type が text/html のため Dio が自動 JSON 化しない。
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
