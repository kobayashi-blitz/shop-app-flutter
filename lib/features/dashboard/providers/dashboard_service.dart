import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  /// 明日の配送予定件数 / 指定日の配送完了件数取得API
  ///
  /// Laravel 側のエンドポイント:
  ///   POST /api/pcwMobileApi/sp-tomorrow-delivery-count
  ///
  /// リクエスト:
  ///   {
  ///     "shop_id": 1
  ///   }
  ///
  /// レスポンス例:
  ///   {
  ///     "status": "OK",
  ///     "tomorrow_date": "2025/11/20",
  ///     "target_date": "2025-11-19",
  ///     "shop_id": 1,
  ///     "delivery_planned_count": 5,
  ///     "delivery_completed_count": 3
  ///   }
  /// 明日の配送予定件数 / 指定日の配送完了件数取得API
  ///
  /// Laravel 側のエンドポイント:
  ///   POST /pcwMobileApi/sp-tomorrow-delivery-count
  Future<DeliveryInfo> getDeliveryCounts({required int shopId}) async {
    // MOCK: pcw 側に対応 API 未実装のためデザイン確認用にダミー値を返す。実装後に差し戻す。
    print('### [DashboardService] MOCK getDeliveryCounts shop_id=$shopId');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return DeliveryInfo(
      tomorrowScheduledCount: 7,
      completedTodayCount: 4,
    );
  }

  /// 互換用ラッパー。既存コードで fetchDeliveryInfo を呼んでいる場合はこちらを利用。
  Future<DeliveryInfo> fetchDeliveryInfo({required int shopId}) {
    return getDeliveryCounts(shopId: shopId);
  }
}
