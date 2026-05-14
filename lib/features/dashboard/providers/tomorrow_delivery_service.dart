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

  // MOCK: pcw 側 `haisou-kanryo/syosai` 詳細 API が未実装のため、本日配送完了
  // 「一覧」画面は MOCK 維持。件数カードは riyojokyo_service.haisouKanryoCount で
  // 実 API 連携済み。詳細 API が pcw 側に追加されたら本メソッドを差し戻す。
  Future<List<TomorrowDeliveryItem>> fetchTodayCompletedList({
    required int shopId,
    String? targetDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final today = DateTime.now();
    final dateText =
        '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';

    return [
      TomorrowDeliveryItem(
        id: 11,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '伊藤 良子 様',
        deliveryDate: dateText,
        deliveryTime: '09:00',
        haisouTantoName: '中村 配送員',
        itemName: '電動ベッド 3M (KQ-7733)',
        address: '〒531-0072 大阪府大阪市北区豊崎 3-2-1',
      ),
      TomorrowDeliveryItem(
        id: 12,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '渡辺 隆 様',
        deliveryDate: dateText,
        deliveryTime: '10:45',
        haisouTantoName: '吉田 配送員',
        itemName: 'サイドレール 2 本セット',
        address: '〒532-0011 大阪府大阪市淀川区西中島 4-1-1',
      ),
      TomorrowDeliveryItem(
        id: 13,
        type: 'sale',
        kubun: '汎用配送',
        customerName: '小林 千夏 様',
        deliveryDate: dateText,
        deliveryTime: '13:20',
        haisouTantoName: '中村 配送員',
        itemName: '杖 (折りたたみ式)',
        address: '〒536-0014 大阪府大阪市城東区鶴見 2-3-4',
      ),
      TomorrowDeliveryItem(
        id: 14,
        type: 'rental',
        kubun: 'レンタル',
        customerName: '中島 進 様',
        deliveryDate: dateText,
        deliveryTime: '15:10',
        haisouTantoName: '吉田 配送員',
        itemName: '車椅子 自走式 (NA-516A)',
        address: '〒545-0011 大阪府大阪市阿倍野区昭和町 1-5-2',
      ),
    ];
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
