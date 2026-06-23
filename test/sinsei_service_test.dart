import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/core/api/api_client.dart';
import 'package:shop_app_flutter/features/sinsei/providers/sinsei_service.dart';

/// regist の送信ボディを捕捉するためのフェイク ApiClient。
/// 実ネットワーク (Dio) には触れず、post() の data を記録して固定レスポンスを返す。
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
      data: <String, dynamic>{'result': '1', 'sinsei_syonin_id': 123},
      statusCode: 200,
    );
  }
}

void main() {
  group('SinseiService.regist - shop_syain_id 契約', () {
    late _CapturingApiClient api;
    late SinseiService service;

    setUp(() {
      api = _CapturingApiClient();
      service = SinseiService(api);
    });

    test('shopSyainId 指定時は body に shop_syain_id を含む', () async {
      final id = await service.regist(
        shopId: 1,
        riyosyaId: 2,
        sinseiKubun: '1',
        sinseiFromDate: '2026/06/22',
        horyucheck: const [10],
        rentalid: const [10],
        tankaflag: const ['0'],
        shopSyainId: 42,
      );

      expect(id, 123);
      expect(api.lastBody!.containsKey('shop_syain_id'), isTrue);
      expect(api.lastBody!['shop_syain_id'], 42);
    });

    test('shopSyainId 未指定時は body に shop_syain_id を含めない', () async {
      await service.regist(
        shopId: 1,
        riyosyaId: 2,
        sinseiKubun: '1',
        sinseiFromDate: '2026/06/22',
        horyucheck: const [10],
        rentalid: const [10],
        tankaflag: const ['0'],
      );

      expect(api.lastBody!.containsKey('shop_syain_id'), isFalse);
    });
  });
}
