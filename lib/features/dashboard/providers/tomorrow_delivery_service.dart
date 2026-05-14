import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/tomorrow_delivery_item.dart';

class TomorrowDeliveryService {
  final ApiClient _apiClient;

  TomorrowDeliveryService(this._apiClient);

  /// 「翌日配送一覧」を pcw `haisouyotei/syosai` から取得する。
  ///
  /// pcw 側は今日〜翌日両方を返すので、クライアント側で `kibou_date == YMD` フィルタ。
  /// [targetDate] は呼出元 (画面または provider) で `dashboard_data.scheduledTargetDate`
  /// から確定済みの値を渡す（17 時切替ロジックの単一ソース化）。
  ///
  /// [haisouTantoNameFallback] が渡されたら、各 item の `haisouTantoName` を上書きする。
  /// pcw 側に配送担当者名カラムが無いため、Service 層でログインユーザ名を埋める運用。
  ///
  /// 異常 (DioException, result != '1') は **例外を throw**。Provider 側で
  /// state.error に詰めて UI に表示する。
  Future<List<TomorrowDeliveryItem>> fetchTomorrowList({
    required int shopId,
    required int tantoId,
    required DateTime targetDate,
    String? haisouTantoNameFallback,
  }) async {
    final ymd =
        '${targetDate.year}/${targetDate.month.toString().padLeft(2, '0')}/'
        '${targetDate.day.toString().padLeft(2, '0')}';

    final Response res;
    try {
      res = await _apiClient.post(
        '/api/pcwMobileApi/shop/haisouyotei/syosai',
        data: {'shop_id': shopId, 'tanto_id': tantoId},
      );
    } on DioException catch (e) {
      throw Exception('配送予定の取得に失敗しました (${e.message ?? "通信エラー"})');
    }

    final data = _asMap(res.data);
    if (data['result'] != '1') {
      throw Exception('配送予定の取得に失敗しました (result=${data['result']})');
    }
    final list = (data['details'] as List?) ?? const [];
    return list.whereType<Map>().where((e) => e['kibou_date'] == ymd).map((e) {
      var item = TomorrowDeliveryItem.fromJson(Map<String, dynamic>.from(e));
      if (haisouTantoNameFallback != null &&
          haisouTantoNameFallback.isNotEmpty &&
          item.haisouTantoName.isEmpty) {
        item = item.copyWith(haisouTantoName: haisouTantoNameFallback);
      }
      return item;
    }).toList();
  }

  /// 「本日配送完了一覧」を pcw `haisou-kanryo/syosai` から取得する。
  ///
  /// pcw 側で完了日 = today で絞っているため、クライアント側で日付フィルタは不要。
  /// 配送単位 (`hs1.haisou_id`) に集約済みのため、1 配送 = 1 行で返る
  /// (件数 API と完全に一致)。
  ///
  /// [haisouTantoNameFallback] が渡されたら、各 item の `haisouTantoName` を上書き
  /// (`fetchTomorrowList` と同じ運用、pcw 側に配送担当者名カラム無いため)。
  ///
  /// 異常 (DioException, result != '1') は **例外を throw**。
  Future<List<TomorrowDeliveryItem>> fetchTodayCompletedList({
    required int shopId,
    required int tantoId,
    String? haisouTantoNameFallback,
  }) async {
    final Response res;
    try {
      res = await _apiClient.post(
        '/api/pcwMobileApi/shop/haisou-kanryo/syosai',
        data: {'shop_id': shopId, 'tanto_id': tantoId},
      );
    } on DioException catch (e) {
      throw Exception('本日配送完了の取得に失敗しました (${e.message ?? "通信エラー"})');
    }

    final data = _asMap(res.data);
    if (data['result'] != '1') {
      throw Exception('本日配送完了の取得に失敗しました (result=${data['result']})');
    }
    final list = (data['details'] as List?) ?? const [];
    return list.whereType<Map>().map((e) {
      var item = TomorrowDeliveryItem.fromJson(Map<String, dynamic>.from(e));
      if (haisouTantoNameFallback != null &&
          haisouTantoNameFallback.isNotEmpty &&
          item.haisouTantoName.isEmpty) {
        item = item.copyWith(haisouTantoName: haisouTantoNameFallback);
      }
      return item;
    }).toList();
  }

  // pcw 側 Content-Type が text/html のため Dio が自動 JSON 化しない。
  // 文字列のときは手動 decode。riyojokyo_service.dart:218 と同形。
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
