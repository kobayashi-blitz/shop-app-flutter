import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/dashboard/models/riyosya_syokai_item.dart';
import 'package:shop_app_flutter/features/dashboard/screens/riyosya_syokai_detail_screen.dart';

/// 利用者名の敬称「様」の代表画面テスト。
///
/// 一覧系は Riverpod プロバイダと API モックが要るため、`items` を直接渡せる
/// この詳細画面で「敬称が付く / 未登録時は付かない」を担保する。
void main() {
  RiyosyaSyokaiItem buildItem({required String name}) => RiyosyaSyokaiItem(
        primaryId: 1,
        riyosyaId: 345,
        riyosyaName: name,
        riyosyaKana: 'さとう ゆうこ',
        riyosyaPref: '大阪府',
        riyosyaJyusyo1: '堺市北区新金岡町3-1',
        riyosyaJyusyo2: '20-304',
        riyosyaPost: '591-8022',
        riyosyaTel: '090-9889-2131',
        riyosyaGender: '女',
        riyosyaBirthday: '1940/01/01',
        riyosyaKaigoRank: '要介護2',
        riyosyaKaigoKikanFrom: '2026/01/01',
        riyosyaKaigoKikanTo: '2026/12/31',
        riyosyaCareMan: '山本 花子',
        syohinName: 'シンフォニーSPスリム 花柄紺',
        rentalSincyokuFlag: 40,
        keiyakuDateFrom: '2026/08/05',
        keiyakuDateTo: '',
      );

  Future<void> pumpScreen(WidgetTester tester, {required String name}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RiyosyaSyokaiDetailScreen(items: [buildItem(name: name)]),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('AppBar の利用者名に敬称「様」が付く', (tester) async {
    await pumpScreen(tester, name: '佐藤 雄子');

    expect(find.text('佐藤 雄子 様'), findsOneWidget);
    // 敬称なしの生値は出ない。
    expect(find.text('佐藤 雄子'), findsNothing);
  });

  testWidgets('氏名未登録のときは敬称を付けずプレースホルダのまま', (tester) async {
    await pumpScreen(tester, name: '');

    expect(find.text('(氏名未登録)'), findsOneWidget);
    // 「(氏名未登録) 様」のような表示にはしない。
    expect(find.text('(氏名未登録) 様'), findsNothing);
  });
}
