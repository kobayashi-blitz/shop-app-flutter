# 介護ショップ担当者向けスマホアプリ

Flutter で作成された介護ショップ担当者向けのモバイルアプリケーションです。

## 機能

### 1. ログイン画面
- ログインID / メールアドレス入力
- パスワード入力（表示/非表示切り替え可能）
- ログインボタン
- ローディング表示
- エラーメッセージ表示
- トークンベースの認証（Laravel Sanctum / JWT）

### 2. ホーム画面（ダッシュボード）
- ログインユーザ情報表示
- 配送状況
  - 翌日配送予定件数
  - 配送完了（本日）件数
- 利用状況
  - 長期デモ商品件数
  - 入院保留件数
  - 契約利用者数
  - レンタル中商品数
  - レンタル売上（当月）
  - 当月新規受注件数
- プルダウンでリフレッシュ可能
- 各項目から詳細画面への遷移（現在はプレースホルダー）

## 技術スタック

- **Flutter**: 3.38.1
- **状態管理**: Riverpod (flutter_riverpod ^2.6.1)
- **HTTP通信**: Dio (^5.7.0)
- **ローカルストレージ**: shared_preferences (^2.3.3)
- **数値フォーマット**: intl (^0.19.0)

## プロジェクト構成

```
lib/
├── main.dart                          # アプリのエントリーポイント
├── core/                              # コア機能
│   ├── api/
│   │   └── api_client.dart           # API通信クライアント（Dio + インターセプター）
│   └── models/
│       ├── user.dart                  # ユーザモデル
│       └── login_response.dart        # ログインレスポンスモデル
├── features/
│   ├── auth/                          # 認証機能
│   │   ├── screens/
│   │   │   └── login_screen.dart     # ログイン画面
│   │   └── providers/
│   │       ├── auth_service.dart     # 認証サービス
│   │       └── auth_provider.dart    # 認証状態管理
│   └── dashboard/                     # ダッシュボード機能
│       ├── screens/
│       │   ├── dashboard_screen.dart # ダッシュボード画面
│       │   └── placeholder_screen.dart # プレースホルダー画面
│       ├── models/
│       │   └── dashboard_data.dart   # ダッシュボードデータモデル
│       └── providers/
│           ├── dashboard_service.dart # ダッシュボードサービス
│           └── dashboard_provider.dart # ダッシュボード状態管理
```

## セットアップ

### 前提条件

- Flutter SDK 3.35.4 以上
- Dart 3.10.0 以上
- Android Studio / Xcode（モバイルデバイスでの実行用）

### インストール手順

1. リポジトリをクローン

```bash
git clone https://github.com/kobayashi-blitz/shop-app-flutter.git
cd shop-app-flutter
```

2. 依存関係をインストール

```bash
flutter pub get
```

3. API エンドポイントの設定

`lib/core/api/api_client.dart` の `baseUrl` を環境に合わせて変更してください。

```dart
static const String baseUrl = 'http://localhost:8000';  // Laravel API のURL
```

4. アプリを実行

```bash
flutter run
```

## API 仕様

このアプリは、Laravel バックエンドの以下の API エンドポイントを使用します。

### 1. ログイン API

**エンドポイント**: `POST /api/login`

**リクエスト**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**レスポンス（成功時）**:
```json
{
  "token": "1|abcdefghijklmnopqrstuvwxyz",
  "user": {
    "id": 1,
    "name": "山田 太郎",
    "office_name": "〇〇介護サービス"
  }
}
```

**レスポンス（失敗時）**:
```json
{
  "message": "認証に失敗しました"
}
```

### 2. ダッシュボード API

**エンドポイント**: `GET /api/dashboard`

**ヘッダー**:
```
Authorization: Bearer {token}
```

**レスポンス**:
```json
{
  "user": {
    "name": "山田 太郎",
    "office_name": "〇〇介護サービス"
  },
  "delivery": {
    "tomorrow_scheduled_count": 12,
    "completed_today_count": 8
  },
  "usage": {
    "long_term_demo_count": 5,
    "hospital_on_hold_count": 3,
    "contract_user_count": 120,
    "rental_in_use_count": 340,
    "rental_sales_amount_month": 1234567,
    "new_orders_this_month_count": 18
  }
}
```

## Laravel バックエンドの実装例

### 必要な実装

1. **Laravel Sanctum のインストールと設定**
```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

2. **ユーザテーブルのマイグレーション**
```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->string('password'); // bcrypt でハッシュ化
    $table->string('office_name');
    $table->timestamps();
});
```

3. **ログインコントローラー**
```php
public function login(Request $request)
{
    $credentials = $request->validate([
        'email' => 'required|email',
        'password' => 'required',
    ]);

    if (!Auth::attempt($credentials)) {
        return response()->json([
            'message' => '認証に失敗しました'
        ], 401);
    }

    $user = Auth::user();
    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'token' => $token,
        'user' => [
            'id' => $user->id,
            'name' => $user->name,
            'office_name' => $user->office_name,
        ]
    ]);
}
```

4. **ダッシュボードコントローラー**
```php
public function dashboard(Request $request)
{
    $user = $request->user();
    
    // ここでデータベースから実際のデータを取得
    return response()->json([
        'user' => [
            'name' => $user->name,
            'office_name' => $user->office_name,
        ],
        'delivery' => [
            'tomorrow_scheduled_count' => 12,
            'completed_today_count' => 8,
        ],
        'usage' => [
            'long_term_demo_count' => 5,
            'hospital_on_hold_count' => 3,
            'contract_user_count' => 120,
            'rental_in_use_count' => 340,
            'rental_sales_amount_month' => 1234567,
            'new_orders_this_month_count' => 18,
        ]
    ]);
}
```

5. **ルート設定 (routes/api.php)**
```php
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'dashboard']);
});
```

## セキュリティ

- パスワードは平文で保存せず、Laravel の bcrypt でハッシュ化されます
- トークンは shared_preferences に安全に保存されます
- API 通信には Bearer トークン認証を使用します
- パスワードはアプリ側に保存されません

## 開発

### コード解析

```bash
flutter analyze
```

### テスト実行

```bash
flutter test
```

### ビルド

**Android**:
```bash
flutter build apk
```

**iOS**:
```bash
flutter build ios
```

## トラブルシューティング

### API 接続エラー

- `baseUrl` が正しく設定されているか確認してください
- Laravel サーバーが起動しているか確認してください
- Android エミュレータから localhost にアクセスする場合は `http://10.0.2.2:8000` を使用してください

### 認証エラー

- トークンが正しく保存されているか確認してください
- Laravel Sanctum が正しく設定されているか確認してください

## ライセンス

このプロジェクトは非公開です。

## 作成者

Shinya Kobayashi (kobayashi@blitz.vc)
