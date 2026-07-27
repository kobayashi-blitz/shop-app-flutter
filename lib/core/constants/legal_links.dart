/// 外部リンク・問い合わせ先の集約。
///
/// これらは機密情報ではないため定数直書きでよい（security.md 準拠）。
/// TODO(申請): 実値が確定次第、以下のプレースホルダを差し替える。
/// - プライバシーポリシー / 利用規約 の URL は Play/App Store の掲載 URL と同一を想定。
/// - アカウント発行・データ削除の窓口は運営の実連絡先に差し替える。
class LegalLinks {
  LegalLinks._();

  /// プライバシーポリシー（公開ホスト URL）。
  static const String privacyPolicyUrl =
      'https://example.com/privacy'; // TODO(申請): 実 URL

  /// 利用規約（公開ホスト URL）。
  static const String termsOfServiceUrl =
      'https://example.com/terms'; // TODO(申請): 実 URL

  /// アカウント発行の申請フォーム/案内ページ（外部ブラウザで開く）。
  static const String accountRequestUrl =
      'https://example.com/account-request'; // TODO(申請): 実 URL

  /// データ削除のお問い合わせ先メールアドレス（mailto で開く）。
  static const String dataDeletionEmail =
      'support@example.com'; // TODO(申請): 実アドレス
}
