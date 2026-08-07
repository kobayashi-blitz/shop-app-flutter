import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/core/widgets/riyosya_name_text.dart';

/// 敬称「様」を氏名より 2pt 小さく描くウィジェットのテスト。
///
/// サイズを固定値ではなく氏名からの相対で決めているため、
/// 「明示スタイル」「祖先の DefaultTextStyle 継承」の両経路を固定しておく。
void main() {
  /// 描画された Text の TextSpan から、氏名スパンと敬称スパンを取り出す。
  ({TextSpan name, TextSpan honorific}) spansOf(WidgetTester tester) {
    final text = tester.widget<Text>(find.byType(Text));
    final root = text.textSpan! as TextSpan;
    final children = root.children!.cast<TextSpan>();
    expect(children.length, 2, reason: '氏名スパンと敬称スパンの 2 つ');
    return (name: children[0], honorific: children[1]);
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('style を明示したとき、敬称は氏名より 2pt 小さい', (tester) async {
    await pump(
      tester,
      const RiyosyaNameText(
        name: '佐藤 雄子',
        style: TextStyle(fontSize: 16),
      ),
    );

    final s = spansOf(tester);
    expect(s.name.text, '佐藤 雄子');
    expect(s.honorific.text, ' 様');
    expect(s.honorific.style!.fontSize, 14);
  });

  testWidgets('氏名 14pt なら敬称 12pt（配送詳細の情報行を想定）', (tester) async {
    await pump(
      tester,
      const RiyosyaNameText(
        name: '佐藤 雄子',
        style: TextStyle(fontSize: 14),
      ),
    );

    expect(spansOf(tester).honorific.style!.fontSize, 12);
  });

  testWidgets('style 未指定なら祖先の DefaultTextStyle から 2pt 引く', (tester) async {
    await pump(
      tester,
      const DefaultTextStyle(
        style: TextStyle(fontSize: 22),
        child: RiyosyaNameText(name: '佐藤 雄子'),
      ),
    );

    // AppBar タイトル (M3 titleLarge = 22pt) 相当の経路。
    expect(spansOf(tester).honorific.style!.fontSize, 20);
  });

  testWidgets('極端に小さい氏名でも敬称は下限を下回らない', (tester) async {
    await pump(
      tester,
      const RiyosyaNameText(
        name: '佐藤 雄子',
        style: TextStyle(fontSize: 8),
      ),
    );

    expect(
      spansOf(tester).honorific.style!.fontSize,
      RiyosyaNameText.minHonorificSize,
    );
  });

  testWidgets('前後の空白は落として敬称を付ける', (tester) async {
    await pump(
      tester,
      const RiyosyaNameText(
        name: '  佐藤 雄子  ',
        style: TextStyle(fontSize: 16),
      ),
    );

    expect(spansOf(tester).name.text, '佐藤 雄子');
    expect(find.text('佐藤 雄子 様'), findsOneWidget);
  });

  testWidgets('未登録のときは敬称を付けずプレースホルダだけを描く', (tester) async {
    await pump(
      tester,
      const RiyosyaNameText(
        name: '   ',
        emptyPlaceholder: '(氏名未登録)',
        style: TextStyle(fontSize: 16),
      ),
    );

    expect(find.text('(氏名未登録)'), findsOneWidget);
    expect(find.text('(氏名未登録) 様'), findsNothing);
    // 敬称スパンが無い＝素の Text で描かれている。
    expect(tester.widget<Text>(find.byType(Text)).textSpan, isNull);
  });

  testWidgets('emptyPlaceholder に空文字を渡すと何も出さない', (tester) async {
    await pump(
      tester,
      const RiyosyaNameText(
        name: '',
        emptyPlaceholder: '',
        style: TextStyle(fontSize: 16),
      ),
    );

    expect(find.text(''), findsOneWidget);
    expect(find.text(' 様'), findsNothing);
  });
}
