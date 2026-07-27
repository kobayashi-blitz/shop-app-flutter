import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app_flutter/features/user/screens/my_page_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // authProvider は起動時に SharedPreferences から現在ユーザーを読む。
    // 空にしておけば user=null で安定（ネットワークは呼ばれない）。
    SharedPreferences.setMockInitialValues({});
    // _VersionTile の PackageInfo.fromPlatform() をモック。
    PackageInfo.setMockInitialValues(
      appName: 'shop_app_flutter',
      packageName: 'com.careershop.shop_app_flutter',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('情報セクションの各項目が表示される', (tester) async {
    await pumpScreen(tester);

    expect(find.text('マイページ'), findsOneWidget); // AppBar
    expect(find.text('プライバシーポリシー'), findsOneWidget);
    expect(find.text('利用規約'), findsOneWidget);
    expect(find.text('データ削除のお問い合わせ'), findsOneWidget);
    expect(find.text('バージョン'), findsOneWidget);
  });

  testWidgets('バージョンが version (build buildNumber) 形式で表示される', (tester) async {
    await pumpScreen(tester);

    expect(find.text('1.0.0 (build 1)'), findsOneWidget);
  });
}
