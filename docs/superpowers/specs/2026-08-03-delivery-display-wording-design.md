# 配送予定/完了 画面の表示文言修正 設計

- 日付: 2026-08-03
- 対象: 配送予定 詳細 / 配送完了 詳細、配送予定 / 配送完了 一覧カード
- 起票: 先方からのアプリ修正依頼（画面キャプチャへの赤入れ）

## 背景

配送予定 詳細画面のキャプチャに対して、以下 3 点の修正依頼を受けた。

1. 利用者名に敬称「様」を付ける
2. 引渡し場所の「代理店」を「御社」と表示する
3. 担当（配送員）の電話番号テキストを画面に出さない。「発信」ボタンは残す

いずれも **表示文言のみ** の変更であり、pcw（基幹）が返す値そのものは変更しない。

## 現状

| 項目 | 実装 | 表示値 |
|---|---|---|
| 利用者名 | `delivery_detail_screen.dart:181` | `d.riyosyaName` を素通し（空なら `-`） |
| 引渡し場所 | `delivery_detail_screen.dart:189` | `d.placeDelivery` を素通し（空なら `-`） |
| 配送員 電話番号 | `delivery_detail_screen.dart:293` → `_CallablePhoneRow` | 「電話番号 090-…」行 + その下に「発信」ボタン |
| 一覧 利用者名 | `delivery_list_tile.dart:99` | `item.customerName` を素通し（空なら空表示） |
| 一覧 引渡し場所 | `delivery_list_tile.dart:118` | `item.placeDelivery` を素通し（空なら `-`） |

pcw 側は `nouhin_place` / `hikitori_place` の生値をそのまま `place_delivery` として返す
（`app/Http/Controllers/Api/shop/RiyojokyoApiController.php`、ブランチ `fix/shop-haisou-detail-kubun-mapping`）。
取りうる値は `利用者宅` / `代理店` / `プライムケアウエスト` および空。

なお pcw の帳票側 (`app/Models/r03_rental_order_tbl.php:85-94`) では
`利用者宅 → ご利用者宅` / `代理店 → 貴社事務所` / `プライムケアウエスト → プライムケアウエスト(支店名)`
という別の丁寧表記マッピングが存在する。今回はこれには揃えず、依頼どおり「御社」を採用する。

## 決定事項

先方確認の結果:

- **適用範囲**: 詳細画面だけでなく **一覧カードにも適用**する。同じ値が両画面に出るため、片方だけ直すと表記が食い違う。
- **引渡し場所の変換**: `代理店 → 御社` のみ。`利用者宅` / `プライムケアウエスト` は pcw の生値のまま出す（今回の依頼範囲外を勝手に広げない）。
- **電話番号**: 番号テキスト行のみ非表示。「発信」ボタンは残す（番号は見せずに発信はできる）。

## 設計

### 1. 表示整形ヘルパー（新規）

`lib/core/utils/display_format.dart`

```dart
/// 利用者名に敬称「様」を付ける。未登録時は敬称を付けない。
String formatRiyosyaName(String raw, {String emptyPlaceholder = '-'});

/// 引渡し場所の表示名。pcw の nouhin_place 生値のうち「代理店」だけ、
/// 当アプリの読み手（代理店担当者）向けに「御社」と読み替える。
/// それ以外（利用者宅 / プライムケアウエスト 等）は生値のまま。
String formatPlaceDelivery(String raw, {String emptyPlaceholder = '-'});
```

仕様:

- 入力は前後空白を `trim()` してから判定する。pcw から `'代理店 '` のような値が来ても取りこぼさない。
- `formatRiyosyaName`: trim 後が空なら `emptyPlaceholder` を返す（敬称は付けない）。それ以外は `'<名前> 様'`。
- `formatPlaceDelivery`: trim 後が空なら `emptyPlaceholder`。trim 後が `代理店` と完全一致なら `御社`。それ以外は trim 後の値をそのまま返す。
- 純関数。Widget / Provider に依存しない。

配置理由: `lib/core/utils/` は既存（`external_launch.dart` / `pdf_opener.dart`）で、複数 feature から使う副作用なしヘルパーの置き場として確立している。`architecture.md` の「features 同士で import し合わない」も満たす。

### 2. 適用箇所

