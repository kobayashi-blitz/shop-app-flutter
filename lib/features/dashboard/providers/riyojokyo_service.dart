import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/keiyakutyu_riyosya_item.dart';
import '../models/monthly_order_item.dart';
import '../models/nyuin_horyu_item.dart';
import '../models/rental_syohin_item.dart';
import '../models/tyoki_demo_item.dart';

class RiyojokyoService {
  final ApiClient _apiClient;

  RiyojokyoService(this._apiClient);

  /// 件数系の共通呼び出し。result == '1' なら count を、'2' (空) なら 0 を返す。
  ///
  /// 設計上、**API 障害 (DioException) も真の 0 件もすべて 0 にフォールバック** する。
  /// ダッシュボードの件数カードが画面エラーで埋まるより、暫定で 0 を見せて他カードの
  /// 取得を続行する方が UX 上望ましいため。区別が必要になる場合は呼出し側で
  /// 例外を再 throw する別メソッドを切ること。
  Future<int> _fetchCount(String path, int shopId, int tantoId) async {
    try {
      final res = await _apiClient.post(
        path,
        data: {'shop_id': shopId, 'tanto_id': tantoId},
      );
      final data = _asMap(res.data);
      if (data['result'] != '1') return 0;
      final raw = data['count'];
      if (raw is int) return raw;
      return int.tryParse('$raw') ?? 0;
    } on DioException {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// totalkin (金額) 系の共通呼び出し。pcw 側 SQL が重く 504 になるので 3 秒で諦めて 0 にフォールバック。
  Future<int> _fetchTotalKin(String path, int shopId, int tantoId) async {
    try {
      final res = await _apiClient.post(
        path,
        data: {'shop_id': shopId, 'tanto_id': tantoId},
      ).timeout(const Duration(seconds: 3));
      final data = _asMap(res.data);
      if (data['result'] != '1') return 0;
      final raw = data['totalkin'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse('$raw') ?? 0;
    } on TimeoutException {
      return 0;
    } on DioException {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// 配送予定件数の「特定日分」だけを取得する。
  ///
  /// pcw 側 `shop/haisouyotei` API は本日〜翌日 2 日合算しか返さないので、
  /// 詳細リスト (`shop/haisouyotei/syosai`) を取って `kibou_date == targetDate`
  /// の件数をクライアント側でカウントする。
  ///
  /// [targetDate] は端末ローカル時刻基準の DateTime。`Y/M/D` 形式に変換して
  /// API レスポンスの `kibou_date` (Y/m/d) と比較する。
  Future<int> haisouYoteiCountForDate({
    required int shopId,
    required int tantoId,
    required DateTime targetDate,
  }) async {
    final ymd =
        '${targetDate.year}/${targetDate.month.toString().padLeft(2, '0')}/'
        '${targetDate.day.toString().padLeft(2, '0')}';
    try {
      final res = await _apiClient.post(
        '/api/pcwMobileApi/shop/haisouyotei/syosai',
        data: {'shop_id': shopId, 'tanto_id': tantoId},
      );
      final data = _asMap(res.data);
      if (data['result'] != '1') return 0;
      final list = (data['details'] as List?) ?? const [];
      return list.where((e) {
        if (e is Map) {
          return e['kibou_date'] == ymd;
        }
        return false;
      }).length;
    } on DioException {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> togetuSinkiOrderCount(
          {required int shopId, required int tantoId}) =>
      _fetchCount('/api/pcwMobileApi/shop/togetu-sinki-order', shopId, tantoId);

  Future<int> moreOneMonthDemoCount(
          {required int shopId, required int tantoId}) =>
      _fetchCount(
          '/api/pcwMobileApi/shop/more-one-month-demo', shopId, tantoId);

  Future<int> keiyakutyuRiyosyaCount(
          {required int shopId, required int tantoId}) =>
      _fetchCount('/api/pcwMobileApi/shop/keiyakutyu-riyosya', shopId, tantoId);

  Future<int> rentalSyohinCount({required int shopId, required int tantoId}) =>
      _fetchCount('/api/pcwMobileApi/shop/rental-syohin', shopId, tantoId);

  Future<int> nyuinHoryuSyohinCount(
          {required int shopId, required int tantoId}) =>
      _fetchCount('/api/pcwMobileApi/shop/nyuin-horyu-syohin', shopId, tantoId);

  /// 本日の配送完了件数。pcw 側 `haisou-kanryo` は配送種別ごとに完了日カラム = today
  /// (預入系は r31.updated_at で代用) でカウントを返す。`_fetchCount` パターンで
  /// 失敗時は 0 フォールバック。
  Future<int> haisouKanryoCount({required int shopId, required int tantoId}) =>
      _fetchCount('/api/pcwMobileApi/shop/haisou-kanryo', shopId, tantoId);

  /// レンタル売上累計。pcw 側 SQL が重く 504 になることがあるので失敗時は 0 を返す。
  Future<int> rentalUriageTotal({required int shopId, required int tantoId}) =>
      _fetchTotalKin('/api/pcwMobileApi/shop/rental-uriage', shopId, tantoId);

  /// 当月新規受注詳細
  Future<List<MonthlyOrderItem>> togetuSinkiOrderDetails({
    required int shopId,
    required int tantoId,
  }) async {
    final list = await _fetchDetails(
      '/api/pcwMobileApi/shop/togetu-sinki-order/syosai',
      shopId,
      tantoId,
      '当月新規受注詳細',
    );
    return list.map((e) => MonthlyOrderItem.fromJson(e)).toList();
  }

  /// 入院保留商品詳細
  Future<List<NyuinHoryuItem>> nyuinHoryuSyohinDetails({
    required int shopId,
    required int tantoId,
  }) async {
    final list = await _fetchDetails(
      '/api/pcwMobileApi/shop/nyuin-horyu-syohin/syosai',
      shopId,
      tantoId,
      '入院保留商品詳細',
    );
    return list.map((e) => NyuinHoryuItem.fromJson(e)).toList();
  }

  /// レンタル中商品詳細
  Future<List<RentalSyohinItem>> rentalSyohinDetails({
    required int shopId,
    required int tantoId,
  }) async {
    final list = await _fetchDetails(
      '/api/pcwMobileApi/shop/rental-syohin/syosai',
      shopId,
      tantoId,
      'レンタル中商品詳細',
    );
    return list.map((e) => RentalSyohinItem.fromJson(e)).toList();
  }

  /// 契約中利用者詳細（利用者単位で複数商品行が返る）
  Future<List<KeiyakutyuRiyosyaItem>> keiyakutyuRiyosyaDetails({
    required int shopId,
    required int tantoId,
  }) async {
    final list = await _fetchDetails(
      '/api/pcwMobileApi/shop/keiyakutyu-riyosya/syosai',
      shopId,
      tantoId,
      '契約中利用者詳細',
    );
    return list.map((e) => KeiyakutyuRiyosyaItem.fromJson(e)).toList();
  }

  /// 長期デモ詳細（API は 30日以上のレコードを返す。3ヶ月以上はフロントで絞り込み）
  Future<List<TyokiDemoItem>> moreOneMonthDemoDetails({
    required int shopId,
    required int tantoId,
  }) async {
    final list = await _fetchDetails(
      '/api/pcwMobileApi/shop/more-one-month-demo/syosai',
      shopId,
      tantoId,
      '長期デモ詳細',
    );
    return list.map((e) => TyokiDemoItem.fromJson(e)).toList();
  }

  /// 詳細系の共通呼び出し。result == '2' (空) のときは空配列。
  Future<List<Map<String, dynamic>>> _fetchDetails(
    String path,
    int shopId,
    int tantoId,
    String labelForError,
  ) async {
    final res = await _apiClient.post(
      path,
      data: {'shop_id': shopId, 'tanto_id': tantoId},
    );
    final data = _asMap(res.data);
    if (data['result'] == '2') return [];
    if (data['result'] != '1') {
      throw Exception('$labelForError の取得に失敗しました');
    }
    final list = (data['details'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // pcw 側 Content-Type が text/html のため Dio が自動 JSON 化しない。文字列のときは手動 decode。
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
