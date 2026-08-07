/// 代理店担当者向けの表示整形ヘルパー。
///
/// pcw (基幹) が返す値そのものは変えず、**表示層だけ**で読み手に合わせた文言に寄せる。
/// モデル・Service 側は pcw の生値を保持したままにすること
/// (`.claude/rules/architecture.md`「キー名 / 値は pcw に合わせる」)。
library;

/// 利用者に付ける敬称。表示側で使い回すため定数化する。
const String riyosyaHonorific = '様';

/// 利用者名を trim して返す。未登録 (空文字 / 空白のみ) なら null。
///
/// 「利用者名が未登録か」の判定はここに一本化する。文字列版 [formatRiyosyaName] と
/// ウィジェット版 `RiyosyaNameText` で判定がズレると、「(氏名未登録) 様」のような
/// 表示が片方だけで起きうるため。
String? trimmedRiyosyaNameOrNull(String raw) {
  final name = raw.trim();
  return name.isEmpty ? null : name;
}

/// 利用者名に敬称「様」を付ける。
///
/// 未登録 (空文字 / 空白のみ) のときは敬称を付けず [emptyPlaceholder] を返す。
/// 一覧カードのように「空なら何も出さない」箇所では `emptyPlaceholder: ''` を渡す。
///
/// 敬称のフォントサイズを氏名より小さくしたい表示箇所では、この文字列版ではなく
/// `RiyosyaNameText` ウィジェットを使う (文字ごとにサイズを変えられないため)。
String formatRiyosyaName(String raw, {String emptyPlaceholder = '-'}) {
  final name = trimmedRiyosyaNameOrNull(raw);
  if (name == null) return emptyPlaceholder;
  return '$name $riyosyaHonorific';
}

/// 引渡し場所の表示名。
///
/// pcw は `nouhin_place` / `hikitori_place` の生値
/// (`利用者宅` / `代理店` / `プライムケアウエスト`) をそのまま返す。
/// このアプリの読み手は代理店担当者なので、`代理店` だけ `御社` と読み替える。
/// それ以外の値は生値のまま表示する (勝手な言い換えをしない)。
String formatPlaceDelivery(String raw, {String emptyPlaceholder = '-'}) {
  final place = raw.trim();
  if (place.isEmpty) return emptyPlaceholder;
  if (place == '代理店') return '御社';
  return place;
}
