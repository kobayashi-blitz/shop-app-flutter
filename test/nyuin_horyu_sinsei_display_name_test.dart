import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/sinsei/screens/nyuin_horyu_sinsei_create_screen.dart';

/// 入院保留申請 作成画面のヘッダ利用者名（基底文字列）の組み立てテスト。
///
/// この画面だけ「ふりがな（氏名）」の併記形式なので、片方が欠けたときの
/// 組み立てが他画面と異なる。境界を固定しておく。
///
/// 敬称「様」の付与とフォントサイズ調整は `RiyosyaNameText` 側の責務なので、
/// ここでは基底文字列だけを検証する。
void main() {
  group('buildRiyosyaNameBase', () {
    test('氏名 + ふりがな → ふりがな（氏名）', () {
      expect(
        buildRiyosyaNameBase(name: '佐藤 雄子', kana: 'さとう ゆうこ'),
        'さとう ゆうこ（佐藤 雄子）',
      );
    });

    test('氏名のみ → 氏名', () {
      expect(buildRiyosyaNameBase(name: '佐藤 雄子', kana: ''), '佐藤 雄子');
    });

    test('ふりがなのみ → ふりがな（空の括弧を作らない）', () {
      expect(buildRiyosyaNameBase(name: '', kana: 'さとう ゆうこ'), 'さとう ゆうこ');
    });

    test('両方空 → 空文字', () {
      expect(buildRiyosyaNameBase(name: '', kana: ''), '');
    });

    test('空白のみは未登録扱いにする', () {
      expect(buildRiyosyaNameBase(name: '   ', kana: '  '), '');
    });

    test('前後の空白は落としてから組み立てる', () {
      expect(
        buildRiyosyaNameBase(name: '  佐藤 雄子 ', kana: ' さとう ゆうこ  '),
        'さとう ゆうこ（佐藤 雄子）',
      );
    });

    test('氏名が空白のみ・ふりがなありでも空の括弧を作らない', () {
      expect(buildRiyosyaNameBase(name: '  ', kana: 'さとう ゆうこ'), 'さとう ゆうこ');
    });
  });
}
