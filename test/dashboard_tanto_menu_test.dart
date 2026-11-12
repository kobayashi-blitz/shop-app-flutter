import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app_flutter/features/dashboard/models/dashboard_data.dart';
import 'package:shop_app_flutter/features/dashboard/providers/dashboard_provider.dart';
import 'package:shop_app_flutter/features/dashboard/screens/dashboard_screen.dart';
import 'package:shop_app_flutter/features/tanto/providers/tanto_provider.dart';
import 'package:shop_app_flutter/features/tanto/screens/tanto_misettei_screen.dart';
import 'package:shop_app_flutter/features/tanto/screens/tanto_saitoroku_screen.dart';
import 'package:shop_app_flutter/features/tanto/tanto_labels.dart';

import 'helpers/fake_tanto_service.dart';

/// PRMT-31: 利用状況タブに再登録の 2 メニューがあり、各画面に移る。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pumpUsageTab(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dashboardProvider.overrideWith((ref) => _FakeDashboardNotifier(ref)),
        tantoServiceProvider.overrideWithValue(FakeTantoService([])),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('利用状況'));
    await tester.pumpAndSettle();
  }

  testWidgets('利用者再登録へ移る', (tester) async {
    await pumpUsageTab(tester);

    await tester.tap(find.text(TantoLabels.saitoroku));
    await tester.pumpAndSettle();

    expect(find.byType(TantoSaitorokuScreen), findsOneWidget);
  });

  testWidgets('担当者未設定登録へ移る', (tester) async {
    await pumpUsageTab(tester);

    await tester.tap(find.text(TantoLabels.misettei));
    await tester.pumpAndSettle();

    expect(find.byType(TantoMisetteiScreen), findsOneWidget);
  });
}

class _FakeDashboardNotifier extends DashboardNotifier {
  _FakeDashboardNotifier(super.ref);

  @override
  Future<void> loadDashboard() async {
    final today = DateTime(2026, 11, 9);
    state = DashboardState(
      data: DashboardData(
        user: UserInfo(name: '担当 自分', officeName: 'テスト店', shopName: 'テスト店'),
        delivery: DeliveryInfo(
          tomorrowScheduledCount: 0,
          completedTodayCount: 0,
          scheduledTargetDate: today,
          completedTargetDate: today,
        ),
        usage: UsageInfo(
          hospitalOnHoldCount: 0,
          contractUserCount: 0,
          rentalInUseCount: 0,
          rentalSalesAmountMonth: 0,
          newOrdersThisMonthCount: 0,
          oneMonthDemoCount: 0,
        ),
      ),
    );
  }
}
