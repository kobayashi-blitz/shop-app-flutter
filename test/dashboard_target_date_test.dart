import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app_flutter/features/dashboard/providers/dashboard_provider.dart';

/// 配送予定カード / 一覧の表示対象日の切替時刻テスト。
///
/// 切替は 19:55（端末ローカル時刻）。pcw の配送予定 Push 送信（20:00）より手前に置き、
/// 通知を受けて開いた時点で一覧が既に翌日を向いているようにしている。
/// 時刻境界の変更はデグレしても気付きにくいので、境界値を固定しておく。
void main() {
  /// 対象日の Y/M/D だけを比較する（戻り値の時刻部は呼出側で使われないため）。
  void expectYmd(DateTime actual, int year, int month, int day) {
    expect(
      [actual.year, actual.month, actual.day],
      [year, month, day],
    );
  }

  group('resolveScheduledTargetDate', () {
    test('00:00 は当日', () {
      expectYmd(
          resolveScheduledTargetDate(DateTime(2026, 8, 4, 0, 0)), 2026, 8, 4);
    });

    test('12:00 は当日', () {
      expectYmd(
          resolveScheduledTargetDate(DateTime(2026, 8, 4, 12, 0)), 2026, 8, 4);
    });

    test('19:54:59 はまだ当日（境界の直前）', () {
      expectYmd(resolveScheduledTargetDate(DateTime(2026, 8, 4, 19, 54, 59)),
          2026, 8, 4);
    });

    test('19:55:00 から翌日（境界そのもの）', () {
      expectYmd(resolveScheduledTargetDate(DateTime(2026, 8, 4, 19, 55, 0)),
          2026, 8, 5);
    });

    test('23:59 は翌日', () {
      expectYmd(
          resolveScheduledTargetDate(DateTime(2026, 8, 4, 23, 59)), 2026, 8, 5);
    });

    test('月末をまたぐ', () {
      expectYmd(
          resolveScheduledTargetDate(DateTime(2026, 8, 31, 20, 0)), 2026, 9, 1);
    });

    test('年末をまたぐ', () {
      expectYmd(resolveScheduledTargetDate(DateTime(2026, 12, 31, 20, 0)), 2027,
          1, 1);
    });

    test('うるう年の 2/28 → 2/29', () {
      expectYmd(resolveScheduledTargetDate(DateTime(2028, 2, 28, 20, 0)), 2028,
          2, 29);
    });
  });

  group('resolveCompletedTargetDate', () {
    test('時刻によらず常に当日', () {
      expectYmd(
          resolveCompletedTargetDate(DateTime(2026, 8, 4, 0, 0)), 2026, 8, 4);
      expectYmd(
          resolveCompletedTargetDate(DateTime(2026, 8, 4, 23, 59)), 2026, 8, 4);
    });

    test('時刻部は 0 に落とされる', () {
      final d = resolveCompletedTargetDate(DateTime(2026, 8, 4, 23, 59, 58));
      expect([d.hour, d.minute, d.second], [0, 0, 0]);
    });
  });
}