| ファイル | 行 | 変更 |
|---|---|---|
| `lib/features/dashboard/screens/delivery_detail_screen.dart` | 181 | `value: formatRiyosyaName(d.riyosyaName)` |
| `lib/features/dashboard/screens/delivery_detail_screen.dart` | 189 | `value: formatPlaceDelivery(d.placeDelivery)` |
| `lib/features/dashboard/widgets/delivery_list_tile.dart` | 99 | `formatRiyosyaName(item.customerName, emptyPlaceholder: '')` |
| `lib/features/dashboard/widgets/delivery_list_tile.dart` | 118 | `formatPlaceDelivery(item.placeDelivery)` |

一覧カードの利用者名は現状「空なら空文字を表示」なので、`emptyPlaceholder: ''` を渡して既存挙動を維持する
（ここだけ `-` に変えると無関係な見た目変更になるため）。

### 3. 電話番号の非表示

`delivery_detail_screen.dart` の `_CallablePhoneRow` を `_CallButton` に置き換える。

- 「電話番号」ラベル + 番号テキストの `Row` を削除する（赤入れはラベル行ごと消されている）。
- 「発信」ボタン（緑・`Icons.call`）は現状のスタイルのまま残す。
- 電話番号は `_dialPhone` に渡すためウィジェット内部に保持するだけで、描画には使わない。
- `_buildTantoCard` 側の `if (d.haisouTantoTel.isNotEmpty)` ガードは維持する。番号が無ければ発信ボタンも出さない（押しても何も起きないボタンを見せない）。
- ボタン単体になるため、番号行との間隔用 `SizedBox(height: 8)` は不要になり削除する。

### 4. テスト

- `test/display_format_test.dart`（新規）
  - `formatRiyosyaName`: 通常名 → `様` 付き / 空文字 → `-` / 空白のみ → `-` / `emptyPlaceholder: ''` 指定時 → 空文字
  - `formatPlaceDelivery`: `代理店` → `御社` / `代理店 `（末尾空白）→ `御社` / `利用者宅` → `利用者宅`（素通し）/ `プライムケアウエスト` → 素通し / 空 → `-`
- `test/delivery_detail_screen_test.dart`（新規）
  - `ProviderScope` で `haisouDetailProvider(key)` を override し、`riyosyaName: '佐藤 雄子'` / `placeDelivery: '代理店'` / `haisouTantoTel: '090-9999-0000'` のダミー `HaisouDetail` を返す
  - 検証: `佐藤 雄子 様` が表示される / `御社` が表示される / **配送員の番号 `090-9999-0000` が画面に存在しない** / `発信` ボタンが存在する
  - 注: 「電話番号」ラベルは **利用者カード側に残る**（消すのは担当カードの配送員番号だけ）ため、
    `find.text('電話番号')` は `findsOneWidget`、利用者の番号は表示されたままであることも併せて検証する
  - 番号未登録 (`haisouTantoTel: ''`) のとき発信ボタンが出ないケースも検証する
  - `ElevatedButton.icon` は private サブクラスを返し `find.byType(ElevatedButton)` で拾えないため、
    ボタンの検出はラベル `発信` と `Icons.call` で行う
  - `_TantoPhoto` は URL 空でプレースホルダになるようダミーを空文字にし、`Image.network` をテストで叩かない

既存の `test/haisou_detail_test.dart` / `test/haisou_detail_service_test.dart` はモデル・通信層のテストで、
今回モデルもレスポンス契約も変更しないため影響なし。

### 5. スコープ外

- pcw（基幹）側の変更はしない。`place_delivery` は生値を返し続ける。
- `利用者宅` / `プライムケアウエスト` の丁寧表記化はしない。
- 利用者照会など他画面の敬称表記には手を入れない（`riyosya_syokai_detail_screen.dart:18` は既に `様` 付き）。

## 検証手順

本プロジェクトは fvm で Flutter 3.29.3 に固定されている (`.fvmrc`)。
シェル既定の `flutter` は 3.22.2 で `firebase_core` の SDK 制約を満たさず `pub get` が失敗するため、
**必ず `fvm flutter` を使う**こと。

1. `fvm flutter analyze`
2. `fvm flutter test`
3. 実機/エミュレータで配送予定一覧 → 詳細を開き、3 点の表示を目視確認

## リスク

低。表示層のみの変更で、API リクエスト/レスポンス、状態管理、遷移には触れない。
唯一の挙動変更は「配送員の電話番号が画面から読み取れなくなる」点だが、発信ボタンは残るため運用上の発信手段は維持される。
