import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/core/api/api_client.dart';
import 'package:shop_app_flutter/features/dashboard/providers/haisou_detail_service.dart';

/// fetchDetail の送信ボディを捕捉するためのフェイク ApiClient。
/// 実ネットワーク (Dio) には触れず、post() の data を記録して固定レスポンスを返す。
/// sinsei_service_test.dart:8 と同形。
class _CapturingApiClient extends ApiClient {
  Map<String, dynamic>? lastBody;

  @override
  Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    lastBody = data;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{
        'result': '1',
        'detail': <String, dynamic>{
          'haisou_id': 118637,
          'kubun': '1',
          'reception_no': 'R-711304',
          'haisou_tanto_name': '山田太郎',
        },
        'products': const [],
      },
      statusCode: 200,
    );
  }
}

void main() {
  group('HaisouDetailService.fetchDetail - 受付単位パラメータ送信', () {
    late _CapturingApiClient api;
    late HaisouDetailService service;

    setUp(() {
      api = _CapturingApiClient();
      service = HaisouDetailService(api);
    });

    test('haisou_id / order_id / kubun を必ず両方(3値)送る', () async {
      await service.fetchDetail(
        shopId: 1,
        tantoId: 42,
        haisouId: 118637,
        orderId: 711304, // = 受付ID = 一覧の primary_id
        kubun: '1', // 生コード（サーバは kubun 併用時のみ受付を一意化）
      );

      final body = api.lastBody!;
      // order_id だけでは種別跨ぎで tbl_id が衝突しうるため kubun 併用が必須。
      expect(body['haisou_id'], 118637);
      expect(body['order_id'], 711304);
      expect(body['kubun'], '1');
    });

    test('合積みの別受付は order_id が異なる値で送られる', () async {
      await service.fetchDetail(
        shopId: 1,
        tantoId: 42,
        haisouId: 118637,
        orderId: 711305,
        kubun: '1',
      );

      final body = api.lastBody!;
      expect(body['haisou_id'], 118637); // 同じ配送
      expect(body['order_id'], 711305); // 別受付
    });
  });
}
