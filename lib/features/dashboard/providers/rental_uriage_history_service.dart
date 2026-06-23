import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/rental_uriage_month_item.dart';

/// pcw `rental-uriage/monthly` API のレスポンスを保持する Record 型。
typedef RentalUriageHistoryResult = ({
  int totalkinAll,
  String periodFrom,
  String periodTo,
  List<RentalUriageMonthItem> months,
});

class RentalUriageHistoryService {
  final ApiClient _apiClient;

  RentalUriageHistoryService(this._apiClient);

  /// 担当者単位のレンタル売上月別履歴を取得する。
  ///
  /// 期間は **当月を除く過去 12 ヶ月** をフロント側で確保する。
  /// pcw 側に 13 ヶ月リクエストして当月行 (まだ月次確定処理が走っていないため
  /// 常に 0 円) をクライアント側で除外し、結果 12 ヶ月を返す。
  /// データなし月も 0 埋めして DESC で返る。
  /// 累計の対象期間 (period_from / period_to、`YYYY/MM`) も同梱されるので
  /// 履歴画面のヘッダで「対象期間」表示に利用する。
  /// 異常 (DioException, result != '1') は **例外を throw**。
  /// SQL が重い場合に備えて receiveTimeout は 60 秒に明示延長。
  Future<RentalUriageHistoryResult> fetchMonthly({
    required int shopId,
    required int tantoId,
  }) async {
    final Response res;
    try {
      res = await _apiClient.post(
        '/api/pcwMobileApi/shop/rental-uriage/monthly',
        data: {'shop_id': shopId, 'tanto_id': tantoId, 'months': 13},
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
    final periodFrom = (data['period_from'] ?? '').toString();
    final periodTo = (data['period_to'] ?? '').toString();
    final list = (data['months'] as List?) ?? const [];
    final now = DateTime.now();
    final currentYm = '${now.year}/${now.month.toString().padLeft(2, '0')}';
    final monthItems = list
        .whereType<Map>()
        .map(
            (e) => RentalUriageMonthItem.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.ym != currentYm)
        .toList();
    return (
      totalkinAll: totalkinAll,
      periodFrom: periodFrom,
      periodTo: periodTo,
      months: monthItems,
    );
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
