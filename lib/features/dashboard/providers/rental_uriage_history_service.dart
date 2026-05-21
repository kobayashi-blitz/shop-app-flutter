import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/rental_uriage_month_item.dart';

/// pcw `rental-uriage/monthly` API のレスポンスを保持する Record 型。
typedef RentalUriageHistoryResult = ({
  int totalkinAll,
  List<RentalUriageMonthItem> months,
});

class RentalUriageHistoryService {
  final ApiClient _apiClient;

  RentalUriageHistoryService(this._apiClient);

  /// 担当者単位のレンタル売上月別履歴を取得する。
  ///
  /// pcw 側は `months` パラメータで取得月数を指定 (デフォルト 3、最大 24)。
  /// データなし月も 0 埋めして DESC で返す。
  /// 異常 (DioException, result != '1') は **例外を throw**。
  /// SQL が重いため receiveTimeout は 60 秒に明示延長 (Dio default 30 秒の上書き)。
  Future<RentalUriageHistoryResult> fetchMonthly({
    required int shopId,
    required int tantoId,
    int months = 3,
  }) async {
    final Response res;
    try {
      res = await _apiClient.post(
        '/api/pcwMobileApi/shop/rental-uriage/monthly',
        data: {'shop_id': shopId, 'tanto_id': tantoId, 'months': months},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
    } on DioException catch (e) {
      throw Exception('レンタル売上履歴の取得に失敗しました (${e.message ?? "通信エラー"})');
    }

    final data = _asMap(res.data);
    if (data['result'] != '1') {
      throw Exception('レンタル売上履歴の取得に失敗しました (result=${data['result']})');
    }
    final totalkinAll = int.tryParse('${data['totalkin_all']}') ?? 0;
    final list = (data['months'] as List?) ?? const [];
    final monthItems = list
        .whereType<Map>()
        .map(
            (e) => RentalUriageMonthItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (totalkinAll: totalkinAll, months: monthItems);
  }

  // pcw 側 Content-Type が text/html のため Dio が自動 JSON 化しない。
  // 文字列のときは手動 decode。tomorrow_delivery_service.dart と同形。
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
