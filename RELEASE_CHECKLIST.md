# リリース準備チェックリスト（shop-app-flutter）

対象：**Android (Google Play) + iOS (App Store) 同時並行 / Push 通知込み / 内部・クローズドテスト → 本番**
バージョン：`1.0.0+1`（初回）／applicationId・bundle id：`com.careershop.shop_app_flutter`

凡例：所有者 **[あなた]**＝アカウント/コンソール/証明書系、**[私]**＝リポジトリのコード/設定（実装前に Plan Mode）、**[pcw]**＝基幹バックエンド側スレッド

> **Firebase 先方アカウントは未着** → クリティカルパス外。**テストは個人の `pcw-test` Firebase で実施**し、**本番提出の直前に差し替えるだけ**（→ フェーズ4）。

---

## フェーズ0：アカウント/プロジェクト整備（前提・他が依存）
- [x] Apple Developer アカウント取得 **[あなた]**
- [x] Google Play Developer アカウント取得 **[あなた]**
- [ ] `pcw-test` Firebase に **iOS アプリを追加**（bundle id 一致）→ `GoogleService-Info.plist` 取得 **[あなた]**
- [ ] **APNs 認証キー(.p8)** を Apple Developer で作成 → `pcw-test` Firebase の iOS アプリに登録 **[あなた]**
- [ ] Apple：App ID（bundle id）・配布証明書・プロビジョニングプロファイル **[あなた]**
- [ ] Google Play Console：アプリ作成（内部テストトラック） **[あなた]**
- [ ] **プライバシーポリシー URL** 用意（両ストア必須） **[あなた]**
- [ ] 本番 pcw：HTTPS エンドポイント／**push トークン登録・送信 API**（`HANDOFF_*` 参照） **[pcw]**

## フェーズ1：リポジトリのリリース対応
### Android
- [ ] release `signingConfig` 追加（`key.properties` 読込）／keystore はあなたが生成→私が wiring **[あなた/私]**
- [ ] `key.properties`・`*.jks/*.keystore` を `.gitignore` に **[私]**
- [ ] 本番 baseUrl の `--dart-define=API_BASE_URL=https://…` ビルド手順 **[私]**
### iOS
- [ ] `GoogleService-Info.plist` 配置（gitignore）＋ Firebase iOS 初期化 **[あなた/私]**
- [ ] Push capability・`aps-environment`・`UIBackgroundModes: remote-notification`・entitlements **[私]**
- [ ] iOS の通知許諾・フォアグラウンド表示・APNs トークン handling を `push_notification_service` に追加 **[私]**
### 共通
- [ ] bundle id / applicationId の最終確定（Firebase/Apple と一致） **[あなた/私]**
- [ ] アプリ表示名・アイコン・スプラッシュ **[あなた/私]**
- [ ] バージョン/ビルド番号の方針（`1.0.0+1` 起点） **[私]**

## フェーズ2：ビルド & 内部/クローズド配信
- [ ] Android `--release` aab → Play **内部テスト** にアップロード **[あなた/私]**
- [ ] iOS Archive → **TestFlight** にアップロード **[あなた/私]**
- [ ] 実機で Push（配送予定/配送完了）・ログイン・主要フロー確認（進行中の結合テストと合流） **[あなた]**

## フェーズ3：ストア掲載・コンプライアンス
### Google Play
- [ ] データセーフティ申告 / コンテンツレーティング **[あなた]**
- [ ] 掲載情報（説明・スクショ・アイコン・フィーチャーグラフィック） **[あなた]**
### App Store
- [ ] プライバシー栄養ラベル / 輸出コンプライアンス（暗号化）/ 審査情報（テスト用ログイン） **[あなた]**
- [ ] 掲載情報（説明・スクショ） **[あなた]**

## フェーズ4：本番切替 → 審査提出 → リリース
- [ ] **Firebase を先方アカウントへ差し替え**：`google-services.json`／`GoogleService-Info.plist`／APNs キー（同じ bundle id で登録） **[あなた]**
- [ ] 本番 pcw baseUrl（HTTPS）でリリースビルド **[私]**
- [ ] Android 本番トラックへ昇格 / iOS 本番審査提出 **[あなた]**
- [ ] 審査通過 → 公開 **[あなた]**

---

## 既知の注意点
- 現状 Android の release ビルドは **debug 鍵で署名**（`build.gradle.kts`）→ フェーズ1で要対応。
- iOS は Firebase/APNs **未設定** → フェーズ0/1 で構築。
- 秘匿物（`google-services.json`・`GoogleService-Info.plist`・`*.jks`・`key.properties`・APNs `.p8`・サービスアカウント鍵）は **コミットしない**（gitignore 済み/追加）。CI 導入時は secret 注入。
- `minSdk = 23`（firebase_core/messaging 要件）。
