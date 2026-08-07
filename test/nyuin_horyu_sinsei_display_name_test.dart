import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/sinsei/screens/nyuin_horyu_sinsei_create_screen.dart';

/// 入院保留申請 作成画面のヘッダ利用者名の組み立てテスト。
///
/// この画面だけ「ふりがな（氏名）」の併記形式なので、敬称の位置と
/// 片方が欠けたときの組み立てが他画面と異なる。境界を固定しておく。
void main() {
  group('buildRiyosyaDisplayName', () {
    test('氏名 + ふりがな → ふりがな（氏名） 様', () {
      expect(
        buildRiyosyaDisplayName(name: '佐藤 雄子', kana: 'さとう ゆうこ'),
        'さとう ゆうこ（佐藤 雄子） 様',
      );
    });

    test('氏名のみ → 氏名 様', () {
      expect(buildRiyosyaDisplayName(name: '佐藤 雄子', kana: ''), '佐藤 雄子 様');
    });

    test('ふりがなのみ → ふりがな 様（空の括弧を作らない）', () {
      expect(buildRiyosyaDisplayName(name: '', kana: 'さとう ゆうこ'), 'さとう ゆうこ 様');
    });

    test('両方空 → 空文字（この画面は空欄表示を維持する）', () {
      expect(buildRiyosyaDisplayName(name: '', kana: ''), '');
    });

    test('空白のみは未登録扱いにする', () {
      expect(buildRiyosyaDisplayName(name: '   ', kana: '  '), '');
    });

    test('前後の空白は落としてから組み立てる', () {
      expect(
        buildRiyosyaDisplayName(name: '  佐藤 雄子 ', kana: ' さとう ゆうこ  '),
        'さとう ゆうこ（佐藤 雄子） 様',
      );
    });

    test('氏名が空白のみ・ふりがなありでも空の括弧を作らない', () {
      expect(buildRiyosyaDisplayName(name: '  ', kana: 'さとう ゆうこ'), 'さとう ゆうこ 様');
    });
  });
}
