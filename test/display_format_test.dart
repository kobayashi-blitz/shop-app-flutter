import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/core/utils/display_format.dart';

void main() {
  group('formatRiyosyaName', () {
    test('通常の氏名には敬称「様」を付ける', () {
      expect(formatRiyosyaName('佐藤 雄子'), '佐藤 雄子 様');
    });

    test('前後の空白は落としてから敬称を付ける', () {
      expect(formatRiyosyaName('  佐藤 雄子  '), '佐藤 雄子 様');
    });

    test('空文字は敬称を付けずプレースホルダを返す', () {
      expect(formatRiyosyaName(''), '-');
    });

    test('空白のみも未登録扱いにする', () {
      expect(formatRiyosyaName('   '), '-');
    });

    test('一覧カード用に空プレースホルダを指定できる', () {
      expect(formatRiyosyaName('', emptyPlaceholder: ''), '');
    });
  });

  group('formatPlaceDelivery', () {
    test('「代理店」は読み手 (代理店担当者) 向けに「御社」と読み替える', () {
      expect(formatPlaceDelivery('代理店'), '御社');
    });

    test('前後に空白があっても「御社」に変換する', () {
      expect(formatPlaceDelivery(' 代理店 '), '御社');
    });

    test('「利用者宅」は pcw の生値のまま出す', () {
      expect(formatPlaceDelivery('利用者宅'), '利用者宅');
    });

    test('「プライムケアウエスト」も生値のまま出す', () {
      expect(formatPlaceDelivery('プライムケアウエスト'), 'プライムケアウエスト');
    });

    test('部分一致では変換しない', () {
      expect(formatPlaceDelivery('代理店事務所'), '代理店事務所');
    });

    test('空文字はプレースホルダを返す', () {
      expect(formatPlaceDelivery(''), '-');
    });

    test('空白のみもプレースホルダを返す', () {
      expect(formatPlaceDelivery('  '), '-');
    });
  });
}
