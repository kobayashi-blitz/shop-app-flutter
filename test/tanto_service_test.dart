import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/core/api/api_client.dart';
import 'package:shop_app_flutter/core/auth/token_storage.dart';
import 'package:shop_app_flutter/features/tanto/models/tanto_models.dart';
import 'package:shop_app_flutter/features/tanto/providers/tanto_service.dart';

import 'helpers/fake_http_adapter.dart';

const _row = {
  'riyosya_id': 101,
  'riyosya_name': '介護 花子',
  'riyosya_kana': 'かいご はなこ',
  'riyosya_jyusyo_1': '大阪市',
  'riyosya_jyusyo_2': null,
  'shop_syain_id': 55,
  'rireki_id': null,
  'tanto_syain_id': null,
  'tanto_name': null,
  'keiyakutyu_count': 2,
  'kako_count': 1,
};

/// PRMT-32〜34: 再登録 API の本文と応答・エラーの読み方 (pcw TantoSaitorokuApiController に合わせる)。
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  (TantoService, FakeHttpAdapter) build((int, Object?) Function() reply) {
    final adapter = FakeHttpAdapter((_) => reply());
    final client =
        ApiClient(tokenStorage: TokenStorage(), dio: fakeDio(adapter));
    return (TantoService(client), adapter);
  }

  test('一覧: 条件を pcw のキーで送り、応答を読む', () async {
    final (service, adapter) = build(() => (
          200,
          {
            'result': '1',
            'items': [_row],
            'total': 31,
            'page': 2,
            'per_page': 30,
            'syain_list': [
              {'shop_syain_id': 7, 'shop_syain_name': '担当 一郎'},
            ],
            'jibun_syain_id': 7,
          }
        ));

    final result = await service.fetchList(
      keyword: ' 花子 ',
      jotai: TantoJotai.tanin,
      syainId: 7,
      keiyaku: TantoKeiyaku.all,
      page: 2,
    );

    final req = adapter.requests.single;
    expect(req.path, '/api/pcwMobileApi/shop/tanto/list');
    expect(req.data, {
      'jotai': 'tanin',
      'keiyaku': 'all',
      'page': 2,
      'keyword': '花子',
      'syain_id': 7,
    });
    expect(result.totalPages, 2);
    expect(result.jibunSyainId, 7);
    expect(result.syainList.single.name, '担当 一郎');
    final item = result.items.single;
    expect(item.shopSyainId, 55);
    expect(item.rirekiId, isNull);
    // 退職者など、生の担当者 ID があっても有効な担当者がいなければ未設定
    expect(item.tantoLabel, '担当者未設定');
  });

  test('登録: 一覧で受け取った shop_syain_id・rireki_id を null も含めてそのまま送る', () async {
    final (service, adapter) = build(() => (
          200,
          {
            'result': '1',
            'changed': [101],
            'unchanged': <int>[],
          }
        ));

    final result = await service.saitoroku([TantoRiyosyaItem.fromJson(_row)]);

    final req = adapter.requests.single;
    expect(req.path, '/api/pcwMobileApi/shop/tanto/saitoroku');
    expect(req.data, {
      'items': [
        {'riyosya_id': 101, 'shop_syain_id': 55, 'rireki_id': null},
      ],
    });
    expect(result.changed, [101]);
  });

  test('未設定登録は misettei に送る', () async {
    final (service, adapter) = build(() => (
          200,
          {
            'result': '1',
            'changed': <int>[],
            'unchanged': [101]
          }
        ));

    await service.misettei([TantoRiyosyaItem.fromJson(_row)]);

    expect(
        adapter.requests.single.path, '/api/pcwMobileApi/shop/tanto/misettei');
  });

  Future<TantoApiException> errorOf((int, Object?) reply) async {
    final (service, _) = build(() => reply);
    try {
      await service.saitoroku([TantoRiyosyaItem.fromJson(_row)]);
    } on TantoApiException catch (e) {
      return e;
    }
    fail('例外が出なかった');
  }

  test('409 は競合として、競合した利用者を返す', () async {
    final e = await errorOf((
      409,
      {
        'result': '0',
        'status': 'conflict',
        'riyosya_ids': [101]
      }
    ));
    expect(e.kind, TantoErrorKind.conflict);
    expect(e.riyosyaIds, [101]);
  });

  test('422 は理由と利用者を返す', () async {
    final e = await errorOf((
      422,
      {
        'result': '0',
        'status': 'invalid',
        'reason': 'owner',
        'riyosya_ids': [101]
      }
    ));
    expect(e.kind, TantoErrorKind.invalid);
    expect(e.reason, 'owner');
    expect(e.riyosyaIds, [101]);
  });

  test('503 は再送できるエラー', () async {
    final e = await errorOf((503, {'result': '0', 'status': 'retry'}));
    expect(e.kind, TantoErrorKind.retry);
  });

  test('401 は認証エラー', () async {
    final e = await errorOf((401, {'result': '0', 'error': 'unauthenticated'}));
    expect(e.kind, TantoErrorKind.unauthenticated);
  });
}
