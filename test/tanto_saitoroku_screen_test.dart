import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/tanto/models/tanto_models.dart';
import 'package:shop_app_flutter/features/tanto/providers/tanto_provider.dart';
import 'package:shop_app_flutter/features/tanto/screens/tanto_saitoroku_screen.dart';

import 'helpers/fake_tanto_service.dart';

/// PRMT-32・33: 利用者再登録画面。
void main() {
  late FakeTantoService service;

  Future<void> pump(WidgetTester tester, {int maxSelection = 500}) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [tantoServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        home: TantoSaitorokuScreen(maxSelection: maxSelection),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder checkboxOf(int id) => find.descendant(
        of: find.byKey(ValueKey('tanto-$id')),
        matching: find.byType(Checkbox),
      );

  bool? valueOf(WidgetTester tester, int id) =>
      tester.widget<Checkbox>(checkboxOf(id)).value;

  Future<void> tapCheck(WidgetTester tester, int id) async {
    await tester.ensureVisible(checkboxOf(id));
    await tester.tap(checkboxOf(id));
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.textContaining('登録（'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録する'));
  }

  test('件数から最後のページを計算する', () {
    expect(
      const TantoListResult(
        items: [],
        total: 31,
        page: 1,
        perPage: 30,
        syainList: [],
        jibunSyainId: 1,
      ).totalPages,
      2,
    );
  });

  testWidgets('自分が担当している利用者は、チェック済みのまま外せず案内が出る', (tester) async {
    service = FakeTantoService([
      tantoItem(1,
          shopSyainId: 7, rirekiId: 10, tantoSyainId: 7, tantoName: '担当 自分'),
      tantoItem(2),
    ]);
    await pump(tester);

    final jibun = tester.widget<Checkbox>(checkboxOf(1));
    expect(jibun.value, isTrue);
    expect(jibun.onChanged, isNull);
    expect(find.text('担当を外すには担当者未設定登録へ'), findsOneWidget);
    expect(valueOf(tester, 2), isFalse);
  });

  testWidgets('担当者がいない利用者は「担当者未設定」と出す', (tester) async {
    service = FakeTantoService([tantoItem(1, shopSyainId: 99)]);
    await pump(tester);

    expect(find.text('担当者未設定'), findsWidgets);
  });

  testWidgets('ページを移っても選択が残り、両方のページの人を送る', (tester) async {
    service = FakeTantoService(List.generate(31, (i) => tantoItem(i + 1)));
    await pump(tester);

    await tapCheck(tester, 1);
    await tester.tap(find.byTooltip('次のページ'));
    await tester.pumpAndSettle();
    await tapCheck(tester, 31);
    await tester.tap(find.byTooltip('前のページ'));
    await tester.pumpAndSettle();

    expect(valueOf(tester, 1), isTrue);
    expect(find.text('登録（2人）'), findsOneWidget);

    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      service.saitorokuCalls.single.map((e) => e['riyosya_id']),
      [1, 31],
    );
  });

  testWidgets('確認ダイアログに、登録する人数と引き継ぐ人数を出す', (tester) async {
    service = FakeTantoService([
      tantoItem(1, shopSyainId: 8, tantoSyainId: 8, tantoName: '担当 他人'),
      tantoItem(2),
      tantoItem(3),
    ]);
    await pump(tester);

    for (final id in [1, 2, 3]) {
      await tapCheck(tester, id);
    }
    await tester.tap(find.text('登録（3人）'));
    await tester.pumpAndSettle();

    expect(find.text('自分の担当に登録：3人'), findsOneWidget);
    expect(find.text('うち、ほかの担当者から引き継ぎ：1人'), findsOneWidget);
    expect(find.textContaining('担当者が変わります'), findsOneWidget);
  });

  testWidgets('送信中は登録ボタンを押せない', (tester) async {
    service = FakeTantoService([tantoItem(1)])..submitGate = Completer<void>();
    await pump(tester);

    await tapCheck(tester, 1);
    await submit(tester);
    // ダイアログが閉じ切るまで進める (送信中のスピナーが回り続けるので settle はしない)
    await tester.pump(const Duration(milliseconds: 500));

    final button = tester.widget<FilledButton>(find.ancestor(
      of: find.byType(CircularProgressIndicator),
      matching: find.byType(FilledButton),
    ));
    expect(button.onPressed, isNull);

    service.submitGate!.complete();
    await tester.pumpAndSettle();
    expect(service.saitorokuCalls, hasLength(1));
  });

  testWidgets('競合 (409) のあと、競合した人だけ選択から外れ、一覧を取り直す', (tester) async {
    service = FakeTantoService([tantoItem(1), tantoItem(2)])
      ..nextSubmitError = const TantoApiException(
        TantoErrorKind.conflict,
        riyosyaIds: [1],
      );
    await pump(tester);

    await tapCheck(tester, 1);
    await tapCheck(tester, 2);
    final listCallsBefore = service.listCalls.length;
    await submit(tester);
    await tester.pumpAndSettle();

    expect(service.listCalls.length, greaterThan(listCallsBefore));
    expect(valueOf(tester, 1), isFalse);
    expect(valueOf(tester, 2), isTrue);
    expect(find.textContaining('対象：利用者1 様'), findsOneWidget);
  });

  testWidgets('指定できない利用者 (422) は選択から外れる', (tester) async {
    service = FakeTantoService([tantoItem(1), tantoItem(2)])
      ..nextSubmitError = const TantoApiException(
        TantoErrorKind.invalid,
        reason: 'riyosya',
        riyosyaIds: [2],
      );
    await pump(tester);

    await tapCheck(tester, 1);
    await tapCheck(tester, 2);
    await submit(tester);
    await tester.pumpAndSettle();

    expect(valueOf(tester, 1), isTrue);
    expect(valueOf(tester, 2), isFalse);
  });

  testWidgets('混み合い (503) のときは選択を残し、もう一度送れる', (tester) async {
    service = FakeTantoService([tantoItem(1)])
      ..nextSubmitError = const TantoApiException(TantoErrorKind.retry);
    await pump(tester);

    await tapCheck(tester, 1);
    await submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('混み合っています。もう一度お試しください。'), findsOneWidget);
    expect(valueOf(tester, 1), isTrue);
    expect(find.text('登録（1人）'), findsOneWidget);
  });

  testWidgets('一覧を取り直しても、選んだ時点の担当者 ID・履歴 ID を送る', (tester) async {
    service = FakeTantoService([tantoItem(1, shopSyainId: 5, rirekiId: 50)]);
    await pump(tester);

    await tapCheck(tester, 1);
    // ほかの所で担当者が変わり、取り直した一覧の値が新しくなった
    service.rows = [tantoItem(1, shopSyainId: 6, rirekiId: 60)];
    await tester.tap(find.byTooltip('検索'));
    await tester.pumpAndSettle();
    await submit(tester);
    await tester.pumpAndSettle();

    expect(service.saitorokuCalls.single.single, {
      'riyosya_id': 1,
      'shop_syain_id': 5,
      'rireki_id': 50,
    });
  });

  testWidgets('上限を超えて選べない', (tester) async {
    service = FakeTantoService([tantoItem(1), tantoItem(2), tantoItem(3)]);
    await pump(tester, maxSelection: 2);

    await tapCheck(tester, 1);
    await tapCheck(tester, 2);
    await tapCheck(tester, 3);

    expect(valueOf(tester, 3), isFalse);
    expect(find.text('一度に登録できるのは2人までです。'), findsOneWidget);
  });

  testWidgets('登録で最後のページが空になったら、前のページに戻る', (tester) async {
    service = FakeTantoService(List.generate(31, (i) => tantoItem(i + 1)));
    await pump(tester);

    await tester.tap(find.byTooltip('次のページ'));
    await tester.pumpAndSettle();
    await tapCheck(tester, 31);
    // 登録すると 31 人目は一覧から消える (例: 自分の担当だけの絞り込み)
    service.submitGate = Completer<void>();
    await submit(tester);
    service.rows = service.rows.sublist(0, 30);
    service.submitGate!.complete();
    await tester.pumpAndSettle();

    expect(service.listCalls.last.page, 1);
    expect(find.byKey(const ValueKey('tanto-1')), findsOneWidget);
  });
}
