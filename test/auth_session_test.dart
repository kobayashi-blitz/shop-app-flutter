import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app_flutter/core/api/api_client.dart';
import 'package:shop_app_flutter/core/auth/token_storage.dart';
import 'package:shop_app_flutter/core/models/user.dart';
import 'package:shop_app_flutter/core/notifications/push_notification_service.dart';
import 'package:shop_app_flutter/features/auth/providers/auth_provider.dart';
import 'package:shop_app_flutter/features/auth/providers/auth_service.dart';
import 'package:shop_app_flutter/features/auth/providers/session_controller.dart';

import 'helpers/fake_http_adapter.dart';

const _loggedInPrefs = <String, Object>{
  'sp_shop_syain_id': '12',
  'sp_name': '担当 太郎',
  'sp_shop_id': '3',
  'sp_login_id': 'a001',
  'sp_shop_name': 'テスト店',
};

const _loginOk = {
  'result': '1',
  'shop_syain_id': 12,
  'shop_id': 3,
  'shop_syain_name': '担当 太郎',
  'shop_name': 'テスト店',
  'token': '7|abcdef',
};

/// PRMT-30: トークンの保存・送信、旧版からの更新時の強制ログアウト、401 時のログアウト。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  AuthService buildService(
    FakeHttpAdapter adapter, [
    TokenStorage? storage,
  ]) {
    final s = storage ?? TokenStorage();
    return AuthService(ApiClient(tokenStorage: s, dio: fakeDio(adapter)), s);
  }

  group('AuthService.login', () {
    test('応答の token を保存し、ログイン情報も保存する', () async {
      final storage = TokenStorage();
      final service =
          buildService(FakeHttpAdapter((_) => (200, _loginOk)), storage);

      final user = await service.login('a001', 'pw');

      expect(user.shopSyainId, 12);
      expect(await TokenStorage().read(), '7|abcdef');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sp_shop_syain_id'), '12');
    });

    test('token が無い応答はログイン失敗にし、何も保存しない', () async {
      final noToken = Map<String, Object>.from(_loginOk)..remove('token');
      final service = buildService(FakeHttpAdapter((_) => (200, noToken)));

      await expectLater(service.login('a001', 'pw'), throwsException);

      expect(await TokenStorage().read(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sp_shop_syain_id'), isNull);
    });
  });

  group('AuthService.checkSession', () {
    AuthService service() =>
        buildService(FakeHttpAdapter((_) => (200, {'result': '1'})));

    test('トークンとログイン情報がそろえばログイン中', () async {
      SharedPreferences.setMockInitialValues(_loggedInPrefs);
      FlutterSecureStorage.setMockInitialValues({TokenStorage.key: '7|x'});

      final check = await service().checkSession();

      expect(check, isA<SessionLoggedIn>());
      expect((check as SessionLoggedIn).user.shopSyainId, 12);
    });

    test('旧版でログイン中 (sp_shop_syain_id あり・トークン無し) なら再ログインが必要', () async {
      SharedPreferences.setMockInitialValues(_loggedInPrefs);

      expect(await service().checkSession(), isA<SessionNeedsRelogin>());
    });

    test('トークンだけ残っている (iOS で入れ直した後) なら未ログインにして消す', () async {
      FlutterSecureStorage.setMockInitialValues({TokenStorage.key: '7|x'});

      expect(await service().checkSession(), isA<SessionLoggedOut>());
      expect(await TokenStorage().read(), isNull);
    });

    test('ログイン情報が一部だけなら未ログインにして消す', () async {
      SharedPreferences.setMockInitialValues({'sp_name': '担当 太郎'});
      FlutterSecureStorage.setMockInitialValues({TokenStorage.key: '7|x'});

      expect(await service().checkSession(), isA<SessionLoggedOut>());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sp_name'), isNull);
      expect(await TokenStorage().read(), isNull);
    });
  });

  group('SessionController', () {
    late _FakePush push;
    late _FakeAuthService auth;
    late ProviderContainer container;

    setUp(() {
      push = _FakePush();
      auth = _FakeAuthService();
      container = ProviderContainer(overrides: [
        pushNotificationServiceProvider.overrideWithValue(push),
        authServiceProvider.overrideWithValue(auth),
      ]);
      addTearDown(container.dispose);
    });

    test('logout は pcw のトークンも消す', () async {
      await container.read(sessionControllerProvider).logout();

      expect(auth.logoutRemoteCalls, 1);
      expect(auth.clearCalls, 1);
      expect(push.unregisterCalls, 1);
      expect(push.suspended, isTrue);
    });

    test('expire は pcw に送らず、ログイン画面に案内を出す', () async {
      await container.read(sessionControllerProvider).expire();

      expect(auth.logoutRemoteCalls, 0);
      expect(auth.clearCalls, 1);
      expect(container.read(authProvider).user, isNull);
      expect(
          container.read(authProvider).notice, SessionController.expiredNotice);
    });

    test('アプリ更新後の強制ログアウトは pcw に送らず、再ログインの案内を出す', () async {
      await container.read(sessionControllerProvider).forceRelogin();

      expect(auth.logoutRemoteCalls, 0);
      expect(push.unregisterCalls, 1);
      expect(auth.clearCalls, 1);
      expect(
        container.read(authProvider).notice,
        SessionController.reloginNotice,
      );
    });

    test('logout 中に 401 が来て expire が呼ばれても、終了処理は 1 回だけ', () async {
      final gate = Completer<void>();
      push.unregisterGate = gate.future;
      final controller = container.read(sessionControllerProvider);

      final a = controller.logout();
      final b = controller.expire();
      gate.complete();
      await Future.wait([a, b]);

      expect(push.unregisterCalls, 1);
      expect(auth.clearCalls, 1);
    });

    test('FCM の解除で例外が出ても、ログイン情報は消えてログアウト状態になる', () async {
      push.throwOnUnregister = true;

      await container.read(sessionControllerProvider).logout();

      expect(auth.clearCalls, 1);
      expect(container.read(authProvider).user, isNull);
    });
  });

  test('本物の Provider の組み合わせで、401 からログアウトまで通しで動く', () async {
    SharedPreferences.setMockInitialValues(_loggedInPrefs);
    FlutterSecureStorage.setMockInitialValues({TokenStorage.key: '7|x'});
    final adapter = FakeHttpAdapter(
      (_) => (401, {'result': '0', 'error': 'unauthenticated'}),
    );
    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWith((ref) => ApiClient(
            tokenStorage: ref.watch(tokenStorageProvider),
            dio: fakeDio(adapter),
          )),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.notifier).initialized;
    expect(container.read(authProvider).user, isNotNull);

    // MyApp と同じく Provider の外で受けてログアウトする
    final done = Completer<void>();
    container.read(apiClientProvider).unauthorizedEvents.listen((_) async {
      await container.read(sessionControllerProvider).expire();
      done.complete();
    });
    try {
      await container.read(apiClientProvider).post(
        '/api/pcwMobileApi/shop/tanto/list',
        data: {},
      );
    } on DioException catch (_) {}
    await done.future;

    expect(container.read(authProvider).user, isNull);
    expect(await container.read(tokenStorageProvider).read(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sp_shop_syain_id'), isNull);
  });
}

class _FakePush implements PushNotificationService {
  int unregisterCalls = 0;
  bool suspended = false;
  bool throwOnUnregister = false;
  Future<void>? unregisterGate;

  @override
  void suspend() => suspended = true;

  @override
  void resume() => suspended = false;

  @override
  Future<void> unregisterToken() async {
    unregisterCalls++;
    if (unregisterGate != null) await unregisterGate;
    if (throwOnUnregister) throw StateError('fcm');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(ApiClient(), TokenStorage());

  int logoutRemoteCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> logoutRemote() async => logoutRemoteCalls++;

  @override
  Future<void> clearSession() async => clearCalls++;

  @override
  Future<SessionCheck> checkSession() async => SessionLoggedIn(User(
        shopSyainId: 12,
        shopSyainName: '担当 太郎',
        shopId: 3,
        loginId: 'a001',
      ));
}
