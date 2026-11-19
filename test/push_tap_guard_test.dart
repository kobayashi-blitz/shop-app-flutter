import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/core/api/api_client.dart';
import 'package:shop_app_flutter/core/notifications/push_notification_service.dart';

/// PRMT-30: ログアウトの間・ログイン前は、通知タップで画面を開かない。
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('ログインしていなければ、通知タップで画面を移らない', (tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('ログイン画面')),
    ));
    final push = PushNotificationService(ApiClient())..suspend();

    pendingPushTap = {'type': 'haisou_kanryo'};
    push.processPendingTap();
    await tester.pumpAndSettle();

    expect(find.text('ログイン画面'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
  });
}
