/// 外部リンク・問い合わせ先の集約。
///
/// これらは機密情報ではないため定数直書きでよい（security.md 準拠）。
/// 利用規約は v1 では用意しないため定数を持たない（マイページの導線も非表示）。
/// 規約を用意したら定数と ListTile を復活させること。
class LegalLinks {
  LegalLinks._();

  /// プライバシーポリシー（公開ホスト URL）。
  /// Play Console / App Store Connect の掲載欄にも同一 URL を登録する。
  static const String privacyPolicyUrl =
      'https://primecare-west.com/privacy_policy.html';

  /// 問い合わせフォーム（外部ブラウザで開く）。
  ///
  /// アカウント発行の依頼とデータ削除の請求は、いずれもこのフォームで受け付ける。
  /// メーラー未設定の端末でも開けるよう mailto ではなく Web フォームにしている。
  /// プライバシーポリシー第11項の問い合わせ窓口の記載と一致させること
  /// （アプリの導線とポリシーが食い違うと審査で指摘される）。
  static const String contactFormUrl = 'https://primecare-west.com/contact/';
}
