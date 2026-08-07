import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/display_format.dart';

/// 利用者名 + 敬称「様」を表示する共通ウィジェット。
///
/// 敬称は氏名より [honorificSizeDelta] pt 小さく描く。単一の [Text] では
/// 文字ごとにサイズを変えられないため [Text.rich] で 2 スパンに分ける。
///
/// サイズは固定値ではなく**氏名からの相対**で決める。一覧カード (16pt) は敬称 14pt、
/// 配送詳細の情報行 (14pt) は 12pt、AppBar タイトル (M3 titleLarge = 22pt) は 20pt になり、
/// どの画面でも見た目の比率が揃う。
///
/// 氏名が未登録 (空文字 / 空白のみ) のときは敬称を付けず [emptyPlaceholder] だけを描く。
/// 「(氏名未登録) 様」のような表示にならないよう、判定は
/// [trimmedRiyosyaNameOrNull] に一本化している。
class RiyosyaNameText extends StatelessWidget {
  /// 利用者名。生値でよい (trim はこのウィジェット内で行う)。
  final String name;

  /// 氏名側のスタイル。省略時は祖先の [DefaultTextStyle] を使う。
  final TextStyle? style;

  /// 未登録時に表示する文字列。呼出元の従来挙動に合わせて渡す
  /// ('' / '(氏名未登録)' / '(利用者未設定)' / '-')。
  final String emptyPlaceholder;

  final TextOverflow? overflow;
  final int? maxLines;

  const RiyosyaNameText({
    super.key,
    required this.name,
    this.style,
    this.emptyPlaceholder = '-',
    this.overflow,
    this.maxLines,
  });

  /// 敬称を氏名より何 pt 小さくするか。
  static const double honorificSizeDelta = 2;

  /// 敬称がこれ以上小さくならないようにする下限。
  /// 氏名側が極端に小さい場合に敬称が潰れる/消えるのを防ぐ。
  static const double minHonorificSize = 8;

  @override
  Widget build(BuildContext context) {
    final trimmed = trimmedRiyosyaNameOrNull(name);
    if (trimmed == null) {
      return Text(
        emptyPlaceholder,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    // 明示スタイル > 祖先の DefaultTextStyle > Text の既定 (14) の順に解決する。
    // AppBar は title を DefaultTextStyle で包むので、そこからも拾える。
    final baseSize =
        style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14.0;
    final honorificSize =
        math.max(baseSize - honorificSizeDelta, minHonorificSize);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: trimmed),
          TextSpan(
            text: ' $riyosyaHonorific',
            style: TextStyle(fontSize: honorificSize),
          ),
        ],
      ),
      style: style,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
