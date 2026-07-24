# 設計: マイページのページ化＋情報セクション

- 日付: 2026-07-24
- ブランチ: `feat_mypage_screen`
- 対象: `shop-app-flutter`

## 目的 / 背景
現在の「マイページ」は AppBar 人型アイコン（`Icons.person`）から開く小さな `AlertDialog`
（`dashboard_screen.dart` の `_showProfileDialog`）で、店舗名・担当者名・「閉じる」だけ。
ストア申請に向けてプライバシーポリシー等の情報導線が必要になったため、フルページ化して
情報セクションを追加する。

## スコープ
- **含む**: プロフィール表示のページ化、情報セクション（ポリシー/規約/データ削除/バージョン）。
- **含まない**: ログアウトの移設（AppBar に据え置き）、通知設定等の将来機能、OSSライセンス表記。

## 画面 / 導線
- 新規 `MyPageScreen`（`Scaffold` フルページ）。
- 既存 AppBar の人型アイコン `onPressed` を `Navigator.push(MyPageScreen)` に変更。
- `_showProfileDialog`（AlertDialog）は撤去。
- ログアウトアイコンは現状どおり AppBar に残す。

## ページ構成
1. **プロフィールカード**: 店舗名（`user.shopName`）／担当者名（`user.shopSyainName` ＋「様」）。
   現状 `_showProfileDialog` と同じ値。空の場合は行を出さない。
2. **情報セクション**（`ListTile` 群）:
   - プライバシーポリシー → 外部ブラウザでホスト URL を開く（`url_launcher`, external）
   - 利用規約 → 同上
   - データ削除のお問い合わせ → `mailto:` でメール起動
   - アプリバージョン → 表示のみ（非タップ）

## 実装方針
- **リンク定数**: `lib/core/constants/legal_links.dart` に URL / メールを集約（プレースホルダ開始、実値は後日差替）。
  機密ではないためソース直書き可（security.md 準拠）。
- **リンク起動**: 既存 `url_launcher` を使用。失敗時は SnackBar 通知（`delivery_detail_screen.dart` の `_dialPhone` と同様の頑健な launch）。
- **バージョン**: `package_info_plus` を追加し `PackageInfo.fromPlatform()` で `version (build buildNumber)` を表示。
- レイヤー: `MyPageScreen` は表示のみ。データは既存 `authProvider` から取得（Dio 直叩きなし）。architecture.md 準拠。

## ファイル変更
- 追加: `lib/features/user/screens/my_page_screen.dart`
- 追加: `lib/core/constants/legal_links.dart`
- 変更: `lib/features/dashboard/screens/dashboard_screen.dart`（`_showProfileDialog` 撤去 → `MyPageScreen` 遷移）
- 変更: `pubspec.yaml` / `pubspec.lock`（`package_info_plus` 追加）

## テスト計画
- `fvm flutter analyze` エラー0 / `fvm flutter test` 既存パス維持。
- Widget テスト（可能なら）: `MyPageScreen` が店舗名・担当者名・各情報 ListTile・バージョン行を描画すること。
  `authProvider` を override した `ProviderScope` でポンプ。`url_launcher` は起動せず存在確認まで。
- 実機: 人型アイコン → マイページ遷移、各リンクの遷移/メール起動、バージョン表示、縦固定維持を目視。

## 申請 TODO（コード外・別管理）
- プライバシーポリシー／利用規約の**公開ホスト URL** 確保（Play/Apple 掲載必須。アプリ内リンク先にも使用）。
- データ削除の**連絡先メール**確定。
- 確定後、`legal_links.dart` のプレースホルダを実値へ差替。

## 非対象・留意
- Play Console / App Store のプライバシーポリシー URL 登録は本アプリ実装とは別要件（アプリ内リンクだけでは不足）。
- `package_info_plus` は Flutter Community の定番。pub.dev スコア・メンテ状況を追加時に確認（security.md 依存審査）。
