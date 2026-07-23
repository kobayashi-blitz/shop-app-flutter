class TomorrowDeliveryItem {
  /// カードの一意キー = 受付ID (`primary_id` = hs3.tbl_id)。
  /// 詳細 API (`haisou/detail`) の `order_id` にもこの値を送る。
  /// 合積み配送では複数カードが同じ [haisouId] を持つため、識別はこの受付IDで行う。
  final int id;
  final int haisouId; // 配送ID (hs1.haisou_id)。詳細 API の `haisou_id` に送る。
  final String type; // rental / sale  (kubunCode から派生、UI 色分岐用)
  final String kubun; // 日本語ラベル（レンタル / 返却 / 汎用配送 / 預入引取 / 預入返却）
  final String kubunCode; // 生の区分コード ('1'〜'5')。詳細 API の `kubun` に送る。
  final String customerName; // 利用者名
  final String deliveryDate; // 納品希望日 (YYYY/MM/DD)
  final String deliveryTime; // 納品時間（空文字の場合もあり）
  final String itemName; // 商品名
  final String
      placeDelivery; // 引渡し場所 (pcw `*.nouhin_place` / `r31.hikitori_place`)

  TomorrowDeliveryItem({
    required this.id,
    required this.haisouId,
    required this.type,
    required this.kubun,
    required this.kubunCode,
    required this.customerName,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.itemName,
    required this.placeDelivery,
  });

  TomorrowDeliveryItem copyWith({
    int? id,
    int? haisouId,
    String? type,
    String? kubun,
    String? kubunCode,
    String? customerName,
    String? deliveryDate,
    String? deliveryTime,
    String? itemName,
    String? placeDelivery,
  }) {
    return TomorrowDeliveryItem(
      id: id ?? this.id,
      haisouId: haisouId ?? this.haisouId,
      type: type ?? this.type,
      kubun: kubun ?? this.kubun,
      kubunCode: kubunCode ?? this.kubunCode,
      customerName: customerName ?? this.customerName,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      itemName: itemName ?? this.itemName,
      placeDelivery: placeDelivery ?? this.placeDelivery,
    );
  }

  /// pcw `haisouyotei/syosai` / `haisou-kanryo/syosai` レスポンスの 1 要素から構築する。
  ///
  /// サーバは **受付単位** で集約（PR #3036）し、1 受付 = 1 行で返す。合積み配送は
  /// 同じ `haisou_id` を持つ複数行になるため、カード識別には受付ID (`primary_id`) を使う。
  /// - `primary_id` (= hs3.tbl_id, 受付ID) → [id]（カードキー / 詳細 API の order_id）
  /// - `haisou_id` (= hs1.haisou_id, 配送ID) → [haisouId]（詳細 API の haisou_id）
  /// - `kubun` (生コード '1'〜'5') → [kubunCode]（詳細 API の kubun）。表示ラベルは別途 [kubun]。
  ///
  /// 一覧表示に必要な項目のみ保持。利用者住所と配送担当者名は **詳細画面 (HaisouDetail) 経由** で取得し、
  /// 一覧モデルには持たない (責務分離)。
  factory TomorrowDeliveryItem.fromJson(Map<String, dynamic> json) {
    final kubunRaw = (json['kubun'] ?? '').toString();

    return TomorrowDeliveryItem(
      id: _toInt(json['primary_id']),
      haisouId: _toInt(json['haisou_id']),
      type: _kubunToType(kubunRaw),
      kubun: _kubunToLabel(kubunRaw),
      kubunCode: kubunRaw,
      customerName: (json['riyosya_name'] ?? '') as String,
      deliveryDate: (json['kibou_date'] ?? '') as String,
      deliveryTime: _pickDeliveryTime(json),
      itemName: _pickItemName(json),
      placeDelivery: (json['place_delivery'] ?? '') as String,
    );
  }

  /// pcw のレスポンスは int / 数値文字列が混在しうるため吸収する。欠損・不正は 0。
  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  /// kubun ('1'〜'5') → 色分岐用 type。汎用配送 (kubun=3) のみ 'sale' 緑バッジ、
  /// それ以外 (レンタル/返却/預入) は 'rental' 青バッジ。
  static String _kubunToType(String kubun) {
    return kubun == '3' ? 'sale' : 'rental';
  }

  static String _kubunToLabel(String kubun) {
    switch (kubun) {
      case '1':
        return 'レンタル';
      case '2':
        return '返却';
      case '3':
        return '汎用配送';
      case '4':
        return '預入引取';
      case '5':
        return '預入返却';
      default:
        return kubun;
    }
  }

  /// pcw 側 SELECT は kibou_time が空の種別もあるため hosoku (備考) で代用。
  static String _pickDeliveryTime(Map<String, dynamic> json) {
    final t = (json['kibou_time'] ?? '').toString();
    if (t.isNotEmpty) return t;
    return (json['hosoku'] ?? '').toString();
  }

  /// kubun=3 (汎用) のみ pn2.panhaisou_hinmei、他は syohin_name。
  /// fromJson はどちらも見て non-empty を採用する。
  static String _pickItemName(Map<String, dynamic> json) {
    final syohin = (json['syohin_name'] ?? '').toString();
    if (syohin.isNotEmpty) return syohin;
    return (json['panhaisou_hinmei'] ?? '').toString();
  }
}
