import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app_flutter/features/auth/screens/login_screen.dart';

/// ログイン画面に自社サイトへの外部リンクを置かないことを守るテスト。
///
/// 「アカウント発行のお問い合わせ」ボタンが問い合わせフォームを開いていたため、
/// App Store の Guideline 3.1.1 (外部の購入導線とみなされた) で 2026-08-24 に
/// リジェクトされた。同じ導線を戻すと再びリジェクトされるので、ここで止める。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // authProvider は起動時に SharedPreferences から現在ユーザーを読む。
    // 空にしておけば user=null で安定（ネットワークは呼ばれない）。
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Apple に指摘された問い合わせ導線を出さない', (tester) async {
    await pumpScreen(tester);

    expect(find.text('アカウント発行のお問い合わせ'), findsNothing);
  });

  testWidgets('外部リンクを示すアイコンを出さない', (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.open_in_new), findsNothing);
  });

  testWidgets('アカウント発行の案内文は残す', (tester) async {
    await pumpScreen(tester);

    expect(
      find.text('ログインID・パスワードは運営より発行されます。'),
      findsOneWidget,
    );
  });
}
