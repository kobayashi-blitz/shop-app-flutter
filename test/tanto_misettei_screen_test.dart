import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/tanto/models/tanto_models.dart';
import 'package:shop_app_flutter/features/tanto/providers/tanto_provider.dart';
import 'package:shop_app_flutter/features/tanto/screens/tanto_misettei_screen.dart';

import 'helpers/fake_tanto_service.dart';

/// PRMT-34: 担当者未設定登録画面。
void main() {
  late FakeTantoService service;

  TantoRiyosyaItem jibun(int id) => tantoItem(
        id,
        shopSyainId: 7,
        rirekiId: id * 10,
        tantoSyainId: 7,
        tantoName: '担当 自分',
      );

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [tantoServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(home: TantoMisetteiScreen()),
    ));
    await tester.pumpAndSettle();
  }

  Finder checkboxOf(int id) => find.descendant(
        of: find.byKey(ValueKey('tanto-$id')),
        matching: find.byType(Checkbox),
      );

  bool? valueOf(WidgetTester tester, int id) =>
      tester.widget<Checkbox>(checkboxOf(id)).value;

  Future<void> uncheck(WidgetTester tester, int id) async {
    await tester.ensureVisible(checkboxOf(id));
    await tester.tap(checkboxOf(id));
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.textContaining('担当者未設定にする（'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('未設定にする'));
    await tester.pumpAndSettle();
  }

  testWidgets('自分の担当だけを取り、初めは全員チェック済み', (tester) async {
    service = FakeTantoService([jibun(1), jibun(2)]);
    await pump(tester);

    expect(service.listCalls.first.jotai, TantoJotai.jibun);
    expect(valueOf(tester, 1), isTrue);
    expect(valueOf(tester, 2), isTrue);
    expect(find.text('担当者未設定にする（0人）'), findsOneWidget);
  });

  testWidgets('チェックを外した人だけを、一覧の値のまま送る', (tester) async {
    service = FakeTantoService([jibun(1), jibun(2), jibun(3)]);
    await pump(tester);

    await uncheck(tester, 2);
    await submit(tester);

    expect(service.misetteiCalls.single, [
      {'riyosya_id': 2, 'shop_syain_id': 7, 'rireki_id': 20},
    ]);
    expect(find.text('1人を担当者未設定にしました。'), findsOneWidget);
  });

  testWidgets('ほかの担当者に変わった人 (422 owner) は外して取り直す', (tester) async {
    service = FakeTantoService([jibun(1), jibun(2)])
      ..nextSubmitError = const TantoApiException(
        TantoErrorKind.invalid,
        reason: 'owner',
        riyosyaIds: [1],
      );
    await pump(tester);

    await uncheck(tester, 1);
    await uncheck(tester, 2);
    final before = service.listCalls.length;
    await submit(tester);

    expect(service.listCalls.length, greaterThan(before));
    expect(find.textContaining('ほかの担当者に変わった利用者が含まれています'), findsOneWidget);
    // 1 は外れて (チェック済みに戻り)、2 は外したまま
    expect(valueOf(tester, 1), isTrue);
    expect(valueOf(tester, 2), isFalse);
  });

  testWidgets('競合 (409) のあと、競合した人だけ外して取り直す', (tester) async {
    service = FakeTantoService([jibun(1), jibun(2)])
      ..nextSubmitError = const TantoApiException(
        TantoErrorKind.conflict,
        riyosyaIds: [2],
      );
    await pump(tester);

    await uncheck(tester, 1);
    await uncheck(tester, 2);
    await submit(tester);

    expect(valueOf(tester, 1), isFalse);
    expect(valueOf(tester, 2), isTrue);
    expect(find.text('担当者未設定にする（1人）'), findsOneWidget);
  });
}
