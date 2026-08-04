import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/dashboard/models/haisou_detail.dart';
import 'package:shop_app_flutter/features/dashboard/models/tomorrow_delivery_item.dart';
import 'package:shop_app_flutter/features/dashboard/providers/haisou_detail_provider.dart';
import 'package:shop_app_flutter/features/dashboard/screens/delivery_detail_screen.dart';

/// 先方の修正依頼 (2026-08-03) に対する回帰テスト。
/// - 利用者名に「様」を付ける
/// - 引渡し場所の「代理店」を「御社」と表示する
/// - 配送員の電話番号を画面に出さない (発信ボタンは残す)
void main() {
  final item = TomorrowDeliveryItem(
    id: 711328,
    haisouId: 5001,
    type: 'rental',
    kubun: 'レンタル',
    kubunCode: '1',
    customerName: '佐藤 雄子',
    deliveryDate: '2026/08/03',
    deliveryTime: '18:30',
    itemName: 'シンフォニーSPスリム 花柄紺',
    placeDelivery: '代理店',
  );

  HaisouDetail buildDetail() => HaisouDetail(
        haisouId: 5001,
        kubun: '1',
        receptionNo: '受付No.711328',
        contractStartDate: '2026/08/05',
        sitenName: '松原センター',
        riyosyaName: '佐藤 雄子',
        // 利用者の電話番号は従来どおり表示する (非表示にするのは配送員の番号だけ)。
        riyosyaTel: '090-9889-2131',
        riyosyaAddress: '大阪府堺市北区新金岡町3-1-20-304',
        placeDelivery: '代理店',
        hikkosiAddress: '',
        haisouTantoName: '北野 貴士',
        haisouTantoTel: '090-9999-0000',
        // 空にして Image.network をテストで叩かせない (プレースホルダ表示になる)。
        haisouTantoPhotoUrl: '',
        agentTantoName: '',
        footerComment: '',
        isDelivered: false,
        products: const [],
      );

  Future<void> pumpScreen(
    WidgetTester tester, {
    required HaisouDetail detail,
  }) async {
    final key = (
      haisouId: item.haisouId,
      orderId: item.id,
      kubun: item.kubunCode,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          haisouDetailProvider(key).overrideWith((ref) async => detail),
        ],
        child: MaterialApp(
          home: DeliveryDetailScreen(
            item: item,
            mode: DeliveryDetailMode.scheduled,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('利用者名に敬称「様」が付く', (tester) async {
    await pumpScreen(tester, detail: buildDetail());

    expect(find.text('佐藤 雄子 様'), findsOneWidget);
    // 敬称なしの生値は出ない。
    expect(find.text('佐藤 雄子'), findsNothing);
  });

  testWidgets('引渡し場所の「代理店」が「御社」と表示される', (tester) async {
    await pumpScreen(tester, detail: buildDetail());

    expect(find.text('御社'), findsOneWidget);
    expect(find.text('代理店'), findsNothing);
  });

  testWidgets('配送員の電話番号は表示せず、発信ボタンだけ残る', (tester) async {
    await pumpScreen(tester, detail: buildDetail());

    expect(find.text('北野 貴士'), findsOneWidget);
    // 配送員の番号は画面に出さない。
    expect(find.text('090-9999-0000'), findsNothing);
    // 「電話番号」ラベルは利用者カードの 1 件だけ (担当カードからは消える)。
    expect(find.text('電話番号'), findsOneWidget);
    expect(find.text('090-9889-2131'), findsOneWidget);
    // 発信ボタンは残る。
    // `ElevatedButton.icon` は private サブクラスを返すため byType では拾えない。
    // ラベルと電話アイコンで検出する。
    expect(find.text('発信'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
  });

  testWidgets('配送員の電話番号が未登録なら発信ボタンも出さない', (tester) async {
    final detail = buildDetail();
    await pumpScreen(
      tester,
      detail: HaisouDetail(
        haisouId: detail.haisouId,
        kubun: detail.kubun,
        receptionNo: detail.receptionNo,
        contractStartDate: detail.contractStartDate,
        sitenName: detail.sitenName,
        riyosyaName: detail.riyosyaName,
        riyosyaTel: detail.riyosyaTel,
        riyosyaAddress: detail.riyosyaAddress,
        placeDelivery: detail.placeDelivery,
        hikkosiAddress: detail.hikkosiAddress,
        haisouTantoName: detail.haisouTantoName,
        haisouTantoTel: '',
        haisouTantoPhotoUrl: detail.haisouTantoPhotoUrl,
        agentTantoName: detail.agentTantoName,
        footerComment: detail.footerComment,
        isDelivered: detail.isDelivered,
        products: detail.products,
      ),
    );

    expect(find.text('北野 貴士'), findsOneWidget);
    expect(find.text('発信'), findsNothing);
    expect(find.byIcon(Icons.call), findsNothing);
  });
}
