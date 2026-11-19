import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/core/api/api_client.dart';
import 'package:shop_app_flutter/core/auth/token_storage.dart';

import 'helpers/fake_http_adapter.dart';

/// PRMT-30: ApiClient がトークンを送り、401 でセッション切れを知らせること。
void main() {
  late TokenStorage storage;
  late List<void> events;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = TokenStorage();
    events = [];
  });

  ApiClient build(FakeHttpAdapter adapter) {
    final client = ApiClient(tokenStorage: storage, dio: fakeDio(adapter));
    client.unauthorizedEvents.listen(events.add);
    return client;
  }

  Future<void> post(ApiClient client, String path) async {
    try {
      await client.post(path, data: {});
    } on DioException catch (_) {}
    await Future<void>.delayed(Duration.zero);
  }

  test('保存したトークンを Authorization: Bearer で送る', () async {
    await storage.write('1|abc');
    final adapter = FakeHttpAdapter((_) => (200, {'result': '1'}));
    final client = build(adapter);

    await client.post('/api/pcwMobileApi/shop/tanto/list', data: {});

    expect(adapter.requests.single.headers['Authorization'], 'Bearer 1|abc');
  });

  test('トークンが無ければ Authorization を付けない', () async {
    final adapter = FakeHttpAdapter((_) => (200, {'result': '1'}));
    final client = build(adapter);

    await client.post('/api/pcwMobileApi/shop/haisouyotei', data: {});

    expect(adapter.requests.single.headers.containsKey('Authorization'), false);
  });

  test('401 を受けたらセッション切れを 1 回知らせる', () async {
    await storage.write('1|abc');
    final client = build(FakeHttpAdapter(
      (_) => (401, {'result': '0', 'error': 'unauthenticated'}),
    ));

    await post(client, '/api/pcwMobileApi/shop/tanto/list');

    expect(events, hasLength(1));
  });

  test('ログイン API の 401 では知らせない', () async {
    await storage.write('1|abc');
    final client = build(FakeHttpAdapter((_) => (401, {'result': '0'})));

    await post(client, '/api/pcwMobileApi/shop/login');

    expect(events, isEmpty);
  });

  test('トークンを持たずに送ったリクエストの 401 では知らせない', () async {
    final client = build(FakeHttpAdapter((_) => (401, {'result': '0'})));

    await post(client, '/api/pcwMobileApi/shop/tanto/list');

    expect(events, isEmpty);
  });

  test('ログインし直した後に、古いトークンのリクエストの 401 が届いても知らせない', () async {
    await storage.write('1|old');
    final client = build(FakeHttpAdapter((options) async {
      // 応答が返るまでの間に、別の画面でログインし直したことにする
      await storage.write('2|new');
      return (401, {'result': '0', 'error': 'unauthenticated'});
    }));

    await post(client, '/api/pcwMobileApi/shop/tanto/list');

    expect(events, isEmpty);
  });
}
